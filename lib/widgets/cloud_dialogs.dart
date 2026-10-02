import 'package:flutter/material.dart';
import '../services/app_data.dart';
import '../services/cloud_service.dart';

Future<int?> askCloudChoice(BuildContext context) => showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Existing data found'),
        content: const Text(
          'There is data in the cloud and on this device. What would you like to do?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, 0),
              child: const Text('Use cloud data')),
          TextButton(
              onPressed: () => Navigator.pop(context, 1),
              child: const Text('Use this device\'s data')),
          TextButton(
              onPressed: () => Navigator.pop(context, 2),
              child: const Text('Merge both')),
          TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel')),
        ],
      ),
    );

/// Google login + link. Returns true if logged in & synced.
Future<bool> connectCloudUi(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final err = await CloudService.instance.connect(AppData.instance, () async {
    if (!context.mounted) return null;
    return askCloudChoice(context);
  });
  if (err != null) {
    messenger.showSnackBar(SnackBar(content: Text(err)));
    return false;
  }
  if (!CloudService.instance.signedIn) return false;
  messenger.showSnackBar(
      const SnackBar(content: Text('Signed in. Cloud backup is on.')));
  return true;
}
