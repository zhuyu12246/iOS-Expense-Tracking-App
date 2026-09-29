import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/account.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'category_avatar.dart';

/// Shows a floating snack bar message.
void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
}

/// iOS style destructive confirmation.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  String confirmText = '删除',
  String cancelText = '取消',
  bool destructive = true,
}) async {
  final palette = context.palette;
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoTheme(
      data: CupertinoThemeData(
        brightness: Theme.of(dialogContext).brightness,
        primaryColor: palette.brand,
      ),
      child: CupertinoAlertDialog(
        title: Text(title),
        content: message == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(message),
              ),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelText),
          ),
          CupertinoDialogAction(
            isDestructiveAction: destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

/// Asks for a money amount, returns cents.
Future<int?> showAmountInputDialog(
  BuildContext context, {
  required String title,
  String? message,
  int initialCents = 0,
  String confirmText = '保存',
}) async {
  final controller = TextEditingController(
    text: initialCents == 0 ? '' : (initialCents / 100).toStringAsFixed(2),
  );

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (message != null) ...<Widget>[
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: dialogContext.palette.muted,
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: '¥ ',
              hintText: '0.00',
              isDense: true,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
          child: Text(confirmText),
        ),
      ],
    ),
  );

  if (result == null) return null;
  if (result.isEmpty) return 0;
  final value = double.tryParse(result);
  if (value == null) return null;
  return (value * 100).round();
}

/// Rounded sheet shell with a grabber handle and a title.
class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 16),
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Row(
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

Future<T?> _showSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => child,
  );
}

/// Month grid picker.
Future<DateTime?> showMonthPickerSheet(
  BuildContext context, {
  required DateTime initial,
}) {
  var year = initial.year;

  return _showSheet<DateTime>(
    context,
    StatefulBuilder(
      builder: (sheetContext, setState) => _SheetShell(
        title: '选择月份',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => setState(() => year -= 1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$year 年',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(sheetContext).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => year += 1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.0,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: <Widget>[
                for (var month = 1; month <= 12; month++)
                  _MonthCell(
                    label: '$month 月',
                    selected: year == initial.year && month == initial.month,
                    palette: sheetContext.palette,
                    onTap: () =>
                        Navigator.of(sheetContext).pop(DateTime(year, month)),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.brand : palette.chipBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Wallet picker.
Future<Account?> showAccountPickerSheet(
  BuildContext context, {
  required List<Account> accounts,
  required int Function(String accountId) balanceOf,
  String? selectedId,
}) {
  return _showSheet<Account>(
    context,
    _SheetShell(
      title: '选择账户',
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final account in accounts)
            InkWell(
              onTap: () => Navigator.of(context).pop(account),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: <Widget>[
                    CategoryAvatar(
                      iconKey: account.iconKey,
                      color: Color(account.colorValue),
                      size: 38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        account.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      formatMoney(balanceOf(account.id)),
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.muted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      account.id == selectedId
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 20,
                      color: account.id == selectedId
                          ? context.palette.brand
                          : context.palette.faint,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Native date wheel.
Future<DateTime?> showDatePickerSheet(
  BuildContext context, {
  required DateTime initial,
}) {
  var value = initial;
  final palette = context.palette;
  final now = DateTime.now();

  return _showSheet<DateTime>(
    context,
    _SheetShell(
      title: '选择日期',
      trailing: TextButton(
        onPressed: () => Navigator.of(context).pop(value),
        child: const Text('完成'),
      ),
      child: SizedBox(
        height: 216,
        child: CupertinoTheme(
          data: CupertinoThemeData(
            brightness: Theme.of(context).brightness,
            primaryColor: palette.brand,
          ),
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: initial,
            minimumDate: DateTime(now.year - 10),
            maximumDate: DateTime(now.year + 10),
            onDateTimeChanged: (picked) => value = picked,
          ),
        ),
      ),
    ),
  );
}

/// Note editor.
Future<String?> showNoteEditorSheet(
  BuildContext context, {
  String initial = '',
}) {
  final controller = TextEditingController(text: initial)
    ..selection = TextSelection.collapsed(offset: initial.length);

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final palette = sheetContext.palette;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '备注',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(sheetContext).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    maxLength: 40,
                    onSubmitted: (text) =>
                        Navigator.of(sheetContext).pop(text.trim()),
                    decoration: InputDecoration(
                      hintText: '写点什么，例如「和朋友吃火锅」',
                      filled: true,
                      fillColor: palette.chipBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(''),
                          child: const Text('清空'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(sheetContext)
                              .pop(controller.text.trim()),
                          child: const Text('完成'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
