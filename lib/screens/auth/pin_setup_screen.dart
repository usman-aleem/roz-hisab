import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import 'pin_keypad.dart';

/// First-time PIN creation flow: enter 4 digits, then confirm them.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _auth = AuthService();
  String _first = '';
  String _current = '';
  bool _confirming = false;
  String? _error;

  void _onDigit(String d) {
    if (_current.length >= 4) return;
    setState(() {
      _error = null;
      _current += d;
    });
    if (_current.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _handleComplete);
    }
  }

  void _onBackspace() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  Future<void> _handleComplete() async {
    if (!_confirming) {
      setState(() {
        _first = _current;
        _current = '';
        _confirming = true;
      });
      return;
    }

    if (_current == _first) {
      await _auth.setPin(_first);
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _error = "PINs didn't match — try again";
        _current = '';
        _confirming = false;
        _first = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Up App Lock')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: PinKeypad(
          title: _confirming ? 'Confirm PIN' : 'Create New PIN',
          subtitle: _error ??
              (_confirming
                  ? 'Enter the same 4-digit PIN again'
                  : 'Set a 4-digit PIN to open the app'),
          enteredLength: _current.length,
          onDigit: _onDigit,
          onBackspace: _onBackspace,
        ),
      ),
    );
  }
}
