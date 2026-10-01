import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/contact.dart';
import '../../models/udhar_entry.dart';
import '../../services/app_data.dart';
import '../../widgets/contact_balance_tile.dart';
import '../../widgets/due_date_picker.dart';
import '../../widgets/status_pill.dart';
import 'contact_detail_screen.dart';

class UdharHomeScreen extends StatefulWidget {
  const UdharHomeScreen({super.key});

  @override
  State<UdharHomeScreen> createState() => _UdharHomeScreenState();
}

class _UdharHomeScreenState extends State<UdharHomeScreen> {
  final data = AppData.instance;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    data.addListener(_onData);
  }

  @override
  void dispose() {
    data.removeListener(_onData);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onData() {
    if (mounted) setState(() {});
  }

  /// ONE sheet: Naam -> Amount -> (optional last date) -> tap
  /// "I Gave" or "I Took" and it is SAVED. Nothing else on screen.
  void _addSheet() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    DateTime? dueDate;
    bool showMore = false;
    String? error;
    List<String> suggestions = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          void save(UdharType t) {
            final name = nameCtrl.text.trim();
            final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
            if (name.isEmpty) {
              setModalState(() => error = 'Naam likhein');
              return;
            }
            if (amount <= 0) {
              setModalState(() => error = 'Amount likhein');
              return;
            }

            final match = data.contacts.where(
                (c) => c.name.trim().toLowerCase() == name.toLowerCase());
            if (match.isNotEmpty) {
              data.addUdharEntry(match.first, t, amount,
                  note: noteCtrl.text.trim(), dueDate: dueDate);
            } else {
              data.addContactWithEntry(
                name: name,
                phone: phoneCtrl.text.trim(),
                type: t,
                amount: amount,
                note: noteCtrl.text.trim(),
                dueDate: dueDate,
              );
            }
            Navigator.pop(sheetCtx);
            ScaffoldMessenger.of(this.context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(t == UdharType.theyOweMe
                    ? '$name ko Rs. ${amount.toStringAsFixed(0)} diye ✅'
                    : '$name se Rs. ${amount.toStringAsFixed(0)} liye ✅'),
                duration: const Duration(seconds: 3),
              ));
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    const Text('Naya Udhar',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(hintText: 'Naam'),
                      onChanged: (v) {
                        final q = v.trim().toLowerCase();
                        setModalState(() {
                          error = null;
                          suggestions = q.isEmpty
                              ? []
                              : data.contacts
                                  .map((c) => c.name)
                                  .where((n) =>
                                      n.toLowerCase().contains(q) &&
                                      n.toLowerCase() != q)
                                  .take(4)
                                  .toList();
                        });
                      },
                    ),
                    if (suggestions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          children: suggestions
                              .map((n) => ActionChip(
                                    label: Text(n,
                                        style: const TextStyle(fontSize: 12)),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => setModalState(() {
                                      nameCtrl.text = n;
                                      nameCtrl.selection =
                                          TextSelection.collapsed(
                                              offset: n.length);
                                      suggestions = [];
                                    }),
                                  ))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          hintText: 'Amount', prefixText: 'Rs. '),
                      onChanged: (_) {
                        if (error != null) setModalState(() => error = null);
                      },
                    ),
                    const SizedBox(height: 12),
                    DueDatePicker(
                      value: dueDate,
                      onChanged: (d) => setModalState(() => dueDate = d),
                    ),
                    if (showMore) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: noteCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Note (optional) — e.g. chai'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            hintText: 'Phone (optional — WhatsApp reminder)'),
                      ),
                    ] else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => setModalState(() => showMore = true),
                          child: const Text('+ Note / Phone'),
                        ),
                      ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 2),
                        child: Text(error!,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 12.5)),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => save(UdharType.theyOweMe),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success),
                            icon:
                                const Icon(Icons.north_east_rounded, size: 18),
                            label: const Text('I Gave'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => save(UdharType.iOweThem),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.danger),
                            icon:
                                const Icon(Icons.south_west_rounded, size: 18),
                            label: const Text('I Took'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'I Gave = maine diye (mujhe milenge)  •  I Took = maine liye (mujhe dene hain)',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openContact(Contact c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ContactDetailScreen(contact: c)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final all = data.contacts;
    final contacts = _query.isEmpty
        ? all
        : all
            .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Udhar Khata')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'udharFab',
        onPressed: _addSheet,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Naya Udhar'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _TotalChip(
                    label: "You're Owed",
                    value: data.totalTheyOweMe,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TotalChip(
                    label: 'You Owe',
                    value: data.totalIOweThem,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          if (all.length > 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search naam',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
          Expanded(
            child: all.isEmpty
                ? const EmptyState(
                    icon: Icons.people_alt_outlined,
                    title: 'No entries yet',
                    subtitle:
                        'Tap "Naya Udhar" — naam aur amount\nlikho, bas ho gaya.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final c = contacts[index];
                      return ContactBalanceTile(
                        key: ValueKey(c.id),
                        contact: c,
                        onTap: () => _openContact(c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _TotalChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            'Rs. ${value.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
