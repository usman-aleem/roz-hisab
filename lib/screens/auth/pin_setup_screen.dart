import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import 'pin_keypad.dart';

/// A handful of easy-to-remember prompts — picked from a dropdown so
/// people aren't stuck staring at a blank "type your own question"
/// field, which most people abandon or fill with something they
/// forget by next week.
const List<String> kSecurityQuestions = [
  "What's your favorite personality?",
  "What was your childhood nickname?",
  "What's your favorite food?",
  "What was the name of your first pet?",
  "What's your favorite color?",
];

/// PIN creation flow: enter 4 digits, confirm them, then (for a
/// first-time setup) pick a security question + answer used later to
/// recover access if the PIN itself is forgotten.
///
/// When [isReset] is true, this is being used to set a NEW PIN after
/// a "Forgot PIN" security-question verification already succeeded —
/// so the question/answer step is skipped (the existing one still
/// works for future resets).
class PinSetupScreen extends StatefulWidget {
  final bool isReset;

  const PinSetupScreen({super.key, this.isReset = false});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

enum _Step { enter, confirm, securityQuestion }

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _auth = AuthService();
  String _first = '';
  String _current = '';
  _Step _step = _Step.enter;
  String? _error;
  int _shakeTrigger = 0;

  String _selectedQuestion = kSecurityQuestions.first;
  final _answerCtrl = TextEditingController();

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

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
    if (_step == _Step.enter) {
      setState(() {
        _first = _current;
        _current = '';
        _step = _Step.confirm;
      });
      return;
    }

    // _step == _Step.confirm
    if (_current != _first) {
      setState(() {
        _error = "PINs didn't match — try again";
        _current = '';
        _step = _Step.enter;
        _first = '';
        _shakeTrigger++;
      });
      return;
    }

    await _auth.setPin(_first);

    if (widget.isReset) {
      // Existing security question stays valid for next time —
      // nothing more to collect.
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() => _step = _Step.securityQuestion);
    }
  }

  Future<void> _finishWithSecurityQuestion() async {
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty) {
      setState(() => _error = 'Please enter an answer you\'ll remember');
      return;
    }
    await _auth.setSecurityQuestion(_selectedQuestion, answer);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _Step.securityQuestion) {
      return Scaffold(
        appBar: AppBar(title: const Text('Security Question')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline_rounded,
                    color: AppColors.accent, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'One last step — in case you forget your PIN',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pick a question and answer only you would know. If you '
                'ever forget your PIN, answering this correctly lets you '
                'set a new one — without it, App Lock can only be turned '
                'off completely (and your PIN reset that way).',
                style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4),
              ),
              const SizedBox(height: 20),
              const Text('Question',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedQuestion,
                    isExpanded: true,
                    items: kSecurityQuestions
                        .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedQuestion = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Your Answer',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _answerCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type your answer',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finishWithSecurityQuestion,
                  child: const Text('Finish Setup'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.isReset ? 'Set a New PIN' : 'Set Up App Lock')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ShakeWidget(
          trigger: _shakeTrigger,
          child: PinKeypad(
            title: _step == _Step.confirm ? 'Confirm PIN' : 'Create New PIN',
            subtitle: _error ??
                (_step == _Step.confirm
                    ? 'Enter the same 4-digit PIN again'
                    : 'Set a 4-digit PIN to open the app'),
            enteredLength: _current.length,
            hasError: _error != null,
            onDigit: _onDigit,
            onBackspace: _onBackspace,
          ),
        ),
      ),
    );
  }
}
