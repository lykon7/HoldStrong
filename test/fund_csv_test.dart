import 'package:flutter_test/flutter_test.dart';
import 'package:holdstrong/data/backup/backup_service.dart';
import 'package:holdstrong/data/models/account_transfer.dart';
import 'package:holdstrong/data/models/expense_entry.dart';
import 'package:holdstrong/data/models/fund_account.dart';
import 'package:holdstrong/data/models/income_entry.dart';

void main() {
  final cash = FundAccount()
    ..uuid = 'f1'
    ..name = 'Cash'
    ..openingBalance = 1000
    ..createdAt = DateTime(2026, 1, 1);
  final bank = FundAccount()
    ..uuid = 'f2'
    ..name = 'Bank, Main'
    ..openingBalance = 0
    ..createdAt = DateTime(2026, 2, 1);

  test('fund accounts csv has opening and current balances', () {
    final csv = BackupService.fundAccountsCsv(
      funds: [bank, cash],
      incomes: [
        IncomeEntry()
          ..uuid = 'i'
          ..amount = 500
          ..source = 'S'
          ..fundUuid = 'f1'
          ..loggedAt = DateTime(2026, 3, 1),
      ],
      expenses: [
        ExpenseEntry()
          ..uuid = 'e'
          ..amount = 200
          ..purpose = 'P'
          ..fundUuid = 'f1'
          ..loggedAt = DateTime(2026, 3, 2),
      ],
      transfers: [
        AccountTransfer()
          ..uuid = 't'
          ..fromFundUuid = 'f1'
          ..toFundUuid = 'f2'
          ..amount = 300
          ..transferAt = DateTime(2026, 3, 3),
      ],
    );
    final lines = csv.replaceFirst('﻿', '').trim().split('\n');
    expect(lines[0], 'name,opening_balance,current_balance,created_at,uuid');
    // Oldest account first: 1000 + 500 - 200 - 300 = 1000
    expect(lines[1], startsWith('Cash,1000.0,1000.0,2026-01-01'));
    // Commas are quoted; received the 300 transfer.
    expect(lines[2], startsWith('"Bank, Main",0.0,300.0,'));
  });

  test('transfers csv resolves account names, newest first', () {
    AccountTransfer t(String id, DateTime at, String? note) => AccountTransfer()
      ..uuid = id
      ..fromFundUuid = 'f1'
      ..toFundUuid = 'f2'
      ..amount = 50
      ..note = note
      ..transferAt = at;
    final csv = BackupService.transfersCsv(
      funds: [cash, bank],
      transfers: [t('old', DateTime(2026, 3, 1), null), t('new', DateTime(2026, 4, 1), 'rent')],
    );
    final lines = csv.replaceFirst('﻿', '').trim().split('\n');
    expect(lines[0], 'date,amount,from_account,to_account,note,uuid');
    expect(lines[1], '2026-04-01T00:00:00.000,50.0,Cash,"Bank, Main",rent,new');
    expect(lines[2], endsWith(',old'));
  });
}
