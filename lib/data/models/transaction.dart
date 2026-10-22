import 'package:isar/isar.dart';

part 'transaction.g.dart';

/// Transaction type: income or expense
enum TransactionType { income, expense }

/// Isar schema for a single financial transaction
@collection
class Transaction {
  Id id = Isar.autoIncrement;

  late double amount;

  @Enumerated(EnumType.name)
  late TransactionType type;

  late String categoryName;
  late String categoryIcon;

  late DateTime date;

  String? note;
}
