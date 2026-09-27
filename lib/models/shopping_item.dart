class ShoppingItem {
  String name;
  double quantity;
  double price;

  /// Auto-detected spend category (e.g. "Grocery", "Vegetables & Fruit").
  /// Empty for items added before this field existed — treated as
  /// "Other" wherever categories are totalled/displayed.
  String category;

  ShoppingItem({
    this.name = '',
    this.quantity = 1,
    this.price = 0,
    this.category = '',
  });

  double get total => quantity * price;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'price': price,
        'category': category,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        name: json['name'] ?? '',
        quantity: (json['quantity'] ?? 1).toDouble(),
        price: (json['price'] ?? 0).toDouble(),
        category: json['category'] ?? '',
      );
}
