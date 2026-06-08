import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/beat.dart';
import '../services/recording_session.dart';
import '../services/tab_navigation_service.dart';
import '../theme/app_theme.dart';
import 'info_modal.dart';

class RecordingPanel extends StatelessWidget {
  final Beat beat;
  final VoidCallback? onStopRecording;

  const RecordingPanel({
    super.key,
    required this.beat,
    this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordingSession>(
      builder: (context, session, _) {
        final isRecording = session.isAnyBeatRecording;
        final canClose = !isRecording &&
            !session.isPreparing &&
            !session.isStopping &&
            session.recordedDuration.isNotEmpty;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A1A), Color(0xFF111111)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 24,
                offset: Offset(0, -8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recording Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isRecording) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const _PulsingDot(),
                                  const SizedBox(width: 8),
                                  Text(
                                    'REC ${session.formatTime(session.recordingTime)}  ·  '
                                    '${session.formatTime(session.remainingTime)} left',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: session.recordingTime /
                                RecordingSession.maxRecordingTime,
                            backgroundColor: Colors.white24,
                            color: AppColors.danger,
                            minHeight: 4,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (canClose) ...[
                    const SizedBox(width: 8),
                    _CloseButton(onPressed: session.closeSelectedBeat),
                  ],
                ],
              ),
              if (isRecording && onStopRecording != null) ...[
                const SizedBox(height: 16),
                _ActionButton(
                  label: 'STOP RECORDING',
                  icon: Icons.stop_circle_outlined,
                  color: AppColors.danger,
                  onTap: onStopRecording!,
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.music_note_outlined,
                        color: AppColors.accentGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        beat.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (session.recordedDuration.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.blue),
                      const SizedBox(width: 12),
                      Text(
                        session.recordedDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (session.isStopping)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentGreen,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Finalizing recording...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              if (session.recordingFailed && !session.isStopping)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Recording too short. Hold record longer and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              if (session.hasRecording &&
                  !session.isStopping &&
                  session.isRecordingDownloaded) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Saved on your phone',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _RecordingNameField(
                  key: ValueKey(session.savedRecordingId),
                  initialName: session.recordingTitle.isNotEmpty
                      ? session.recordingTitle
                      : beat.name,
                  onSave: (name) => session.renameSavedRecording(name),
                ),
              ],
              if (session.hasRecording &&
                  !session.isStopping &&
                  !session.isRecordingDownloaded)
                _ActionButton(
                  label: 'SAVE RECORDING',
                  icon: Icons.save_outlined,
                  color: AppColors.success,
                  onTap: () async {
                    try {
                      await session.saveRecording();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recording saved'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not save recording'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    }
                  },
                ),
              if (session.hasRecording &&
                  !session.isStopping &&
                  session.isRecordingDownloaded)
                _ActionButton(
                  label: 'VIEW IN RECORDINGS',
                  icon: Icons.library_music,
                  color: AppColors.success,
                  onTap: () =>
                      context.read<TabNavigationService>().openRecordings(),
                ),
              if (session.hasRecording &&
                  !session.isStopping &&
                  !session.playRecordedAudio)
                _ActionButton(
                  label: 'PLAY RECORDING',
                  icon: Icons.play_arrow_outlined,
                  color: AppColors.purple,
                  onTap: () async {
                    final ok = await session.playRecording();
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not play recording — file may be empty',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              if (session.hasRecording && session.playRecordedAudio)
                _ActionButton(
                  label: 'STOP PLAYBACK',
                  icon: Icons.stop_outlined,
                  color: AppColors.danger,
                  onTap: () async {
                    await session.stopPlayRecording();
                    if (context.mounted) {
                      await RatingPopup.showIfNeeded(context);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CloseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFF4D4D).withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.close,
            color: Color(0xFFFF4D4D),
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
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
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_controller),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _RecordingNameField extends StatefulWidget {
  final String initialName;
  final Future<bool> Function(String name) onSave;

  const _RecordingNameField({
    super.key,
    required this.initialName,
    required this.onSave,
  });

  @override
  State<_RecordingNameField> createState() => _RecordingNameFieldState();
}

class _RecordingNameFieldState extends State<_RecordingNameField> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void didUpdateWidget(_RecordingNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialName != widget.initialName &&
        _controller.text == oldWidget.initialName) {
      _controller.text = widget.initialName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    final ok = await widget.onSave(name);
    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording name saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Name your recording',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            maxLength: 48,
            decoration: InputDecoration(
              hintText: 'e.g. My freestyle #1',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              counterStyle: const TextStyle(color: Colors.white38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 4),
          _ActionButton(
            label: _saving ? 'SAVING...' : 'SAVE NAME',
            icon: Icons.drive_file_rename_outline,
            color: AppColors.accentGreen,
            onTap: _saving ? () {} : _save,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
