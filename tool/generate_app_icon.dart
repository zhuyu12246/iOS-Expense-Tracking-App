// Generates the app icons for 轻记账 — both the iOS and the macOS icon sets.
//
//   dart run tool/generate_app_icon.dart
//
// The mark is drawn from scratch in code (indigo gradient + a bold ¥), so every
// size is rendered crisp, stays on brand with the app's palette, and can be
// regenerated at any time.
//
//   * iOS  : full-bleed square, RGB with no alpha channel — the App Store
//            rejects icons that carry transparency.
//   * macOS: Apple's squircle (824/1024 body with rounded corners) on a
//            transparent canvas, RGBA, so it looks native in the Dock.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Size of the master render. Everything else is area-averaged from it.
const int _masterSize = 1024;

/// Samples per pixel per axis when rendering the master.
const int _superSample = 2;

// ---- Brand palette -------------------------------------------------------

const _Rgb _topColor = _Rgb(0x6E, 0x7B, 0xFF);
const _Rgb _bottomColor = _Rgb(0x3A, 0x46, 0xC9);
const _Rgb _shadowColor = _Rgb(0x18, 0x1F, 0x63);

/// Stroke radius of the ¥ mark, in normalised face coordinates.
const double _stroke = 0.036;

/// Capsule segments that make up the ¥ glyph:
/// (x1, y1, x2, y2) in normalised 0..1 face coordinates, y pointing down.
const List<(double, double, double, double)> _segments =
    <(double, double, double, double)>[
  (0.295, 0.300, 0.500, 0.500), // 左撇
  (0.705, 0.300, 0.500, 0.500), // 右撇
  (0.500, 0.490, 0.500, 0.712), // 竖：从交叉点起笔，避免上方出现小圆凸起
  (0.318, 0.568, 0.682, 0.568), // 上横
  (0.318, 0.658, 0.682, 0.658), // 下横
];

/// Bounding box of the glyph (plus the drop shadow offset) used to skip the
/// expensive per-segment maths for pixels nowhere near the mark.
const double _glyphMin = 0.24;
const double _glyphMax = 0.77;

/// macOS squircle geometry, matching Apple's 824/1024 icon grid.
const double _macInset = 0.0975;
const double _macBody = 0.805;
const double _macRadius = 0.181;

/// iOS set: filenames referenced by the iOS Contents.json.
const Map<String, int> _iosTargets = <String, int>{
  'Icon-App-20x20@1x.png': 20,
  'Icon-App-20x20@2x.png': 40,
  'Icon-App-20x20@3x.png': 60,
  'Icon-App-29x29@1x.png': 29,
  'Icon-App-29x29@2x.png': 58,
  'Icon-App-29x29@3x.png': 87,
  'Icon-App-40x40@1x.png': 40,
  'Icon-App-40x40@2x.png': 80,
  'Icon-App-40x40@3x.png': 120,
  'Icon-App-60x60@2x.png': 120,
  'Icon-App-60x60@3x.png': 180,
  'Icon-App-76x76@1x.png': 76,
  'Icon-App-76x76@2x.png': 152,
  'Icon-App-83.5x83.5@2x.png': 167,
  'Icon-App-1024x1024@1x.png': 1024,
};

/// macOS set: filenames referenced by the macOS Contents.json.
const Map<String, int> _macTargets = <String, int>{
  'app_icon_16.png': 16,
  'app_icon_32.png': 32,
  'app_icon_64.png': 64,
  'app_icon_128.png': 128,
  'app_icon_256.png': 256,
  'app_icon_512.png': 512,
  'app_icon_1024.png': 1024,
};

const String _iosIconDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const String _macIconDir = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
const String _sourceCopyPath = 'docs/app-icon.png';

void main() {
  final iosDir = Directory(_iosIconDir);
  final macDir = Directory(_macIconDir);
  if (!iosDir.existsSync() && !macDir.existsSync()) {
    stderr.writeln('找不到图标目录，请在项目根目录运行本脚本');
    exit(1);
  }

  stdout.writeln('渲染 $_masterSize×$_masterSize 母版…');
  final iosMaster = _renderMaster(_masterSize, macOS: false);
  final macMaster = _renderMaster(_masterSize, macOS: true);

  File(_sourceCopyPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(
      _encodePng(_masterSize, _masterSize, iosMaster, keepAlpha: false),
    );
  stdout.writeln('  $_sourceCopyPath');

  if (iosDir.existsSync()) {
    for (final entry in _iosTargets.entries) {
      final size = entry.value;
      final pixels = _resample(iosMaster, _masterSize, size);
      File('$_iosIconDir/${entry.key}').writeAsBytesSync(
        _encodePng(size, size, pixels, keepAlpha: false),
      );
    }
    stdout.writeln('  iOS：${_iosTargets.length} 个尺寸 → $_iosIconDir');
  }

  if (macDir.existsSync()) {
    for (final entry in _macTargets.entries) {
      final size = entry.value;
      final pixels = _resample(macMaster, _masterSize, size);
      File('$_macIconDir/${entry.key}').writeAsBytesSync(
        _encodePng(size, size, pixels, keepAlpha: true),
      );
    }
    stdout.writeln('  macOS：${_macTargets.length} 个尺寸 → $_macIconDir');
  }

  stdout.writeln('完成。');
}

// ---- Drawing -------------------------------------------------------------

class _Rgb {
  const _Rgb(this.r, this.g, this.b);

  final int r;
  final int g;
  final int b;
}

/// One sample: straight (non-premultiplied) 0..255 components.
class _Rgba {
  _Rgba(this.r, this.g, this.b, this.a);

  double r;
  double g;
  double b;
  double a;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// 1 in the middle, fading smoothly to 0 at [radius].
double _glow(double u, double v, double cx, double cy, double radius) {
  final dx = u - cx;
  final dy = v - cy;
  final d = math.sqrt(dx * dx + dy * dy) / radius;
  if (d >= 1) return 0;
  final k = 1 - d;
  return k * k;
}

double _distanceSquaredToSegment(
  double px,
  double py,
  double x1,
  double y1,
  double x2,
  double y2,
) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final lengthSquared = dx * dx + dy * dy;
  var t = lengthSquared == 0
      ? 0.0
      : ((px - x1) * dx + (py - y1) * dy) / lengthSquared;
  t = t.clamp(0.0, 1.0);
  final ex = px - (x1 + t * dx);
  final ey = py - (y1 + t * dy);
  return ex * ex + ey * ey;
}

/// Antialiased coverage (0..1) of the ¥ mark at a normalised point.
double _glyphCoverage(double u, double v, double feather) {
  if (u < _glyphMin || u > _glyphMax || v < _glyphMin || v > _glyphMax) {
    return 0;
  }
  var best = double.infinity;
  for (final segment in _segments) {
    final d = _distanceSquaredToSegment(
      u,
      v,
      segment.$1,
      segment.$2,
      segment.$3,
      segment.$4,
    );
    if (d < best) best = d;
  }
  final signed = math.sqrt(best) - _stroke;
  return (0.5 - signed / feather).clamp(0.0, 1.0);
}

/// Antialiased coverage of a rounded rectangle.
double _roundedRectCoverage(
  double u,
  double v,
  double left,
  double top,
  double right,
  double bottom,
  double radius,
  double feather,
) {
  final cx = (left + right) / 2;
  final cy = (top + bottom) / 2;
  final halfWidth = (right - left) / 2 - radius;
  final halfHeight = (bottom - top) / 2 - radius;
  final dx = (u - cx).abs() - halfWidth;
  final dy = (v - cy).abs() - halfHeight;
  final outsideX = math.max(dx, 0.0);
  final outsideY = math.max(dy, 0.0);
  final outside = math.sqrt(outsideX * outsideX + outsideY * outsideY);
  final inside = math.min(math.max(dx, dy), 0.0);
  final signed = outside + inside - radius;
  return (0.5 - signed / feather).clamp(0.0, 1.0);
}

/// The icon face itself: gradient background, glow, halo, shadow and glyph.
_Rgba _shadeFace(double u, double v, double feather) {
  // Diagonal gradient, eased so the middle stays rich instead of washing out.
  var t = (u * 0.45 + v * 0.78 - 0.09).clamp(0.0, 1.0);
  t = t * t * (3 - 2 * t);
  final color = _Rgba(
    _lerp(_topColor.r.toDouble(), _bottomColor.r.toDouble(), t),
    _lerp(_topColor.g.toDouble(), _bottomColor.g.toDouble(), t),
    _lerp(_topColor.b.toDouble(), _bottomColor.b.toDouble(), t),
    255,
  );

  // Top-left highlight.
  final highlight = _glow(u, v, 0.24, 0.14, 0.95) * 0.20;
  color
    ..r = _lerp(color.r, 255, highlight)
    ..g = _lerp(color.g, 255, highlight)
    ..b = _lerp(color.b, 255, highlight);

  // Bottom-right shade for depth.
  final shade = _glow(u, v, 0.98, 1.04, 0.88) * 0.30;
  color
    ..r = _lerp(color.r, _shadowColor.r.toDouble(), shade)
    ..g = _lerp(color.g, _shadowColor.g.toDouble(), shade)
    ..b = _lerp(color.b, _shadowColor.b.toDouble(), shade);

  // Soft halo behind the mark, so the glyph sits on a lighter disc.
  final halo = _glow(u, v, 0.5, 0.5, 0.46) * 0.13;
  color
    ..r = _lerp(color.r, 255, halo)
    ..g = _lerp(color.g, 255, halo)
    ..b = _lerp(color.b, 255, halo);

  // Drop shadow of the mark.
  final shadowCoverage = _glyphCoverage(u, v - 0.014, feather);
  if (shadowCoverage > 0) {
    final a = shadowCoverage * 0.26;
    color
      ..r = _lerp(color.r, _shadowColor.r.toDouble(), a)
      ..g = _lerp(color.g, _shadowColor.g.toDouble(), a)
      ..b = _lerp(color.b, _shadowColor.b.toDouble(), a);
  }

  // The mark itself.
  final coverage = _glyphCoverage(u, v, feather);
  if (coverage > 0) {
    color
      ..r = _lerp(color.r, 255, coverage)
      ..g = _lerp(color.g, 255, coverage)
      ..b = _lerp(color.b, 255, coverage);
  }

  return color;
}

/// macOS variant: the face is scaled into Apple's squircle and the corners
/// outside it become transparent.
_Rgba _shadeMac(double u, double v, double feather) {
  final coverage = _roundedRectCoverage(
    u,
    v,
    _macInset,
    _macInset,
    _macInset + _macBody,
    _macInset + _macBody,
    _macRadius,
    feather,
  );
  if (coverage <= 0) return _Rgba(0, 0, 0, 0);

  final face = _shadeFace(
    ((u - _macInset) / _macBody).clamp(0.0, 1.0),
    ((v - _macInset) / _macBody).clamp(0.0, 1.0),
    feather / _macBody,
  );
  return _Rgba(face.r, face.g, face.b, coverage * 255);
}

Uint8List _renderMaster(int size, {required bool macOS}) {
  final feather = 1.25 / size;
  final samples = _superSample * _superSample;
  final out = Uint8List(size * size * 4);

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      var r = 0.0;
      var g = 0.0;
      var b = 0.0;
      var a = 0.0;
      for (var sy = 0; sy < _superSample; sy++) {
        final v = (y + (sy + 0.5) / _superSample) / size;
        for (var sx = 0; sx < _superSample; sx++) {
          final u = (x + (sx + 0.5) / _superSample) / size;
          final c = macOS ? _shadeMac(u, v, feather) : _shadeFace(u, v, feather);
          // Accumulate premultiplied so transparent corners stay clean.
          final alpha = c.a / 255;
          r += c.r * alpha;
          g += c.g * alpha;
          b += c.b * alpha;
          a += c.a;
        }
      }
      final p = (y * size + x) * 4;
      final alphaAverage = a / samples;
      final unpremultiply = alphaAverage <= 0 ? 0.0 : 255 / alphaAverage;
      out[p] = (r / samples * unpremultiply).round().clamp(0, 255);
      out[p + 1] = (g / samples * unpremultiply).round().clamp(0, 255);
      out[p + 2] = (b / samples * unpremultiply).round().clamp(0, 255);
      out[p + 3] = alphaAverage.round().clamp(0, 255);
    }
  }
  return out;
}

/// Separable box filter: exact area averaging from [srcSize] down to
/// [dstSize]. Keeps the small icons (16px) smooth instead of aliased, and
/// works in premultiplied alpha so edges do not pick up dark fringes.
Uint8List _resample(Uint8List src, int srcSize, int dstSize) {
  if (srcSize == dstSize) return src;
  const channels = 4;
  final scale = srcSize / dstSize;

  final horizontal = Float32List(srcSize * dstSize * channels);
  for (var y = 0; y < srcSize; y++) {
    final srcRow = y * srcSize * channels;
    final dstRow = y * dstSize * channels;
    for (var x = 0; x < dstSize; x++) {
      final start = x * scale;
      final end = start + scale;
      var weight = 0.0;
      var r = 0.0;
      var g = 0.0;
      var b = 0.0;
      var a = 0.0;
      for (var i = start.floor(); i < end.ceil() && i < srcSize; i++) {
        final overlap = math.min(end, i + 1.0) - math.max(start, i.toDouble());
        if (overlap <= 0) continue;
        final p = srcRow + i * channels;
        final alpha = src[p + 3] / 255;
        r += src[p] * alpha * overlap;
        g += src[p + 1] * alpha * overlap;
        b += src[p + 2] * alpha * overlap;
        a += src[p + 3] * overlap;
        weight += overlap;
      }
      final p = dstRow + x * channels;
      horizontal[p] = r / weight;
      horizontal[p + 1] = g / weight;
      horizontal[p + 2] = b / weight;
      horizontal[p + 3] = a / weight;
    }
  }

  final out = Uint8List(dstSize * dstSize * channels);
  for (var y = 0; y < dstSize; y++) {
    final start = y * scale;
    final end = start + scale;
    for (var x = 0; x < dstSize; x++) {
      var weight = 0.0;
      var r = 0.0;
      var g = 0.0;
      var b = 0.0;
      var a = 0.0;
      for (var j = start.floor(); j < end.ceil() && j < srcSize; j++) {
        final overlap = math.min(end, j + 1.0) - math.max(start, j.toDouble());
        if (overlap <= 0) continue;
        final p = (j * dstSize + x) * channels;
        r += horizontal[p] * overlap;
        g += horizontal[p + 1] * overlap;
        b += horizontal[p + 2] * overlap;
        a += horizontal[p + 3] * overlap;
        weight += overlap;
      }
      final p = (y * dstSize + x) * channels;
      final alpha = a / weight;
      final unpremultiply = alpha <= 0 ? 0.0 : 255 / alpha;
      out[p] = (r / weight * unpremultiply).round().clamp(0, 255);
      out[p + 1] = (g / weight * unpremultiply).round().clamp(0, 255);
      out[p + 2] = (b / weight * unpremultiply).round().clamp(0, 255);
      out[p + 3] = alpha.round().clamp(0, 255);
    }
  }
  return out;
}

// ---- Minimal PNG writer --------------------------------------------------

final List<int> _crcTable = _buildCrcTable();

List<int> _buildCrcTable() {
  final table = List<int>.filled(256, 0);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    table[n] = c;
  }
  return table;
}

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final byte in bytes) {
    c = _crcTable[(c ^ byte) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

List<int> _uint32(int value) => <int>[
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];

Uint8List _chunk(String type, List<int> data) {
  final typeBytes = type.codeUnits;
  final body = Uint8List(typeBytes.length + data.length)
    ..setRange(0, typeBytes.length, typeBytes)
    ..setRange(typeBytes.length, typeBytes.length + data.length, data);
  final out = BytesBuilder()
    ..add(_uint32(data.length))
    ..add(body)
    ..add(_uint32(_crc32(body)));
  return out.toBytes();
}

/// [rgba] always has 4 channels; when [keepAlpha] is false the alpha channel is
/// dropped and the PNG is written as truecolour RGB (what iOS requires).
Uint8List _encodePng(
  int width,
  int height,
  Uint8List rgba, {
  required bool keepAlpha,
}) {
  const channels = 4;
  final outChannels = keepAlpha ? 4 : 3;
  final stride = width * outChannels;
  final raw = Uint8List(height * (stride + 1));
  var out = 0;

  for (var y = 0; y < height; y++) {
    // Filter type 1 (Sub): compresses a smooth gradient nicely.
    raw[out++] = 1;
    final rowStart = y * width * channels;
    for (var i = 0; i < width; i++) {
      final pixel = rowStart + i * channels;
      for (var c = 0; c < outChannels; c++) {
        final value = rgba[pixel + c];
        final left = i > 0 ? rgba[pixel - channels + c] : 0;
        raw[out++] = (value - left) & 0xFF;
      }
    }
  }

  final header = <int>[
    ..._uint32(width),
    ..._uint32(height),
    8, // bit depth
    keepAlpha ? 6 : 2, // colour type: RGBA or RGB
    0, // deflate
    0, // adaptive filtering
    0, // no interlace
  ];

  return (BytesBuilder()
        ..add(<int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        ..add(_chunk('IHDR', header))
        ..add(_chunk('IDAT', ZLibCodec(level: 9).encode(raw)))
        ..add(_chunk('IEND', const <int>[])))
      .toBytes();
}
