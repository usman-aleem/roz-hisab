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
///
/// When [editList] is provided, this screen instead opens in Edit
/// mode: pre-filled with that list's items, saving updates the
/// existing list in place instead of creating a new one — this is
/// the "Update" and part of "Delete" (per-item) of full CRUD for
/// shopping lists (the list-level Delete lives on the Shopping home
/// screen).
class ActiveListScreen extends StatefulWidget {
  final ShoppingListModel? editList;

  const ActiveListScreen({super.key, this.editList});

  @override
  State<ActiveListScreen> createState() => _ActiveListScreenState();
}

class _ActiveListScreenState extends State<ActiveListScreen> {
  late final List<ShoppingItem> _items;
  final GlobalKey<QuickAddBarState> _quickAddKey = GlobalKey();
  static const _averagePriceHint = 400.0; // used for the sanity-check nudge

  bool get _isEditing => widget.editList != null;

  @override
  void initState() {
    super.initState();
    // Copy items so edits here don't mutate the original list until
    // the user actually taps Save — cancelling (back button) leaves
    // the saved list untouched.
    _items = widget.editList == null
        ? []
        : widget.editList!.items
            .map((i) => ShoppingItem(
                  name: i.name,
                  price: i.price,
                  quantity: i.quantity,
                  category: i.category,
                ))
            .toList();
  }

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
        (i) =>
            i.name.trim().toLowerCase() == suggestion.name.trim().toLowerCase(),
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

  String _fmtQty(double q) =>
      q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(1);

  /// Deletes an item but offers UNDO, so a wrong tap costs nothing.
  void _removeItem(int index) {
    final removed = _items[index];
    setState(() => _items.removeAt(index));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${removed.name}" removed'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () =>
                setState(() => _items.insert(index.clamp(0, _items.length), removed)),
          ),
        ),
      );
  }

  double get _total => _items.fold(0, (sum, i) => sum + i.total);

  /// Edit an already-added item's name, price, or quantity — without
  /// this, fixing a typo or a wrong price meant deleting the row and
  /// retyping it from scratch.
  void _editItem(int index) {
    final item = _items[index];
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(
        text: item.price > 0 ? item.price.toStringAsFixed(0) : '');
    final qtyCtrl = TextEditingController(
        text: item.quantity == item.quantity.roundToDouble()
            ? item.quantity.toStringAsFixed(0)
            : item.quantity.toStringAsFixed(1));

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
              const Text('Edit Item',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Item name'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Price'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Qty'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _removeItem(index);
                      },
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger),
                      child: const Text('Delete'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        final price =
                            double.tryParse(priceCtrl.text.trim()) ?? 0;
                        final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1;
                        setState(() {
                          _items[index] = ShoppingItem(
                            name: name,
                            price: price,
                            quantity: qty <= 0 ? 1 : qty,
                            category: CategoryService.categorize(name),
                          );
                        });
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
    );
  }

  void _finish() {
    if (_items.isEmpty) return;

    if (_isEditing) {
      final updated = ShoppingListModel(
        id: widget.editList!.id,
        title: widget.editList!.title,
        date: widget.editList!.date,
        items: _items,
        isDone: true,
      );
      AppData.instance.updateShoppingList(updated);
      Navigator.pop(context);
      return;
    }

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
      appBar: AppBar(title: Text(_isEditing ? 'Edit List' : 'New Trip')),
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
                      return Container(
                        key: ObjectKey(item),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _editItem(index),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                        '${_fmtQty(item.quantity)} x Rs. ${item.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Quick quantity - no need to open the editor
                            _MiniBtn(
                              icon: Icons.remove_rounded,
                              onTap: item.quantity > 1
                                  ? () => setState(() => item.quantity -= 1)
                                  : null,
                            ),
                            SizedBox(
                              width: 26,
                              child: Text(
                                _fmtQty(item.quantity),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                            _MiniBtn(
                              icon: Icons.add_rounded,
                              onTap: () => setState(() => item.quantity += 1),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 66,
                              child: Text(
                                'Rs. ${item.total.toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _editItem(index),
                              icon: const Icon(Icons.edit_outlined,
                                  size: 19, color: AppColors.primary),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _removeItem(index),
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 20, color: AppColors.danger),
                            ),
                          ],
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(_isEditing ? 'Save Changes' : 'Finish'),
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

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _MiniBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16,
            color: enabled ? AppColors.primaryDark : AppColors.textMuted),
      ),
    );
  }
}