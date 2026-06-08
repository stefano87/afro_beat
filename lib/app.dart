import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'screens/home_shell.dart';
import 'services/admob_service.dart';
import 'theme/app_theme.dart';
import 'widgets/license_dialog.dart';

class AfroBeatTrapApp extends StatelessWidget {
  const AfroBeatTrapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _AppLoader(),
    );
  }
}

class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.statusBar,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    // 1. License agreement (always first)
    await _showLicenseIfNeeded();
    if (!mounted) return;

    // 2. AdMob UMP consent (replaces custom privacy dialog)
    final adMob = context.read<AdMobService>();
    await adMob.requestUmpConsent(context);
    if (!mounted) return;

    // 3. Initialize AdMob SDK (after consent is gathered)
    await adMob.initialize();
    await adMob.showBanner();
    await adMob.prepareInterstitial();

    // 4. Request microphone permission proactively so user is ready to record
    await _requestMicPermission();

    if (mounted) setState(() => _ready = true);
  }

  Future<void> _showLicenseIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(AppConfig.licenseAcceptedKey) == 'true') return;

    if (!mounted) return;
    while (mounted) {
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const LicenseDialog(),
      );
      if (accepted == true) break;
    }
  }

  Future<void> _requestMicPermission() async {
    if (!mounted) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentGreen),
        ),
      );
    }
    return const HomeShell();
  }
}
