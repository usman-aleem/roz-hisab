enum UdharType { theyOweMe, iOweThem }

class UdharEntry {
  String id;
  UdharType type;
  double amount;
  String note;
  DateTime date;
  bool isSettled;

  UdharEntry({
    required this.id,
    required this.type,
    required this.amount,
    this.note = '',
    DateTime? date,
    this.isSettled = false,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'note': note,
        'date': date.toIso8601String(),
        'isSettled': isSettled,
      };

  factory UdharEntry.fromJson(Map<String, dynamic> json) => UdharEntry(
        id: json['id'],
        type: UdharType.values.firstWhere((t) => t.name == json['type']),
        amount: (json['amount'] ?? 0).toDouble(),
        note: json['note'] ?? '',
        date: DateTime.parse(json['date']),
        isSettled: json['isSettled'] ?? false,
      );
}
