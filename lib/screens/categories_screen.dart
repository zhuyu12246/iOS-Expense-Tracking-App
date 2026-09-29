import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/types.dart';
import '../providers/ledger_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/category_avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/sheets.dart';
import '../widgets/surface_card.dart';
import 'category_editor_screen.dart';

/// Manage expense and income categories.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this)..addListener(_onTabChanged);

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  TxType get _currentType => TxType.values[_tabController.index];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.pageBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => CategoryEditorScreen(type: _currentType),
          ),
        ),
        backgroundColor: palette.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('新建分类'),
      ),
      appBar: AppBar(
        backgroundColor: palette.pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '分类管理',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: palette.brand,
          unselectedLabelColor: palette.muted,
          indicatorColor: palette.brand,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          tabs: const <Widget>[
            Tab(text: '支出'),
            Tab(text: '收入'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _CategoryList(categories: provider.expenseCategories),
          _CategoryList(categories: provider.incomeCategories),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final provider = context.watch<LedgerProvider>();

    if (categories.isEmpty) {
      return const EmptyState(
        icon: Icons.category_rounded,
        title: '还没有分类',
        message: '点击右下角新建一个分类。',
      );
    }

    return SlidableAutoCloseBehavior(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: <Widget>[
          SurfaceCard(
            clip: true,
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                for (var i = 0; i < categories.length; i++) ...<Widget>[
                  if (i > 0)
                    Divider(height: 1, indent: 62, color: palette.border),
                  _CategoryRow(category: categories[i], provider: provider),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.provider});

  final Category category;
  final LedgerProvider provider;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final count = provider.recordCountForCategory(category.id);

    return Slidable(
      key: ValueKey<String>(category.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.48,
        children: <Widget>[
          SlidableAction(
            onPressed: (_) => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => CategoryEditorScreen(category: category),
              ),
            ),
            backgroundColor: palette.brand,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: '编辑',
          ),
          SlidableAction(
            onPressed: (_) => _delete(context),
            backgroundColor: palette.expense,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: '删除',
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => CategoryEditorScreen(category: category),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
            child: Row(
              children: <Widget>[
                CategoryAvatar(
                  iconKey: category.iconKey,
                  color: Color(category.colorValue),
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  count == 0 ? '暂无记录' : '$count 笔',
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '删除「${category.name}」？',
      message: '若该分类下已经记过账，需要先处理这些记录。',
    );
    if (!confirmed) return;
    final result = await provider.deleteCategory(category.id);
    if (!context.mounted) return;
    if (result.ok) {
      showToast(context, '已删除分类');
    } else {
      showToast(context, result.message ?? '删除失败');
    }
  }
}
