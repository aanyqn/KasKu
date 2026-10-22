import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category.dart';
import '../data/models/transaction.dart';
import '../data/repositories/category_repository.dart';
import 'isar_provider.dart';

// ── Category list notifier ────────────────────────────────────────────────────

class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final isar = await ref.watch(isarProvider.future);
    return CategoryRepository(isar).getAll();
  }

  Future<void> add(Category category) async {
    final isar = await ref.read(isarProvider.future);
    await CategoryRepository(isar).addCategory(category);
    ref.invalidateSelf();
  }

  /// Update an existing category (renamed from `update` to avoid override conflict)
  Future<void> edit(Category category) async {
    final isar = await ref.read(isarProvider.future);
    await CategoryRepository(isar).updateCategory(category);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    final isar = await ref.read(isarProvider.future);
    await CategoryRepository(isar).deleteCategory(id);
    ref.invalidateSelf();
  }
}

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(
  CategoryNotifier.new,
);

// ── Filtered by type ─────────────────────────────────────────────────────────

final categoriesByTypeProvider =
    FutureProvider.family<List<Category>, TransactionType>((ref, type) async {
  final all = await ref.watch(categoryProvider.future);
  return all.where((c) => c.type == type).toList();
});
