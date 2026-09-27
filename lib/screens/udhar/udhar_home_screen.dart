import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../models/contact.dart';
import '../../services/app_data.dart';
import '../../widgets/contact_balance_tile.dart';
import '../../widgets/status_pill.dart';
import 'contact_detail_screen.dart';

class UdharHomeScreen extends StatefulWidget {
  const UdharHomeScreen({super.key});

  @override
  State<UdharHomeScreen> createState() => _UdharHomeScreenState();
}

class _UdharHomeScreenState extends State<UdharHomeScreen> {
  final data = AppData.instance;

  void _addContact() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
              const Text('Add Person',
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Naam'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    hintText: 'Phone (optional — for WhatsApp reminders)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    setState(() {
                      data.addContact(Contact(
                        id: const Uuid().v4(),
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                      ));
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = data.contacts;

    return Scaffold(
      appBar: AppBar(title: const Text('Udhar Khata')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'udharFab',
        onPressed: _addContact,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Person'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
          Expanded(
            child: contacts.isEmpty
                ? const EmptyState(
                    icon: Icons.people_alt_outlined,
                    title: 'No entries yet',
                    subtitle:
                        'Tap "Add Person" to start\ntracking who owes what.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final c = contacts[index];
                      return ContactBalanceTile(
                        contact: c,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContactDetailScreen(contact: c),
                            ),
                          );
                          setState(() {});
                        },
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
        color: color.withOpacity(0.1),
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
