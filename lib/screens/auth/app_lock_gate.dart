import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'pin_lock_screen.dart';

/// Wraps the whole app (post-unlock) and watches app lifecycle.
/// If App Lock is enabled and the app goes to the background
/// (user switches to another app / locks the phone) and later comes
/// back, this re-shows the PIN screen — so an already-unlocked
/// session can't just be picked up by anyone who has the phone.
///
/// Without this, PIN/biometric would only ever be asked once per
/// cold start, which defeats most of the point of having a lock.
class AppLockGate extends StatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  final _auth = AuthService();
  bool _locked = false;
  bool _wasBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only react to a real backgrounding (paused), not transient
    // "inactive" states like a share sheet or file picker opening —
    // otherwise the app would annoyingly re-lock itself constantly.
    if (state == AppLifecycleState.paused) {
      _wasBackgrounded = true;
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      _checkLockOnResume();
    }
  }

  Future<void> _checkLockOnResume() async {
    final hasPin = await _auth.hasPin();
    if (hasPin && mounted) {
      setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_locked) {
      return PinLockScreen(
        onUnlocked: () => setState(() => _locked = false),
      );
    }
    return widget.child;
  }
}
