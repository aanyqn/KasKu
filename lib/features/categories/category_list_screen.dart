import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../providers/category_provider.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategori')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_cat',
        onPressed: () => _showAddEditDialog(context, ref, null),
        child: const Icon(Icons.add_rounded),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final income =
              categories.where((c) => c.type == TransactionType.income).toList();
          final expense =
              categories.where((c) => c.type == TransactionType.expense).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _SectionHeader(label: '💰 Pemasukan (${income.length})'),
              const SizedBox(height: 8),
              ...income.map((c) => _CategoryTile(
                    category: c,
                    onEdit: () => _showAddEditDialog(context, ref, c),
                    onDelete: () => _confirmDelete(context, ref, c),
                  )),
              const SizedBox(height: 16),
              _SectionHeader(label: '💸 Pengeluaran (${expense.length})'),
              const SizedBox(height: 8),
              ...expense.map((c) => _CategoryTile(
                    category: c,
                    onEdit: () => _showAddEditDialog(context, ref, c),
                    onDelete: () => _confirmDelete(context, ref, c),
                  )),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.emerald, strokeWidth: 2),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _showAddEditDialog(
    BuildContext context,
    WidgetRef ref,
    Category? existing,
  ) async {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final iconController =
        TextEditingController(text: existing?.icon ?? '');
    TransactionType type = existing?.type ?? TransactionType.expense;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing != null ? 'Edit Kategori' : 'Tambah Kategori'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type selector
              Row(
                children: [
                  _typeButton(
                    'Pengeluaran',
                    TransactionType.expense,
                    type,
                    AppColors.expense,
                    (t) => setState(() => type = t),
                  ),
                  const SizedBox(width: 8),
                  _typeButton(
                    'Pemasukan',
                    TransactionType.income,
                    type,
                    AppColors.income,
                    (t) => setState(() => type = t),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(
                  labelText: 'Emoji / Ikon',
                  hintText: '🏠',
                ),
                maxLength: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kategori',
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final icon = iconController.text.trim();
                if (name.isEmpty) return;

                final cat = existing ?? Category();
                cat
                  ..name = name
                  ..icon = icon.isEmpty ? '📦' : icon
                  ..type = type
                  ..isDefault = false;

                if (existing != null) {
                  ref.read(categoryProvider.notifier).edit(cat);
                } else {
                  ref.read(categoryProvider.notifier).add(cat);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(
    String label,
    TransactionType value,
    TransactionType selected,
    Color color,
    ValueChanged<TransactionType> onChanged,
  ) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? color : null,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category cat,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: Text('${cat.icon} ${cat.name} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(categoryProvider.notifier).delete(cat.id);
    }
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

// ── Category tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = category.type == TransactionType.income;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (isIncome ? AppColors.income : AppColors.expense)
                .withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(category.icon,
                style: const TextStyle(fontSize: 18)),
          ),
        ),
        title: Text(category.name,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: category.isDefault
            ? Text('Default',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.emerald,
                      fontSize: 11,
                    ))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            if (!category.isDefault)
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.expense),
                onPressed: onDelete,
                tooltip: 'Hapus',
              ),
          ],
        ),
      ),
    );
  }
}
