import 'package:isar/isar.dart';
import 'models/goal.dart';
import 'models/resist_entry.dart';
import 'models/craving_label.dart';
import 'models/account_transfer.dart';

class IsarService {
  IsarService._();

  static IsarService? _instance;
  static IsarService get instance => _instance ??= IsarService._();

  Isar? _isar;

  void init(Isar isar) {
    _isar = isar;
  }

  Isar get db {
    assert(_isar != null, 'IsarService not initialised. Call init() before use.');
    return _isar!;
  }
}
