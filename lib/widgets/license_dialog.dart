import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';

class LicenseDialog extends StatelessWidget {
  const LicenseDialog({super.key});

  Future<void> _accept(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.licenseAcceptedKey, 'true');
    await prefs.setString(
      'license_acceptance_date',
      DateTime.now().toIso8601String(),
    );
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: const Text('Music License Agreement'),
            automaticallyImplyLeading: false,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pixabay Music License Terms',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'By using this app, you acknowledge and agree to the following '
                    'terms regarding the music content:',
                  ),
                  const SizedBox(height: 16),
                  const Text('✓ You may:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('• Use the beats within this app for recording your voice'),
                  const Text(
                      '• Create mixed recordings combining your voice with the provided beats'),
                  const Text('• Save your personal recordings locally on your device'),
                  const SizedBox(height: 12),
                  const Text('✗ You may NOT:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('• Download, extract, or redistribute the original beat files'),
                  const Text('• Share or sell the original music tracks outside this app'),
                  const Text('• Claim ownership of the original beats'),
                  const Text(
                      '• Register mixed recordings in Content ID or rights management systems'),
                  const Text('• Use the music for commercial purposes outside of this app'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppColors.accentGreen),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Important: All music is provided under Pixabay\'s Content License. '
                            'The beats are for creative use within this app only. Your voice '
                            'recordings are yours, but the underlying music remains licensed content.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'By clicking "I Accept", you confirm that you have read, understood, '
                    'and agree to comply with these license terms.',
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _accept(context),
                child: const Text('I Accept & Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
