import 'shopping_item.dart';

class ShoppingListModel {
  String id;
  String title; // e.g. "Grocery - 24 Sep" (optional / auto)
  DateTime date;
  List<ShoppingItem> items;
  bool isDone;

  ShoppingListModel({
    required this.id,
    this.title = '',
    DateTime? date,
    List<ShoppingItem>? items,
    this.isDone = false,
  })  : date = date ?? DateTime.now(),
        items = items ?? [];

  double get total => items.fold(0, (sum, i) => sum + i.total);
  int get itemCount => items.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
        'isDone': isDone,
      };

  factory ShoppingListModel.fromJson(Map<String, dynamic> json) =>
      ShoppingListModel(
        id: json['id'],
        title: json['title'] ?? '',
        date: DateTime.parse(json['date']),
        items: (json['items'] as List)
            .map((i) => ShoppingItem.fromJson(i))
            .toList(),
        isDone: json['isDone'] ?? false,
      );
}
