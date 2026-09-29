import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/transaction_record.dart';
import '../models/types.dart';
import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../models/account.dart';
import '../widgets/amount_keypad.dart';
import '../widgets/category_avatar.dart';
import '../widgets/sheets.dart';
import '../widgets/tx_type_selector.dart';
import 'account_editor_screen.dart';

/// Create or edit a single record.
class TransactionEditorScreen extends StatefulWidget {
  const TransactionEditorScreen({super.key, this.record});

  final TransactionRecord? record;

  @override
  State<TransactionEditorScreen> createState() =>
      _TransactionEditorScreenState();
}

class _TransactionEditorScreenState extends State<TransactionEditorScreen> {
  late TxType _type;
  late String _input;
  String? _categoryId;
  late String _accountId;
  late DateTime _date;
  late String _note;
  bool _saving = false;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final provider = context.read<LedgerProvider>();
    final record = widget.record;

    _type = record?.type ?? TxType.expense;
    _input = record == null ? '' : centsToInput(record.amount);
    _categoryId = record?.categoryId ?? _firstCategoryId(provider, _type);
    _accountId = record?.accountId ??
        (provider.accounts.isEmpty ? '' : provider.accounts.first.id);
    _date = record?.date ?? provider.now;
    _note = record?.note ?? '';
  }

  String? _firstCategoryId(LedgerProvider provider, TxType type) {
    final list = provider.categoriesOf(type);
    return list.isEmpty ? null : list.first.id;
  }

  void _onTypeChanged(TxType type) {
    if (type == _type) return;
    final provider = context.read<LedgerProvider>();
    setState(() {
      _type = type;
      final list = provider.categoriesOf(type);
      final stillValid = list.any((item) => item.id == _categoryId);
      if (!stillValid) {
        _categoryId = list.isEmpty ? null : list.first.id;
      }
    });
  }

  void _onKey(String key) {
    setState(() {
      if (key == '.') {
        if (_input.contains('.')) return;
        _input = _input.isEmpty ? '0.' : '$_input.';
        return;
      }
      final parts = _input.split('.');
      if (parts.length == 2 && parts[1].length >= 2) return;
      if (parts.length == 1 && parts[0].length >= 9) return;
      if (_input == '0') {
        _input = key;
        return;
      }
      _input = '$_input$key';
    });
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _pickAccount() async {
    final provider = context.read<LedgerProvider>();

    // No wallets yet: take the user straight to the wallet editor and select
    // whatever they create, instead of showing an empty picker.
    if (provider.accounts.isEmpty) {
      final created = await Navigator.of(context).push<Account>(
        MaterialPageRoute<Account>(
          builder: (_) => const AccountEditorScreen(),
        ),
      );
      if (!mounted) return;
      final accounts = context.read<LedgerProvider>().accounts;
      if (created != null) {
        setState(() => _accountId = created.id);
      } else if (accounts.isNotEmpty) {
        setState(() => _accountId = accounts.last.id);
      }
      return;
    }

    final account = await showAccountPickerSheet(
      context,
      accounts: provider.accounts,
      selectedId: _accountId,
      balanceOf: provider.accountBalance,
    );
    if (account != null) setState(() => _accountId = account.id);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePickerSheet(context, initial: _date);
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _editNote() async {
    final result = await showNoteEditorSheet(context, initial: _note);
    if (result != null) setState(() => _note = result);
  }

  Future<void> _save() async {
    final provider = context.read<LedgerProvider>();
    final navigator = Navigator.of(context);
    final cents = parseAmountToCents(_input);

    if (cents <= 0) {
      showToast(context, '请输入金额');
      return;
    }
    if (_categoryId == null) {
      showToast(context, '请选择一个分类');
      return;
    }
    if (_accountId.isEmpty) {
      showToast(context, '请先添加一个账户');
      return;
    }

    setState(() => _saving = true);

    if (_isEditing) {
      await provider.updateRecord(
        widget.record!.copyWith(
          type: _type,
          amount: cents,
          categoryId: _categoryId,
          accountId: _accountId,
          note: _note,
          date: _date,
        ),
      );
    } else {
      await provider.addRecord(
        type: _type,
        amount: cents,
        categoryId: _categoryId!,
        accountId: _accountId,
        date: _date,
        note: _note,
      );
    }

    if (!mounted) return;
    navigator.pop();
  }

  Future<void> _delete() async {
    final provider = context.read<LedgerProvider>();
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: '删除这笔记录？',
      message: '删除后无法恢复。',
    );
    if (!confirmed) return;
    await provider.deleteRecord(widget.record!.id);
    if (!mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final palette = context.palette;
    final categories = provider.categoriesOf(_type);
    final account = provider.accountById(_accountId);
    final cents = parseAmountToCents(_input);
    final now = provider.now;

    return Scaffold(
      backgroundColor: palette.pageBackground,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '取消',
            style: TextStyle(fontSize: 15, color: palette.muted),
          ),
        ),
        leadingWidth: 64,
        title: Text(
          _isEditing ? '编辑记录' : '记一笔',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: <Widget>[
          if (_isEditing)
            IconButton(
              tooltip: '删除',
              onPressed: _delete,
              icon: Icon(Icons.delete_outline_rounded, color: palette.expense),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TxTypeSelector(value: _type, onChanged: _onTypeChanged),
          ),
          _AmountDisplay(input: _input),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _MetaChip(
                    icon: Icons.account_balance_wallet_rounded,
                    label: provider.accounts.isEmpty
                        ? '添加账户'
                        : (account?.name ?? '选择账户'),
                    onTap: _pickAccount,
                    highlighted: account == null && provider.accounts.isEmpty,
                  ),
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.event_rounded,
                    label: _dateLabel(_date, now),
                    onTap: _pickDate,
                  ),
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.edit_note_rounded,
                    label: _note.isEmpty ? '添加备注' : _note,
                    onTap: _editNote,
                    highlighted: _note.isNotEmpty,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: categories.isEmpty
                ? Center(
                    child: Text(
                      '还没有${_type.label}分类，去「我的 - 分类管理」添加',
                      style: TextStyle(fontSize: 13, color: palette.muted),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    itemCount: categories.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 0.86,
                    ),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _CategoryCell(
                        category: category,
                        selected: category.id == _categoryId,
                        onTap: () =>
                            setState(() => _categoryId = category.id),
                      );
                    },
                  ),
          ),
          Container(
            color: palette.card,
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              10 + MediaQuery.of(context).padding.bottom,
            ),
            child: AmountKeypad(
              onKey: _onKey,
              onBackspace: _onBackspace,
              onSave: _save,
              saveEnabled: !_saving && cents > 0,
              saveLabel: _isEditing ? '保存' : '记一笔',
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (date.year == now.year) return monthDayLabel(date);
    return fullDateLabel(date);
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.input});

  final String input;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isEmpty = input.isEmpty;
    final text = isEmpty ? '0.00' : input;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            '¥',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isEmpty
                  ? palette.faint
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 42,
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: isEmpty
                  ? palette.faint
                  : Theme.of(context).colorScheme.onSurface,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 3),
          const _BlinkingCaret(),
        ],
      ),
    );
  }
}

class _BlinkingCaret extends StatefulWidget {
  const _BlinkingCaret();

  @override
  State<_BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<_BlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2.4,
        height: 34,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: context.palette.brand,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = highlighted ? palette.brand : palette.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: palette.chipBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded, size: 14, color: palette.faint),
          ],
        ),
      ),
    );
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CategoryAvatar(
            iconKey: category.iconKey,
            color: color,
            size: 46,
            selected: selected,
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? color
                  : Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.75,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
