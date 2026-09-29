import 'package:flutter/material.dart';

/// Semantic colours that flip with the brightness of the app.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brand,
    required this.brandDeep,
    required this.brandSoft,
    required this.expense,
    required this.income,
    required this.card,
    required this.border,
    required this.muted,
    required this.faint,
    required this.pageBackground,
    required this.chipBackground,
  });

  final Color brand;
  final Color brandDeep;
  final Color brandSoft;
  final Color expense;
  final Color income;
  final Color card;
  final Color border;
  final Color muted;
  final Color faint;
  final Color pageBackground;
  final Color chipBackground;

  static const Color seed = Color(0xFF5B6BF5);

  static const light = AppPalette(
    brand: seed,
    brandDeep: Color(0xFF3B49C7),
    brandSoft: Color(0xFFEDEFFF),
    expense: Color(0xFFF2555A),
    income: Color(0xFF18B98A),
    card: Colors.white,
    border: Color(0xFFE9EBF2),
    muted: Color(0xFF8A90A6),
    faint: Color(0xFFB9BECD),
    pageBackground: Color(0xFFF4F5F9),
    chipBackground: Color(0xFFF1F2F7),
  );

  static const dark = AppPalette(
    brand: Color(0xFF8A97FF),
    brandDeep: Color(0xFF6C7BFF),
    brandSoft: Color(0xFF232741),
    expense: Color(0xFFFF7A7F),
    income: Color(0xFF35D3A3),
    card: Color(0xFF171A22),
    border: Color(0xFF262A36),
    muted: Color(0xFF8D93A8),
    faint: Color(0xFF5A6076),
    pageBackground: Color(0xFF0B0D12),
    chipBackground: Color(0xFF20242F),
  );

  @override
  AppPalette copyWith({
    Color? brand,
    Color? brandDeep,
    Color? brandSoft,
    Color? expense,
    Color? income,
    Color? card,
    Color? border,
    Color? muted,
    Color? faint,
    Color? pageBackground,
    Color? chipBackground,
  }) {
    return AppPalette(
      brand: brand ?? this.brand,
      brandDeep: brandDeep ?? this.brandDeep,
      brandSoft: brandSoft ?? this.brandSoft,
      expense: expense ?? this.expense,
      income: income ?? this.income,
      card: card ?? this.card,
      border: border ?? this.border,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      pageBackground: pageBackground ?? this.pageBackground,
      chipBackground: chipBackground ?? this.chipBackground,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      brand: Color.lerp(brand, other.brand, t)!,
      brandDeep: Color.lerp(brandDeep, other.brandDeep, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      income: Color.lerp(income, other.income, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light);

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Colours used for category / account dots and charts.
const List<Color> kAccentPalette = <Color>[
  Color(0xFF5B6BF5),
  Color(0xFFF2555A),
  Color(0xFF18B98A),
  Color(0xFFF7A325),
  Color(0xFF8B5CF6),
  Color(0xFF38BDF8),
  Color(0xFFEC4899),
  Color(0xFF34D399),
  Color(0xFFFB923C),
  Color(0xFF6366F1),
  Color(0xFF14B8A6),
  Color(0xFFEF4444),
];

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppPalette.light, Brightness.light);
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.seed,
      brightness: brightness,
    ).copyWith(
      primary: palette.brand,
      surface: palette.card,
      error: palette.expense,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      platform: TargetPlatform.iOS,
      scaffoldBackgroundColor: palette.pageBackground,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[palette],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.pageBackground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF2A2F3D)
            : const Color(0xFF232733),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      textTheme: Typography.blackCupertino.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }
}
