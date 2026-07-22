import 'package:isar/isar.dart';

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
