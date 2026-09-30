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

  void _startNewList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActiveListScreen()),
    );
    setState(() {});
  }

  void _editList(ShoppingListModel list) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ActiveListScreen(editList: list)),
    );
    setState(() {});
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
        icon: const Icon(Icons.add_rounded),
        label: const Text('New List'),
      ),
      body: lists.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'No lists yet',
              subtitle: 'Tap "New List" while you shop\nand add items as you go.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                return Dismissible(
                  key: ValueKey(list.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete this list?'),
                      content: Text(
                          '"${list.title.isEmpty ? "Shopping List" : list.title}" will be permanently deleted.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (_) {
                    data.deleteShoppingList(list.id);
                    setState(() {});
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white),
                  ),
                  child: _ListTile(
                    list: list,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReceiptScreen(list: list),
                        ),
                      );
                    },
                    onEdit: () => _editList(list),
                  ),
                );
              },
            ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final ShoppingListModel list;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ListTile(
      {required this.list, required this.onTap, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: HoverCard(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
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
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs. ${list.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined,
                        size: 15, color: AppColors.textMuted),
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