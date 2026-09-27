import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../models/shopping_item.dart';
import '../../models/shopping_list.dart';
import '../../services/app_data.dart';
import '../../services/category_service.dart';
import '../../widgets/quick_add_bar.dart';
import '../../widgets/buy_again_row.dart';
import 'receipt_screen.dart';

/// This is the screen used WHILE shopping — designed for speed.
/// One tap to add an item, running total always visible.
class ActiveListScreen extends StatefulWidget {
  const ActiveListScreen({super.key});

  @override
  State<ActiveListScreen> createState() => _ActiveListScreenState();
}

class _ActiveListScreenState extends State<ActiveListScreen> {
  final List<ShoppingItem> _items = [];
  final GlobalKey<QuickAddBarState> _quickAddKey = GlobalKey();
  static const _averagePriceHint = 400.0; // used for the sanity-check nudge

  List<ShoppingItem> get _buyAgainSuggestions {
    final bought = _items.map((i) => i.name.trim().toLowerCase()).toSet();
    return AppData.instance
        .frequentItems(limit: 10)
        .where((i) => !bought.contains(i.name.trim().toLowerCase()))
        .take(6)
        .toList();
  }

  void _addItem(String name, double price, double quantity) {
    // Soft sanity-check nudge (lazy-user problem #2): unusually large price
    if (price > _averagePriceHint * 20 && price > 5000) {
      _confirmLargePrice(name, price, quantity);
      return;
    }
    setState(() {
      _items.add(ShoppingItem(
        name: name,
        price: price,
        quantity: quantity,
        category: CategoryService.categorize(name),
      ));
    });
  }

  void _confirmLargePrice(String name, double price, double quantity) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(
            '"$name" for Rs. ${price.toStringAsFixed(0)} — — is this correct?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Re-enter'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _items.add(ShoppingItem(
                    name: name,
                    price: price,
                    quantity: quantity,
                    category: CategoryService.categorize(name),
                  )));
              Navigator.pop(context);
            },
            child: const Text('Yes, correct'),
          ),
        ],
      ),
    );
  }

  /// Tapping a "Buy Again" chip adds the item straight away at its
  /// last known price — zero typing. If it's already in the current
  /// list, bump the quantity instead of creating a duplicate row.
  void _addFromSuggestion(ShoppingItem suggestion) {
    setState(() {
      final existingIndex = _items.indexWhere(
        (i) => i.name.trim().toLowerCase() == suggestion.name.trim().toLowerCase(),
      );
      if (existingIndex != -1) {
        _items[existingIndex].quantity += 1;
      } else {
        _items.add(ShoppingItem(
          name: suggestion.name,
          price: suggestion.price,
          quantity: 1,
          category: suggestion.category.isEmpty
              ? CategoryService.categorize(suggestion.name)
              : suggestion.category,
        ));
      }
    });
  }

  void _removeItem(int index) => setState(() => _items.removeAt(index));

  double get _total => _items.fold(0, (sum, i) => sum + i.total);

  void _finish() {
    if (_items.isEmpty) return;
    final list = ShoppingListModel(
      id: const Uuid().v4(),
      title: 'Shopping List',
      items: _items,
      isDone: true,
    );
    AppData.instance.addShoppingList(list);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ReceiptScreen(list: list)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _buyAgainSuggestions;
    return Scaffold(
      appBar: AppBar(title: const Text('New Trip')),
      body: Column(
        children: [
          Expanded(
            child: _items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_shopping_cart_rounded,
                              size: 40, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'Add an item and price below —\nyour list builds up here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Dismissible(
                        key: ValueKey('${item.name}_$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.white),
                        ),
                        onDismissed: (_) => _removeItem(index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    if (item.quantity != 1)
                                      Text(
                                        'x${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)}',
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rs. ${item.total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  if (suggestions.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 2),
                        child: Text(
                          'Buy Again',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    BuyAgainRow(
                      items: suggestions,
                      onTapItem: _addFromSuggestion,
                    ),
                    const SizedBox(height: 10),
                  ],
                  QuickAddBar(key: _quickAddKey, onAdd: _addItem),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            Text(
                              'Rs. ${_total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _items.isEmpty ? null : _finish,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('Finish'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
