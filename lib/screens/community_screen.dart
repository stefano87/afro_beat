import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../services/admob_service.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/info_modal.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _artistController = TextEditingController();
  final _emailController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _privacyAccepted = false;
  PlatformFile? _selectedFile;
  String? _fileError;

  static const _maxFileSize = 3 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AdMobService>().showInterstitial();
      await context.read<AnalyticsService>().logPageView('community');
    });
  }

  @override
  void dispose() {
    _artistController.dispose();
    _emailController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() {
      _fileError = null;
      if (file.size > _maxFileSize) {
        _fileError = 'File size exceeds 3MB limit';
        _selectedFile = null;
      } else {
        _selectedFile = file;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedFile == null ||
        _fileError != null ||
        !_privacyAccepted) {
      return;
    }

    final body = jsonEncode({
      'service_id': 'service_56y1eua',
      'template_id': 'template_ngd0i3o',
      'user_id': 'wGIIne2OHbReiZb6E',
      'template_params': {
        'from_name': _artistController.text,
        'song_title': _titleController.text,
        'description': _descriptionController.text,
        'reply_to': _emailController.text,
      },
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Song submitted successfully! We will review your submission.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _formKey.currentState!.reset();
        setState(() {
          _selectedFile = null;
          _privacyAccepted = false;
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error submitting song. Please try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Community',
        subtitle: 'The world is ready to hear you',
        onInfoTap: () => InfoModal.show(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              color: const Color(0xFF2D2D2D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                        ).createShader(bounds),
                        child: const Text(
                          'Submit Your Song',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Share your music with our community. If your song is selected, '
                        'it will be featured here for all users to enjoy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFD1D1D1)),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Submit your original song for review. Accepted submissions will '
                        'be showcased in our community playlist.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFD1D1D1), fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      _FormField(
                        controller: _artistController,
                        label: 'Artist Name',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      _FormField(
                        controller: _emailController,
                        label: 'Email Address',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      _FormField(
                        controller: _titleController,
                        label: 'Song Title',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      _FormField(
                        controller: _descriptionController,
                        label: 'Description',
                        maxLines: 3,
                        hint: 'Tell us about your song (genre, inspiration, etc.)',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D3D3D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Song File (Max 3MB)',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.upload_file),
                              label: Text(
                                _selectedFile?.name ?? 'Choose audio file',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_fileError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _fileError!,
                            style: const TextStyle(color: AppColors.danger),
                          ),
                        ),
                      CheckboxListTile(
                        value: _privacyAccepted,
                        onChanged: (v) =>
                            setState(() => _privacyAccepted = v ?? false),
                        title: const Text(
                          'I accept the privacy policy and grant permission to share my music',
                          style: TextStyle(fontSize: 13),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Submit Song'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D3D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
