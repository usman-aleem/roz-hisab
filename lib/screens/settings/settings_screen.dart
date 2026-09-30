import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/app_data.dart';
import '../../services/backup_service.dart';
import '../../services/auth_service.dart';
import '../auth/pin_setup_screen.dart';
import '../auth/pin_keypad.dart';
import '../../widgets/hover_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService();
  bool _working = false;
  bool _lockEnabled = false;
  bool _checkingLock = true;

  @override
  void initState() {
    super.initState();
    _refreshLockStatus();
  }

  void _editBudget() {
    final ctrl = TextEditingController(
      text: AppData.instance.monthlyBudget > 0
          ? AppData.instance.monthlyBudget.toStringAsFixed(0)
          : '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
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
              const Text('Monthly Budget',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                'A progress bar shows on Home once this is set',
                style:
                    TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Amount (Rs.)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(ctrl.text.trim()) ?? 0;
                    await AppData.instance.setMonthlyBudget(amount);
                    if (mounted) {
                      setState(() {});
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Your Details" — a small local profile (name, phone, email) the
  /// user fills in once. This never leaves the device or gets sent
  /// anywhere; it's simply saved so it's there next time the app is
  /// opened (used on printed receipts, and for the person's own
  /// reference), the same way any app remembers your saved settings.
  void _editProfile() {
    final nameCtrl = TextEditingController(text: AppData.instance.userName);
    final phoneCtrl = TextEditingController(text: AppData.instance.userPhone);
    final emailCtrl = TextEditingController(text: AppData.instance.userEmail);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
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
              const Text('Your Details',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                'Saved only on this device — prints on receipts and is '
                'just for your own reference.',
                style:
                    TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Full Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: 'Phone (optional)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email (optional)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await AppData.instance.setUserName(nameCtrl.text);
                    await AppData.instance.setUserPhone(phoneCtrl.text);
                    await AppData.instance.setUserEmail(emailCtrl.text);
                    if (mounted) {
                      setState(() {});
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshLockStatus() async {
    final has = await _auth.hasPin();
    if (mounted) {
      setState(() {
        _lockEnabled = has;
        _checkingLock = false;
      });
    }
  }

  Future<void> _export() async {
    setState(() => _working = true);
    try {
      await BackupService.exportBackup();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _import() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
          'This will replace all current data (shopping, udhar, bills) '
          'with the backup file\'s data. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _working = true);
    try {
      final ok = await BackupService.importBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(ok ? 'Backup restored ✅' : 'No file selected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// Explains, in plain language, exactly what "Create Backup" is
  /// about to do — shown once before the share sheet opens, since a
  /// bare "Create Backup" tile with no context was confusing people
  /// about what file they'd get or where it goes.
  void _explainBackup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How Backup Works',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            _explainStep(
              Icons.description_outlined,
              'A single file is created',
              'Everything — shopping lists, Udhar Khata, bills — is '
                  'packed into one .json file, named with today\'s date.',
            ),
            const SizedBox(height: 12),
            _explainStep(
              Icons.ios_share_rounded,
              'You choose where it goes',
              'Your phone\'s normal share screen opens. Send it to '
                  'yourself on WhatsApp, save it to Google Drive, or '
                  'email it — wherever you\'ll be able to find it again.',
            ),
            const SizedBox(height: 12),
            _explainStep(
              Icons.restore_rounded,
              'Bring it back anytime with "Restore Backup"',
              'On a new phone, or after reinstalling the app, use '
                  '"Restore Backup" and pick that same file to get '
                  'everything back exactly as it was.',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _export();
                },
                child: const Text('Got it — Create Backup Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _explainStep(IconData icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.accentDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5)),
              const SizedBox(height: 2),
              Text(body,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _toggleLock() async {
    if (_lockEnabled) {
      // Must verify current PIN before disabling.
      final verified = await _promptVerifyToDisable();
      if (verified) {
        await _auth.disableLock();
        await _refreshLockStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('App Lock turned off')),
          );
        }
      }
    } else {
      final created = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );
      if (created == true) {
        await _refreshLockStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('App Lock enabled ✅')),
          );
        }
      }
    }
  }

  Future<bool> _promptVerifyToDisable() async {
    String entered = '';
    String? error;
    int shakeTrigger = 0;

    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => StatefulBuilder(
            builder: (context, setModalState) => Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: ShakeWidget(
                trigger: shakeTrigger,
                child: PinKeypad(
                  title: 'To Turn Off App Lock',
                  subtitle: error ?? 'Enter your current PIN',
                  enteredLength: entered.length,
                  accentColor: AppColors.danger,
                  hasError: error != null,
                  onDigit: (d) async {
                    if (entered.length >= 4) return;
                    entered += d;
                    setModalState(() {});
                    if (entered.length == 4) {
                      final ok = await _auth.verifyPin(entered);
                      if (ok) {
                        if (context.mounted) Navigator.pop(context, true);
                      } else {
                        entered = '';
                        error = 'Wrong PIN — try again';
                        shakeTrigger++;
                        setModalState(() {});
                      }
                    }
                  },
                  onBackspace: () {
                    if (entered.isEmpty) return;
                    entered = entered.substring(0, entered.length - 1);
                    setModalState(() {});
                  },
                ),
              ),
            ),
          ),
        ) ??
        false;
  }

  Future<void> _resetApp() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset App?'),
        content: const Text(
          'This permanently deletes EVERYTHING on this device — every '
          'shopping list, every Udhar Khata contact and balance, every '
          'bill. There is no undo. If you have a backup file, you can '
          'restore from it afterward — otherwise this data is gone for '
          'good.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Everything',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _working = true);
    await AppData.instance.resetAll();
    if (mounted) {
      setState(() => _working = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Everything has been deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = AppData.instance.userName;
    final phone = AppData.instance.userPhone;
    final profileSubtitle =
        phone.isNotEmpty ? phone : 'Tap to add your name, phone, and email';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.amberLight,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.amber, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Your data is saved only on this phone. Regular '
                    'backups are important — otherwise everything is '
                    'lost if the phone is lost or reset.',
                    style: TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Your Details'),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.badge_outlined,
            title: name.isEmpty ? 'Add Your Details' : name,
            subtitle: profileSubtitle,
            color: AppColors.primary,
            onTap: _editProfile,
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.savings_outlined,
            title: AppData.instance.monthlyBudget > 0
                ? 'Rs. ${AppData.instance.monthlyBudget.toStringAsFixed(0)} / month'
                : 'Set Monthly Budget',
            subtitle: 'Get a progress bar on Home',
            color: AppColors.accent,
            onTap: _editBudget,
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Backup & Restore'),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.upload_outlined,
            title: 'Create Backup',
            subtitle: 'Save a copy of everything — tap to see how',
            color: AppColors.primary,
            onTap: _working ? null : _explainBackup,
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.download_outlined,
            title: 'Restore Backup',
            subtitle: 'Bring back data from a backup file you saved before',
            color: AppColors.accent,
            onTap: _working ? null : _import,
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Security'),
          const SizedBox(height: 10),
          _checkingLock
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                )
              : _SettingsTile(
                  icon: _lockEnabled
                      ? Icons.lock_rounded
                      : Icons.lock_outline_rounded,
                  title: _lockEnabled
                      ? 'App Lock is On'
                      : 'App Lock (PIN/Fingerprint)',
                  subtitle: _lockEnabled
                      ? 'Tap to turn off'
                      : 'Ask for PIN every time you open the app',
                  color: _lockEnabled ? AppColors.success : AppColors.textMuted,
                  onTap: _toggleLock,
                ),
          const SizedBox(height: 24),
          const _SectionLabel('Danger Zone'),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            title: 'Reset App',
            subtitle: 'Permanently erase all data on this device',
            color: AppColors.danger,
            onTap: _working ? null : _resetApp,
          ),
          if (_working) ...[
            const SizedBox(height: 20),
            const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
