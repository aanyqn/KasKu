import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/transaction.dart';
import '../data/models/category.dart';
import '../data/repositories/category_repository.dart';

/// Singleton Isar instance, opened once and shared across the app
final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [TransactionSchema, CategorySchema],
    directory: dir.path,
  );

  // Seed default categories on first launch
  final categoryRepo = CategoryRepository(isar);
  await categoryRepo.seedDefaults();

  return isar;
});
