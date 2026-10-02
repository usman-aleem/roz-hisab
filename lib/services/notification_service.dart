import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/bill.dart';
import '../models/contact.dart';
import '../models/udhar_entry.dart';

/// Schedules a local notification the morning a bill is due, so
/// "Bill Reminders" actually reminds you — not just shows colors in
/// the app you have to remember to open.
///
/// Not available on web (browsers don't support scheduled local
/// notifications the way native apps do) — calls are safely no-ops
/// there.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (kIsWeb || _initialized) return;

    tz_data.initializeTimeZones();
    // Defaulting to Pakistan Standard Time since that's this app's
    // primary market — can be made dynamic (flutter_timezone
    // package) later if the app targets other regions too.
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
    } catch (_) {
      // Falls back to UTC if the timezone database lookup fails.
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // Android 13+ requires this runtime permission explicitly.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  int _notificationIdFor(String billId) => billId.hashCode & 0x7FFFFFFF;

  /// Schedules a reminder for 9:00 AM on the bill's due date. If that
  /// moment has already passed, nothing is scheduled (an overdue bill
  /// already shows red in the app itself).
  Future<void> scheduleBillReminder(Bill bill) async {
    if (kIsWeb || !_initialized || bill.isPaid) return;

    final due = bill.dueDate;
    final reminderTime =
        tz.TZDateTime(tz.local, due.year, due.month, due.day, 9, 0);

    if (reminderTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    try {
      await _plugin.zonedSchedule(
        _notificationIdFor(bill.id),
        '${bill.name} is due today',
        'Rs. ${bill.amount.toStringAsFixed(0)} — open Roz Hisab to mark it paid.',
        reminderTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'bill_reminders',
            'Bill Reminders',
            channelDescription: 'Reminds you when a bill is due',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Roz Hisab: could not schedule reminder for '
          '${bill.name}: $e');
    }
  }

  Future<void> cancelBillReminder(Bill bill) async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(_notificationIdFor(bill.id));
  }

  /// Called once at startup so reminders survive app reinstalls,
  /// cleared notification state, or bills added on another session.
  Future<void> rescheduleAll(List<Bill> bills) async {
    if (kIsWeb || !_initialized) return;
    for (final bill in bills.where((b) => !b.isPaid)) {
      await scheduleBillReminder(bill);
    }
  }

  // ---------- Udhar due-date reminders ----------

  /// 9:00 AM on the day money is due to be given/received.
  Future<void> scheduleUdharReminder(Contact c, UdharEntry e) async {
    if (kIsWeb || !_initialized || e.dueDate == null) return;
    final due = e.dueDate!;
    final when = tz.TZDateTime(tz.local, due.year, due.month, due.day, 9, 0);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;

    final receive = e.type == UdharType.theyOweMe;
    try {
      await _plugin.zonedSchedule(
        _notificationIdFor('udhar_${e.id}'),
        receive ? 'Collect payment from ${c.name}' : 'Pay ${c.name} today',
        'Rs. ${c.balance.abs().toStringAsFixed(0)} is due today. '
        'Open Roz Hisab for details.',
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'udhar_reminders',
            'Ledger Reminders',
            channelDescription: 'Reminds you when a ledger payment is due',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (err) {
      debugPrint('Roz Hisab: could not schedule udhar reminder: $err');
    }
  }

  Future<void> cancelUdharReminder(UdharEntry e) async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(_notificationIdFor('udhar_${e.id}'));
  }

  /// Re-syncs every udhar reminder: schedules the ones still
  /// outstanding, cancels the ones that were settled/changed.
  Future<void> syncUdhar(List<Contact> contacts) async {
    if (kIsWeb || !_initialized) return;
    for (final c in contacts) {
      for (final e in c.entries.where((e) => e.dueDate != null)) {
        if (c.isDueActive(e)) {
          await scheduleUdharReminder(c, e);
        } else {
          await cancelUdharReminder(e);
        }
      }
    }
  }
}
