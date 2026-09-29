import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/types.dart';
import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/category_avatar.dart';
import '../widgets/pickers.dart';
import '../widgets/sheets.dart';
import '../widgets/surface_card.dart';
import '../widgets/tx_type_selector.dart';

/// Create or edit a category.
class CategoryEditorScreen extends StatefulWidget {
  const CategoryEditorScreen({super.key, this.category, this.type});

  final Category? category;
  final TxType? type;

  @override
  State<CategoryEditorScreen> createState() => _CategoryEditorScreenState();
}

class _CategoryEditorScreenState extends State<CategoryEditorScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.category?.name ?? '');
  late String _iconKey = widget.category?.iconKey ?? 'restaurant';
  late int _colorValue =
      widget.category?.colorValue ?? kAccentPalette.first.toARGB32();
  late TxType _type = widget.category?.type ?? widget.type ?? TxType.expense;

  bool get _isEditing => widget.category != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showToast(context, '请输入分类名称');
      return;
    }
    final provider = context.read<LedgerProvider>();
    final navigator = Navigator.of(context);

    await provider.saveCategory(
      Category(
        id: widget.category?.id ?? provider.newId('cat'),
        name: name,
        iconKey: _iconKey,
        colorValue: _colorValue,
        type: _type,
        sortOrder: widget.category?.sortOrder ?? 0,
        isSystem: widget.category?.isSystem ?? false,
      ),
    );

    if (!mounted) return;
    navigator.pop();
  }

  Future<void> _delete() async {
    final provider = context.read<LedgerProvider>();
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: '删除「${widget.category!.name}」？',
      message: '若该分类下已经记过账，需要先处理这些记录。',
    );
    if (!confirmed) return;
    final result = await provider.deleteCategory(widget.category!.id);
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

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _isEditing ? '编辑分类' : '新建分类',
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
          const SizedBox(height: 20),
          const SectionHeader(title: '名称'),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _nameController,
              maxLength: 8,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: '例如：餐饮',
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
          const SectionHeader(title: '类型'),
          TxTypeSelector(
            value: _type,
            onChanged: (value) => setState(() => _type = value),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: '图标'),
          IconPicker(
            selected: _iconKey,
            color: Color(_colorValue),
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
        ],
      ),
    );
  }
}
