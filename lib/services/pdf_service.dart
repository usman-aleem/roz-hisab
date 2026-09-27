import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/shopping_list.dart';

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
                style: pw.TextStyle(
                    font: mono, fontSize: 7.5, letterSpacing: 1.5),
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
}
