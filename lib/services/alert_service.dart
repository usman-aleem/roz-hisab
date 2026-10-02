import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bill.dart';
import '../models/contact.dart';
import '../models/daily_item.dart';
import '../models/udhar_entry.dart';
import 'app_data.dart';

/// Sends a ready-made alert to WhatsApp or Email.
///
/// WHY: browsers can't show scheduled phone notifications, so on the
/// website this is the reliable way to get a reminder - send it to
/// yourself (or to the person) with ONE tap.
class AlertService {
  static String _normalize(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return digits.startsWith('0') ? '92${digits.substring(1)}' : digits;
  }

  static String billMessage(Bill b) {
    final due = DateFormat('dd MMM yyyy').format(b.dueDate);
    final amt = b.amount > 0 ? 'Rs. ${b.amount.toStringAsFixed(0)}' : '';
    final status = switch (b.status) {
      BillStatus.overdue => 'OVERDUE',
      BillStatus.dueSoon => 'due soon',
      BillStatus.paid => 'paid',
      _ => 'due',
    };
    return 'Roz Hisab Alert\n'
        'Bill: ${b.name}\n'
        '${amt.isEmpty ? '' : 'Amount: $amt\n'}'
        'Due date: $due\n'
        'Status: $status';
  }

  /// Plain-text statement of one person's udhar (for WhatsApp).
  static String udharStatement(Contact c) {
    final f = DateFormat('dd MMM');
    final sorted = [...c.entries]..sort((a, b) => b.date.compareTo(a.date));
    final lines = sorted.take(15).map((e) {
      final what = e.type == UdharType.theyOweMe ? 'Gave' : 'Took';
      final note = e.note.isEmpty ? '' : ' (${e.note})';
      return '${f.format(e.date)}  $what  Rs. ${e.amount.toStringAsFixed(0)}$note';
    }).join('\n');
    final bal = c.balance;
    final result = bal == 0
        ? 'All settled.'
        : (bal > 0
            ? 'Balance due from you: Rs. ${bal.abs().toStringAsFixed(0)}.'
            : 'Balance I owe you: Rs. ${bal.abs().toStringAsFixed(0)}.');
    final due = c.nextDueEntry?.dueDate;
    return 'Statement - ${c.name}\n$lines\n\n$result'
        '${due == null ? '' : '\nDue date: ${DateFormat('dd MMM yyyy').format(due)}'}';
  }

  static String dailyMessage(DailyItem d, int year, int month) {
    final days = d.daysInMonth(year, month);
    final qty = d.qtyInMonth(year, month);
    final q = qty == qty.roundToDouble()
        ? qty.toStringAsFixed(0)
        : qty.toStringAsFixed(1);
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));
    return '${d.name} - $monthName\n'
        '$days days, $q ${d.unit} x Rs. ${d.rate.toStringAsFixed(0)}\n'
        'Total: Rs. ${d.amountInMonth(year, month).toStringAsFixed(0)}';
  }

  /// Opens WhatsApp with [text]. If [phone] is empty, WhatsApp lets
  /// the user pick the chat (or "Message yourself").
  static Future<bool> whatsapp(String text, {String phone = ''}) {
    final n = _normalize(phone);
    final uri = Uri.parse(
        'https://wa.me/${n.isEmpty ? '' : n}?text=${Uri.encodeComponent(text)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> email(String subject, String body, {String to = ''}) {
    final uri = Uri.parse('mailto:$to'
        '?subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Convenience: send to the user's own saved phone/email if set.
  static Future<bool> billToWhatsApp(Bill b) =>
      whatsapp(billMessage(b), phone: AppData.instance.userPhone);

  static Future<bool> billToEmail(Bill b) =>
      email('Bill reminder: ${b.name}', billMessage(b),
          to: AppData.instance.userEmail);
}
