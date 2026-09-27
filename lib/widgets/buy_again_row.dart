import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/shopping_item.dart';

/// Horizontal row of "you buy this often" chips shown above the
/// quick-add bar. Tapping a chip adds that item at its last known
/// price immediately — no typing at all. This is the real fix for
/// the app's own stated problem #1 ("market mein kya liya, kitne ka
/// liya" — people don't write it down because typing every item,
/// every trip, is tiring). Most people re-buy the same 10-15 items
/// on repeat.
class BuyAgainRow extends StatelessWidget {
  final List<ShoppingItem> items;
  final void Function(ShoppingItem item) onTapItem;

  const BuyAgainRow({
    super.key,
    required this.items,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => onTapItem(item),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded,
                      size: 14, color: AppColors.accentDark),
                  const SizedBox(width: 4),
                  Text(
                    item.price > 0
                        ? '${item.name} · Rs.${item.price.toStringAsFixed(0)}'
                        : item.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
