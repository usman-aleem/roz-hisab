import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import 'pin_keypad.dart';
import 'pin_setup_screen.dart';

/// Shown every time the app is opened, if App Lock is enabled.
/// Calls [onUnlocked] once the correct PIN (or biometric) is verified.
class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const PinLockScreen({super.key, required this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final _auth = AuthService();
  String _current = '';
  String? _error;
  bool _biometricsAvailable = false;
  int _shakeTrigger = 0;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await _auth.canUseBiometrics();
    if (mounted) setState(() => _biometricsAvailable = available);
    if (available) {
      // Offer it immediately so the user isn't forced to type if
      // fingerprint/face unlock is set up on the device.
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final ok = await _auth.authenticateWithBiometrics();
    if (ok) widget.onUnlocked();
  }

  void _onDigit(String d) {
    if (_current.length >= 4) return;
    setState(() {
      _error = null;
      _current += d;
    });
    if (_current.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), _verify);
    }
  }

  void _onBackspace() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  Future<void> _verify() async {
    final ok = await _auth.verifyPin(_current);
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = 'Wrong PIN — try again';
        _current = '';
        _shakeTrigger++;
      });
    }
  }

  Future<void> _forgotPin() async {
    final hasQuestion = await _auth.hasSecurityQuestion();
    if (!mounted) return;

    if (hasQuestion) {
      await _forgotPinWithSecurityQuestion();
    } else {
      // Legacy fallback for a PIN set before security questions
      // existed — old behavior: reset removes the lock entirely.
      await _forgotPinLegacy();
    }
  }

  Future<void> _forgotPinWithSecurityQuestion() async {
    final question = await _auth.getSecurityQuestion();
    final answerCtrl = TextEditingController();
    String? sheetError;

    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                const Text('Forgot Your PIN?',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  'Answer your security question correctly to set a new PIN.',
                  style:
                      TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(question ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: answerCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Your answer',
                    errorText: sheetError,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final ok =
                          await _auth.verifySecurityAnswer(answerCtrl.text);
                      if (ok) {
                        if (context.mounted) Navigator.pop(context, true);
                      } else {
                        setModalState(
                            () => sheetError = 'Answer incorrect — try again');
                      }
                    },
                    child: const Text('Verify'),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (verified != true || !mounted) return;

    // Identity confirmed — remove the old PIN, then have them set a
    // brand new one. The existing security question stays as-is.
    await _auth.disableLock();
    final newPinSet = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PinSetupScreen(isReset: true)),
    );
    if (newPinSet == true) {
      widget.onUnlocked();
    }
  }

  Future<void> _forgotPinLegacy() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Forgot PIN?'),
        content: const Text(
          'App Lock will reset (your PIN will be removed). Your data — '
          'shopping, udhar, bills — stays completely safe, nothing '
          'gets deleted. You can set a new PIN later from Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Reset Lock'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _auth.disableLock();
      widget.onUnlocked();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: ShakeWidget(
                  trigger: _shakeTrigger,
                  child: PinKeypad(
                    title: 'Roz Hisab is Locked',
                    subtitle: _error ?? 'Enter your 4-digit PIN',
                    enteredLength: _current.length,
                    hasError: _error != null,
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                    topAction: _biometricsAvailable
                        ? TextButton.icon(
                            onPressed: _tryBiometric,
                            icon: const Icon(Icons.fingerprint_rounded),
                            label: const Text('Unlock with Fingerprint'),
                          )
                        : null,
                  ),
                ),
              ),
              TextButton(
                onPressed: _forgotPin,
                child: const Text('Forgot PIN?'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
