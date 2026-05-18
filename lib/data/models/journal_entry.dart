import 'package:isar/isar.dart';

part 'journal_entry.g.dart';

@collection
class JournalEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String content;

  @Index()
  late DateTime date;

  late DateTime createdAt;
  late DateTime updatedAt;
}
