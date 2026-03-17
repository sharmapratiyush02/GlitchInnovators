// lib/screens/baithak/baithak_screen.dart
// ─────────────────────────────────────────────────────────────
// Baithak — Sahara Anonymous Peer Support Forum
//
// Features:
//   • Anonymous symbol identity (12 symbols, refreshable per session)
//   • Feed tab — thread list with category filters
//   • Compose tab — anonymous post with symbol identity
//   • Volunteer tab — respond to pending threads
//   • Crisis resources always visible in thread detail
//   • 7-day thread archive
// ─────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Constants ────────────────────────────────────────────────

const List<Map<String, String>> kSymbols = [
  {'emoji': '🌿', 'name': 'Banyan'},
  {'emoji': '🌊', 'name': 'River'},
  {'emoji': '🪨', 'name': 'Stone'},
  {'emoji': '🌾', 'name': 'Wheat Field'},
  {'emoji': '☁️', 'name': 'Cloud'},
  {'emoji': '🌸', 'name': 'Jasmine'},
  {'emoji': '🕊️', 'name': 'Dove'},
  {'emoji': '🌙', 'name': 'Crescent'},
  {'emoji': '🍃', 'name': 'Leaf'},
  {'emoji': '⭐', 'name': 'Star'},
  {'emoji': '🌺', 'name': 'Marigold'},
  {'emoji': '🪷', 'name': 'Lotus'},
];

const List<Map<String, dynamic>> kCategories = [
  {'label': 'Grief & Loss',       'emoji': '💔', 'color': Color(0xFFA05060)},
  {'label': 'Anxiety & Stress',   'emoji': '🌊', 'color': Color(0xFF4A708A)},
  {'label': 'Loneliness',         'emoji': '🌙', 'color': Color(0xFF5A4A8A)},
  {'label': 'Anger & Frustration','emoji': '🔥', 'color': Color(0xFFB5652A)},
  {'label': 'Burnout',            'emoji': '🍂', 'color': Color(0xFF7A6040)},
  {'label': 'Something else',     'emoji': '🌸', 'color': Color(0xFF4A8C6A)},
];

// ─── Theme ────────────────────────────────────────────────────

class BaithakColors {
  static const bg       = Color(0xFFF7F2EB);
  static const surface  = Color(0xFFFDFAF5);
  static const card     = Color(0xFFFFFFFF);
  static const ember    = Color(0xFFB5652A);
  static const dusk     = Color(0xFFC4956A);
  static const sand     = Color(0xFFE8D5B5);
  static const text     = Color(0xFF2C1F0E);
  static const muted    = Color(0xFF8B6E4E);
  static const soft     = Color(0xFFF0E8D8);
  static const green    = Color(0xFF4A8C6A);
  static const border   = Color(0x248B6E4E);
  static const shadow   = Color(0x122C1F0E);
}

// ─── Data Models ──────────────────────────────────────────────

class BaithakThread {
  final String id;
  final String symbolEmoji;
  final String symbolName;
  final String category;
  final Color  categoryColor;
  final String categoryEmoji;
  final String content;
  final int    responseCount;
  final DateTime createdAt;
  final List<BaithakResponse> responses;
  int helpedCount;

  BaithakThread({
    required this.id,
    required this.symbolEmoji,
    required this.symbolName,
    required this.category,
    required this.categoryColor,
    required this.categoryEmoji,
    required this.content,
    required this.responseCount,
    required this.createdAt,
    this.responses = const [],
    this.helpedCount = 0,
  });

  String get archiveCountdown {
    final expiry = createdAt.add(const Duration(days: 7));
    final diff   = expiry.difference(DateTime.now());
    if (diff.isNegative) return 'Archived';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    return '${diff.inHours}h left';
  }

  String get excerpt => content.length > 100
      ? '${content.substring(0, 100)}…'
      : content;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class BaithakResponse {
  final String symbolEmoji;
  final String symbolName;
  final String content;
  final bool   isVolunteer;
  final DateTime createdAt;

  BaithakResponse({
    required this.symbolEmoji,
    required this.symbolName,
    required this.content,
    required this.isVolunteer,
    required this.createdAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Demo Data ────────────────────────────────────────────────

List<BaithakThread> _demoThreads() => [
  BaithakThread(
    id: '1',
    symbolEmoji: '🌊', symbolName: 'River',
    category: 'Grief & Loss', categoryColor: Color(0xFFA05060), categoryEmoji: '💔',
    content: 'It\'s been 6 months since Aai passed and I still reach for my phone to call her every evening. I don\'t know when this stops feeling so sharp.',
    responseCount: 3,
    helpedCount: 7,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    responses: [
      BaithakResponse(
        symbolEmoji: '🌿', symbolName: 'Banyan',
        content: 'The evening calls are the hardest. I used to call my father every Sunday. It took over a year before I stopped automatically dialing. Be gentle with yourself.',
        isVolunteer: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      BaithakResponse(
        symbolEmoji: '🕊️', symbolName: 'Dove',
        content: 'Grief counselors often say that these instincts — reaching for the phone — are love that doesn\'t know where to go yet. It\'s not a sign something is wrong with you. It\'s a sign of how deep the bond was.',
        isVolunteer: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ],
  ),
  BaithakThread(
    id: '2',
    symbolEmoji: '🌸', symbolName: 'Jasmine',
    category: 'Loneliness', categoryColor: Color(0xFF5A4A8A), categoryEmoji: '🌙',
    content: 'Everyone around me has moved on. Friends, family — they all think I should be "over it" by now. I feel completely alone in this grief.',
    responseCount: 1,
    helpedCount: 4,
    createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    responses: [
      BaithakResponse(
        symbolEmoji: '🌾', symbolName: 'Wheat Field',
        content: 'There is no timeline for grief. Anyone who puts one on you doesn\'t understand. You\'re not alone — many of us here know exactly this feeling.',
        isVolunteer: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
      ),
    ],
  ),
  BaithakThread(
    id: '3',
    symbolEmoji: '🪨', symbolName: 'Stone',
    category: 'Anxiety & Stress', categoryColor: Color(0xFF4A708A), categoryEmoji: '🌊',
    content: 'I have an important presentation tomorrow and I just cannot focus. Every time I try to work, I end up crying. How do people function through grief?',
    responseCount: 0,
    helpedCount: 0,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    responses: [],
  ),
];

// ─── Main Screen ──────────────────────────────────────────────

class BaithakScreen extends StatefulWidget {
  const BaithakScreen({super.key});

  @override
  State<BaithakScreen> createState() => _BaithakScreenState();
}

class _BaithakScreenState extends State<BaithakScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, String> _mySymbol;
  String? _selectedCategory;
  final List<BaithakThread> _threads = _demoThreads();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _mySymbol = _pickRandomSymbol();
  }

  Map<String, String> _pickRandomSymbol() {
    final r = Random();
    return Map<String, String>.from(kSymbols[r.nextInt(kSymbols.length)]);
  }

  void _refreshSymbol() {
    setState(() => _mySymbol = _pickRandomSymbol());
    HapticFeedback.lightImpact();
  }

  List<BaithakThread> get _filteredThreads {
    if (_selectedCategory == null) return _threads;
    return _threads.where((t) => t.category == _selectedCategory).toList();
  }

  List<BaithakThread> get _unansweredThreads =>
      _threads.where((t) => t.responseCount == 0).toList();

  List<BaithakThread> get _answeredThreads =>
      _threads.where((t) => t.responseCount > 0).toList();

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaithakColors.bg,
      appBar: AppBar(
        backgroundColor: BaithakColors.surface,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'बैठक',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: BaithakColors.text,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Baithak',
              style: TextStyle(
                fontSize: 14,
                color: BaithakColors.muted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: BaithakColors.ember,
          unselectedLabelColor: BaithakColors.muted,
          indicatorColor: BaithakColors.ember,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
          tabs: const [
            Tab(text: 'Feed'),
            Tab(text: 'Share'),
            Tab(text: 'Volunteer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FeedTab(
            threads: _filteredThreads,
            selectedCategory: _selectedCategory,
            onCategorySelect: (cat) =>
                setState(() => _selectedCategory = cat == _selectedCategory ? null : cat),
            onThreadTap: (thread) => _openThread(thread),
          ),
          _ComposeTab(
            symbol: _mySymbol,
            onRefreshSymbol: _refreshSymbol,
            onSubmit: _submitThread,
          ),
          _VolunteerTab(
            unanswered: _unansweredThreads,
            answered: _answeredThreads,
            onThreadTap: (thread) => _openThread(thread),
          ),
        ],
      ),
    );
  }

  void _submitThread(String category, String content) {
    final cat = kCategories.firstWhere(
      (c) => c['label'] == category,
      orElse: () => kCategories.last,
    );
    final newThread = BaithakThread(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbolEmoji: _mySymbol['emoji']!,
      symbolName: _mySymbol['name']!,
      category: category,
      categoryColor: cat['color'] as Color,
      categoryEmoji: cat['emoji'] as String,
      content: content,
      responseCount: 0,
      createdAt: DateTime.now(),
    );
    setState(() => _threads.insert(0, newThread));
    _tabController.animateTo(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Your words have been shared 🌿'),
        backgroundColor: BaithakColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openThread(BaithakThread thread) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ThreadDetailScreen(
          thread: thread,
          mySymbol: _mySymbol,
          onResponse: (response) {
            setState(() {
              final t = _threads.firstWhere((t) => t.id == thread.id);
              // responseCount is final so we recreate — for demo just show snackbar
            });
          },
        ),
      ),
    );
  }
}

// ─── Feed Tab ─────────────────────────────────────────────────

class _FeedTab extends StatelessWidget {
  final List<BaithakThread> threads;
  final String? selectedCategory;
  final ValueChanged<String> onCategorySelect;
  final ValueChanged<BaithakThread> onThreadTap;

  const _FeedTab({
    required this.threads,
    required this.selectedCategory,
    required this.onCategorySelect,
    required this.onThreadTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _CategoryFilter(
            selected: selectedCategory,
            onSelect: onCategorySelect,
          ),
        ),
        if (threads.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🌿', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    'No threads yet',
                    style: TextStyle(
                      color: BaithakColors.muted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be the first to share',
                    style: TextStyle(
                      color: BaithakColors.muted.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ThreadCard(
                    thread: threads[i],
                    onTap: () => onThreadTap(threads[i]),
                  ),
                ),
                childCount: threads.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _CategoryFilter({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: kCategories.length,
        itemBuilder: (ctx, i) {
          final cat  = kCategories[i];
          final name = cat['label'] as String;
          final isSelected = selected == name;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (cat['color'] as Color).withOpacity(0.15)
                      : BaithakColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (cat['color'] as Color)
                        : BaithakColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat['emoji'] as String,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? (cat['color'] as Color)
                            : BaithakColors.muted,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  final BaithakThread thread;
  final VoidCallback onTap;

  const _ThreadCard({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: BaithakColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BaithakColors.border),
          boxShadow: [
            BoxShadow(
              color: BaithakColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category color bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: thread.categoryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft:    Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Text(thread.symbolEmoji,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            thread.symbolName,
                            style: TextStyle(
                              fontSize: 13,
                              color: BaithakColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: thread.categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${thread.categoryEmoji} ${thread.category}',
                              style: TextStyle(
                                fontSize: 11,
                                color: thread.categoryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Excerpt
                      Text(
                        thread.excerpt,
                        style: TextStyle(
                          fontSize: 14,
                          color: BaithakColors.text,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Footer
                      Row(
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 14, color: BaithakColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            '${thread.responseCount} responses',
                            style: TextStyle(
                              fontSize: 12,
                              color: BaithakColors.muted,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.favorite_border,
                              size: 14, color: BaithakColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            '${thread.helpedCount} helped',
                            style: TextStyle(
                              fontSize: 12,
                              color: BaithakColors.muted,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            thread.timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: BaithakColors.muted.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            thread.archiveCountdown,
                            style: TextStyle(
                              fontSize: 11,
                              color: BaithakColors.muted.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Compose Tab ──────────────────────────────────────────────

class _ComposeTab extends StatefulWidget {
  final Map<String, String> symbol;
  final VoidCallback onRefreshSymbol;
  final void Function(String category, String content) onSubmit;

  const _ComposeTab({
    required this.symbol,
    required this.onRefreshSymbol,
    required this.onSubmit,
  });

  @override
  State<_ComposeTab> createState() => _ComposeTabState();
}

class _ComposeTabState extends State<_ComposeTab> {
  String? _selectedCategory;
  final _controller = TextEditingController();
  int get _charCount => _controller.text.length;
  static const _maxChars = 500;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please choose a category'),
          backgroundColor: BaithakColors.ember,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please write something'),
          backgroundColor: BaithakColors.ember,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    widget.onSubmit(_selectedCategory!, _controller.text.trim());
    _controller.clear();
    setState(() => _selectedCategory = null);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Symbol identity card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BaithakColors.soft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BaithakColors.border),
            ),
            child: Row(
              children: [
                Text(widget.symbol['emoji']!,
                    style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are ${widget.symbol['name']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: BaithakColors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Your identity is private. No one will know who you are.',
                        style: TextStyle(
                          fontSize: 12,
                          color: BaithakColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onRefreshSymbol,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BaithakColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BaithakColors.border),
                    ),
                    child: Icon(Icons.refresh,
                        size: 18, color: BaithakColors.muted),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'What are you carrying?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: BaithakColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a category that fits best',
            style: TextStyle(fontSize: 13, color: BaithakColors.muted),
          ),
          const SizedBox(height: 14),

          // Category grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: kCategories.length,
            itemBuilder: (ctx, i) {
              final cat        = kCategories[i];
              final name       = cat['label'] as String;
              final isSelected = _selectedCategory == name;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategory = name);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (cat['color'] as Color).withOpacity(0.12)
                        : BaithakColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? (cat['color'] as Color)
                          : BaithakColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat['emoji'] as String,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? (cat['color'] as Color)
                                : BaithakColors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          Text(
            'Write freely',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: BaithakColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No names. No judgement. Just words.',
            style: TextStyle(fontSize: 13, color: BaithakColors.muted),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: BaithakColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BaithakColors.border),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 8,
                  maxLength: _maxChars,
                  style: TextStyle(
                    fontSize: 15,
                    color: BaithakColors.text,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'What\'s been heavy on your heart lately? This is a safe space...',
                    hintStyle: TextStyle(
                      color: BaithakColors.muted.withOpacity(0.5),
                      fontSize: 14,
                      height: 1.6,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    counterText: '',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        '$_charCount / $_maxChars',
                        style: TextStyle(
                          fontSize: 12,
                          color: _charCount > _maxChars * 0.9
                              ? BaithakColors.ember
                              : BaithakColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Privacy strip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: BaithakColors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: BaithakColors.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 15, color: BaithakColors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your post is 100% anonymous. It will be archived in 7 days.',
                    style: TextStyle(
                      fontSize: 12,
                      color: BaithakColors.green,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: BaithakColors.ember,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Share with Baithak',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Volunteer Tab ────────────────────────────────────────────

class _VolunteerTab extends StatelessWidget {
  final List<BaithakThread> unanswered;
  final List<BaithakThread> answered;
  final ValueChanged<BaithakThread> onThreadTap;

  const _VolunteerTab({
    required this.unanswered,
    required this.answered,
    required this.onThreadTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Impact banner
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BaithakColors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: BaithakColors.green.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Text('🕊️', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your words matter',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: BaithakColors.green,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Trained volunteers like you keep this space safe and warm.',
                        style: TextStyle(
                          fontSize: 12,
                          color: BaithakColors.green.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (unanswered.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Awaiting response',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BaithakColors.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: BaithakColors.ember,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'NEW',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _VolunteerThreadCard(
                    thread: unanswered[i],
                    onTap: () => onThreadTap(unanswered[i]),
                    needsResponse: true,
                  ),
                ),
                childCount: unanswered.length,
              ),
            ),
          ),
        ],

        if (answered.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Responded recently',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BaithakColors.text,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _VolunteerThreadCard(
                    thread: answered[i],
                    onTap: () => onThreadTap(answered[i]),
                    needsResponse: false,
                  ),
                ),
                childCount: answered.length,
              ),
            ),
          ),
        ],

        if (unanswered.isEmpty && answered.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                '🌿 All threads have responses',
                style: TextStyle(color: BaithakColors.muted, fontSize: 15),
              ),
            ),
          ),
      ],
    );
  }
}

class _VolunteerThreadCard extends StatelessWidget {
  final BaithakThread thread;
  final VoidCallback onTap;
  final bool needsResponse;

  const _VolunteerThreadCard({
    required this.thread,
    required this.onTap,
    required this.needsResponse,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BaithakColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: needsResponse
                ? BaithakColors.ember.withOpacity(0.3)
                : BaithakColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: BaithakColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(thread.symbolEmoji,
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  thread.symbolName,
                  style: TextStyle(
                    fontSize: 13,
                    color: BaithakColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: thread.categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${thread.categoryEmoji} ${thread.category}',
                    style: TextStyle(
                      fontSize: 11,
                      color: thread.categoryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              thread.excerpt,
              style: TextStyle(
                fontSize: 14,
                color: BaithakColors.text,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  thread.timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: BaithakColors.muted,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: needsResponse
                        ? BaithakColors.ember
                        : BaithakColors.soft,
                    foregroundColor: needsResponse
                        ? Colors.white
                        : BaithakColors.muted,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    needsResponse ? 'Respond' : 'View',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Thread Detail Screen ─────────────────────────────────────

class _ThreadDetailScreen extends StatefulWidget {
  final BaithakThread thread;
  final Map<String, String> mySymbol;
  final ValueChanged<BaithakResponse> onResponse;

  const _ThreadDetailScreen({
    required this.thread,
    required this.mySymbol,
    required this.onResponse,
  });

  @override
  State<_ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<_ThreadDetailScreen> {
  final _replyController = TextEditingController();
  late List<BaithakResponse> _responses;
  bool _helped = false;

  @override
  void initState() {
    super.initState();
    _responses = List.from(widget.thread.responses);
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _submitReply() {
    if (_replyController.text.trim().isEmpty) return;
    final response = BaithakResponse(
      symbolEmoji: widget.mySymbol['emoji']!,
      symbolName:  widget.mySymbol['name']!,
      content:     _replyController.text.trim(),
      isVolunteer: false,
      createdAt:   DateTime.now(),
    );
    setState(() => _responses.add(response));
    widget.onResponse(response);
    _replyController.clear();
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaithakColors.bg,
      appBar: AppBar(
        backgroundColor: BaithakColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: BaithakColors.text),
        title: Row(
          children: [
            Text(widget.thread.symbolEmoji,
                style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              widget.thread.symbolName,
              style: TextStyle(
                fontSize: 16,
                color: BaithakColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.thread.categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${widget.thread.categoryEmoji} ${widget.thread.category}',
              style: TextStyle(
                fontSize: 11,
                color: widget.thread.categoryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Original post
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: BaithakColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BaithakColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.thread.content,
                        style: TextStyle(
                          fontSize: 15,
                          color: BaithakColors.text,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            widget.thread.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: BaithakColors.muted,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _helped = !_helped;
                                if (_helped) widget.thread.helpedCount++;
                                else widget.thread.helpedCount--;
                              });
                            },
                            child: Row(
                              children: [
                                Icon(
                                  _helped
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 16,
                                  color: _helped
                                      ? BaithakColors.ember
                                      : BaithakColors.muted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'This helped me',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _helped
                                        ? BaithakColors.ember
                                        : BaithakColors.muted,
                                    fontWeight: _helped
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (_responses.isNotEmpty) ...[
                  Text(
                    '${_responses.length} ${_responses.length == 1 ? 'response' : 'responses'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: BaithakColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._responses.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ResponseCard(response: r),
                  )),
                ],

                const SizedBox(height: 16),

                // Crisis resources
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFA05060).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Color(0xFFA05060).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite,
                              size: 14, color: Color(0xFFA05060)),
                          const SizedBox(width: 6),
                          Text(
                            'If you need immediate support',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFA05060),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _CrisisResource(
                          name: 'iCall',
                          number: '9152987821'),
                      _CrisisResource(
                          name: 'Vandrevala Foundation',
                          number: '9999666555'),
                      _CrisisResource(
                          name: 'AASRA',
                          number: '9820466627'),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),

          // Reply bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: BaithakColors.surface,
              border: Border(
                  top: BorderSide(color: BaithakColors.border)),
            ),
            child: Row(
              children: [
                Text(widget.mySymbol['emoji']!,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    style: TextStyle(
                        fontSize: 14, color: BaithakColors.text),
                    decoration: InputDecoration(
                      hintText: 'Write a kind response...',
                      hintStyle: TextStyle(
                          color: BaithakColors.muted.withOpacity(0.5),
                          fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            BorderSide(color: BaithakColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                            color: BaithakColors.ember, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            BorderSide(color: BaithakColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: BaithakColors.card,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _submitReply,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: BaithakColors.ember,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        size: 18, color: Colors.white),
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

class _ResponseCard extends StatelessWidget {
  final BaithakResponse response;

  const _ResponseCard({required this.response});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BaithakColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BaithakColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(response.symbolEmoji,
                  style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(
                response.symbolName,
                style: TextStyle(
                  fontSize: 13,
                  color: BaithakColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (response.isVolunteer) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: BaithakColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Volunteer',
                    style: TextStyle(
                      fontSize: 10,
                      color: BaithakColors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                response.timeAgo,
                style: TextStyle(
                    fontSize: 11,
                    color: BaithakColors.muted.withOpacity(0.7)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            response.content,
            style: TextStyle(
              fontSize: 14,
              color: BaithakColors.text,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrisisResource extends StatelessWidget {
  final String name;
  final String number;

  const _CrisisResource({required this.name, required this.number});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              color: BaithakColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            number,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFA05060),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
