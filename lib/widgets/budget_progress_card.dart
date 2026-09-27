import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Shows how much of this month's shopping budget has been spent,
/// color-shifting from brand teal → amber → red as it gets close to
/// or exceeds the limit. Hidden entirely if no budget is set — an
/// empty progress bar at 0% would just be noise.
class BudgetProgressCard extends StatelessWidget {
  final double spent;
  final double budget;
  final VoidCallback? onTap;

  const BudgetProgressCard({
    super.key,
    required this.spent,
    required this.budget,
    this.onTap,
  });

  Color _barColor(double fraction) {
    if (fraction >= 1.0) return AppColors.danger;
    if (fraction >= 0.8) return AppColors.amber;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final fraction = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.5);
    final barColor = _barColor(fraction);
    final isOver = spent > budget;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
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
                const Text(
                  'Monthly Budget',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (isOver)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Over budget',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fraction > 1.0 ? 1.0 : fraction,
                minHeight: 10,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rs. ${spent.toStringAsFixed(0)} spent',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'of Rs. ${budget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
