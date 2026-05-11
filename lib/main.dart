import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/constants.dart';
import 'data/models/goal.dart';
import 'data/models/resist_entry.dart';
import 'data/models/craving_label.dart';
import 'data/models/expense_entry.dart';
import 'domain/providers/goal_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [GoalSchema, ResistEntrySchema, CravingLabelSchema, ExpenseEntrySchema],
    directory: dir.path,
    name: AppConstants.kIsarDbName,
  );

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const HoldStrongApp(),
    ),
  );
}
