import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/shopping_list.dart';
import '../../services/app_data.dart';
import '../../services/pdf_service.dart';

class ReceiptScreen extends StatefulWidget {
  final ShoppingListModel list;

  const ReceiptScreen({super.key, required this.list});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _working = false;

  Future<void> _downloadPdf() async {
    setState(() => _working = true);
    try {
      final bytes = await PdfService.buildReceiptPdf(
        widget.list,
        userName: AppData.instance.userName,
      );
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// On a real device (the Android app, or a phone's browser), the OS
  /// share sheet natively includes WhatsApp with the PDF attached —
  /// no special handling needed, `Printing.sharePdf` already does this.
  ///
  /// DESKTOP web browsers (e.g. testing via `flutter run -d chrome`)
  /// don't support the Web Share API for files at all — no website
  /// can attach a file directly into WhatsApp there, that's a browser
  /// sandboxing limit, not something any app's code can override. So
  /// on web specifically: download the PDF AND open WhatsApp with a
  /// pre-filled message, so the user just has to attach the file that
  /// was already downloaded — as close to "goes to WhatsApp" as a
  /// desktop browser allows.
  Future<void> _sharePdf() async {
    setState(() => _working = true);
    try {
      final bytes = await PdfService.buildReceiptPdf(
        widget.list,
        userName: AppData.instance.userName,
      );
      final fileName =
          'roz_hisab_receipt_${widget.list.date.millisecondsSinceEpoch}.pdf';

      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);

        final message = Uri.encodeComponent(
          'Roz Hisab Receipt — Total Rs. ${widget.list.total.toStringAsFixed(0)} '
          '(${DateFormat('dd MMM yyyy').format(widget.list.date)}).\n'
          'I just downloaded the PDF — attaching it here.',
        );
        final waUri = Uri.parse('https://wa.me/?text=$message');
        await launchUrl(waUri, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'PDF downloaded — attach it in the WhatsApp chat that just opened'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        // Mobile app / desktop app: real native share sheet, file
        // attaches directly — WhatsApp shows up automatically.
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTokens.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(list.title.isEmpty ? 'Shopping List' : list.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(list.date),
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                      if (AppData.instance.userName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Bill by: ${AppData.instance.userName}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 26),
                ],
              ),
              const Divider(height: 32),
              ...list.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item.name,
                            style: const TextStyle(fontSize: 14.5)),
                      ),
                      Text('x${item.quantity.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 70,
                        child: Text(
                          'Rs. ${item.total.toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(
                    'Rs. ${list.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _working ? null : _downloadPdf,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _working ? null : _sharePdf,
                  icon: _working
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
