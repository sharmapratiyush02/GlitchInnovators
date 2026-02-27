import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/biometric_service.dart';
import '../theme/sahara_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final initials = _initials(profile?.userName ?? 'S');

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Profile Card ─────────────────────────────────────────────
          _ProfileCard(
            initials: initials,
            userName: profile?.userName ?? 'You',
            lovedOneName: profile?.lovedOneName,
            relationship: profile?.relationship,
          ),
          const SizedBox(height: 24),

          // ── Appearance ───────────────────────────────────────────────
          _SectionLabel(label: 'APPEARANCE'),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            label: 'Dark Mode',
            trailing: Switch(
              value: state.isDarkMode,
              onChanged: (_) => state.toggleDarkMode(),
              activeColor: SaharaTheme.ember,
            ),
          ),
          _SettingsTile(
            icon: Icons.language,
            label: 'Language',
            subtitle: state.language.name,
            badge: state.language.flag,
            onTap: () => _showLanguagePicker(context, state),
          ),
          const SizedBox(height: 16),

          // ── Security ─────────────────────────────────────────────────
          _SectionLabel(label: 'SECURITY'),
          _BiometricTile(state: state),
          const SizedBox(height: 16),

          // ── Notifications ─────────────────────────────────────────────
          _SectionLabel(label: 'NOTIFICATIONS'),
          _SettingsTile(
            icon: Icons.wb_sunny_outlined,
            label: 'Morning Check-in',
            subtitle: 'Daily mood reminder at 8 AM',
            trailing: Switch(
              value: state.morningCheckIn,
              onChanged: (_) => state.toggleMorningCheckIn(),
              activeColor: SaharaTheme.ember,
            ),
          ),
          _SettingsTile(
            icon: Icons.auto_awesome_outlined,
            label: 'Memory of the Day',
            subtitle: 'A warm memory each morning',
            trailing: Switch(
              value: state.memoryOfDay,
              onChanged: (_) => state.toggleMemoryOfDay(),
              activeColor: SaharaTheme.ember,
            ),
          ),
          _SettingsTile(
            icon: Icons.bar_chart_outlined,
            label: 'Weekly Summary',
            subtitle: 'Your emotional weather report',
            trailing: Switch(
              value: state.weeklySummary,
              onChanged: (_) => state.toggleWeeklySummary(),
              activeColor: SaharaTheme.ember,
            ),
          ),
          const SizedBox(height: 16),

          // ── Privacy ───────────────────────────────────────────────────
          _SectionLabel(label: 'PRIVACY'),
          _PrivacyBadge(),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.upload_file_outlined,
            label: 'Re-import WhatsApp Chat',
            subtitle: profile?.memoriesImported == true
                ? '${profile!.memoriesCount} memories indexed'
                : 'No chats imported yet',
            onTap: () => _confirmReimport(context),
          ),
          const SizedBox(height: 16),

          // ── Crisis Resources ──────────────────────────────────────────
          _SectionLabel(label: 'CRISIS RESOURCES'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SaharaTheme.crisisRed.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: SaharaTheme.crisisRed.withOpacity(0.25)),
            ),
            child: Column(
              children: [
                _CrisisResourceRow(
                    name: 'iCall', number: '9152987821'),
                const Divider(height: 20),
                _CrisisResourceRow(
                    name: 'Vandrevala Foundation',
                    number: '1860-2662-345'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── About ─────────────────────────────────────────────────────
          _SectionLabel(label: 'ABOUT'),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'Sahara v1.0.0',
            subtitle: 'Built with ❤️ at 24hr Hackathon',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  void _showLanguagePicker(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanguageSheet(
        selected: state.language,
        onChanged: (l) {
          state.setLanguage(l);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _confirmReimport(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Re-import Chat',
            style: Theme.of(context).textTheme.titleLarge),
        content: const Text(
            'This will replace your existing memories. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue',
                style: TextStyle(color: SaharaTheme.ember)),
          ),
        ],
      ),
    );
  }
}

// ── Profile Card ───────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final String initials;
  final String userName;
  final String? lovedOneName;
  final dynamic relationship;

  const _ProfileCard({
    required this.initials,
    required this.userName,
    this.lovedOneName,
    this.relationship,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? SaharaTheme.darkCard : SaharaTheme.sandDeep,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SaharaTheme.ember,
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName,
                    style: Theme.of(context).textTheme.titleLarge),
                if (lovedOneName != null)
                  Text(
                    'Remembering ${lovedOneName!}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SaharaTheme.mutedBrown),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: SaharaTheme.mutedBrown,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Settings Tile ──────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? badge;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.badge,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? SaharaTheme.darkCard : SaharaTheme.sandDeep,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: SaharaTheme.ember, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (badge != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(badge!,
                    style: const TextStyle(fontSize: 18)),
              ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              const Icon(Icons.chevron_right,
                  color: SaharaTheme.mutedBrown),
          ],
        ),
      ),
    );
  }
}

// ── Biometric Tile ─────────────────────────────────────────────────────
class _BiometricTile extends StatefulWidget {
  final AppState state;
  const _BiometricTile({required this.state});

  @override
  State<_BiometricTile> createState() => _BiometricTileState();
}

class _BiometricTileState extends State<_BiometricTile> {
  bool _loading = false;

  Future<void> _toggle() async {
    if (_loading) return;
    setState(() => _loading = true);

    final svc = BiometricService.instance;
    if (widget.state.biometricEnabled) {
      // Confirm before disabling
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Disable Face Lock?'),
          content: const Text(
              'Anyone with access to your device will be able to open Sahara.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Disable',
                  style: TextStyle(color: SaharaTheme.crisisRed)),
            ),
          ],
        ),
      );
      if (ok == true) {
        await svc.setEnabled(false);
        widget.state.setBiometricEnabled(false);
      }
    } else {
      // Require auth before enabling
      final enrolled = await svc.isEnrolled();
      if (!enrolled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No biometrics enrolled. Please set up in device Settings.'),
          ),
        );
        setState(() => _loading = false);
        return;
      }

      final result = await svc.authenticate(
          reason: 'Verify your identity to enable Face Lock');
      if (result == AuthResult.success) {
        await svc.setEnabled(true);
        widget.state.setBiometricEnabled(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Face Lock enabled ✓')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(svc.describeResult(result))),
        );
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? SaharaTheme.darkCard : SaharaTheme.sandDeep,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.face_retouching_natural,
              color: SaharaTheme.ember, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Face Lock',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 15)),
                Text('Require Face ID to open Sahara',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: SaharaTheme.ember),
                )
              : Switch(
                  value: widget.state.biometricEnabled,
                  onChanged: (_) => _toggle(),
                  activeColor: SaharaTheme.ember,
                ),
        ],
      ),
    );
  }
}

// ── Privacy Badge ──────────────────────────────────────────────────────
class _PrivacyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SaharaTheme.sage.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: SaharaTheme.sage.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: SaharaTheme.sage, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '🔒 On-Device Processing — your memories never leave your phone.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SaharaTheme.sage,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Crisis Resource Row ────────────────────────────────────────────────
class _CrisisResourceRow extends StatelessWidget {
  final String name;
  final String number;
  const _CrisisResourceRow(
      {required this.name, required this.number});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.phone, color: SaharaTheme.crisisRed, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14, color: SaharaTheme.crisisRed)),
              Text(number,
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: SaharaTheme.crisisRed)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Language Sheet ─────────────────────────────────────────────────────
class _LanguageSheet extends StatelessWidget {
  final dynamic selected;
  final ValueChanged<dynamic> onChanged;

  const _LanguageSheet({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Import AppLanguage properly
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Language', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Language selection available from home screen.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
