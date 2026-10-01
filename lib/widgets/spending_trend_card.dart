import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Simple bar-style spending trend for the last 6 months — no
/// charting package needed, just proportional Containers. Answers
/// the daily question "am I spending more than last month?" at a
/// glance on the Home dashboard.
class SpendingTrendCard extends StatelessWidget {
  final Map<String, double> monthlyTotals;

  const SpendingTrendCard({super.key, required this.monthlyTotals});

  @override
  Widget build(BuildContext context) {
    final values = monthlyTotals.values.toList();
    final maxValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    final hasAnyData = values.any((v) => v > 0);

    return Container(
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
          const Text(
            'Spending Trend',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 2),
          const Text(
            'Last 6 months',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (!hasAnyData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Add a few shopping lists to see your trend here.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            )
          else
            SizedBox(
              height: 90,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: monthlyTotals.entries.map((entry) {
                  final isLast = entry.key == monthlyTotals.keys.last;
                  final heightFraction =
                      maxValue == 0 ? 0.0 : entry.value / maxValue;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            entry.value > 0
                                ? _shortAmount(entry.value)
                                : '',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: (heightFraction * 55).clamp(3.0, 55.0),
                            decoration: BoxDecoration(
                              color: isLast
                                  ? AppColors.accent
                                  : AppColors.primary.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _shortAmount(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}
