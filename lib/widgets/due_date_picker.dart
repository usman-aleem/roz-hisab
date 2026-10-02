import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';

/// "Akhri date" selector used when adding udhar: quick chips
/// (1 hafta / 15 din / 1 mahina) + calendar. Tiny, tap-only.
class DueDatePicker extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String label;

  const DueDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Due date (you will get a reminder)',
  });

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool _isDays(int days) =>
      value != null && value!.difference(_today()).inDays == days;

  @override
  Widget build(BuildContext context) {
    Widget chip(String text, bool selected, VoidCallback onTap) => ChoiceChip(
          label: Text(text, style: const TextStyle(fontSize: 12)),
          selected: selected,
          visualDensity: VisualDensity.compact,
          onSelected: (_) => onTap(),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 0,
          children: [
            chip('None', value == null, () => onChanged(null)),
            chip('1 week', _isDays(7),
                () => onChanged(_today().add(const Duration(days: 7)))),
            chip('15 days', _isDays(15),
                () => onChanged(_today().add(const Duration(days: 15)))),
            chip('1 month', _isDays(30),
                () => onChanged(_today().add(const Duration(days: 30)))),
            ActionChip(
              avatar: const Icon(Icons.calendar_today_outlined, size: 14),
              label: Text(
                value == null
                    ? 'Pick a date'
                    : DateFormat('dd MMM yyyy').format(value!),
                style: const TextStyle(fontSize: 12),
              ),
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: value ?? _today().add(const Duration(days: 7)),
                  firstDate: _today().subtract(const Duration(days: 365)),
                  lastDate: _today().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) onChanged(picked);
              },
            ),
          ],
        ),
      ],
    );
  }
}
