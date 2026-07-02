import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/wishlist_item.dart';
import '../data/models/journal_entry.dart';
import '../data/models/liability_item.dart';

class ExportHelper {
  static Future<void> exportWishlist(List<WishlistItem> items) async {
    final csvBuffer = StringBuffer();
    // Headers
    csvBuffer.writeln('Item Name,Estimated Cost (LKR),Created At');
    for (final item in items) {
      final nameClean = item.name.replaceAll('"', '""');
      final cost = item.estimatedCost.toStringAsFixed(2);
      final date = DateFormat('yyyy-MM-dd').format(item.createdAt);
      csvBuffer.writeln('"$nameClean",$cost,$date');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/wishlist_export.csv');
    await file.writeAsString(csvBuffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'HoldStrong Wishlist Export',
    );
  }

  static Future<void> exportJournal(List<JournalEntry> entries) async {
    final txtBuffer = StringBuffer();
    txtBuffer.writeln('HOLDSTRONG JOURNAL EXPORT');
    txtBuffer.writeln('Exported on: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}');
    txtBuffer.writeln('=' * 50);
    txtBuffer.writeln();

    // Sort entries by date ascending
    final sortedEntries = List<JournalEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final entry in sortedEntries) {
      final dateStr = DateFormat('EEEE, d MMMM yyyy').format(entry.date);
      txtBuffer.writeln(dateStr);
      txtBuffer.writeln('-' * dateStr.length);
      txtBuffer.writeln(entry.content);
      txtBuffer.writeln();
      txtBuffer.writeln('=' * 50);
      txtBuffer.writeln();
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/journal_export.txt');
    await file.writeAsString(txtBuffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'HoldStrong Journal Export',
    );
  }

  static Future<void> exportLiabilities(List<LiabilityItem> items) async {
    final csvBuffer = StringBuffer();
    csvBuffer.writeln('Title,Amount (LKR),Type,Due Date,Recurring,Frequency,Notes,Paid,Instalment');
    for (final item in items) {
      final titleClean = item.title.replaceAll('"', '""');
      final amount = item.amount.toStringAsFixed(2);
      
      final typeEnum = LiabilityType.values[item.type % LiabilityType.values.length];
      final typeLabel = typeEnum.label;

      final dueDate = DateFormat('yyyy-MM-dd').format(item.dueDate);
      final recurring = item.isRecurring.toString();
      
      String freqLabel = 'N/A';
      if (item.recurrenceFrequency != null) {
        final freqEnum = LiabilityFrequency.values[item.recurrenceFrequency! % LiabilityFrequency.values.length];
        freqLabel = freqEnum.label;
      }

      final notesClean = (item.notes ?? '').replaceAll('"', '""');
      final paid = item.isPaid.toString();
      
      String instalmentInfo = 'N/A';
      if (item.instalmentNumber != null && item.totalInstalments != null) {
        instalmentInfo = '${item.instalmentNumber}/${item.totalInstalments}';
      }

      csvBuffer.writeln('"$titleClean",$amount,$typeLabel,$dueDate,$recurring,$freqLabel,"$notesClean",$paid,$instalmentInfo');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/liabilities_export.csv');
    await file.writeAsString(csvBuffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'HoldStrong Liabilities Export',
    );
  }
}
