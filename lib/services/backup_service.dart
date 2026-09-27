import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../models/bill.dart';
import '../models/contact.dart';
import '../models/shopping_list.dart';
import 'app_data.dart';

/// Export / Import all app data as a single JSON file.
///
/// Built to work identically on mobile AND web:
/// - Export uses `XFile.fromData` (in-memory bytes) instead of writing
///   to a temp folder first — on mobile this opens the native share
///   sheet, on web it triggers a browser download. No `path_provider`
///   needed (which isn't supported on web anyway).
/// - Import reads file bytes directly from `file_picker` (`withData:
///   true`), which works the same on mobile and web — no raw file
///   path handling required.
///
/// WHY THIS MATTERS: all data lives only on this device/browser. If
/// the phone is lost/reset, the browser storage is cleared, or the
/// app/site is uninstalled, everything — including Udhar Khata
/// balances — is gone permanently. Regular backups are the safety net.
class BackupService {
  static Future<void> exportBackup() async {
    final data = AppData.instance;
    final backup = {
      'app': 'roz_hisab',
      'exportedAt': DateTime.now().toIso8601String(),
      'shoppingLists': data.shoppingLists.map((l) => l.toJson()).toList(),
      'contacts': data.contacts.map((c) => c.toJson()).toList(),
      'bills': data.bills.map((b) => b.toJson()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
    final bytes = utf8.encode(jsonStr);
    final dateTag = DateTime.now().toIso8601String().split('T').first;
    final fileName = 'roz_hisab_backup_$dateTag.json';

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: fileName,
          mimeType: 'application/json',
        ),
      ],
      text: 'Roz Hisab backup — $dateTag',
    );
  }

  /// Lets the user pick a previously exported .json file and restores
  /// it, REPLACING current data. Returns true if a file was picked
  /// and successfully restored.
  static Future<bool> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true, // ensures bytes are available on web too
    );
    if (result == null || result.files.single.bytes == null) return false;

    final jsonStr = utf8.decode(result.files.single.bytes!);
    final Map<String, dynamic> backup = jsonDecode(jsonStr);

    final data = AppData.instance;
    data.shoppingLists
      ..clear()
      ..addAll((backup['shoppingLists'] as List)
          .map((e) => ShoppingListModel.fromJson(e as Map<String, dynamic>)));
    data.contacts
      ..clear()
      ..addAll((backup['contacts'] as List)
          .map((e) => Contact.fromJson(e as Map<String, dynamic>)));
    data.bills
      ..clear()
      ..addAll((backup['bills'] as List)
          .map((e) => Bill.fromJson(e as Map<String, dynamic>)));

    await data.persistAll();
    data.refresh();
    return true;
  }
}
