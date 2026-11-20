import 'package:flutter_test/flutter_test.dart';
import 'package:holdstrong/data/backup/backup_service.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeIsar implements Isar {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('preferences round-trip, skipping device-specific and existing keys',
      () async {
    SharedPreferences.setMockInitialValues({
      'configured_income_sources': ['DA', 'PM'],
      'configured_expense_accounts': ['Cash', 'Card'],
      'custom_timers_list': ['{"id":"1"}'],
      'some_bool': true,
      'some_int': 7,
      'some_double': 1.5,
      'some_string': 'x',
      'cloud_backup_enabled': true,
      'cloud_backup_account': 'me@example.com',
    });
    final source = BackupService(_FakeIsar(), await SharedPreferences.getInstance());
    final exported = source.exportPreferences();

    expect(exported.keys, isNot(contains('cloud_backup_enabled')));
    expect(exported.keys, isNot(contains('cloud_backup_account')));
    expect(exported['configured_expense_accounts'],
        {'type': 'stringList', 'value': ['Cash', 'Card']});
    expect(exported.length, 7);

    // Restore onto a fresh device that already has one conflicting key.
    SharedPreferences.setMockInitialValues({'some_int': 99});
    final target = await SharedPreferences.getInstance();
    final restored =
        await BackupService(_FakeIsar(), target).importPreferences(exported);

    expect(restored, 6);
    expect(target.getInt('some_int'), 99); // not overwritten
    expect(target.getStringList('configured_income_sources'), ['DA', 'PM']);
    expect(target.getStringList('custom_timers_list'), ['{"id":"1"}']);
    expect(target.getBool('some_bool'), true);
    expect(target.getDouble('some_double'), 1.5);
    expect(target.getString('some_string'), 'x');
    expect(target.containsKey('cloud_backup_account'), false);
  });
}
