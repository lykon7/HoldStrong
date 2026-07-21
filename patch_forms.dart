import 'dart:io';

void main() {
  final files = [
    'lib/ui/transactions/transactions_screen.dart',
    'lib/ui/income/income_screen.dart',
    'lib/ui/expenses/expenses_screen.dart',
    'lib/ui/transactions/recurring_screen.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();

    // 1. Restore the bad edit in transactions_screen
    if (path.contains('transactions_screen')) {
      content = content.replaceFirst(
        "hintText: 'e.g. Fuel for bike...',",
        "hintText: 'or type a custom source...',",
      );
    }

    // 2. Add `String? _selectedCategory;` below `_selectedFundUuid` in state definitions
    content = content.replaceAll(
      '  String? _selectedFundUuid;\n  bool _saving = false;',
      '  String? _selectedFundUuid;\n  String? _selectedCategory;\n  bool _saving = false;'
    );
    content = content.replaceAll(
      '  late String? _selectedFundUuid;\n  bool _saving = false;',
      '  late String? _selectedFundUuid;\n  late String? _selectedCategory;\n  bool _saving = false;'
    );

    // 3. For Edit States, initialize `_selectedCategory = widget.entry.category;`
    content = content.replaceAll(
      '    _selectedFundUuid = widget.entry.fundUuid;\n  }',
      '    _selectedFundUuid = widget.entry.fundUuid;\n    _selectedCategory = widget.entry.category;\n  }'
    );
    // Also for Recurring screen
    content = content.replaceAll(
      '    _selectedFundUuid = widget.recurring.fundUuid;\n  }',
      '    _selectedFundUuid = widget.recurring.fundUuid;\n    _selectedCategory = widget.recurring.category;\n  }'
    );

    // 4. Update IncomeEntry / ExpenseEntry / RecurringTransaction generation to include `..category = _selectedCategory`
    // Match `..fundUuid = _selectedFundUuid` and prefix it with `..category = _selectedCategory`
    // (Except where it's already added in transactions_screen.dart)
    content = content.replaceAll(
      '      ..fundUuid = _selectedFundUuid',
      '      ..category = _selectedCategory\n      ..fundUuid = _selectedFundUuid'
    );
    // Clean up duplicate `..category = _selectedCategory` we just caused in transactions_screen.dart
    content = content.replaceAll(
      '      ..category = _selectedCategory\n      ..category = _selectedCategory',
      '      ..category = _selectedCategory'
    );
    content = content.replaceAll(
      '        ..category = _selectedCategory\n        ..category = _selectedCategory',
      '        ..category = _selectedCategory'
    );

    // 5. Add CATEGORY dropdown UI
    // Income forms: after TextField for source
    final incomeDropdown = '''
                const SizedBox(height: 20),
                const _SheetLabel('CATEGORY'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    hintText: 'Select category (optional)',
                  ),
                  icon: const Icon(Icons.expand_more),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  dropdownColor: AppColors.backgroundElevated,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...ref.watch(incomeCategoriesProvider).map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }),
                  ],
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
''';
    content = content.replaceAll(
      '''
                  decoration: const InputDecoration(
                    hintText: 'or type a custom source...',
                  ),
                ),
                const SizedBox(height: 20),
                const _SheetLabel('ADD TO FUND'),
''',
      '''
                  decoration: const InputDecoration(
                    hintText: 'or type a custom source...',
                  ),
                ),
$incomeDropdown                const SizedBox(height: 20),
                const _SheetLabel('ADD TO FUND'),
'''
    );

    // Expense forms: after TextField for purpose
    final expenseDropdown = '''
                const SizedBox(height: 20),
                const _SheetLabel('CATEGORY'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    hintText: 'Select category (optional)',
                  ),
                  icon: const Icon(Icons.expand_more),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  dropdownColor: AppColors.backgroundElevated,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...ref.watch(expenseCategoriesProvider).map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }),
                  ],
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
''';
    content = content.replaceAll(
      '''
                  decoration: const InputDecoration(
                    hintText: 'e.g. Fuel for bike...',
                  ),
                ),
                const SizedBox(height: 20),
                const _SheetLabel('DEDUCT FROM FUND'),
''',
      '''
                  decoration: const InputDecoration(
                    hintText: 'e.g. Fuel for bike...',
                  ),
                ),
$expenseDropdown                const SizedBox(height: 20),
                const _SheetLabel('DEDUCT FROM FUND'),
'''
    );

    // Recurring screen: after TextField for title
    final recurringDropdown = '''
                const SizedBox(height: 20),
                const _SheetLabel('CATEGORY'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    hintText: 'Select category (optional)',
                  ),
                  icon: const Icon(Icons.expand_more),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  dropdownColor: AppColors.backgroundElevated,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...(_isIncome ? ref.watch(incomeCategoriesProvider) : ref.watch(expenseCategoriesProvider)).map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }),
                  ],
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
''';
    content = content.replaceAll(
      '''
                  decoration: const InputDecoration(
                    hintText: 'e.g. Salary, Groceries...',
                  ),
                ),
                const SizedBox(height: 20),
                const _SheetLabel('FUND ACCOUNT'),
''',
      '''
                  decoration: const InputDecoration(
                    hintText: 'e.g. Salary, Groceries...',
                  ),
                ),
$recurringDropdown                const SizedBox(height: 20),
                const _SheetLabel('FUND ACCOUNT'),
'''
    );
    
    // Add badge display to `_TransactionRow` in income_screen and expenses_screen
    // The transaction row rendering has `item.title` or `entry.source` or `entry.purpose`.
    // Actually in `income_screen.dart` and `expenses_screen.dart` we need to find `entry.source` and `entry.purpose`
    // In income_screen.dart:
    content = content.replaceAll(
      '''
                  Text(
                    entry.source,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
''',
      '''
                  Text(
                    entry.source,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (entry.category != null && entry.category!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.category!,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
'''
    );
    // In expenses_screen.dart:
    content = content.replaceAll(
      '''
                  Text(
                    entry.purpose,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
''',
      '''
                  Text(
                    entry.purpose,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (entry.category != null && entry.category!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.category!,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
'''
    );

    // In recurring_screen.dart:
    content = content.replaceAll(
      '''
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
''',
      '''
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (item.category != null && item.category!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category!,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
'''
    );

    file.writeAsStringSync(content);
  }
}
