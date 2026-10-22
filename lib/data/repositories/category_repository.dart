import 'package:isar/isar.dart';
import '../models/category.dart';
import '../models/transaction.dart';

/// Repository for Category CRUD and seeding default categories
class CategoryRepository {
  final Isar isar;

  CategoryRepository(this.isar);

  // ── Default categories ───────────────────────────────────────────────────

  static final List<Map<String, dynamic>> _defaults = [
    // Expense
    {'name': 'Makanan', 'icon': '🍔', 'type': TransactionType.expense},
    {'name': 'Transportasi', 'icon': '🚗', 'type': TransactionType.expense},
    {'name': 'Hiburan', 'icon': '🎮', 'type': TransactionType.expense},
    {'name': 'Rumah', 'icon': '🏠', 'type': TransactionType.expense},
    {'name': 'Belanja', 'icon': '🛒', 'type': TransactionType.expense},
    {'name': 'Kesehatan', 'icon': '💊', 'type': TransactionType.expense},
    {'name': 'Pendidikan', 'icon': '📚', 'type': TransactionType.expense},
    {'name': 'Lainnya', 'icon': '📦', 'type': TransactionType.expense},
    // Income
    {'name': 'Gaji', 'icon': '💰', 'type': TransactionType.income},
    {'name': 'Investasi', 'icon': '📈', 'type': TransactionType.income},
    {'name': 'Bonus', 'icon': '🎁', 'type': TransactionType.income},
    {'name': 'Lainnya', 'icon': '✨', 'type': TransactionType.income},
  ];

  /// Seeds default categories if none exist yet (called on first launch)
  Future<void> seedDefaults() async {
    final count = await isar.categorys.count();
    if (count > 0) return;

    final cats = _defaults.map((d) {
      final cat = Category()
        ..name = d['name'] as String
        ..icon = d['icon'] as String
        ..isDefault = true
        ..type = d['type'] as TransactionType;
      return cat;
    }).toList();

    await isar.writeTxn(() async {
      await isar.categorys.putAll(cats);
    });
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<List<Category>> getAll() async {
    return isar.categorys.where().findAll();
  }

  Future<List<Category>> getByType(TransactionType type) async {
    return isar.categorys.filter().typeEqualTo(type).findAll();
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> addCategory(Category category) async {
    await isar.writeTxn(() async {
      await isar.categorys.put(category);
    });
  }

  Future<void> updateCategory(Category category) async {
    await isar.writeTxn(() async {
      await isar.categorys.put(category);
    });
  }

  Future<void> deleteCategory(int id) async {
    final cat = await isar.categorys.get(id);
    if (cat == null || cat.isDefault) return; // cannot delete defaults
    await isar.writeTxn(() async {
      await isar.categorys.delete(id);
    });
  }

  // ── Bulk ──────────────────────────────────────────────────────────────────

  Future<void> clearCustom() async {
    await isar.writeTxn(() async {
      final custom =
          await isar.categorys.filter().isDefaultEqualTo(false).findAll();
      final ids = custom.map((c) => c.id).toList();
      await isar.categorys.deleteAll(ids);
    });
  }

  Future<void> importAll(List<Category> categories) async {
    await isar.writeTxn(() async {
      await isar.categorys.putAll(categories);
    });
  }
}
