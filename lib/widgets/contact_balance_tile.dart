import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/contact.dart';
import 'hover_card.dart';

class ContactBalanceTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;

  const ContactBalanceTile({
    super.key,
    required this.contact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bal = contact.balance;
    final isPositive = bal >= 0; // they owe me
    final color = bal == 0
        ? AppColors.textMuted
        : (isPositive ? AppColors.success : AppColors.danger);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HoverCard(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTokens.softShadow,
          ),
          child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                contact.name.isEmpty ? '?' : contact.name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bal == 0
                        ? 'Settled'
                        : (isPositive ? 'They owe you' : 'You owe them'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              bal == 0 ? '—' : 'Rs. ${bal.abs().toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: color,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
