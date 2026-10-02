/// A thing you buy/receive EVERY DAY and settle monthly:
/// doodh, naan, akhbar, pani bottle, maid...
/// One tick per day -> end of month you instantly know the amount.
class DailyItem {
  String id;
  String name;
  String emoji;
  String unit; // L, kg, piece, bottle, din
  double rate; // price per unit
  double defaultQty; // qty added on a single tap
  Map<String, double> log; // 'yyyy-MM-dd' -> qty

  DailyItem({
    required this.id,
    required this.name,
    this.emoji = '🛒',
    this.unit = 'piece',
    this.rate = 0,
    this.defaultQty = 1,
    Map<String, double>? log,
  }) : log = log ?? {};

  static String keyOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _prefix(int y, int m) => '$y-${m.toString().padLeft(2, '0')}-';

  double qtyOn(DateTime d) => log[keyOf(d)] ?? 0;
  bool takenOn(DateTime d) => qtyOn(d) > 0;

  int daysInMonth(int y, int m) =>
      log.keys.where((k) => k.startsWith(_prefix(y, m))).length;

  double qtyInMonth(int y, int m) => log.entries
      .where((e) => e.key.startsWith(_prefix(y, m)))
      .fold(0.0, (s, e) => s + e.value);

  double amountInMonth(int y, int m) => qtyInMonth(y, m) * rate;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'unit': unit,
        'rate': rate,
        'defaultQty': defaultQty,
        'log': log,
      };

  factory DailyItem.fromJson(Map<String, dynamic> json) => DailyItem(
        id: json['id'],
        name: json['name'] ?? '',
        emoji: json['emoji'] ?? '🛒',
        unit: json['unit'] ?? 'piece',
        rate: (json['rate'] ?? 0).toDouble(),
        defaultQty: (json['defaultQty'] ?? 1).toDouble(),
        log: ((json['log'] ?? {}) as Map)
            .map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      );
}
