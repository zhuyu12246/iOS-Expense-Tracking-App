import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// iOS style numeric keypad with an integrated save button.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.onKey,
    required this.onBackspace,
    required this.onSave,
    this.saveEnabled = true,
    this.saveLabel = '保存',
    this.height = 232,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onSave;
  final bool saveEnabled;
  final String saveLabel;
  final double height;

  static const List<List<String>> _rows = <List<String>>[
    <String>['1', '2', '3'],
    <String>['4', '5', '6'],
    <String>['7', '8', '9'],
    <String>['.', '0', 'back'],
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                for (final row in _rows)
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        for (final key in row)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: _KeypadKey(
                                label: key,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  if (key == 'back') {
                                    onBackspace();
                                  } else {
                                    onKey(key);
                                  }
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: _SaveButton(
                label: saveLabel,
                enabled: saveEnabled,
                gradient: <Color>[palette.brand, palette.brandDeep],
                onTap: () {
                  if (!saveEnabled) return;
                  HapticFeedback.mediumImpact();
                  onSave();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isBackspace = label == 'back';

    return Material(
      color: palette.chipBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Center(
          child: isBackspace
              ? Icon(
                  Icons.backspace_outlined,
                  size: 22,
                  color: Theme.of(context).colorScheme.onSurface,
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.label,
    required this.enabled,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? <BoxShadow>[
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
