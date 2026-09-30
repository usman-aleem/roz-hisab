import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/contact.dart';
import '../../models/udhar_entry.dart';
import '../../services/app_data.dart';

class ContactDetailScreen extends StatefulWidget {
  final Contact contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  void _addEntry(UdharType type) => _entryForm(type: type);

  /// Shared form for adding a new entry AND editing an existing one
  /// (pass [existing] to edit it in place). The type can be corrected
  /// via the two chips when editing, in case something was logged
  /// the wrong way round originally.
  void _entryForm({required UdharType type, UdharEntry? existing}) {
    final isEditing = existing != null;
    final amountCtrl = TextEditingController(
        text: existing != null ? existing.amount.toStringAsFixed(0) : '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    UdharType selectedType = existing?.type ?? type;

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
                Text(
                  isEditing
                      ? 'Edit Entry (${widget.contact.name})'
                      : (type == UdharType.theyOweMe
                          ? 'I Gave (${widget.contact.name})'
                          : 'I Took (${widget.contact.name})'),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800),
                ),
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeChip(
                          label: 'I Gave',
                          selected: selectedType == UdharType.theyOweMe,
                          onTap: () => setModalState(
                              () => selectedType = UdharType.theyOweMe),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TypeChip(
                          label: 'I Took',
                          selected: selectedType == UdharType.iOweThem,
                          onTap: () => setModalState(
                              () => selectedType = UdharType.iOweThem),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  autofocus: !isEditing,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Amount (Rs.)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Note (optional) — e.g. tea money'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (isEditing) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            AppData.instance
                                .deleteUdharEntry(widget.contact, existing!.id);
                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger),
                          child: const Text('Delete'),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final amount =
                              double.tryParse(amountCtrl.text.trim());
                          if (amount == null || amount <= 0) return;
                          setState(() {
                            if (isEditing) {
                              existing!.type = selectedType;
                              existing.amount = amount;
                              existing.note = noteCtrl.text.trim();
                            } else {
                              widget.contact.entries.add(UdharEntry(
                                id: const Uuid().v4(),
                                type: type,
                                amount: amount,
                                note: noteCtrl.text.trim(),
                              ));
                            }
                          });
                          AppData.instance.saveContacts();
                          Navigator.pop(context);
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "Settle Up" — the real-world action of recording a payment
  /// (full or partial) against the outstanding balance, framed the
  /// way people actually think about it ("kitna wapis kiya?") rather
  /// than making them figure out whether a repayment counts as
  /// "I Gave" or "I Took".
  void _settleUp() {
    final bal = widget.contact.balance;
    if (bal == 0) return;
    final theyOweMe = bal > 0;
    final amountCtrl =
        TextEditingController(text: bal.abs().toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
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
              Text(
                theyOweMe
                    ? 'Settle Up — ${widget.contact.name} paid you'
                    : 'Settle Up — you paid ${widget.contact.name}',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Outstanding: Rs. ${bal.abs().toStringAsFixed(0)}. Enter the full amount or just what was paid back so far.',
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Amount (Rs.)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) return;
                    setState(() {
                      AppData.instance.recordPayment(widget.contact, amount);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sends a friendly WhatsApp reminder with the current balance —
  /// solves the awkwardness of asking someone in person or over a
  /// phone call to pay back what they owe. Prompts for a phone
  /// number first if the contact doesn't have one saved yet.
  Future<void> _remindViaWhatsApp() async {
    final bal = widget.contact.balance;
    if (bal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Already all settled — nothing to remind about.')),
      );
      return;
    }

    var phone = widget.contact.phone.trim();
    if (phone.isEmpty) {
      final entered = await _promptForPhone();
      if (entered == null || entered.isEmpty) return;
      phone = entered;
      setState(() {
        widget.contact.phone = phone;
      });
      AppData.instance.saveContacts();
    }

    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // Pakistani mobile numbers are commonly saved as "03xx-xxxxxxx" —
    // normalize the leading 0 to the country code so wa.me accepts it.
    final normalized =
        digits.startsWith('0') ? '92${digits.substring(1)}' : digits;

    final message = bal > 0
        ? 'Salam ${widget.contact.name}, Roz Hisab ke mutabiq apka mera Rs. ${bal.abs().toStringAsFixed(0)} udhar hai. Waqt milte hi ada kar dein, shukriya!'
        : 'Salam ${widget.contact.name}, yaad dila raha hoon ke mujhe apka Rs. ${bal.abs().toStringAsFixed(0)} dena hai — jald ada kar doon ga.';

    final uri = Uri.parse(
        'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Could not open WhatsApp — check the number and try again.')),
      );
    }
  }

  Future<String?> _promptForPhone() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add phone number'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '03xx-xxxxxxx'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editContact() {
    final nameCtrl = TextEditingController(text: widget.contact.name);
    final phoneCtrl = TextEditingController(text: widget.contact.phone);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
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
              const Text('Edit Person',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
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
                      widget.contact.name = nameCtrl.text.trim();
                      widget.contact.phone = phoneCtrl.text.trim();
                    });
                    AppData.instance.saveContacts();
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteContact() async {
    final bal = widget.contact.balance;
    final hasBalance = bal != 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this contact?'),
        content: Text(
          hasBalance
              ? '⚠️ "${widget.contact.name}" currently ${bal > 0 ? "owes you" : "you owe them"} Rs. ${bal.abs().toStringAsFixed(0)} — deleting this will also erase that record.'
              : '"${widget.contact.name}" and their entire history will be deleted.',
        ),
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
    );

    if (confirmed == true) {
      AppData.instance.deleteContact(widget.contact.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;
    final bal = contact.balance;
    final isPositive = bal >= 0;
    final color = bal == 0
        ? AppColors.textMuted
        : (isPositive ? AppColors.success : AppColors.danger);

    return Scaffold(
      appBar: AppBar(
        title: Text(contact.name),
        actions: [
          IconButton(
            onPressed: _editContact,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _deleteContact,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  bal == 0
                      ? 'All Settled'
                      : (isPositive ? 'They owe you' : 'You owe them'),
                  style: TextStyle(
                      fontSize: 13, color: color, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${bal.abs().toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _addEntry(UdharType.theyOweMe),
                        child: const Text('+ I Gave'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _addEntry(UdharType.iOweThem),
                        child: const Text('+ I Took'),
                      ),
                    ),
                  ],
                ),
                if (bal != 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _settleUp,
                          icon: const Icon(Icons.check_circle_outline_rounded,
                              size: 18),
                          label: const Text('Settle Up'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _remindViaWhatsApp,
                          icon: const Icon(Icons.chat_outlined, size: 18),
                          label: const Text('Remind'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                Text('History',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: contact.entries.isEmpty
                ? const Center(
                    child: Text('No entries',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: contact.entries.length,
                    itemBuilder: (context, index) {
                      final sorted = [...contact.entries]
                        ..sort((a, b) => b.date.compareTo(a.date));
                      final e = sorted[index];
                      final positive = e.type == UdharType.theyOweMe;
                      return Dismissible(
                        key: ValueKey(e.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete this entry?'),
                            content: const Text(
                                'This transaction will be permanently removed.'),
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
                        onDismissed: (_) {
                          AppData.instance
                              .deleteUdharEntry(widget.contact, e.id);
                          setState(() {});
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.white),
                        ),
                        child: InkWell(
                          onTap: () => _entryForm(type: e.type, existing: e),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  positive
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  color: positive
                                      ? AppColors.success
                                      : AppColors.danger,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.note.isEmpty
                                            ? (positive ? 'Diya' : 'Liya')
                                            : e.note,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        DateFormat('dd MMM').format(e.date),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Rs. ${e.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: positive
                                        ? AppColors.success
                                        : AppColors.danger,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_outlined,
                                    size: 14, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Small selectable pill used in the Edit Entry sheet to switch an
/// entry between "I Gave" and "I Took".
class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
