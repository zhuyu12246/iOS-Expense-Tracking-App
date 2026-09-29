import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The rounded, hairline-bordered container used for every grouped block.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 20,
    this.color,
    this.onTap,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shape = BorderRadius.circular(radius);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? palette.card,
        borderRadius: shape,
        border: Border.all(color: palette.border),
        boxShadow: context.isDark
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF1B2033).withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: content,
        ),
      );
    }

    if (clip) {
      content = ClipRRect(borderRadius: shape, child: content);
    }

    return margin == null ? content : Padding(padding: margin!, child: content);
  }
}

/// Small uppercase-ish section title with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                  ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
