import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/bill.dart';
import '../services/alert_service.dart';
import '../services/app_data.dart';
import 'bill_tile.dart';

/// Tap a bill -> this sheet:
///   Status:  Paid | Pending | Upcoming
///   Alert:   WhatsApp | Email
///   Edit / Delete
void showBillOptions(
  BuildContext context,
  Bill bill, {
  VoidCallback? onEdit,
}) {
  final data = AppData.instance;
  final messenger = ScaffoldMessenger.of(context);

  void toast(String msg, {SnackBarAction? action}) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 4),
        action: action,
      ));
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) {
      Widget statusBtn(String label, IconData icon, Color color, bool selected,
          VoidCallback onTap) {
        return Expanded(
          child: InkWell(
            onTap: () {
              Navigator.pop(sheetCtx);
              onTap();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.14) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: selected ? color : AppColors.border,
                    width: selected ? 1.6 : 1),
              ),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 4),
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: color)),
                ],
              ),
            ),
          ),
        );
      }

      Widget alertBtn(String label, IconData icon, Color color,
          Future<bool> Function() send) {
        return Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(sheetCtx);
              final ok = await send();
              if (!ok) toast('Could not open the app. Please try again.');
            },
            icon: Icon(icon, size: 18, color: color),
            label: Text(label),
          ),
        );
      }

      final st = bill.status;
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(bill.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  Text(
                    bill.amount > 0
                        ? 'Rs. ${bill.amount.toStringAsFixed(0)}'
                        : '',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(BillTile.dueText(bill),
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              const Text('Status',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  statusBtn('Paid', Icons.check_circle_rounded,
                      AppColors.success, st == BillStatus.paid, () {
                    if (bill.isPaid) return;
                    final next = data.markBillPaid(bill);
                    toast(
                      next == null
                          ? '"${bill.name}" paid ✅'
                          : '"${bill.name}" paid ✅  Next month\'s bill added',
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () =>
                            data.markBillUnpaid(bill, autoCreatedNext: next),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  statusBtn('Pending', Icons.hourglass_bottom_rounded,
                      AppColors.primary, st == BillStatus.pending, () {
                    data.setBillStatus(bill, manual: 'pending');
                    toast('"${bill.name}" pending');
                  }),
                  const SizedBox(width: 8),
                  statusBtn('Upcoming', Icons.event_rounded, AppColors.amber,
                      st == BillStatus.upcoming, () {
                    data.setBillStatus(bill, manual: 'upcoming');
                    toast('"${bill.name}" upcoming');
                  }),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Send alert',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  alertBtn(
                      'WhatsApp',
                      Icons.chat_rounded,
                      const Color(0xFF25D366),
                      () => AlertService.billToWhatsApp(bill)),
                  const SizedBox(width: 10),
                  alertBtn('Email', Icons.mail_outline_rounded,
                      AppColors.primary, () => AlertService.billToEmail(bill)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Save your phone or email in Settings to send alerts straight to yourself.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const Divider(height: 28),
              Row(
                children: [
                  if (onEdit != null)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          onEdit();
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                    ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        final index =
                            data.bills.indexWhere((x) => x.id == bill.id);
                        data.deleteBill(bill.id);
                        toast(
                          '"${bill.name}" deleted',
                          action: SnackBarAction(
                            label: 'UNDO',
                            onPressed: () => data.restoreBill(index, bill),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
