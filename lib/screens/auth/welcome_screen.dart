import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/app_data.dart';
import '../../services/cloud_service.dart';
import '../../widgets/cloud_dialogs.dart';
import '../../widgets/hisab_character.dart';

/// Shown ONCE on first launch: every user types THEIR OWN name, so
/// "Hey <name>" is always their name. Returning users can log in with
/// Google instead and get their data back.
class WelcomeScreen extends StatefulWidget {
  final VoidCallback onDone;
  const WelcomeScreen({super.key, required this.onDone});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _name = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    await AppData.instance.setUserName(name);
    await AppData.instance.completeOnboarding();
    widget.onDone();
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    final ok = await connectCloudUi(context);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    if (AppData.instance.userName.trim().isEmpty) {
      setState(() => _error = 'Signed in. Please enter your name.');
      return;
    }
    await AppData.instance.completeOnboarding();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      children: [
                        HisabCharacter(),
                        SizedBox(height: 6),
                        Text('Roz Hisab',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Shopping • Ledger • Bills • Daily',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12.5)),
                        SizedBox(height: 14),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Welcome 👋\nWhat should we call you?',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.3)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    onSubmitted: (_) => _start(),
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      errorText: _error,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _start,
                      child: const Text('Get started'),
                    ),
                  ),
                  if (CloudService.instance.available) ...[
                    const SizedBox(height: 18),
                    const Row(children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('or',
                            style: TextStyle(color: AppColors.textMuted)),
                      ),
                      Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _google,
                        icon: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.login_rounded, size: 18),
                        label: const Text(
                            'Sign in with Google to restore your data'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
