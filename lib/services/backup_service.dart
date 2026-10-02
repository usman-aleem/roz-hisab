import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/bill.dart';
import '../models/contact.dart';
import '../models/daily_item.dart';
import '../models/shopping_list.dart';
import 'app_data.dart';
import 'pdf_service.dart';

/// Backup is now ONE TAP:
///  - [exportPdf]  -> a readable PDF of ALL your data (shopping, udhar,
///                    bills, daily) - downloads on the website, share
///                    sheet on phone.
///  - [exportBackup] -> a .json restore file (a PDF can't be re-imported).
///  - [importBackup] -> restores from that .json.
class BackupService {
  static String _dateTag() => DateTime.now().toIso8601String().split('T').first;

  static Future<void> exportPdf() async {
    final bytes = await PdfService.buildBackupReport(AppData.instance);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'roz_hisab_backup_${_dateTag()}.pdf',
    );
  }

  static Future<void> exportBackup() async {
    final data = AppData.instance;
    final backup = {
      'app': 'roz_hisab',
      'exportedAt': DateTime.now().toIso8601String(),
      'shoppingLists': data.shoppingLists.map((l) => l.toJson()).toList(),
      'contacts': data.contacts.map((c) => c.toJson()).toList(),
      'bills': data.bills.map((b) => b.toJson()).toList(),
      'dailyItems': data.dailyItems.map((d) => d.toJson()).toList(),
    };

    final bytes =
        utf8.encode(const JsonEncoder.withIndent('  ').convert(backup));
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: 'roz_hisab_restore_${_dateTag()}.json',
          mimeType: 'application/json',
        ),
      ],
      text: 'Roz Hisab restore file - ${_dateTag()}',
    );
  }

  static Future<bool> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return false;

    final Map<String, dynamic> backup =
        jsonDecode(utf8.decode(result.files.single.bytes!));

    List<dynamic> listOf(String key) => (backup[key] as List?) ?? const [];

    final data = AppData.instance;
    data.shoppingLists
      ..clear()
      ..addAll(listOf('shoppingLists')
          .map((e) => ShoppingListModel.fromJson(e as Map<String, dynamic>)));
    data.contacts
      ..clear()
      ..addAll(listOf('contacts')
          .map((e) => Contact.fromJson(e as Map<String, dynamic>)));
    data.bills
      ..clear()
      ..addAll(
          listOf('bills').map((e) => Bill.fromJson(e as Map<String, dynamic>)));
    data.dailyItems
      ..clear()
      ..addAll(listOf('dailyItems')
          .map((e) => DailyItem.fromJson(e as Map<String, dynamic>)));

    await data.persistAll();
    data.refresh();
    return true;
  }
}
