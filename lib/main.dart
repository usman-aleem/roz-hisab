import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/main_shell.dart';
import 'screens/auth/app_lock_gate.dart';
import 'screens/auth/pin_lock_screen.dart';
import 'services/app_data.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() {
  runApp(const RozHisabApp());
}

class RozHisabApp extends StatelessWidget {
  const RozHisabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roz Hisab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AppLoader(),
    );
  }
}

/// 1. Loads persisted data (SharedPreferences).
/// 2. Checks whether App Lock (PIN) is enabled — if so, shows the
///    lock screen before anything else in the app is reachable.
class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  final _auth = AuthService();
  bool _dataReady = false;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await NotificationService.instance.init();
    await AppData.instance.init();
    final hasPin = await _auth.hasPin();
    if (mounted) {
      setState(() {
        _dataReady = true;
        _locked = hasPin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataReady) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_locked) {
      return PinLockScreen(
        onUnlocked: () => setState(() => _locked = false),
      );
    }

    // AppLockGate keeps watching in the background — if App Lock is
    // on and the app is backgrounded/resumed later, it re-locks.
    return const AppLockGate(child: MainShell());
  }
}
