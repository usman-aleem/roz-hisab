import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Shared numeric keypad + dot indicator used by both the PIN setup
/// screen and the PIN unlock screen.
///
/// Wrapped in a SingleChildScrollView with no Spacer (fixed gaps
/// instead) so it never overflows on short viewports — e.g. a
/// resized desktop browser window or a bottom sheet with limited
/// height.
class PinKeypad extends StatelessWidget {
  final String title;
  final String subtitle;
  final int enteredLength;
  final int pinLength;
  final Color accentColor;
  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;
  final Widget? topAction;

  const PinKeypad({
    super.key,
    required this.title,
    required this.subtitle,
    required this.enteredLength,
    required this.onDigit,
    required this.onBackspace,
    this.pinLength = 4,
    this.accentColor = AppColors.primary,
    this.topAction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_outline_rounded,
                        color: accentColor, size: 30),
                  ),
                  const SizedBox(height: 20),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pinLength, (i) {
                      final filled = i < enteredLength;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? accentColor : Colors.transparent,
                          border: Border.all(color: accentColor, width: 1.6),
                        ),
                      );
                    }),
                  ),
                  if (topAction != null) ...[
                    const SizedBox(height: 16),
                    topAction!,
                  ],
                  const SizedBox(height: 32),
                  _Keypad(onDigit: onDigit, onBackspace: onBackspace),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;

  const _Keypad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 76, height: 60);
              }
              return _KeyButton(
                label: key,
                onTap: () {
                  if (key == '⌫') {
                    onBackspace();
                  } else {
                    onDigit(key);
                  }
                },
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 76,
          height: 60,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
