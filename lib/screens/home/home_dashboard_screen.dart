import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/app_data.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/bill_tile.dart';
import '../../widgets/spending_trend_card.dart';
import '../../widgets/budget_progress_card.dart';
import '../../widgets/category_breakdown_card.dart';
import '../bills/bills_home_screen.dart';
import '../settings/settings_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const HomeDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final data = AppData.instance;

  @override
  Widget build(BuildContext context) {
    final nextBill =
        data.upcomingUnpaidBills.isNotEmpty ? data.upcomingUnpaidBills.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roz Hisab'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textPrimary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            const Text(
              'Your Overview',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: [
                SummaryCard(
                  label: "Today's Spend",
                  value: 'Rs. ${data.todaySpend.toStringAsFixed(0)}',
                  icon: Icons.shopping_basket_outlined,
                  color: AppColors.primary,
                  onTap: () => widget.onNavigateTab?.call(1),
                ),
                SummaryCard(
                  label: "You're Owed",
                  value: 'Rs. ${data.totalTheyOweMe.toStringAsFixed(0)}',
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.success,
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
                SummaryCard(
                  label: 'You Owe',
                  value: 'Rs. ${data.totalIOweThem.toStringAsFixed(0)}',
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.danger,
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
                SummaryCard(
                  label: 'Pending Bills',
                  value: '${data.upcomingUnpaidBills.length}',
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.amber,
                  onTap: () => widget.onNavigateTab?.call(3),
                ),
              ],
            ),
            if (nextBill != null) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Next Bill',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigateTab?.call(3),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              BillTile(
                bill: nextBill,
                onMarkPaid: () {
                  setState(() => data.markBillPaid(nextBill));
                },
              ),
            ],
            if (data.monthlyBudget > 0) ...[
              const SizedBox(height: 24),
              BudgetProgressCard(
                spent: data.currentMonthSpend,
                budget: data.monthlyBudget,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  setState(() {});
                },
              ),
            ],
            const SizedBox(height: 24),
            SpendingTrendCard(monthlyTotals: data.monthlySpendLast6Months()),
            if (data.categorySpendThisMonth().isNotEmpty) ...[
              const SizedBox(height: 16),
              CategoryBreakdownCard(
                  categoryTotals: data.categorySpendThisMonth()),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.primaryDark),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Start a new shopping trip — just 2 taps',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigateTab?.call(1),
                    child: const Text('Start'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
