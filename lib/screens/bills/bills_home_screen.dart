import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../models/bill.dart';
import '../../services/app_data.dart';
import '../../widgets/bill_tile.dart';
import '../../widgets/status_pill.dart';

class BillsHomeScreen extends StatefulWidget {
  const BillsHomeScreen({super.key});

  @override
  State<BillsHomeScreen> createState() => _BillsHomeScreenState();
}

class _BillsHomeScreenState extends State<BillsHomeScreen> {
  final data = AppData.instance;

  void _addBill() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    bool recurring = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
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
                const Text('Add Bill',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                      hintText: 'Name (e.g. K-Electric)'),
                ),
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
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
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
                        Text(
                            '${dueDate.day}/${dueDate.month}/${dueDate.year}'),
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
                      setState(() {
                        data.addBill(Bill(
                          id: const Uuid().v4(),
                          name: nameCtrl.text.trim(),
                          amount:
                              double.tryParse(amountCtrl.text.trim()) ?? 0,
                          dueDate: dueDate,
                          isRecurring: recurring,
                        ));
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
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
  Widget build(BuildContext context) {
    final bills = data.upcomingUnpaidBills;
    final paidBills = data.bills.where((b) => b.isPaid).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Bills')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'billsFab',
        onPressed: _addBill,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Bill'),
      ),
      body: bills.isEmpty && paidBills.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No bills added yet',
              subtitle: 'Tap "Add Bill" — it\'ll remind\nyou automatically next time.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              children: [
                if (bills.isNotEmpty) ...[
                  const _SectionLabel('Pending'),
                  const SizedBox(height: 8),
                  ...bills.map((b) => _dismissibleBill(
                        b,
                        BillTile(
                          bill: b,
                          onMarkPaid: () =>
                              setState(() => data.markBillPaid(b)),
                        ),
                      )),
                ],
                if (paidBills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const _SectionLabel('Paid'),
                  const SizedBox(height: 8),
                  ...paidBills.map((b) => _dismissibleBill(
                        b,
                        BillTile(bill: b, onMarkPaid: () {}),
                      )),
                ],
              ],
            ),
    );
  }
}

extension _BillsHomeScreenDismiss on _BillsHomeScreenState {
  Widget _dismissibleBill(Bill b, Widget child) {
    return Dismissible(
      key: ValueKey(b.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete this bill?'),
          content: Text('"${b.name}" will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      onDismissed: (_) => setState(() => data.deleteBill(b.id)),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: child,
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
