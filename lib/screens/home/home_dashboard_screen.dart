import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/daily_item.dart';
import '../../services/app_data.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/spending_trend_card.dart';
import '../../widgets/budget_progress_card.dart';
import '../../widgets/category_breakdown_card.dart';
import '../../widgets/hisab_character.dart';
import '../settings/settings_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  /// 0 Home, 1 Shopping, 2 Udhar, 3 Bills, 4 Daily
  final void Function(int tabIndex)? onNavigateTab;

  const HomeDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final data = AppData.instance;

  @override
  void initState() {
    super.initState();
    data.addListener(_onData);
  }

  @override
  void dispose() {
    data.removeListener(_onData);
    super.dispose();
  }

  void _onData() {
    if (mounted) setState(() {});
  }

  void _go(int i) => widget.onNavigateTab?.call(i);

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final reminders = data.upcomingReminders();
    final urgent = reminders.where((r) => r.daysLeft <= 0).length;
    final recent = data.recentActivity();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roz Hisab'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textPrimary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            _GreetingBanner(
              name: data.userName,
              urgentCount: urgent,
              onTap: data.userName.isEmpty ? _openSettings : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _QuickAction(
                    icon: Icons.shopping_basket_rounded,
                    label: 'Kharid',
                    color: AppColors.primary,
                    onTap: () => _go(1)),
                _QuickAction(
                    icon: Icons.people_alt_rounded,
                    label: 'Udhar',
                    color: AppColors.success,
                    onTap: () => _go(2)),
                _QuickAction(
                    icon: Icons.receipt_long_rounded,
                    label: 'Bills',
                    color: AppColors.amber,
                    onTap: () => _go(3)),
                _QuickAction(
                    icon: Icons.calendar_month_rounded,
                    label: 'Daily',
                    color: AppColors.accent,
                    onTap: () => _go(4)),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Hisab ek nazar mein'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                SummaryCard(
                  label: "Aaj ka kharcha",
                  value: data.todaySpend,
                  icon: Icons.shopping_basket_outlined,
                  color: AppColors.primary,
                  hint: 'Is mahine: Rs. ${data.currentMonthSpend.toStringAsFixed(0)}',
                  onTap: () => _go(1),
                ),
                SummaryCard(
                  label: "Mujhe milne hain",
                  value: data.totalTheyOweMe,
                  icon: Icons.south_west_rounded,
                  color: AppColors.success,
                  onTap: () => _go(2),
                ),
                SummaryCard(
                  label: 'Mujhe dene hain',
                  value: data.totalIOweThem,
                  icon: Icons.north_east_rounded,
                  color: AppColors.danger,
                  onTap: () => _go(2),
                ),
                SummaryCard(
                  label: 'Pending bills',
                  value: data.upcomingUnpaidBills.length.toDouble(),
                  prefix: '',
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.amber,
                  hint: data.overdueBillCount > 0
                      ? '${data.overdueBillCount} overdue'
                      : 'Koi overdue nahi',
                  onTap: () => _go(3),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _RemindersCard(
              items: reminders.take(5).toList(),
              onTap: (r) =>
                  _go(r.kind == ReminderKind.bill ? 3 : 2),
            ),
            if (data.dailyItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DailyTodayCard(
                items: data.dailyItems,
                onOpen: () => _go(4),
              ),
            ],
            if (data.monthlyBudget > 0) ...[
              const SizedBox(height: 16),
              BudgetProgressCard(
                spent: data.currentMonthSpend,
                budget: data.monthlyBudget,
                onTap: _openSettings,
              ),
            ],
            const SizedBox(height: 16),
            SpendingTrendCard(monthlyTotals: data.monthlySpendLast6Months()),
            if (data.categorySpendThisMonth().isNotEmpty) ...[
              const SizedBox(height: 16),
              CategoryBreakdownCard(
                  categoryTotals: data.categorySpendThisMonth()),
            ],
            if (recent.isNotEmpty) ...[
              const SizedBox(height: 16),
              _RecentCard(items: recent),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// Greeting banner with the animated hisab person
// ---------------------------------------------------------------
class _GreetingBanner extends StatelessWidget {
  final String name;
  final int urgentCount;
  final VoidCallback? onTap;

  const _GreetingBanner({
    required this.name,
    required this.urgentCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final first = name.trim().isEmpty ? '' : name.trim().split(' ').first;
    final hour = DateTime.now().hour;
    final salam = hour < 12
        ? 'Subah bakhair'
        : (hour < 17 ? 'Assalam o Alaikum' : 'Shaam bakhair');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF0D7C74)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(salam,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    first.isEmpty ? 'Hey dost 👋' : 'Hey $first 👋',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      urgentCount > 0
                          ? '⚠️ $urgentCount cheez ka waqt aa gaya'
                          : '✅ Sab kuch control mein',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    first.isEmpty
                        ? 'Naam set karne ke liye tap karein'
                        : DateFormat('EEEE, dd MMM').format(DateTime.now()),
                    style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const HisabCharacter(),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      );
}

class _CardShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _CardShell({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------
// Upcoming dates: bills + udhar due dates in one list
// ---------------------------------------------------------------
class _RemindersCard extends StatelessWidget {
  final List<ReminderItem> items;
  final void Function(ReminderItem) onTap;

  const _RemindersCard({required this.items, required this.onTap});

  String _when(int d) {
    if (d < 0) return '${-d} din late';
    if (d == 0) return 'Aaj';
    if (d == 1) return 'Kal';
    return '$d din baad';
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Aane wali dates',
      subtitle: 'Bills aur udhar ki akhri dates',
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('Abhi koi date nahi aane wali 🎉',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            )
          : Column(
              children: items.map((r) {
                final color = r.kind == ReminderKind.bill
                    ? AppColors.amber
                    : (r.kind == ReminderKind.toReceive
                        ? AppColors.success
                        : AppColors.danger);
                final icon = r.kind == ReminderKind.bill
                    ? Icons.receipt_long_rounded
                    : (r.kind == ReminderKind.toReceive
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded);
                final late = r.daysLeft < 0;
                return InkWell(
                  onTap: () => onTap(r),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 17, color: color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5)),
                              Text(r.label,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              r.amount > 0
                                  ? 'Rs. ${r.amount.toStringAsFixed(0)}'
                                  : '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            Text(
                              _when(r.daysLeft),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: late
                                    ? AppColors.danger
                                    : (r.daysLeft <= 1
                                        ? AppColors.amber
                                        : AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ---------------------------------------------------------------
// Today's daily items - one tap to tick doodh/naan/akhbar
// ---------------------------------------------------------------
class _DailyTodayCard extends StatelessWidget {
  final List<DailyItem> items;
  final VoidCallback onOpen;

  const _DailyTodayCard({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return _CardShell(
      title: 'Aaj ka Daily',
      subtitle: 'Jo aaj aaya, us par tap karein',
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ...items.map((d) => FilterChip(
                label: Text('${d.emoji} ${d.name}'),
                selected: d.takenOn(today),
                showCheckmark: true,
                selectedColor: AppColors.accentLight,
                onSelected: (_) => AppData.instance.toggleDay(d, today),
              )),
          ActionChip(
            label: const Text('Sab dekho'),
            avatar: const Icon(Icons.arrow_forward_rounded, size: 16),
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------
// Latest activity (shopping + udhar)
// ---------------------------------------------------------------
class _RecentCard extends StatelessWidget {
  final List<ActivityItem> items;
  const _RecentCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Haal hi ki activity',
      child: Column(
        children: items.map((a) {
          final color = a.kind == ActivityKind.shopping
              ? AppColors.primary
              : (a.kind == ActivityKind.gave
                  ? AppColors.success
                  : AppColors.danger);
          final icon = a.kind == ActivityKind.shopping
              ? Icons.shopping_basket_outlined
              : (a.kind == ActivityKind.gave
                  ? Icons.north_east_rounded
                  : Icons.south_west_rounded);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13.5)),
                      Text(
                        '${a.subtitle}  •  ${DateFormat('dd MMM').format(a.date)}',
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text('Rs. ${a.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}