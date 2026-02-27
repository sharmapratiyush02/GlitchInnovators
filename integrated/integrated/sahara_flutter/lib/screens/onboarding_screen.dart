import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../theme/sahara_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // Form state
  final _nameCtrl      = TextEditingController();
  final _lovedOneCtrl  = TextEditingController();
  Relationship  _relationship = Relationship.mother;
  AppLanguage   _language     = AppLanguage.english;

  // Import state
  bool   _importing      = false;
  bool   _imported       = false;
  int    _memoriesCount  = 0;
  String _importError    = '';

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _lovedOneCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 3) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish() {
    final profile = UserProfile(
      userName: _nameCtrl.text.trim(),
      lovedOneName: _lovedOneCtrl.text.trim(),
      relationship: _relationship,
      language: _language,
      memoriesImported: _imported,
      memoriesCount: _memoriesCount,
    );
    context.read<AppState>().completeOnboarding(profile);
  }

  // ── Real WhatsApp import via file picker + API ──────────────────────
  Future<void> _pickAndImport() async {
    setState(() {
      _importing    = true;
      _importError  = '';
    });

    try {
      // 1. Let user pick _chat.txt
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        dialogTitle: 'Select your WhatsApp _chat.txt',
      );

      if (result == null || result.files.single.path == null) {
        // User cancelled
        setState(() => _importing = false);
        return;
      }

      final file = File(result.files.single.path!);

      // 2. Upload to backend
      final count = await ApiService.importChat(file);

      setState(() {
        _importing     = false;
        _imported      = true;
        _memoriesCount = count;
      });
    } catch (e) {
      setState(() {
        _importing   = false;
        _importError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [SaharaTheme.sand, Color(0xFFEDD9A3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: List.generate(
                      4,
                      (i) => _ProgressDot(active: i <= _page, current: i == _page),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _WelcomePage(onNext: _next),
                      _ProfilePage(
                        nameCtrl: _nameCtrl,
                        lovedOneCtrl: _lovedOneCtrl,
                        relationship: _relationship,
                        onRelationshipChanged: (r) => setState(() => _relationship = r),
                        onNext: _next,
                      ),
                      _LanguagePage(
                        selected: _language,
                        onChanged: (l) => setState(() => _language = l),
                        onNext: _next,
                      ),
                      _ImportPage(
                        importing: _importing,
                        imported: _imported,
                        memoriesCount: _memoriesCount,
                        importError: _importError,
                        onImport: _pickAndImport,
                        onFinish: _finish,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  final bool active;
  final bool current;
  const _ProgressDot({required this.active, required this.current});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      width: current ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? SaharaTheme.ember : SaharaTheme.mutedBrown.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ── Welcome Page ───────────────────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final features = [
      ('🌿', 'On-Device Privacy',  'Your memories never leave your phone'),
      ('💬', 'WhatsApp Memories',  'Relive warm conversations together'),
      ('🔒', 'Secure & Safe',      'Biometric lock keeps your heart safe'),
      ('🌙', 'Always Here',        'Available in English, Hindi & Marathi'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('Welcome to\nSahara',
              style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 10),
          Text(
            'A gentle companion for your grief journey.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: SaharaTheme.mutedBrown),
          ),
          const SizedBox(height: 36),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: SaharaTheme.ember.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                          child: Text(f.$1, style: const TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.$2,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontSize: 15)),
                          Text(f.$3, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onNext, child: const Text('Begin')),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Profile Page ───────────────────────────────────────────────────────
class _ProfilePage extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController lovedOneCtrl;
  final Relationship relationship;
  final ValueChanged<Relationship> onRelationshipChanged;
  final VoidCallback onNext;

  const _ProfilePage({
    required this.nameCtrl,
    required this.lovedOneCtrl,
    required this.relationship,
    required this.onRelationshipChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final relLabels = {
      Relationship.mother:  '👩 Mother',
      Relationship.father:  '👨 Father',
      Relationship.partner: '💑 Partner',
      Relationship.sibling: '👫 Sibling',
      Relationship.friend:  '🤝 Friend',
      Relationship.child:   '👶 Child',
      Relationship.other:   '💛 Other',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Tell us about\nyourself',
              style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 28),
          Text('Your name', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'e.g. Priya')),
          const SizedBox(height: 20),
          Text("Your loved one's name", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(controller: lovedOneCtrl, decoration: const InputDecoration(hintText: 'e.g. Aai')),
          const SizedBox(height: 20),
          Text('They were your...', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Relationship.values.map((r) {
              final selected = r == relationship;
              return GestureDetector(
                onTap: () => onRelationshipChanged(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? SaharaTheme.ember.withOpacity(0.15)
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? SaharaTheme.ember : Colors.grey.withOpacity(0.3),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(relLabels[r]!,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? SaharaTheme.ember : SaharaTheme.inkBrown,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onNext, child: const Text('Continue')),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Language Page ──────────────────────────────────────────────────────
class _LanguagePage extends StatelessWidget {
  final AppLanguage selected;
  final ValueChanged<AppLanguage> onChanged;
  final VoidCallback onNext;

  const _LanguagePage({
    required this.selected,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Choose your\nlanguage', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text('Sahara will respond in your preferred language.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: SaharaTheme.mutedBrown)),
          const SizedBox(height: 28),
          ...AppLanguage.values.map((lang) {
            final isSelected = lang == selected;
            return GestureDetector(
              onTap: () => onChanged(lang),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? SaharaTheme.ember.withOpacity(0.12)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? SaharaTheme.ember : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Text(lang.flag, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lang.name, style: Theme.of(context).textTheme.titleMedium),
                        Text(lang.subtitle, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const Spacer(),
                    if (isSelected) const Icon(Icons.check_circle, color: SaharaTheme.ember),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onNext, child: const Text('Continue')),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Import Page ────────────────────────────────────────────────────────
class _ImportPage extends StatelessWidget {
  final bool importing;
  final bool imported;
  final int memoriesCount;
  final String importError;
  final VoidCallback onImport;
  final VoidCallback onFinish;

  const _ImportPage({
    required this.importing,
    required this.imported,
    required this.memoriesCount,
    required this.importError,
    required this.onImport,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Import\nMemories', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text(
            'Export your WhatsApp chat with your loved one and import it here.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: SaharaTheme.mutedBrown),
          ),
          const SizedBox(height: 20),

          // Privacy notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SaharaTheme.sage.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SaharaTheme.sage.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock, color: SaharaTheme.sage, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '100% on-device processing. Your conversations are processed locally and never uploaded to any cloud server.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // How to export instructions
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SaharaTheme.ember.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How to export from WhatsApp:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13)),
                const SizedBox(height: 6),
                Text('Open chat → ⋮ Menu → More → Export Chat → Without Media',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Import zone
          GestureDetector(
            onTap: (importing || imported) ? null : onImport,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: imported
                    ? SaharaTheme.sage.withOpacity(0.1)
                    : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: imported ? SaharaTheme.sage : SaharaTheme.ember.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  if (importing)
                    const CircularProgressIndicator(color: SaharaTheme.ember)
                  else if (imported)
                    const Icon(Icons.check_circle, color: SaharaTheme.sage, size: 48)
                  else
                    const Icon(Icons.upload_file, color: SaharaTheme.ember, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    importing
                        ? 'Indexing memories...'
                        : imported
                            ? '$memoriesCount memories indexed ✨'
                            : 'Tap to select _chat.txt',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Error message
          if (importError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SaharaTheme.crisisRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: SaharaTheme.crisisRed, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        importError,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: SaharaTheme.crisisRed),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onFinish,
              child: const Text("I'm ready"),
            ),
          ),
          if (!imported)
            Center(
              child: TextButton(
                onPressed: onFinish,
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.nunito(color: SaharaTheme.mutedBrown, fontSize: 14),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
