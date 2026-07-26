import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Wraps a beat row with a subtle afro/neon glow when the track is playing.
class PlayingBeatCard extends StatelessWidget {
  const PlayingBeatCard({
    super.key,
    required this.isPlaying,
    required this.child,
    this.isPremium = false,
  });

  final bool isPlaying;
  final bool isPremium;
  final Widget child;

  static const _radius = 8.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        color: isPlaying
            ? const Color(0xFF1A2420)
            : AppColors.itemBg,
        gradient: isPlaying
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.accentGreen.withValues(alpha: 0.14),
                  const Color(0xF21E1E1E),
                  AppColors.accentOrange.withValues(alpha: 0.07),
                ],
              )
            : null,
        border: Border.all(
          color: isPlaying
              ? AppColors.accentGreen.withValues(alpha: 0.55)
              : isPremium
                  ? AppColors.accentOrange.withValues(alpha: 0.5)
                  : Colors.transparent,
          width: isPlaying ? 1.5 : 1,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: AppColors.accentGreen.withValues(alpha: 0.28),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppColors.accentOrange.withValues(alpha: 0.14),
                  blurRadius: 22,
                  spreadRadius: -4,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Stack(
          children: [
            if (isPlaying)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.accentGreen,
                        AppColors.accentOrange,
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(isPlaying ? 14 : 12, 12, 12, 12),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small equalizer-style bars shown next to the beat title while playing.
class PlayingBeatIndicator extends StatelessWidget {
  const PlayingBeatIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlayingBars();
  }
}

class _PlayingBars extends StatefulWidget {
  const _PlayingBars();

  @override
  State<_PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<_PlayingBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(0.35 + _controller.value * 0.65),
            const SizedBox(width: 2),
            _bar(0.85 - _controller.value * 0.45),
            const SizedBox(width: 2),
            _bar(0.5 + _controller.value * 0.5),
          ],
        );
      },
    );
  }

  Widget _bar(double heightFactor) {
    return Container(
      width: 3,
      height: 14 * heightFactor.clamp(0.25, 1.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1.5),
        gradient: const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppColors.accentGreen, AppColors.accentOrange],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withValues(alpha: 0.45),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
