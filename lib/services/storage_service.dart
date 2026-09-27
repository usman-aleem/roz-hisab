import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill.dart';
import '../models/contact.dart';
import '../models/shopping_list.dart';
import 'crypto_service.dart';

/// Persists app data to the device using SharedPreferences — but the
/// JSON payload is AES-256 encrypted first (see CryptoService) before
/// it's written, since this data is real financial information
/// (shopping spend, udhar balances, bills).
///
/// Every load is wrapped in try/catch: if a value ever gets corrupted
/// or fails to decrypt (e.g. the app was killed mid-write), we fall
/// back to an empty list for THAT category instead of throwing —
/// which would otherwise crash the app on every single future launch.
class StorageService {
  static const _keyShoppingLists = 'roz_hisab_shopping_lists';
  static const _keyContacts = 'roz_hisab_contacts';
  static const _keyBills = 'roz_hisab_bills';
  static const _keySeeded = 'roz_hisab_seeded_v1';
  static const _keyUserName = 'roz_hisab_user_name';
  static const _keyMonthlyBudget = 'roz_hisab_monthly_budget';

  final CryptoService _crypto = CryptoService();

  Future<void> saveShoppingLists(List<ShoppingListModel> lists) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(lists.map((l) => l.toJson()).toList());
    final encrypted = await _crypto.encryptString(jsonStr);
    await prefs.setString(_keyShoppingLists, encrypted);
  }

  Future<List<ShoppingListModel>> loadShoppingLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_keyShoppingLists);
      if (stored == null) return [];
      final jsonStr = await _crypto.decryptString(stored);
      if (jsonStr == null) return [];
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((e) => ShoppingListModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Roz Hisab: shopping lists data was corrupted, '
          'starting fresh for this category. Error: $e');
      return [];
    }
  }

  Future<void> saveContacts(List<Contact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(contacts.map((c) => c.toJson()).toList());
    final encrypted = await _crypto.encryptString(jsonStr);
    await prefs.setString(_keyContacts, encrypted);
  }

  Future<List<Contact>> loadContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_keyContacts);
      if (stored == null) return [];
      final jsonStr = await _crypto.decryptString(stored);
      if (jsonStr == null) return [];
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((e) => Contact.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Roz Hisab: contacts data was corrupted, '
          'starting fresh for this category. Error: $e');
      return [];
    }
  }

  Future<void> saveBills(List<Bill> bills) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(bills.map((b) => b.toJson()).toList());
    final encrypted = await _crypto.encryptString(jsonStr);
    await prefs.setString(_keyBills, encrypted);
  }

  Future<List<Bill>> loadBills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_keyBills);
      if (stored == null) return [];
      final jsonStr = await _crypto.decryptString(stored);
      if (jsonStr == null) return [];
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((e) => Bill.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Roz Hisab: bills data was corrupted, '
          'starting fresh for this category. Error: $e');
      return [];
    }
  }

  /// The user's own name isn't sensitive financial data, so it's
  /// stored as plain text (not encrypted) — it's only used to print
  /// on receipts, e.g. "Bill by: Usman Khan".
  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  Future<String> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? '';
  }

  /// A budget target isn't sensitive financial data on its own (no
  /// transaction details), so it's stored as plain text like the
  /// user's name.
  Future<void> saveMonthlyBudget(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMonthlyBudget, amount);
  }

  Future<double> loadMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyMonthlyBudget) ?? 0;
  }

  Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final seeded = prefs.getBool(_keySeeded) ?? false;
    if (!seeded) {
      await prefs.setBool(_keySeeded, true);
      return true;
    }
    return false;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyShoppingLists);
    await prefs.remove(_keyContacts);
    await prefs.remove(_keyBills);
  }
}
