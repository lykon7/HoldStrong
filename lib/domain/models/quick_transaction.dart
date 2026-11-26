import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

enum QuickTransactionType { income, expense }

/// A saved preset for the add-transaction sheet: name (purpose/source),
/// category, fund account and (optionally) amount are pre-filled when it is
/// tapped.
class QuickTransaction {
  final String id;
  final QuickTransactionType type;
  final String name;
  final String? category;
  final String? fundUuid;
  final double? amount;

  const QuickTransaction({
    required this.id,
    required this.type,
    required this.name,
    this.category,
    this.fundUuid,
    this.amount,
  });

  factory QuickTransaction.create({
    required QuickTransactionType type,
    required String name,
    String? category,
    String? fundUuid,
    double? amount,
  }) {
    return QuickTransaction(
      id: const Uuid().v4(),
      type: type,
      name: name,
      category: category,
      fundUuid: fundUuid,
      amount: amount,
    );
  }

  /// Amount as text for an input field: no trailing ".0".
  String? get amountInput {
    final a = amount;
    if (a == null) return null;
    return a == a.roundToDouble() ? a.toStringAsFixed(0) : a.toString();
  }

  /// Amount for display, e.g. "1,500".
  String? get amountLabel {
    final a = amount;
    if (a == null) return null;
    return NumberFormat('#,##0.##').format(a);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'name': name,
        'category': category,
        'fundUuid': fundUuid,
        'amount': amount,
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
      amount: (map['amount'] as num?)?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory QuickTransaction.fromJson(String source) =>
      QuickTransaction.fromMap(json.decode(source));

  /// Explicit nulls are meaningful here (clearing category / fund / amount), so the
  /// edit is expressed by building a new instance instead of copyWith.
  QuickTransaction edited({
    required String name,
    required String? category,
    required String? fundUuid,
    required double? amount,
  }) {
    return QuickTransaction(
      id: id,
      type: type,
      name: name,
      category: category,
      fundUuid: fundUuid,
      amount: amount,
    );
  }
}
