import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/icon_registry.dart';
import 'surface_card.dart';

/// Grid of the icons available for categories and accounts.
class IconPicker extends StatelessWidget {
  const IconPicker({
    super.key,
    required this.selected,
    required this.color,
    required this.onChanged,
    this.icons = kIconKeys,
  });

  final String selected;
  final Color color;
  final ValueChanged<String> onChanged;
  final List<String> icons;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final key in icons)
            GestureDetector(
              onTap: () => onChanged(key),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: key == selected ? color : palette.chipBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  iconForKey(key),
                  size: 21,
                  color: key == selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Swatch row for picking an accent colour.
class ColorPicker extends StatelessWidget {
  const ColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.colors = kAccentPalette,
  });

  final int selected;
  final ValueChanged<int> onChanged;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: <Widget>[
          for (final color in colors)
            GestureDetector(
              onTap: () => onChanged(color.toARGB32()),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: color.toARGB32() == selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
