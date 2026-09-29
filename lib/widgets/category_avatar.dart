import 'package:flutter/material.dart';

import '../utils/icon_registry.dart';

/// Round tinted icon used for categories and accounts.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.iconKey,
    required this.color,
    this.size = 42,
    this.selected = false,
  });

  final String iconKey;
  final Color color;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? color : color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        iconForKey(iconKey),
        size: size * 0.5,
        color: selected ? Colors.white : color,
      ),
    );
  }
}
