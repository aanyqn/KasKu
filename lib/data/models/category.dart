import 'package:isar/isar.dart';
import 'transaction.dart';

part 'category.g.dart';

/// Isar schema for a transaction category
@collection
class Category {
  Id id = Isar.autoIncrement;

  late String name;

  /// Emoji string representing this category
  late String icon;

  /// Default categories cannot be deleted
  late bool isDefault;

  @Enumerated(EnumType.name)
  late TransactionType type;
}
