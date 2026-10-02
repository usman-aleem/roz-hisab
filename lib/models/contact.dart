import 'udhar_entry.dart';

class Contact {
  String id;
  String name;
  String phone;
  List<UdharEntry> entries;

  Contact({
    required this.id,
    required this.name,
    this.phone = '',
    List<UdharEntry>? entries,
  }) : entries = entries ?? [];

  /// Positive => they owe me. Negative => I owe them.
  double get balance {
    double bal = 0;
    for (final e in entries) {
      if (e.isSettled) continue;
      bal += e.type == UdharType.theyOweMe ? e.amount : -e.amount;
    }
    return bal;
  }

  DateTime? get lastActivity => entries.isEmpty
      ? null
      : entries.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);

  /// A due-date only matters while money is still outstanding in
  /// the SAME direction as that entry.
  bool isDueActive(UdharEntry e) {
    if (e.dueDate == null || e.isSettled) return false;
    final bal = balance;
    if (bal == 0) return false;
    return bal > 0
        ? e.type == UdharType.theyOweMe
        : e.type == UdharType.iOweThem;
  }

  /// The soonest active due-date entry (null if none).
  UdharEntry? get nextDueEntry {
    final list = entries.where(isDueActive).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return list.isEmpty ? null : list.first;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'],
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        entries: (json['entries'] as List)
            .map((e) => UdharEntry.fromJson(e))
            .toList(),
      );
}
