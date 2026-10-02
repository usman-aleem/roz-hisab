import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../models/daily_item.dart';
import '../../services/alert_service.dart';
import '../../services/app_data.dart';
import '../../widgets/status_pill.dart';

String _fmt(double q) =>
    q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(1);

/// DAILY: doodh, dahi, naan, akhbar, pani, maid...
/// Tick a day with one tap. At month end the total is already there.
class DailyHomeScreen extends StatefulWidget {
  const DailyHomeScreen({super.key});

  @override
  State<DailyHomeScreen> createState() => _DailyHomeScreenState();
}

class _DailyHomeScreenState extends State<DailyHomeScreen> {
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

  @override
  Widget build(BuildContext context) {
    final items = data.dailyItems;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Items')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dailyFab',
        onPressed: () => showDailyItemForm(context),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Item'),
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'No daily items yet',
              subtitle:
                  'Milk, bread, newspaper, water...\nTap once a day and get the full monthly total.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.summarize_rounded,
                          color: AppColors.accentDark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${DateFormat('MMMM').format(now)} daily total',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentDark),
                        ),
                      ),
                      Text(
                        'Rs. ${data.dailyThisMonthTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AppColors.accentDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map((d) => _DailyCard(item: d)),
              ],
            ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  final DailyItem item;
  const _DailyCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final takenToday = item.takenOn(now);
    final days = item.daysInMonth(now.year, now.month);
    final amount = item.amountInMonth(now.year, now.month);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTokens.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DailyDetailScreen(item: item)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        'Rs. ${item.rate.toStringAsFixed(0)} / ${item.unit}  •  $days days',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'This month: Rs. ${amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
                // ONE tap = aaj aaya / nahi aaya
                InkWell(
                  onTap: () => AppData.instance.toggleDay(item, now),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          takenToday ? AppColors.success : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: takenToday
                              ? AppColors.success
                              : AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          takenToday ? Icons.check_rounded : Icons.add_rounded,
                          size: 20,
                          color: takenToday
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        Text(
                          takenToday ? 'Taken' : 'Today',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: takenToday
                                  ? Colors.white
                                  : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// Month calendar for one item
// ---------------------------------------------------------------
class DailyDetailScreen extends StatefulWidget {
  final DailyItem item;
  const DailyDetailScreen({super.key, required this.item});

  @override
  State<DailyDetailScreen> createState() => _DailyDetailScreenState();
}

class _DailyDetailScreenState extends State<DailyDetailScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month, 1);
  }

  DailyItem get item => widget.item;

  void _shiftMonth(int d) =>
      setState(() => _month = DateTime(_month.year, _month.month + d, 1));

  Future<void> _customQty(DateTime day) async {
    final ctrl = TextEditingController(
        text: item.qtyOn(day) > 0 ? _fmt(item.qtyOn(day)) : '');
    final result = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
            '${DateFormat('dd MMM').format(day)} - how many ${item.unit}?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: '0 = remove'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(ctrl.text.trim()) ?? 0),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      AppData.instance.setDayQty(item, day, result);
      setState(() {});
    }
  }

  void _delete() {
    final data = AppData.instance;
    final index = data.dailyItems.indexWhere((d) => d.id == item.id);
    final messenger = ScaffoldMessenger.of(context);
    data.deleteDailyItem(item.id);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('"${item.name}" deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => data.restoreDailyItem(index, item),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final y = _month.year;
    final m = _month.month;
    final daysInMonth = DateTime(y, m + 1, 0).day;
    final offset = DateTime(y, m, 1).weekday - 1; // Mon = 0
    final today = DateTime.now();

    final cells = <Widget>[];
    for (var i = 0; i < offset; i++) {
      cells.add(const SizedBox());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(y, m, d);
      final qty = item.qtyOn(day);
      final taken = qty > 0;
      final isToday = day.year == today.year &&
          day.month == today.month &&
          day.day == today.day;
      cells.add(
        InkWell(
          onTap: () {
            AppData.instance.toggleDay(item, day);
            setState(() {});
          },
          onLongPress: () => _customQty(day),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: taken ? AppColors.accent : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday
                    ? AppColors.gold
                    : (taken ? AppColors.accent : AppColors.border),
                width: isToday ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$d',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: taken ? Colors.white : AppColors.textPrimary)),
                if (taken && qty != item.defaultQty)
                  Text(_fmt(qty),
                      style: const TextStyle(
                          fontSize: 9.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }

    final days = item.daysInMonth(y, m);
    final qty = item.qtyInMonth(y, m);
    final amount = item.amountInMonth(y, m);

    return Scaffold(
      appBar: AppBar(
        title: Text('${item.emoji} ${item.name}'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () async {
              await showDailyItemForm(context, existing: item);
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _shiftMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(_month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => _shiftMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          Row(
            children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((w) => Expanded(
                      child: Center(
                        child: Text(w,
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Tap a day to mark it  •  Long-press to change the quantity',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('$days days  •  ${_fmt(qty)} ${item.unit}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark),
                ),
                Text(
                  '${_fmt(item.defaultQty)} ${item.unit} x Rs. ${item.rate.toStringAsFixed(0)} per ${item.unit}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => AlertService.whatsapp(
                      AlertService.dailyMessage(item, y, m)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366)),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text('WhatsApp'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => AlertService.email('${item.name} summary',
                      AlertService.dailyMessage(item, y, m),
                      to: AppData.instance.userEmail),
                  icon: const Icon(Icons.mail_outline_rounded, size: 18),
                  label: const Text('Email'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------
// Add / edit sheet
// ---------------------------------------------------------------
Future<void> showDailyItemForm(BuildContext context, {DailyItem? existing}) {
  final isEditing = existing != null;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final rateCtrl = TextEditingController(
      text: existing != null && existing.rate > 0
          ? existing.rate.toStringAsFixed(0)
          : '');
  final qtyCtrl = TextEditingController(
      text: existing != null ? _fmt(existing.defaultQty) : '1');
  String emoji = existing?.emoji ?? '🛒';
  String unit = existing?.unit ?? 'piece';
  String? error;

  const presets = [
    ['🥛', 'Milk', 'L', '1'],
    ['🥣', 'Yogurt', 'kg', '1'],
    ['🫓', 'Naan', 'piece', '4'],
    ['📰', 'Newspaper', 'piece', '1'],
    ['💧', 'Water', 'bottle', '1'],
    ['🧹', 'Maid', 'day', '1'],
  ];
  const units = ['L', 'kg', 'piece', 'bottle', 'day'];

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEditing ? 'Edit Item' : 'New Daily Item',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
                if (!isEditing) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: presets
                        .map((p) => ActionChip(
                              label: Text('${p[0]} ${p[1]}',
                                  style: const TextStyle(fontSize: 12)),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setModalState(() {
                                emoji = p[0];
                                nameCtrl.text = p[1];
                                unit = p[2];
                                qtyCtrl.text = p[3];
                              }),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  autofocus: !isEditing,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Name (e.g. Milk)',
                    prefixText: '$emoji  ',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            hintText: 'Rate per $unit', prefixText: 'Rs. '),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(hintText: 'Daily quantity'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: units
                      .map((u) => ChoiceChip(
                            label:
                                Text(u, style: const TextStyle(fontSize: 12)),
                            selected: unit == u,
                            visualDensity: VisualDensity.compact,
                            onSelected: (_) => setModalState(() => unit = u),
                          ))
                      .toList(),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(error!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 12.5)),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        setModalState(() => error = 'Enter a name');
                        return;
                      }
                      final rate = double.tryParse(rateCtrl.text.trim()) ?? 0;
                      var qty = double.tryParse(qtyCtrl.text.trim()) ?? 1;
                      if (qty <= 0) qty = 1;
                      final data = AppData.instance;
                      if (isEditing) {
                        existing!.name = name;
                        existing.emoji = emoji;
                        existing.unit = unit;
                        existing.rate = rate;
                        existing.defaultQty = qty;
                        data.saveDailyItems();
                      } else {
                        data.addDailyItem(DailyItem(
                          id: const Uuid().v4(),
                          name: name,
                          emoji: emoji,
                          unit: unit,
                          rate: rate,
                          defaultQty: qty,
                        ));
                      }
                      Navigator.pop(sheetCtx);
                    },
                    child: Text(isEditing ? 'Save Changes' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
