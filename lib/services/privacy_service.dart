import 'dart:convert';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/license_dialog.dart';

class PrivacyService {
  Future<bool> hasAcceptedLicense() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.licenseAcceptedKey) == 'true';
  }

  Future<bool> hasAcceptedPrivacyPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('privacy_policy_accepted') == 'true';
  }

  Future<void> initializePrivacyChecks(BuildContext context) async {
    if (!await hasAcceptedLicense()) {
      while (context.mounted) {
        final accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const LicenseDialog(),
        );
        if (accepted == true) break;
      }
    }

    if (!context.mounted) return;

    if (!await hasAcceptedPrivacyPolicy()) {
      while (context.mounted) {
        final accepted = await _showPrivacyBanner(context);
        if (accepted) break;
      }
    }
  }

  Future<bool> _showPrivacyBanner(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy & Cookie Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'We care about your privacy. This app uses AdMob for advertisements '
            'and Firebase Analytics for app improvement. We collect anonymous usage '
            'data and device information for ads, but we do NOT collect personal '
            'information or voice recordings (stored locally only). By continuing, '
            'you consent to our privacy practices and the use of cookies for '
            'advertising purposes.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _showDetailedPrivacyOptions(ctx);
            },
            child: const Text('Manage Preferences'),
          ),
          FilledButton(
            onPressed: () async {
              await _savePrivacyConsent(analytics: true, advertising: true);
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            },
            child: const Text('Accept All'),
          ),
        ],
      ),
    );

    return result == true || await hasAcceptedPrivacyPolicy();
  }

  Future<void> _showDetailedPrivacyOptions(BuildContext context) async {
    var analytics = true;
    var advertising = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Privacy Preferences'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text(
                    'Necessary cookies (Required for app functionality)',
                  ),
                  value: true,
                  onChanged: null,
                ),
                CheckboxListTile(
                  title: const Text(
                    'Analytics - Firebase Analytics (Help us improve the app)',
                  ),
                  value: analytics,
                  onChanged: (v) => setState(() => analytics = v ?? true),
                ),
                CheckboxListTile(
                  title: const Text(
                    'Advertising - AdMob (Show personalized ads)',
                  ),
                  value: advertising,
                  onChanged: (v) => setState(() => advertising = v ?? true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await _savePrivacyConsent(
                  analytics: analytics,
                  advertising: advertising,
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  await _showConsentConfirmation(
                    context,
                    analytics,
                    advertising,
                  );
                  if (context.mounted) Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save Preferences'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePrivacyConsent({
    required bool analytics,
    required bool advertising,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final consentData = {
      'analytics': analytics,
      'advertising': advertising,
      'necessary': true,
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
    };

    await prefs.setString('privacy_policy_accepted', 'true');
    await prefs.setString('privacy_consent_details', jsonEncode(consentData));
    await prefs.setString(
      'privacy_acceptance_date',
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> _showConsentConfirmation(
    BuildContext context,
    bool analytics,
    bool advertising,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Preferences Saved'),
        content: Text(
          'Your privacy preferences have been saved successfully.\n\n'
          '• Analytics: ${analytics ? 'Enabled' : 'Disabled'}\n'
          '• Advertising: ${advertising ? 'Enabled' : 'Disabled'}\n'
          '• Necessary: Enabled (Required)\n\n'
          'You can change these preferences at any time in the app settings.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
