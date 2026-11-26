import 'package:flutter_test/flutter_test.dart';
import 'package:holdstrong/data/backup/backup_service.dart';
import 'package:holdstrong/domain/models/quick_transaction.dart';
import 'package:holdstrong/domain/providers/quick_transaction_providers.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeIsar implements Isar {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('presets persist, edit, delete, and survive a backup round-trip',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifier = QuickTransactionsNotifier(prefs);

    final fuel = QuickTransaction.create(
      type: QuickTransactionType.expense,
      name: 'Fuel',
      category: 'Fuel',
      fundUuid: 'fund-1',
      amount: 1500,
    );
    final salary = QuickTransaction.create(
      type: QuickTransactionType.income,
      name: 'SALARY',
    );
    await notifier.add(fuel);
    await notifier.add(salary);

    // Reload from prefs, as after an app restart.
    var reloaded = QuickTransactionsNotifier(prefs).state;
    expect(reloaded.map((q) => q.name), ['Fuel', 'SALARY']);
    expect(reloaded[0].type, QuickTransactionType.expense);
    expect(reloaded[0].fundUuid, 'fund-1');
    expect(reloaded[0].amount, 1500);
    expect(reloaded[0].amountInput, '1500');
    expect(reloaded[0].amountLabel, '1,500');
    expect(reloaded[1].category, isNull);
    expect(reloaded[1].amount, isNull);

    // Editing can clear category and fund.
    await notifier.update(
        fuel.edited(
            name: 'Petrol', category: null, fundUuid: null, amount: null));
    reloaded = QuickTransactionsNotifier(prefs).state;
    expect(reloaded[0].name, 'Petrol');
    expect(reloaded[0].category, isNull);
    expect(reloaded[0].fundUuid, isNull);
    expect(reloaded[0].amount, isNull);

    // Included in the generic preferences backup and restorable.
    final exported = BackupService(_FakeIsar(), prefs).exportPreferences();
    expect(exported.keys, contains('quick_transactions_list'));
    SharedPreferences.setMockInitialValues({});
    final fresh = await SharedPreferences.getInstance();
    await BackupService(_FakeIsar(), fresh).importPreferences(exported);
    expect(QuickTransactionsNotifier(fresh).state.length, 2);

    await notifier.remove(salary.id);
    expect(QuickTransactionsNotifier(prefs).state.single.name, 'Petrol');
  });
}
