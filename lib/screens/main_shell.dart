import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'home/home_dashboard_screen.dart';
import 'shopping/shopping_home_screen.dart';
import 'udhar/udhar_home_screen.dart';
import 'bills/bills_home_screen.dart';
import 'daily/daily_home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(onNavigateTab: _goTo),
      const ShoppingHomeScreen(),
      const UdharHomeScreen(),
      const BillsHomeScreen(),
      const DailyHomeScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: _PremiumNavBar(index: _index, onTap: _goTo),
    );
  }
}

/// A custom bottom bar (replacing the stock Material
/// BottomNavigationBar) — a rounded, gold-underlined pill highlights
/// the active tab against a soft floating card, closer to what a
/// premium fintech app looks like than flat default Android icons.
class _NavItemData {
  final IconData outline;
  final IconData filled;
  final String label;
  const _NavItemData(this.outline, this.filled, this.label);
}

class _PremiumNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _PremiumNavBar({required this.index, required this.onTap});

  static const List<_NavItemData> _items = [
    _NavItemData(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItemData(Icons.shopping_basket_outlined, Icons.shopping_basket_rounded,
        'Shopping'),
    _NavItemData(Icons.people_alt_outlined, Icons.people_alt_rounded, 'Ledger'),
    _NavItemData(
        Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Bills'),
    _NavItemData(
        Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Daily'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = i == index;
              return Expanded(
                child: _NavItem(
                  icon: active ? item.filled : item.outline,
                  label: item.label,
                  active: active,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: active ? AppColors.primaryDark : AppColors.textMuted,
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.primaryDark : AppColors.textMuted,
                  letterSpacing: 0.1,
                ),
                child: Text(label),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 3,
                width: active ? 16 : 0,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
