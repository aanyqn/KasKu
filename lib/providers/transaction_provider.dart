import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction.dart';
import '../data/repositories/transaction_repository.dart';
import 'isar_provider.dart';

// ── Filter model ─────────────────────────────────────────────────────────────

class TransactionFilter {
  final DateTime? month;
  final TransactionType? type;

  const TransactionFilter({this.month, this.type});

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.month == month &&
      other.type == type;

  @override
  int get hashCode => Object.hash(month, type);
}

// ── Transaction list provider ─────────────────────────────────────────────────

class TransactionListNotifier
    extends FamilyAsyncNotifier<List<Transaction>, TransactionFilter> {
  @override
  Future<List<Transaction>> build(TransactionFilter arg) async {
    final isar = await ref.watch(isarProvider.future);
    final repo = TransactionRepository(isar);
    return repo.getTransactions(month: arg.month, filterType: arg.type);
  }

  Future<void> add(Transaction transaction) async {
    final isar = await ref.read(isarProvider.future);
    await TransactionRepository(isar).addTransaction(transaction);
    _invalidateAll();
  }

  Future<void> edit(Transaction transaction) async {
    final isar = await ref.read(isarProvider.future);
    await TransactionRepository(isar).editTransaction(transaction);
    _invalidateAll();
  }

  Future<void> delete(int id) async {
    final isar = await ref.read(isarProvider.future);
    await TransactionRepository(isar).deleteTransaction(id);
    _invalidateAll();
  }

  void _invalidateAll() {
    ref.invalidateSelf();
    ref.invalidate(netBalanceProvider);
    ref.invalidate(monthlySummaryProvider);
    ref.invalidate(categorySpendingProvider);
  }
}

final transactionListProvider = AsyncNotifierProviderFamily<
    TransactionListNotifier, List<Transaction>, TransactionFilter>(
  TransactionListNotifier.new,
);

// ── Balance provider ──────────────────────────────────────────────────────────

final netBalanceProvider = FutureProvider<double>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return TransactionRepository(isar).getNetBalance();
});

// ── Monthly summary provider ──────────────────────────────────────────────────

final monthlySummaryProvider =
    FutureProvider.family<MonthlySummary, DateTime>((ref, month) async {
  final isar = await ref.watch(isarProvider.future);
  return TransactionRepository(isar).getMonthlySummary(month);
});

// ── Category spending provider (for pie chart) ────────────────────────────────

final categorySpendingProvider =
    FutureProvider.family<Map<String, double>, DateTime>((ref, month) async {
  final isar = await ref.watch(isarProvider.future);
  return TransactionRepository(isar).getCategorySpending(month);
});

// ── Selected month provider (controls dashboard filter) ───────────────────────

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});
