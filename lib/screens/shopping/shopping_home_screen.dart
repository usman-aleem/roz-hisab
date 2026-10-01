import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/shopping_list.dart';
import '../../services/app_data.dart';
import '../../widgets/hover_card.dart';
import '../../widgets/status_pill.dart';
import 'active_list_screen.dart';
import 'receipt_screen.dart';

class ShoppingHomeScreen extends StatefulWidget {
  const ShoppingHomeScreen({super.key});

  @override
  State<ShoppingHomeScreen> createState() => _ShoppingHomeScreenState();
}

class _ShoppingHomeScreenState extends State<ShoppingHomeScreen> {
  final data = AppData.instance;

  @override
  void initState() {
    super.initState();
    data.addListener(_onData);
  }

  @override
  void dispose() {
    data.removeListener(_onData);
    super.dispose();
  }

  void _onData() {
    if (mounted) setState(() {});
  }

  Future<void> _startNewList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActiveListScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _editList(ShoppingListModel list) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ActiveListScreen(editList: list)),
    );
    if (mounted) setState(() {});
  }

  void _openReceipt(ShoppingListModel list) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReceiptScreen(list: list)),
    );
  }

  /// Delete instantly, but keep an UNDO in the snackbar - faster than
  /// a confirm dialog and still safe against a mis-tap.
  void _deleteList(ShoppingListModel list) {
    final index = data.shoppingLists.indexWhere((l) => l.id == list.id);
    data.deleteShoppingList(list.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('List deleted'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => data.restoreShoppingList(index, list),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final lists = data.shoppingLists;

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Lists')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'shoppingFab',
        onPressed: _startNewList,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New List'),
      ),
      body: lists.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'No lists yet',
              subtitle:
                  'Tap "New List" while you shop\nand add items as you go.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                return _ListTile(
                  key: ValueKey(list.id),
                  list: list,
                  onOpen: () => _openReceipt(list),
                  onEdit: () => _editList(list),
                  onDelete: () => _deleteList(list),
                );
              },
            ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final ShoppingListModel list;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ListTile({
    super.key,
    required this.list,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final names = list.items.take(3).map((i) => i.name).join(', ');
    final more = list.items.length > 3 ? '  +${list.items.length - 3}' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: HoverCard(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_outlined,
                        color: AppColors.primaryDark, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.title.isEmpty ? 'Shopping List' : list.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('dd MMM, hh:mm a').format(list.date)} • ${list.itemCount} items',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                        if (names.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '$names$more',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      'Rs. ${list.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Divider(height: 1),
              // Big, labelled buttons - no hidden swipe needed
              // (swipe does not work with a mouse on the website).
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                  Container(width: 1, height: 22, color: AppColors.border),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onDelete,
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete'),
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
}
