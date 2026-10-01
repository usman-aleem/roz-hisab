import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/contact.dart';
import 'hover_card.dart';

/// One person row in the Udhar list.
///
/// LAZY-USER RULE: "I Gave" / "I Took" sit RIGHT on the row, so
/// logging money is: tap button -> type amount -> Enter. No need to
/// open the person's page first.
class ContactBalanceTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;
  final VoidCallback onGave;
  final VoidCallback onTook;

  const ContactBalanceTile({
    super.key,
    required this.contact,
    required this.onTap,
    required this.onGave,
    required this.onTook,
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
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTokens.softShadow,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      contact.name.isEmpty
                          ? '?'
                          : contact.name[0].toUpperCase(),
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
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _QuickBtn(
                      label: 'I Gave',
                      icon: Icons.north_east_rounded,
                      color: AppColors.success,
                      onTap: onGave,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickBtn(
                      label: 'I Took',
                      icon: Icons.south_west_rounded,
                      color: AppColors.danger,
                      onTap: onTook,
                    ),
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

class _QuickBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
