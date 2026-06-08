import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CountdownOverlay extends StatelessWidget {
  final int countdownNumber;
  final bool isPreparing;

  const CountdownOverlay({
    super.key,
    required this.countdownNumber,
    this.isPreparing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPreparing) ...[
              const SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  color: AppColors.accentGreen,
                  strokeWidth: 5,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Loading beat…',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Recording will start automatically',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ] else ...[
              Text(
                '$countdownNumber',
                style: const TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Crush it, brother! 🚀',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
