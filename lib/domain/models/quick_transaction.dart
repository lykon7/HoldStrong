import 'dart:convert';
import 'package:uuid/uuid.dart';

enum QuickTransactionType { income, expense }

/// A saved preset for the add-transaction sheet: name (purpose/source),
/// category and fund account are pre-filled when it is tapped.
class QuickTransaction {
  final String id;
  final QuickTransactionType type;
  final String name;
  final String? category;
  final String? fundUuid;

  const QuickTransaction({
    required this.id,
    required this.type,
    required this.name,
    this.category,
    this.fundUuid,
  });

  factory QuickTransaction.create({
    required QuickTransactionType type,
    required String name,
    String? category,
    String? fundUuid,
  }) {
    return QuickTransaction(
      id: const Uuid().v4(),
      type: type,
      name: name,
      category: category,
      fundUuid: fundUuid,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'name': name,
        'category': category,
        'fundUuid': fundUuid,
      };

  factory QuickTransaction.fromMap(Map<String, dynamic> map) {
    return QuickTransaction(
      id: map['id'] ?? const Uuid().v4(),
      type: map['type'] == 'income'
          ? QuickTransactionType.income
          : QuickTransactionType.expense,
      name: map['name'] ?? '',
      category: map['category'],
      fundUuid: map['fundUuid'],
    );
  }

  String toJson() => json.encode(toMap());

  factory QuickTransaction.fromJson(String source) =>
      QuickTransaction.fromMap(json.decode(source));

  /// Explicit nulls are meaningful here (clearing category / fund), so the
  /// edit is expressed by building a new instance instead of copyWith.
  QuickTransaction edited({
    required String name,
    required String? category,
    required String? fundUuid,
  }) {
    return QuickTransaction(
      id: id,
      type: type,
      name: name,
      category: category,
      fundUuid: fundUuid,
    );
  }
}
