import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/sahara_theme.dart';
import '../widgets/widgets.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = state.journalEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showMoodSheet(context, state),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Summary row
                _SummaryRow(
                  streak: state.streakDays,
                  todayMood: state.todayMood,
                  totalEntries: entries.length,
                ),
                const SizedBox(height: 16),

                // Chart
                _MoodChart(entries: entries),
                const SizedBox(height: 20),

                SectionHeader(
                  title: 'Your Journal',
                  trailing: entries.isEmpty
                      ? null
                      : Text(
                          '${entries.length} entries',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: SaharaTheme.mutedBrown,
                          ),
                        ),
                ),
              ],
            ),
          ),

          if (entries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📖',
                        style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      'No entries yet.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to log today\'s mood.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _JournalEntryCard(entry: entries[i]),
                childCount: entries.length,
              ),
            ),

          const SliverToBoxAdapter(
              child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMoodSheet(context, state),
        backgroundColor: SaharaTheme.ember,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showMoodSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoodEntrySheet(
        onSave: (entry) {
          state.addJournalEntry(entry);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Summary Row ────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final int streak;
  final Mood? todayMood;
  final int totalEntries;

  const _SummaryRow({
    required this.streak,
    required this.todayMood,
    required this.totalEntries,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _SummaryCell(
            emoji: '🔥',
            label: 'Streak',
            value: '$streak days',
          ),
          const SizedBox(width: 12),
          _SummaryCell(
            emoji: todayMood?.emoji ?? '—',
            label: 'Today',
            value: todayMood?.label ?? 'Not logged',
          ),
          const SizedBox(width: 12),
          _SummaryCell(
            emoji: '📖',
            label: 'Total',
            value: '$totalEntries entries',
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _SummaryCell(
      {required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? SaharaTheme.darkCard
              : SaharaTheme.sandDeep,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 13),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Mood Chart ─────────────────────────────────────────────────────────
class _MoodChart extends StatelessWidget {
  final List<JournalEntry> entries;
  const _MoodChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build last 7 days data
    final now = DateTime.now();
    final spots = <FlSpot>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayEntries = entries.where((e) =>
          e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day);

      if (dayEntries.isNotEmpty) {
        final moodIndex =
            Mood.values.indexOf(dayEntries.last.mood).toDouble();
        spots.add(FlSpot((6 - i).toDouble(), moodIndex));
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? SaharaTheme.darkCard : SaharaTheme.sandDeep,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Emotional Landscape',
              style: Theme.of(context).textTheme.titleMedium),
          Text('Last 7 days',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: SaharaTheme.mutedBrown.withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= Mood.values.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          Mood.values[idx].emoji,
                          style: const TextStyle(fontSize: 14),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final day = now.subtract(
                            Duration(days: 6 - value.toInt()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('EEE').format(day),
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              color: SaharaTheme.mutedBrown,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: (Mood.values.length - 1).toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty
                        ? [FlSpot(3, 2)]
                        : spots,
                    isCurved: true,
                    color: SaharaTheme.ember,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: SaharaTheme.ember,
                        strokeColor: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: SaharaTheme.ember.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Journal Entry Card ─────────────────────────────────────────────────
class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  const _JournalEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? SaharaTheme.darkCard : SaharaTheme.sandDeep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(entry.mood.color).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Color(entry.mood.color).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(entry.mood.emoji,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.mood.label,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              color: Color(entry.mood.color),
                              fontSize: 15),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('d MMM · h:mm a')
                          .format(entry.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (entry.note != null && entry.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      entry.note!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.5),
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

// ── Mood Entry Sheet ───────────────────────────────────────────────────
class _MoodEntrySheet extends StatefulWidget {
  final void Function(JournalEntry) onSave;
  const _MoodEntrySheet({required this.onSave});

  @override
  State<_MoodEntrySheet> createState() => _MoodEntrySheetState();
}

class _MoodEntrySheetState extends State<_MoodEntrySheet> {
  Mood? _selected;
  final _noteCtrl = TextEditingController();

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
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
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
            Text('Log Your Mood',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, d MMMM').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: Mood.values
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
                hintText:
                    'What\'s on your mind today? (optional)',
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
                child: const Text('Save Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
