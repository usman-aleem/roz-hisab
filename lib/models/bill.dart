enum BillStatus { upcoming, pending, dueSoon, overdue, paid }

class Bill {
  String id;
  String name; // e.g. "K-Electric"
  double amount;
  DateTime dueDate;
  bool isRecurring; // e.g. same date every month
  bool isPaid;

  /// What the user picked from the tap-menu: '' (automatic),
  /// 'pending' or 'upcoming'. Overdue and Paid always win.
  String manualStatus;

  Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.isRecurring = false,
    this.isPaid = false,
    this.manualStatus = '',
  });

  BillStatus get status {
    if (isPaid) return BillStatus.paid;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;
    if (diff < 0) return BillStatus.overdue;
    if (manualStatus == 'pending') return BillStatus.pending;
    if (manualStatus == 'upcoming') return BillStatus.upcoming;
    if (diff <= 3) return BillStatus.dueSoon;
    return BillStatus.upcoming;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'isRecurring': isRecurring,
        'isPaid': isPaid,
        'manualStatus': manualStatus,
      };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: json['id'],
        name: json['name'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        dueDate: DateTime.parse(json['dueDate']),
        isRecurring: json['isRecurring'] ?? false,
        isPaid: json['isPaid'] ?? false,
        manualStatus: json['manualStatus'] ?? '',
      );
}
