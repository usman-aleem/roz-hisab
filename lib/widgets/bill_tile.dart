import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/bill.dart';
import 'hover_card.dart';
import 'status_pill.dart';

/// One bill row.
///
/// TAP the row  -> [onTap] (opens the options sheet: Paid / Pending /
///                 Upcoming / Send alert / Edit / Delete).
/// TAP the tick -> [onQuickPaid] (one-tap "paid" shortcut).
class BillTile extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;
  final VoidCallback? onQuickPaid;

  const BillTile({
    super.key,
    required this.bill,
    required this.onTap,
    this.onQuickPaid,
  });

  static Color colorFor(BillStatus s) {
    switch (s) {
      case BillStatus.overdue:
        return AppColors.danger;
      case BillStatus.dueSoon:
        return AppColors.amber;
      case BillStatus.paid:
        return AppColors.success;
      case BillStatus.pending:
        return AppColors.primary;
      case BillStatus.upcoming:
        return AppColors.textMuted;
    }
  }

  static String labelFor(BillStatus s) {
    switch (s) {
      case BillStatus.overdue:
        return 'Overdue';
      case BillStatus.dueSoon:
        return 'Due Soon';
      case BillStatus.paid:
        return 'Paid';
      case BillStatus.pending:
        return 'Pending';
      case BillStatus.upcoming:
        return 'Upcoming';
    }
  }

  static String dueText(Bill bill) {
    final date = DateFormat('dd MMM').format(bill.dueDate);
    if (bill.isPaid) return 'Due $date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due =
        DateTime(bill.dueDate.year, bill.dueDate.month, bill.dueDate.day);
    final diff = due.difference(today).inDays;
    if (diff < 0)
      return '$date  •  ${-diff} day${diff == -1 ? '' : 's'} overdue';
    if (diff == 0) return '$date  •  Today';
    if (diff == 1) return '$date  •  Tomorrow';
    return '$date  •  In $diff days';
  }

  @override
  Widget build(BuildContext context) {
    final status = bill.status;
    final color = colorFor(status);
    final paid = bill.isPaid;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HoverCard(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 14, 10),
          decoration: BoxDecoration(
            color: paid ? AppColors.background : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(
              color: status == BillStatus.overdue
                  ? AppColors.danger.withOpacity(0.4)
                  : AppColors.border,
            ),
            boxShadow: paid ? null : AppTokens.softShadow,
          ),
          child: Row(
            children: [
              InkWell(
                onTap: onQuickPaid,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: paid ? AppColors.success : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: paid ? AppColors.success : color,
                        width: 2,
                      ),
                    ),
                    child: Icon(Icons.check_rounded,
                        size: 17,
                        color: paid ? Colors.white : Colors.transparent),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            bill.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              decoration:
                                  paid ? TextDecoration.lineThrough : null,
                              color: paid
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (bill.isRecurring) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.repeat_rounded,
                              size: 14, color: AppColors.textMuted),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dueText(bill),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: status == BillStatus.overdue
                            ? AppColors.danger
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    bill.amount > 0
                        ? 'Rs. ${bill.amount.toStringAsFixed(0)}'
                        : '—',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  StatusPill(text: labelFor(status), color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
