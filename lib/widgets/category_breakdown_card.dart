import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Answers README problem #1 directly: "market mein kya liya, kitne
/// ka liya — mahine ke end pe pata nahi chalta paisa kahan gaya."
/// This shows exactly where this month's shopping money went, broken
/// down by category — built entirely from categories the app already
/// auto-detects, so there's zero extra work for the user.
class CategoryBreakdownCard extends StatelessWidget {
  final Map<String, double> categoryTotals;

  const CategoryBreakdownCard({super.key, required this.categoryTotals});

  static const Map<String, Color> _colors = {
    'Grocery / Kirana': AppColors.primary,
    'Vegetables & Fruit': AppColors.success,
    'Dairy': AppColors.gold,
    'Meat & Fish': AppColors.danger,
    'Bakery': Color(0xFFB45309),
    'Snacks & Beverages': Color(0xFF7C3AED),
    'Household': AppColors.accent,
    'Personal Care': Color(0xFFDB2777),
    'Transport': Color(0xFF0284C7),
    'Medical': Color(0xFF059669),
    'Other': AppColors.textMuted,
  };

  Color _colorFor(String category) => _colors[category] ?? AppColors.textMuted;

  @override
  Widget build(BuildContext context) {
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final entries = categoryTotals.entries.take(5).toList();

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
            'Where Your Money Went',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 2),
          const Text(
            'This month, by category',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          if (total <= 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Add a shopping list to see the breakdown here.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            )
          else
            ...entries.map((e) {
              final fraction = total == 0 ? 0.0 : e.value / total;
              final color = _colorFor(e.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Rs. ${e.value.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction.clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
