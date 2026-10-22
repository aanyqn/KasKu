import 'package:isar/isar.dart';
import '../models/transaction.dart';

/// Summary of income and expense for a given month
class MonthlySummary {
  final double totalIncome;
  final double totalExpense;

  const MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
  });

  double get balance => totalIncome - totalExpense;
}

/// Repository for all Transaction CRUD operations
class TransactionRepository {
  final Isar isar;

  TransactionRepository(this.isar);

  // ── Read ────────────────────────────────────────────────────────────────

  /// Returns transactions optionally filtered by month and/or type,
  /// sorted by date descending (newest first).
  Future<List<Transaction>> getTransactions({
    DateTime? month,
    TransactionType? filterType,
  }) async {
    var builder = isar.transactions.where();

    if (month != null && filterType != null) {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      return builder
          .filter()
          .dateBetween(start, end)
          .and()
          .typeEqualTo(filterType)
          .sortByDateDesc()
          .findAll();
    } else if (month != null) {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      return builder
          .filter()
          .dateBetween(start, end)
          .sortByDateDesc()
          .findAll();
    } else if (filterType != null) {
      return builder
          .filter()
          .typeEqualTo(filterType)
          .sortByDateDesc()
          .findAll();
    }

    return builder.sortByDateDesc().findAll();
  }

  /// Returns the sum of all transactions (income - expense) = net balance
  Future<double> getNetBalance() async {
    final all = await isar.transactions.where().findAll();
    double balance = 0;
    for (final t in all) {
      if (t.type == TransactionType.income) {
        balance += t.amount;
      } else {
        balance -= t.amount;
      }
    }
    return balance;
  }

  /// Returns monthly income and expense summary
  Future<MonthlySummary> getMonthlySummary(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final all = await isar.transactions
        .filter()
        .dateBetween(start, end)
        .findAll();

    double income = 0;
    double expense = 0;

    for (final t in all) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    return MonthlySummary(totalIncome: income, totalExpense: expense);
  }

  /// Returns spending grouped by category for a given month (expense only)
  Future<Map<String, double>> getCategorySpending(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final expenses = await isar.transactions
        .filter()
        .dateBetween(start, end)
        .and()
        .typeEqualTo(TransactionType.expense)
        .findAll();

    final Map<String, double> result = {};
    for (final t in expenses) {
      result[t.categoryName] = (result[t.categoryName] ?? 0) + t.amount;
    }
    return result;
  }

  // ── Write ───────────────────────────────────────────────────────────────

  Future<void> addTransaction(Transaction transaction) async {
    await isar.writeTxn(() async {
      await isar.transactions.put(transaction);
    });
  }

  Future<void> editTransaction(Transaction transaction) async {
    await isar.writeTxn(() async {
      await isar.transactions.put(transaction);
    });
  }

  Future<void> deleteTransaction(int id) async {
    await isar.writeTxn(() async {
      await isar.transactions.delete(id);
    });
  }

  // ── Bulk ────────────────────────────────────────────────────────────────

  Future<List<Transaction>> getAll() async {
    return isar.transactions.where().findAll();
  }

  Future<void> clearAll() async {
    await isar.writeTxn(() async {
      await isar.transactions.clear();
    });
  }

  Future<void> importAll(List<Transaction> transactions) async {
    await isar.writeTxn(() async {
      await isar.transactions.putAll(transactions);
    });
  }
}
