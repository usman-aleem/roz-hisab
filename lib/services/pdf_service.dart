import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../models/daily_item.dart';
import '../models/udhar_entry.dart';
import '../models/shopping_list.dart';
import 'app_data.dart';

/// Builds an AUTHENTIC-looking thermal-printer style receipt —
/// narrow roll width, monospace font, dashed separators, centered
/// header — exactly like a real shop/mall POS receipt, not a
/// generic A4 "document". Real receipts are black & white (thermal
/// printers can't print color), so this deliberately has no brand
/// colors — that's what makes it look real instead of designed.
class PdfService {
  static Future<Uint8List> buildReceiptPdf(
    ShoppingListModel list, {
    String userName = '',
  }) async {
    final doc = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy   hh:mm a').format(list.date);
    final receiptNo =
        'RH-${DateFormat('yyyyMMdd').format(list.date)}-${list.id.length >= 4 ? list.id.substring(0, 4).toUpperCase() : list.id.toUpperCase()}';

    final mono = pw.Font.courier();
    final monoBold = pw.Font.courierBold();
    const dash = '--------------------------------';

    pw.Widget dashLine() =>
        pw.Text(dash, style: pw.TextStyle(font: mono, fontSize: 8));

    pw.Widget kv(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label, style: pw.TextStyle(font: mono, fontSize: 8)),
              pw.Text(value, style: pw.TextStyle(font: mono, fontSize: 8)),
            ],
          ),
        );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // real 80mm thermal-roll width
        margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'ROZ HISAB',
                style: pw.TextStyle(
                    font: monoBold, fontSize: 15, letterSpacing: 3),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'SHOPPING RECEIPT',
                style:
                    pw.TextStyle(font: mono, fontSize: 7.5, letterSpacing: 1.5),
              ),
              if (userName.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  'Bill by: $userName',
                  style: pw.TextStyle(font: mono, fontSize: 8),
                ),
              ],
              pw.SizedBox(height: 10),
              dashLine(),
              pw.SizedBox(height: 4),
              kv('Date:', dateStr),
              kv('Receipt #:', receiptNo),
              pw.SizedBox(height: 4),
              dashLine(),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text('ITEM',
                        style: pw.TextStyle(font: monoBold, fontSize: 8)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('QTY',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(font: monoBold, fontSize: 8)),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text('TOTAL',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(font: monoBold, fontSize: 8)),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              dashLine(),
              ...list.items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item.name,
                        style: pw.TextStyle(font: mono, fontSize: 8.5),
                      ),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 5,
                            child: pw.Text(
                              '  @ Rs.${item.price.toStringAsFixed(0)}',
                              style: pw.TextStyle(
                                  font: mono,
                                  fontSize: 7.5,
                                  color: PdfColors.grey700),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'x${item.quantity.toStringAsFixed(0)}',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(font: mono, fontSize: 8),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              item.total.toStringAsFixed(0),
                              textAlign: pw.TextAlign.right,
                              style:
                                  pw.TextStyle(font: monoBold, fontSize: 8.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              dashLine(),
              pw.SizedBox(height: 6),
              kv('Total Items:', '${list.itemCount}'),
              pw.SizedBox(height: 6),
              dashLine(),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAND TOTAL',
                      style: pw.TextStyle(font: monoBold, fontSize: 11)),
                  pw.Text('Rs. ${list.total.toStringAsFixed(0)}',
                      style: pw.TextStyle(font: monoBold, fontSize: 11)),
                ],
              ),
              pw.SizedBox(height: 12),
              dashLine(),
              pw.SizedBox(height: 14),
              pw.Text('* * * THANK YOU * * *',
                  style: pw.TextStyle(font: monoBold, fontSize: 9)),
              pw.SizedBox(height: 3),
              pw.Text('Please Visit Again',
                  style: pw.TextStyle(font: mono, fontSize: 8)),
              pw.SizedBox(height: 16),
              pw.Text('Generated by Roz Hisab App',
                  style: pw.TextStyle(
                      font: mono, fontSize: 6.5, color: PdfColors.grey600)),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ------------------------------------------------------------------
  // Full-data backup report (A4). ASCII-only text on purpose: the
  // built-in PDF fonts cannot draw emoji / special symbols.
  // ------------------------------------------------------------------
  static Future<Uint8List> buildBackupReport(AppData data) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final fmt = DateFormat('dd MMM yyyy');
    String rs(double v) => 'Rs. ${v.toStringAsFixed(0)}';
    String q(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

    pw.Widget h1(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
          child: pw.Text(t,
              style:
                  pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        );

    pw.Widget cell(String t, {bool bold = false, bool right = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: pw.Text(
            t,
            textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        );

    pw.Widget table(List<String> head, List<List<String>> rows,
        {Set<int> rightCols = const {}}) {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              for (var i = 0; i < head.length; i++)
                cell(head[i], bold: true, right: rightCols.contains(i)),
            ],
          ),
          for (final r in rows)
            pw.TableRow(children: [
              for (var i = 0; i < r.length; i++)
                cell(r[i], right: rightCols.contains(i)),
            ]),
        ],
      );
    }

    pw.Widget kv(String k, String v) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(k, style: const pw.TextStyle(fontSize: 10)),
              pw.Text(v,
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );

    final widgets = <pw.Widget>[
      pw.Text('ROZ HISAB - DATA BACKUP',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Text(
        'Created: ${DateFormat('dd MMM yyyy, hh:mm a').format(now)}'
        '${data.userName.isNotEmpty ? '   |   ${data.userName}' : ''}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 12),
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey500),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(children: [
          kv('Money to receive (udhar)', rs(data.totalTheyOweMe)),
          kv('Money to pay (udhar)', rs(data.totalIOweThem)),
          kv('Unpaid bills', rs(data.totalUnpaidBillsAmount)),
          kv('Shopping this month', rs(data.currentMonthSpend)),
          kv('Daily items this month', rs(data.dailyThisMonthTotal)),
        ]),
      ),
    ];

    // ---- Udhar ----
    widgets.add(h1('Ledger (${data.contacts.length} people)'));
    if (data.contacts.isEmpty) {
      widgets
          .add(pw.Text('No entries.', style: const pw.TextStyle(fontSize: 10)));
    }
    for (final c in data.contacts) {
      final bal = c.balance;
      final sorted = [...c.entries]..sort((a, b) => a.date.compareTo(b.date));
      widgets.add(pw.SizedBox(height: 8));
      widgets.add(pw.Text(
        '${c.name}${c.phone.isNotEmpty ? '  (${c.phone})' : ''}  -  '
        '${bal == 0 ? 'Settled' : (bal > 0 ? 'owes you ${rs(bal.abs())}' : 'you owe ${rs(bal.abs())}')}',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ));
      widgets.add(pw.SizedBox(height: 3));
      widgets.add(table(
        ['Date', 'Type', 'Amount', 'Note', 'Last date'],
        sorted
            .map((UdharEntry e) => [
                  fmt.format(e.date),
                  e.type == UdharType.theyOweMe ? 'I gave' : 'I took',
                  rs(e.amount),
                  e.note,
                  e.dueDate == null ? '-' : fmt.format(e.dueDate!),
                ])
            .toList(),
        rightCols: {2},
      ));
    }

    // ---- Bills ----
    widgets.add(h1('Bills (${data.bills.length})'));
    if (data.bills.isEmpty) {
      widgets
          .add(pw.Text('No bills.', style: const pw.TextStyle(fontSize: 10)));
    } else {
      final sortedBills = [...data.bills]
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      widgets.add(table(
        ['Bill', 'Amount', 'Due date', 'Status', 'Repeats'],
        sortedBills
            .map((Bill b) => [
                  b.name,
                  rs(b.amount),
                  fmt.format(b.dueDate),
                  switch (b.status) {
                    BillStatus.paid => 'Paid',
                    BillStatus.overdue => 'Overdue',
                    BillStatus.dueSoon => 'Due soon',
                    BillStatus.pending => 'Pending',
                    BillStatus.upcoming => 'Upcoming',
                  },
                  b.isRecurring ? 'Monthly' : 'No',
                ])
            .toList(),
        rightCols: {1},
      ));
    }

    // ---- Daily ----
    widgets.add(h1('Daily items (${data.dailyItems.length})'));
    if (data.dailyItems.isEmpty) {
      widgets.add(pw.Text('None.', style: const pw.TextStyle(fontSize: 10)));
    } else {
      final months = <String>{};
      for (final d in data.dailyItems) {
        for (final k in d.log.keys) {
          months.add(k.substring(0, 7));
        }
      }
      final sortedMonths = months.toList()..sort((a, b) => b.compareTo(a));
      for (final DailyItem d in data.dailyItems) {
        widgets.add(pw.SizedBox(height: 6));
        widgets.add(pw.Text(
          '${d.name}  -  ${rs(d.rate)} per ${d.unit}',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ));
        widgets.add(pw.SizedBox(height: 3));
        widgets.add(table(
          ['Month', 'Days', 'Quantity', 'Total'],
          sortedMonths.map((m) {
            final y = int.parse(m.substring(0, 4));
            final mo = int.parse(m.substring(5, 7));
            return [
              DateFormat('MMM yyyy').format(DateTime(y, mo)),
              '${d.daysInMonth(y, mo)}',
              '${q(d.qtyInMonth(y, mo))} ${d.unit}',
              rs(d.amountInMonth(y, mo)),
            ];
          }).toList(),
          rightCols: {3},
        ));
      }
    }

    // ---- Shopping ----
    widgets.add(h1('Shopping lists (${data.shoppingLists.length})'));
    if (data.shoppingLists.isEmpty) {
      widgets.add(pw.Text('None.', style: const pw.TextStyle(fontSize: 10)));
    }
    for (final l in data.shoppingLists) {
      widgets.add(pw.SizedBox(height: 8));
      widgets.add(pw.Text(
        '${DateFormat('dd MMM yyyy, hh:mm a').format(l.date)}  -  Total ${rs(l.total)}',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ));
      widgets.add(pw.SizedBox(height: 3));
      widgets.add(table(
        ['Item', 'Qty', 'Price', 'Total'],
        l.items
            .map((i) => [i.name, q(i.quantity), rs(i.price), rs(i.total)])
            .toList(),
        rightCols: {1, 2, 3},
      ));
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
              'Roz Hisab  -  page ${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ),
        build: (ctx) => widgets,
      ),
    );

    return doc.save();
  }
}
