import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../models/bill.dart';
import '../../services/app_data.dart';
import '../../widgets/bill_tile.dart';
import '../../widgets/bill_options_sheet.dart';
import '../../widgets/status_pill.dart';

class BillsHomeScreen extends StatefulWidget {
  const BillsHomeScreen({super.key});

  @override
  State<BillsHomeScreen> createState() => _BillsHomeScreenState();
}

class _BillsHomeScreenState extends State<BillsHomeScreen> {
  final data = AppData.instance;

  /// Shared form for both "Add Bill" and "Edit Bill" — pass
  /// [existing] to pre-fill it and save changes in place instead of
  /// creating a new one.
  void _billForm({Bill? existing}) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final amountCtrl = TextEditingController(
        text: existing != null && existing.amount > 0
            ? existing.amount.toStringAsFixed(0)
            : '');
    DateTime dueDate =
        existing?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    bool recurring = existing?.isRecurring ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                Text(isEditing ? 'Edit Bill' : 'Add Bill',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration:
                      const InputDecoration(hintText: 'Name (e.g. K-Electric)'),
                ),
                if (!isEditing) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 0,
                    children: [
                      'Bijli',
                      'Gas',
                      'Pani',
                      'Internet',
                      'Rent',
                      'School Fee',
                    ]
                        .map((n) => ActionChip(
                              label:
                                  Text(n, style: const TextStyle(fontSize: 12)),
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  setModalState(() => nameCtrl.text = n),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(hintText: 'Amount (optional)'),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 365 * 2)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) {
                      setModalState(() => dueDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Text('${dueDate.day}/${dueDate.month}/${dueDate.year}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Checkbox(
                      value: recurring,
                      activeColor: AppColors.primary,
                      onChanged: (v) =>
                          setModalState(() => recurring = v ?? false),
                    ),
                    const Text('Repeats every month'),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final amount =
                          double.tryParse(amountCtrl.text.trim()) ?? 0;
                      setState(() {
                        if (isEditing) {
                          existing.name = nameCtrl.text.trim();
                          existing.amount = amount;
                          if (existing.dueDate != dueDate) {
                            existing.manualStatus = '';
                          }
                          existing.dueDate = dueDate;
                          existing.isRecurring = recurring;
                          data.updateBill(existing);
                        } else {
                          data.addBill(Bill(
                            id: const Uuid().v4(),
                            name: nameCtrl.text.trim(),
                            amount: amount,
                            dueDate: dueDate,
                            isRecurring: recurring,
                          ));
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: Text(isEditing ? 'Save Changes' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  /// Tick circle = one-tap paid (with UNDO). Tapping the ROW opens
  /// the full options sheet (Paid / Pending / Upcoming / Alert...).
  void _quickPaid(Bill b) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (b.isPaid) {
      data.markBillUnpaid(b);
      messenger.showSnackBar(SnackBar(
        content: Text('"${b.name}" marked unpaid'),
        duration: const Duration(seconds: 3),
      ));
      return;
    }
    final next = data.markBillPaid(b);
    messenger.showSnackBar(SnackBar(
      content: Text(next == null
          ? '"${b.name}" paid ✅'
          : '"${b.name}" paid ✅  Next month added'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () => data.markBillUnpaid(b, autoCreatedNext: next),
      ),
    ));
  }

  Widget _tile(Bill b) => BillTile(
        key: ValueKey(b.id),
        bill: b,
        onQuickPaid: () => _quickPaid(b),
        onTap: () =>
            showBillOptions(context, b, onEdit: () => _billForm(existing: b)),
      );

  @override
  Widget build(BuildContext context) {
    final bills = data.upcomingUnpaidBills;
    final paidBills = data.bills.where((b) => b.isPaid).toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Bills')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'billsFab',
        onPressed: () => _billForm(),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Bill'),
      ),
      body: bills.isEmpty && paidBills.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No bills added yet',
              subtitle:
                  'Tap "Add Bill" — it\'ll remind\nyou automatically next time.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              children: [
                if (bills.isNotEmpty) ...[
                  Row(
                    children: [
                      const _SectionLabel('Pending'),
                      const Spacer(),
                      const Text('Bill par tap = options',
                          style: TextStyle(
                              fontSize: 11.5, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...bills.map(_tile),
                ],
                if (paidBills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const _SectionLabel('Paid'),
                  const SizedBox(height: 8),
                  ...paidBills.map(_tile),
                ],
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}
