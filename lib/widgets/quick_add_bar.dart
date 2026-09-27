import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Designed for SPEED — market mein khade ho kar use hoga.
/// Name type -> keyboard "next" -> price type -> Enter/Add -> field clear,
/// cursor wapas name field pe, agla item turant likh sako.
///
/// Quantity defaults to 1 and stays out of the way (a +/- stepper,
/// no extra typing needed) — real problem: buying "2 dozen eggs" or
/// "3 packets" meant re-adding the same item 2-3 times before this.
class QuickAddBar extends StatefulWidget {
  final void Function(String name, double price, double quantity) onAdd;

  const QuickAddBar({super.key, required this.onAdd});

  @override
  State<QuickAddBar> createState() => QuickAddBarState();
}

class QuickAddBarState extends State<QuickAddBar> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _priceFocus = FocusNode();
  double _qty = 1;

  /// Lets a parent (e.g. a "Buy Again" chip) prefill the fields
  /// without duplicating the submit logic.
  void prefill(String name, double price) {
    setState(() {
      _nameCtrl.text = name;
      _priceCtrl.text = price > 0 ? price.toStringAsFixed(0) : '';
      _qty = 1;
    });
    _priceFocus.requestFocus();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    if (name.isEmpty) return;
    widget.onAdd(name, price, _qty);
    _nameCtrl.clear();
    _priceCtrl.clear();
    setState(() => _qty = 1);
    _nameFocus.requestFocus(); // ready for the next item immediately
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Item (e.g. Rice)',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _priceFocus.requestFocus(),
                ),
              ),
              Container(width: 1, height: 24, color: AppColors.border),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _priceCtrl,
                  focusNode: _priceFocus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Price',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _submit,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Qty:',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              _QtyButton(
                icon: Icons.remove_rounded,
                onTap: _qty > 1 ? () => setState(() => _qty -= 1) : null,
              ),
              SizedBox(
                width: 36,
                child: Text(
                  _qty == _qty.roundToDouble()
                      ? _qty.toStringAsFixed(0)
                      : _qty.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                onTap: _qty < 999 ? () => setState(() => _qty += 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, required this.onTap});

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
