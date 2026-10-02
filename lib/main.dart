import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/main_shell.dart';
import 'screens/auth/app_lock_gate.dart';
import 'screens/auth/pin_lock_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'services/app_data.dart';
import 'services/auth_service.dart';
import 'services/cloud_service.dart';
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

/// 1. Starts Firebase (optional - app still works if it isn't set up).
/// 2. Loads local data, then (if logged in) syncs from the cloud.
/// 3. First launch -> Welcome screen asks THIS user's name.
/// 4. App Lock (PIN) check.
class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  final _auth = AuthService();
  bool _dataReady = false;
  bool _locked = false;
  bool _needsWelcome = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await NotificationService.instance.init();
    await CloudService.instance.init();
    await AppData.instance.init();
    await CloudService.instance
        .startupSync(AppData.instance)
        .timeout(const Duration(seconds: 12), onTimeout: () {});

    final data = AppData.instance;
    // Existing users (already have a name) skip the welcome screen.
    if (!data.onboarded && data.userName.trim().isNotEmpty) {
      await data.completeOnboarding();
    }
    final hasPin = await _auth.hasPin();
    if (mounted) {
      setState(() {
        _dataReady = true;
        _needsWelcome = !data.onboarded;
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

    if (_needsWelcome) {
      return WelcomeScreen(
        onDone: () => setState(() => _needsWelcome = false),
      );
    }

    if (_locked) {
      return PinLockScreen(
        onUnlocked: () => setState(() => _locked = false),
      );
    }

    return const AppLockGate(child: MainShell());
  }
}
