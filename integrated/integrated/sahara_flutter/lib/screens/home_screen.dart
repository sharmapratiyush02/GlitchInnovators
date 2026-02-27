import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/sahara_theme.dart';
import '../widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final isDark = state.isDarkMode;
    final greeting = _greeting(profile?.userName ?? '');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 90,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? SaharaTheme.warmWhite
                          : SaharaTheme.inkBrown,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.language),
                onPressed: () => _showLanguagePicker(context, state),
              ),
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: state.toggleDarkMode,
              ),
            ],
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),

              // ── Today's date ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  DateFormat('EEEE, d MMMM').format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SaharaTheme.mutedBrown),
                ),
              ),
              const SizedBox(height: 20),

              // ── Mood Check-in ────────────────────────────────────────
              SectionHeader(
                title: state.todayMood != null
                    ? "Today you're feeling ${state.todayMood!.emoji}"
                    : 'How are you feeling?',
                trailing: state.todayMood != null
                    ? TextButton(
                        onPressed: () =>
                            _showMoodSheet(context, state),
                        child: Text('Change',
                            style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: SaharaTheme.ember,
                                fontWeight: FontWeight.w700)),
                      )
                    : null,
              ),
              if (state.todayMood == null)
                SizedBox(
                  height: 80,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    children: Mood.values
                        .map((m) => Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: MoodChip(
                                mood: m,
                                selected: false,
                                onTap: () {
                                  _showMoodSheet(context, state,
                                      preselected: m);
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),

              const SizedBox(height: 20),

              // ── Breathing Card ───────────────────────────────────────
              const BreathingCard(),
              const SizedBox(height: 20),

              // ── Memory of the Day ────────────────────────────────────
              if (profile?.memoriesImported == true) ...[
                SectionHeader(title: 'Memory of the Day'),
                _MemoryStripCard(lovedOneName: profile?.lovedOneName ?? ''),
                const SizedBox(height: 20),
              ],

              // ── Start a Conversation ─────────────────────────────────
              _ConversationPromptCard(
                lovedOneName: profile?.lovedOneName ?? 'them',
                onTap: () => context.read<AppState>().setTabIndex(1),
              ),
              const SizedBox(height: 20),

              // ── Streak ───────────────────────────────────────────────
              if (state.streakDays > 0)
                _StreakBadge(days: state.streakDays),

              const SizedBox(height: 80),
            ]),
          ),
        ],
      ),
    );
  }

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    final nameStr = name.isNotEmpty ? ', $name' : '';
    if (hour < 12) return 'Good morning$nameStr';
    if (hour < 17) return 'Good afternoon$nameStr';
    return 'Good evening$nameStr';
  }

  void _showMoodSheet(BuildContext context, AppState state,
      {Mood? preselected}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoodLogSheet(
        preselected: preselected,
        onSave: (entry) {
          state.addJournalEntry(entry);
          Navigator.pop(context);
        },
      ),
    );
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
}

// ── Memory Strip Card ──────────────────────────────────────────────────
class _MemoryStripCard extends StatelessWidget {
  final String lovedOneName;
  const _MemoryStripCard({required this.lovedOneName});

  @override
  Widget build(BuildContext context) {
    // Sample memory for display
    const sampleMemory = '"Remember that rainy day we made chai together? ☕"';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SaharaTheme.ember.withOpacity(0.15),
            SaharaTheme.sandDeep,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 16, color: SaharaTheme.ember),
              const SizedBox(width: 8),
              Text(
                '$lovedOneName · 14 Mar 2022',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: SaharaTheme.ember,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sampleMemory,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: SaharaTheme.inkBrown,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ask Sahara about this memory →',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: SaharaTheme.mutedBrown,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Conversation Prompt Card ───────────────────────────────────────────
class _ConversationPromptCard extends StatelessWidget {
  final String lovedOneName;
  final VoidCallback onTap;
  const _ConversationPromptCard(
      {required this.lovedOneName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SaharaTheme.ember,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Talk about ${lovedOneName.isNotEmpty ? lovedOneName : "them"}',
                    style: GoogleFonts.playfairDisplay(
                      color: SaharaTheme.warmWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Share a memory, ask a question, or just talk.',
                    style: GoogleFonts.nunito(
                      color: SaharaTheme.warmWhite.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chat_bubble_outline,
                color: SaharaTheme.warmWhite, size: 32),
          ],
        ),
      ),
    );
  }
}

// ── Streak Badge ───────────────────────────────────────────────────────
class _StreakBadge extends StatelessWidget {
  final int days;
  const _StreakBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SaharaTheme.sage.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: SaharaTheme.sage.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Text(
            '$days-day check-in streak',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: SaharaTheme.sage),
          ),
          const Spacer(),
          Text(
            'Keep going!',
            style: GoogleFonts.nunito(
                fontSize: 12,
                color: SaharaTheme.sage,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Mood Log Sheet ─────────────────────────────────────────────────────
class _MoodLogSheet extends StatefulWidget {
  final Mood? preselected;
  final void Function(JournalEntry) onSave;
  const _MoodLogSheet({this.preselected, required this.onSave});

  @override
  State<_MoodLogSheet> createState() => _MoodLogSheetState();
}

class _MoodLogSheetState extends State<_MoodLogSheet> {
  Mood? _selected;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.preselected;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Log your mood', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: Mood.values
                .take(4)
                .map((m) => MoodChip(
                      mood: m,
                      selected: _selected == m,
                      onTap: () => setState(() => _selected = m),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add a note (optional)...',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected == null
                  ? null
                  : () {
                      widget.onSave(JournalEntry(
                        id: DateTime.now().toIso8601String(),
                        date: DateTime.now(),
                        mood: _selected!,
                        note: _noteCtrl.text.trim().isEmpty
                            ? null
                            : _noteCtrl.text.trim(),
                      ));
                    },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language Sheet ─────────────────────────────────────────────────────
class _LanguageSheet extends StatelessWidget {
  final AppLanguage selected;
  final ValueChanged<AppLanguage> onChanged;

  const _LanguageSheet({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
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
          ...AppLanguage.values.map((lang) {
            final isSel = lang == selected;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(lang.flag,
                  style: const TextStyle(fontSize: 24)),
              title: Text(lang.name,
                  style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text(lang.subtitle),
              trailing: isSel
                  ? const Icon(Icons.check_circle,
                      color: SaharaTheme.ember)
                  : null,
              onTap: () => onChanged(lang),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
