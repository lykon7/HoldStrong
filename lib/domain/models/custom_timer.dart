import 'dart:convert';
import 'package:uuid/uuid.dart';

class CustomTimer {
  final String id;
  final String title;
  final DateTime targetDate;
  final bool isCountdown;

  CustomTimer({
    required this.id,
    required this.title,
    required this.targetDate,
    required this.isCountdown,
  });

  factory CustomTimer.create({
    required String title,
    required DateTime targetDate,
    required bool isCountdown,
  }) {
    return CustomTimer(
      id: const Uuid().v4(),
      title: title,
      targetDate: targetDate,
      isCountdown: isCountdown,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetDate': targetDate.millisecondsSinceEpoch,
      'isCountdown': isCountdown,
    };
  }

  factory CustomTimer.fromMap(Map<String, dynamic> map) {
    return CustomTimer(
      id: map['id'] ?? const Uuid().v4(),
      title: map['title'] ?? 'TIMER',
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['targetDate'] ?? DateTime.now().millisecondsSinceEpoch),
      isCountdown: map['isCountdown'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory CustomTimer.fromJson(String source) => CustomTimer.fromMap(json.decode(source));

  CustomTimer copyWith({
    String? id,
    String? title,
    DateTime? targetDate,
    bool? isCountdown,
  }) {
    return CustomTimer(
      id: id ?? this.id,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      isCountdown: isCountdown ?? this.isCountdown,
    );
  }
}
