import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../models/types.dart';
import '../data/default_data.dart';
import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/icon_registry.dart';
import '../widgets/category_avatar.dart';
import '../widgets/pickers.dart';
import '../widgets/sheets.dart';
import '../widgets/surface_card.dart';

/// Create or edit a wallet.
class AccountEditorScreen extends StatefulWidget {
  const AccountEditorScreen({super.key, this.account});

  final Account? account;

  @override
  State<AccountEditorScreen> createState() => _AccountEditorScreenState();
}

class _AccountEditorScreenState extends State<AccountEditorScreen> {
  static const List<String> _accountIcons = <String>[
    'cash',
    'bank',
    'creditcard',
    'wallet',
    'alipay',
    'wechat',
    'savings',
    'invest',
    'other',
  ];

  late final TextEditingController _nameController =
      TextEditingController(text: widget.account?.name ?? '');
  late final TextEditingController _balanceController = TextEditingController(
    text: widget.account == null || widget.account!.initialBalance == 0
        ? ''
        : (widget.account!.initialBalance / 100).toStringAsFixed(2),
  );
  late String _iconKey = widget.account?.iconKey ?? 'cash';
  late int _colorValue =
      widget.account?.colorValue ?? kAccentPalette[2].toARGB32();
  late AccountKind _kind = widget.account?.kind ?? AccountKind.cash;

  bool get _isEditing => widget.account != null;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showToast(context, '请输入账户名称');
      return;
    }
    final balanceText = _balanceController.text.trim();
    final balance = balanceText.isEmpty
        ? 0
        : ((double.tryParse(balanceText) ?? 0) * 100).round();

    final provider = context.read<LedgerProvider>();
    final navigator = Navigator.of(context);

    final account = Account(
      id: widget.account?.id ?? provider.newId('acc'),
      name: name,
      iconKey: _iconKey,
      colorValue: _colorValue,
      kind: _kind,
      initialBalance: balance,
      sortOrder: widget.account?.sortOrder ?? 0,
      isSystem: widget.account?.isSystem ?? false,
    );

    await provider.saveAccount(account);

    if (!mounted) return;
    navigator.pop(account);
  }

  void _applyPreset(Account preset) {
    setState(() {
      _nameController.text = preset.name;
      _iconKey = preset.iconKey;
      _colorValue = preset.colorValue;
      _kind = preset.kind;
    });
  }

  Future<void> _delete() async {
    final provider = context.read<LedgerProvider>();
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: '删除「${widget.account!.name}」？',
      message: '若该账户下还有账单记录，需要先处理这些记录。',
    );
    if (!confirmed) return;
    final result = await provider.deleteAccount(widget.account!.id);
    if (!mounted) return;
    if (result.ok) {
      navigator.pop();
    } else {
      showToast(context, result.message ?? '删除失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final provider = context.watch<LedgerProvider>();
    final liveBalance =
        widget.account == null ? 0 : provider.accountBalance(widget.account!.id);

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _isEditing ? '编辑账户' : '新建账户',
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          Center(
            child: CategoryAvatar(
              iconKey: _iconKey,
              color: Color(_colorValue),
              size: 72,
              selected: true,
            ),
          ),
          if (!_isEditing) ...<Widget>[
            const SizedBox(height: 18),
            const SectionHeader(
              title: '快速创建',
              subtitle: '选一个常用钱包，名称和图标会自动填好',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final preset in kAccountPresets)
                  GestureDetector(
                    onTap: () => _applyPreset(preset),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: palette.chipBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            iconForKey(preset.iconKey),
                            size: 15,
                            color: Color(preset.colorValue),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            preset.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          const SectionHeader(title: '名称'),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _nameController,
              maxLength: 12,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: '例如：招商银行',
                counterText: '',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: '账户类型'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final kind in AccountKind.values)
                GestureDetector(
                  onTap: () => setState(() => _kind = kind),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _kind == kind
                          ? palette.brand.withValues(alpha: 0.12)
                          : palette.chipBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _kind == kind
                            ? palette.brand
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      kind.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _kind == kind
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _kind == kind
                            ? palette.brand
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionHeader(
            title: '初始余额',
            subtitle: '记账从这个数字开始累加',
          ),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixText: '¥ ',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: '图标'),
          IconPicker(
            selected: _iconKey,
            color: Color(_colorValue),
            icons: _accountIcons,
            onChanged: (key) => setState(() => _iconKey = key),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: '颜色'),
          ColorPicker(
            selected: _colorValue,
            onChanged: (value) => setState(() => _colorValue = value),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: palette.brand,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('保存'),
          ),
          if (_isEditing) ...<Widget>[
            const SizedBox(height: 16),
            Center(
              child: Text(
                '当前余额 ${formatMoney(liveBalance)}',
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
