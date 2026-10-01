import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import '../models/contact.dart';
import '../models/udhar_entry.dart';
import '../models/bill.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'category_service.dart';

/// In-memory app state, backed by on-device persistence
/// (SharedPreferences via StorageService). Call [init] once before
/// the app starts using it (done in main.dart). Starts completely
/// empty on first run — no demo/sample data.
class AppData extends ChangeNotifier {
  AppData._internal();
  static final AppData instance = AppData._internal();

  final StorageService _storage = StorageService();

  final List<ShoppingListModel> shoppingLists = [];
  final List<Contact> contacts = [];
  final List<Bill> bills = [];

  String userName = '';
  String userPhone = '';
  String userEmail = '';
  double monthlyBudget = 0;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    await _storage.isFirstRun();

    shoppingLists.addAll(await _storage.loadShoppingLists());
    contacts.addAll(await _storage.loadContacts());
    bills.addAll(await _storage.loadBills());
    userName = await _storage.loadUserName();
    userPhone = await _storage.loadUserPhone();
    userEmail = await _storage.loadUserEmail();
    monthlyBudget = await _storage.loadMonthlyBudget();

    _initialized = true;
    notifyListeners();

    // Re-arm bill reminders every launch — covers bills that were
    // added in a previous session, and survives the OS clearing
    // scheduled notifications (e.g. after a device restart).
    await NotificationService.instance.rescheduleAll(bills);
  }

  Future<void> setUserName(String name) async {
    userName = name.trim();
    notifyListeners();
    await _storage.saveUserName(userName);
  }

  Future<void> setUserPhone(String phone) async {
    userPhone = phone.trim();
    notifyListeners();
    await _storage.saveUserPhone(userPhone);
  }

  Future<void> setUserEmail(String email) async {
    userEmail = email.trim();
    notifyListeners();
    await _storage.saveUserEmail(userEmail);
  }

  Future<void> setMonthlyBudget(double amount) async {
    monthlyBudget = amount;
    notifyListeners();
    await _storage.saveMonthlyBudget(amount);
  }

  double get currentMonthSpend {
    final now = DateTime.now();
    return shoppingLists
        .where((l) => l.date.year == now.year && l.date.month == now.month)
        .fold(0.0, (sum, l) => sum + l.total);
  }

  /// 0.0–1.0+ (can exceed 1.0 if over budget). Null when no budget
  /// has been set, so the UI knows to hide the progress bar entirely
  /// rather than show a meaningless 0%.
  double? get budgetProgress {
    if (monthlyBudget <= 0) return null;
    return currentMonthSpend / monthlyBudget;
  }

  Future<void> _saveAll() async {
    await _storage.saveShoppingLists(shoppingLists);
    await _storage.saveContacts(contacts);
    await _storage.saveBills(bills);
  }

  /// Public wrapper used by BackupService after a restore.
  Future<void> persistAll() => _saveAll();

  // ---------- Shopping ----------
  void addShoppingList(ShoppingListModel list) {
    shoppingLists.insert(0, list);
    notifyListeners();
    _storage.saveShoppingLists(shoppingLists);
  }

  void deleteShoppingList(String id) {
    shoppingLists.removeWhere((l) => l.id == id);
    notifyListeners();
    _storage.saveShoppingLists(shoppingLists);
  }

  /// Replaces a saved shopping list in place — used by the Edit flow
  /// so a past list's items/prices/quantities can be corrected after
  /// the fact, not just deleted and re-entered from scratch.
  void updateShoppingList(ShoppingListModel updated) {
    final idx = shoppingLists.indexWhere((l) => l.id == updated.id);
    if (idx != -1) shoppingLists[idx] = updated;
    notifyListeners();
    _storage.saveShoppingLists(shoppingLists);
  }

  /// Puts a deleted list back at its old position (used by Undo).
  void restoreShoppingList(int index, ShoppingListModel list) {
    shoppingLists.insert(index.clamp(0, shoppingLists.length), list);
    notifyListeners();
    _storage.saveShoppingLists(shoppingLists);
  }

  /// Total shopping spend per month for the last 6 months, oldest
  /// first — used to draw the spending trend on the Home dashboard.
  Map<String, double> monthlySpendLast6Months() {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i), 1);
      return d;
    });

    final result = <String, double>{};
    for (final m in months) {
      final label = _monthLabel(m);
      final total = shoppingLists
          .where((l) => l.date.year == m.year && l.date.month == m.month)
          .fold(0.0, (sum, l) => sum + l.total);
      result[label] = total;
    }
    return result;
  }

  String _monthLabel(DateTime d) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[d.month - 1];
  }

  double get todaySpend {
    final now = DateTime.now();
    return shoppingLists
        .where((l) =>
            l.date.year == now.year &&
            l.date.month == now.month &&
            l.date.day == now.day)
        .fold(0, (sum, l) => sum + l.total);
  }

  /// Items bought most often, most-frequent first, each carrying its
  /// most recently paid price — powers the "Buy Again" quick-add
  /// suggestions so people don't retype "Doodh — Rs. 200" every single
  /// day. This is the single biggest speed win for repeat shoppers.
  List<ShoppingItem> frequentItems({int limit = 8}) {
    final Map<String, _ItemStats> stats = {};
    for (final list in shoppingLists) {
      for (final item in list.items) {
        final key = item.name.trim().toLowerCase();
        if (key.isEmpty) continue;
        final existing = stats[key];
        if (existing == null) {
          stats[key] = _ItemStats(
            name: item.name.trim(),
            price: item.price,
            category: item.category,
            count: 1,
            lastDate: list.date,
          );
        } else {
          existing.count += 1;
          if (list.date.isAfter(existing.lastDate)) {
            existing.lastDate = list.date;
            existing.price = item.price;
            existing.category = item.category;
          }
        }
      }
    }
    final sorted = stats.values.toList()
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        if (byCount != 0) return byCount;
        return b.lastDate.compareTo(a.lastDate);
      });
    return sorted
        .take(limit)
        .map((s) => ShoppingItem(
              name: s.name,
              price: s.price,
              category: s.category.isEmpty
                  ? CategoryService.categorize(s.name)
                  : s.category,
            ))
        .toList();
  }

  /// This month's shopping spend grouped by category, largest first —
  /// answers "kahan gaya paisa" (where did the money go) at a glance,
  /// with no manual tagging required from the user.
  Map<String, double> categorySpendThisMonth() {
    final now = DateTime.now();
    final Map<String, double> totals = {};
    for (final list in shoppingLists) {
      if (list.date.year != now.year || list.date.month != now.month) {
        continue;
      }
      for (final item in list.items) {
        final cat = item.category.isEmpty
            ? CategoryService.categorize(item.name)
            : item.category;
        totals[cat] = (totals[cat] ?? 0) + item.total;
      }
    }
    final sorted = Map.fromEntries(
      totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }

  // ---------- Udhar ----------
  void addContact(Contact c) {
    contacts.add(c);
    notifyListeners();
    _storage.saveContacts(contacts);
  }

  /// FAST PATH for lazy users: one call creates the person AND their
  /// first entry ("Ali - 500 - I Gave") so nobody has to open a
  /// second screen just to log the money.
  Contact addContactWithEntry({
    required String name,
    String phone = '',
    UdharType? type,
    double amount = 0,
    String note = '',
  }) {
    final c = Contact(id: const Uuid().v4(), name: name, phone: phone);
    if (type != null && amount > 0) {
      c.entries.add(UdharEntry(
        id: const Uuid().v4(),
        type: type,
        amount: amount,
        note: note,
      ));
    }
    contacts.add(c);
    notifyListeners();
    _storage.saveContacts(contacts);
    return c;
  }

  /// One-line "I Gave / I Took" for an existing person - used by the
  /// quick buttons directly on the Udhar list.
  void addUdharEntry(Contact contact, UdharType type, double amount,
      {String note = ''}) {
    if (amount <= 0) return;
    contact.entries.add(UdharEntry(
      id: const Uuid().v4(),
      type: type,
      amount: amount,
      note: note,
    ));
    saveContacts();
  }

  void restoreContact(int index, Contact c) {
    contacts.insert(index.clamp(0, contacts.length), c);
    notifyListeners();
    _storage.saveContacts(contacts);
  }

  void deleteContact(String id) {
    contacts.removeWhere((c) => c.id == id);
    notifyListeners();
    _storage.saveContacts(contacts);
  }

  /// Call after mutating a contact's entries in-place (e.g. adding an
  /// UdharEntry) so the change gets persisted.
  void saveContacts() {
    notifyListeners();
    _storage.saveContacts(contacts);
  }

  double get totalTheyOweMe =>
      contacts.fold(0, (sum, c) => sum + (c.balance > 0 ? c.balance : 0));

  double get totalIOweThem =>
      contacts.fold(0, (sum, c) => sum + (c.balance < 0 ? -c.balance : 0));

  /// Records a payment against a contact's outstanding balance —
  /// this is "Settle Up": the real-world action of someone paying
  /// back part or all of what they owe (or you paying back part of
  /// what you owe them). It's expressed as a normal offsetting
  /// UdharEntry so the running balance stays correct, but framed as
  /// a payment rather than a fresh loan, since typing "500" into
  /// "+ I Gave" vs "+ I Took" to record a repayment is genuinely
  /// confusing for users — they think in terms of "he paid me back",
  /// not loan direction.
  void recordPayment(Contact contact, double amount, {String note = ''}) {
    if (amount <= 0) return;
    final bal = contact.balance;
    // If they owe me, a payment from them REDUCES that — recorded as
    // an iOweThem-type entry so the sum nets down correctly. If I
    // owe them, a payment I make also nets the balance toward zero
    // via a theyOweMe-type entry. Either way it's "the opposite of
    // whatever put the current balance where it is".
    final type = bal >= 0 ? UdharType.iOweThem : UdharType.theyOweMe;
    contact.entries.add(UdharEntry(
      id: const Uuid().v4(),
      type: type,
      amount: amount,
      note: note.isEmpty ? 'Payment' : note,
    ));
    saveContacts();
  }

  /// Deletes a single Udhar transaction from a contact's history —
  /// for correcting a mis-entered amount/note without having to
  /// delete the whole contact.
  void deleteUdharEntry(Contact contact, String entryId) {
    contact.entries.removeWhere((e) => e.id == entryId);
    saveContacts();
  }

  // ---------- Bills ----------
  void addBill(Bill b) {
    bills.add(b);
    notifyListeners();
    _storage.saveBills(bills);
    NotificationService.instance.scheduleBillReminder(b);
  }

  List<Bill> get upcomingUnpaidBills {
    final list = bills.where((b) => !b.isPaid).toList();
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  void deleteBill(String id) {
    final bill = bills.where((b) => b.id == id).toList();
    bills.removeWhere((b) => b.id == id);
    notifyListeners();
    _storage.saveBills(bills);
    if (bill.isNotEmpty) {
      NotificationService.instance.cancelBillReminder(bill.first);
    }
  }

  /// Marks [bill] paid. If it's a recurring bill, also creates NEXT
  /// month's bill automatically — this is the single biggest real
  /// complaint with manual bill tracking: people mark this month's
  /// electricity bill paid and then completely forget to re-add it
  /// next month, so the reminder silently stops working right when
  /// it's needed again.
  Bill? markBillPaid(Bill bill) {
    bill.isPaid = true;
    notifyListeners();
    _storage.saveBills(bills);
    NotificationService.instance.cancelBillReminder(bill);

    Bill? created;
    if (bill.isRecurring) {
      final due = bill.dueDate;
      final nextDue = DateTime(due.year, due.month + 1, due.day);
      final alreadyExists = bills.any((b) =>
          b.name == bill.name &&
          b.dueDate.year == nextDue.year &&
          b.dueDate.month == nextDue.month &&
          b.dueDate.day == nextDue.day);
      if (!alreadyExists) {
        created = Bill(
          id: const Uuid().v4(),
          name: bill.name,
          amount: bill.amount,
          dueDate: nextDue,
          isRecurring: true,
        );
        addBill(created);
      }
    }
    return created;
  }

  /// Undo for "tap = paid": flips a bill back to unpaid and removes
  /// the auto-created next-month copy of a recurring bill.
  void markBillUnpaid(Bill bill, {Bill? autoCreatedNext}) {
    bill.isPaid = false;
    if (autoCreatedNext != null) {
      bills.removeWhere((b) => b.id == autoCreatedNext.id);
      NotificationService.instance.cancelBillReminder(autoCreatedNext);
    }
    notifyListeners();
    _storage.saveBills(bills);
    NotificationService.instance.scheduleBillReminder(bill);
  }

  void restoreBill(int index, Bill b) {
    bills.insert(index.clamp(0, bills.length), b);
    notifyListeners();
    _storage.saveBills(bills);
    if (!b.isPaid) NotificationService.instance.scheduleBillReminder(b);
  }

  /// Saves changes made to an existing bill in place (name, amount,
  /// due date, recurring flag) — and re-arms its reminder so a
  /// changed due date actually gets a notification at the new time.
  void updateBill(Bill updated) {
    final idx = bills.indexWhere((b) => b.id == updated.id);
    if (idx != -1) bills[idx] = updated;
    notifyListeners();
    _storage.saveBills(bills);
    NotificationService.instance.cancelBillReminder(updated);
    if (!updated.isPaid) {
      NotificationService.instance.scheduleBillReminder(updated);
    }
  }

  void refresh() => notifyListeners();

  double get netBalance => totalTheyOweMe - totalIOweThem;

  double get totalUnpaidBillsAmount =>
      bills.where((b) => !b.isPaid).fold(0.0, (s, b) => s + b.amount);

  int get overdueBillCount =>
      bills.where((b) => b.status == BillStatus.overdue).length;

  /// Wipes everything on-device — used only if the user explicitly
  /// asks to reset the app.
  Future<void> resetAll() async {
    shoppingLists.clear();
    contacts.clear();
    bills.clear();
    await _storage.clearAll();
    notifyListeners();
  }
}

/// Internal accumulator used by [AppData.frequentItems].
class _ItemStats {
  String name;
  double price;
  String category;
  int count;
  DateTime lastDate;

  _ItemStats({
    required this.name,
    required this.price,
    required this.category,
    required this.count,
    required this.lastDate,
  });
}
