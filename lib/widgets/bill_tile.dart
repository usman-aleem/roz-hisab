import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/bill.dart';
import 'hover_card.dart';
import 'status_pill.dart';

class BillTile extends StatelessWidget {
  final Bill bill;
  final VoidCallback onMarkPaid;

  const BillTile({super.key, required this.bill, required this.onMarkPaid});

  Color _statusColor() {
    switch (bill.status) {
      case BillStatus.overdue:
        return AppColors.danger;
      case BillStatus.dueSoon:
        return AppColors.amber;
      case BillStatus.paid:
        return AppColors.success;
      case BillStatus.upcoming:
        return AppColors.textMuted;
    }
  }

  String _statusLabel() {
    switch (bill.status) {
      case BillStatus.overdue:
        return 'Overdue';
      case BillStatus.dueSoon:
        return 'Due Soon';
      case BillStatus.paid:
        return 'Paid';
      case BillStatus.upcoming:
        return 'Upcoming';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HoverCard(
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: bill.status == BillStatus.overdue
              ? AppColors.danger.withOpacity(0.4)
              : AppColors.border,
        ),
        boxShadow: AppTokens.softShadow,
      ),
      child: Row(
        children: [
          Container(width: 4, height: 40, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bill.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (bill.isRecurring)
                      const Icon(Icons.repeat_rounded,
                          size: 14, color: AppColors.textMuted),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM').format(bill.dueDate),
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${bill.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: bill.isPaid ? null : onMarkPaid,
                child: StatusPill(text: _statusLabel(), color: color),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }
}
