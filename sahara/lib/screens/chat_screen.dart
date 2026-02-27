import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../theme/sahara_theme.dart';
import '../widgets/widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _recording = false;
  Timer? _voiceTimer;
  bool _backendAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBackend();
    _addWelcome();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _voiceTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkBackend() async {
    final ok = await ApiService.checkHealth();
    setState(() => _backendAvailable = ok);
  }

  void _addWelcome() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      final name = state.profile?.lovedOneName ?? 'your loved one';
      if (state.messages.isEmpty) {
        state.addMessage(ChatMessage(
          id: 'welcome',
          text:
              "Namaste 🙏 I'm Sahara. I'm here to help you revisit warm memories of $name.\n\n"
              "You can ask me anything — a favourite moment, a shared joke, something they always said. "
              "I'll gently surface what I find from your conversations.",
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ));
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();

    final state = context.read<AppState>();
    final userMsg = ChatMessage(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    state.addMessage(userMsg);

    final loadingId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final loadingMsg = ChatMessage(
      id: loadingId,
      text: '',
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      isLoading: true,
    );
    state.addMessage(loadingMsg);
    state.setTyping(true);
    _scrollToBottom();

    try {
      if (_backendAvailable) {
        final resp = await ApiService.generate(text);
        state.updateMessage(
          loadingId,
          text: resp.response,
          isLoading: false,
          memories: resp.memoriesSample,
        );
      } else {
        // Demo fallback
        await Future.delayed(const Duration(seconds: 2));
        state.updateMessage(
          loadingId,
          text: _demoResponse(text, state.profile?.lovedOneName ?? 'them'),
          isLoading: false,
          memories: _demoMemories,
        );
      }
    } catch (e) {
      state.updateMessage(
        loadingId,
        text:
            "I had trouble connecting to the memory service. Please make sure Sahara's backend is running.",
        isLoading: false,
      );
    } finally {
      state.setTyping(false);
      _scrollToBottom(delay: 100);
    }
  }

  void _startVoice() {
    setState(() => _recording = true);
    // Simulate voice transcription after 2.5s
    _voiceTimer = Timer(const Duration(milliseconds: 2500), () {
      setState(() => _recording = false);
      _inputCtrl.text = 'Tell me about a time we laughed together';
    });
  }

  void _stopVoice() {
    _voiceTimer?.cancel();
    setState(() => _recording = false);
  }

  void _scrollToBottom({int delay = 0}) {
    Future.delayed(Duration(milliseconds: delay), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final messages = state.messages;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sahara',
                style: Theme.of(context).textTheme.headlineMedium),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _backendAvailable
                        ? SaharaTheme.sage
                        : Colors.orange,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _backendAvailable
                      ? 'AI active'
                      : 'Demo mode',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: _backendAvailable
                        ? SaharaTheme.sage
                        : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Crisis SOS button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () => _showCrisisSheet(context),
              style: TextButton.styleFrom(
                backgroundColor:
                    SaharaTheme.crisisRed.withOpacity(0.1),
                foregroundColor: SaharaTheme.crisisRed,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, size: 14),
                  const SizedBox(width: 4),
                  Text('Help',
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (ctx, i) =>
                  _MessageBubble(message: messages[i]),
            ),
          ),

          // Input area
          _InputBar(
            controller: _inputCtrl,
            recording: _recording,
            onSend: _send,
            onVoiceStart: _startVoice,
            onVoiceStop: _stopVoice,
          ),
        ],
      ),
    );
  }

  void _showCrisisSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite,
                color: SaharaTheme.crisisRed, size: 40),
            const SizedBox(height: 16),
            Text(
              'You are not alone.',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Trained counsellors are available 24/7.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: SaharaTheme.mutedBrown),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _CrisisButton(
                name: 'iCall', number: '9152987821'),
            const SizedBox(height: 12),
            _CrisisButton(
                name: 'Vandrevala Foundation',
                number: '1860-2662-345'),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // Demo response generation
  String _demoResponse(String query, String name) {
    final q = query.toLowerCase();
    if (q.contains('chai') || q.contains('tea')) {
      return "I found a beautiful memory 🍵 — there was a rainy afternoon when $name made chai and you both sat by the window watching the rain. "
          "They always said chai tasted better when made slowly.\n\n"
          "It sounds like those quiet moments together were really special.";
    } else if (q.contains('laugh') || q.contains('funny')) {
      return "Oh, $name had such a warm laugh! I found a memory where they were teasing you about something silly and couldn't stop laughing. "
          "The joy in those moments was real and lasting. 💛";
    } else if (q.contains('dream')) {
      return "Dreams can be a tender way of staying connected. $name lives on in your memories — and in the ways they shaped who you are.";
    } else {
      return "I searched through your memories with $name... "
          "There's so much warmth there. Would you like to tell me more about what you're thinking of? "
          "The more specific you are, the better I can help you find those moments. 🌿";
    }
  }

  final List<Memory> _demoMemories = const [
    Memory(
      text: "Made chai together, talked for hours. Best evening.",
      date: "14 Mar 2022",
      sender: "Aai",
      relevanceScore: 0.92,
    ),
  ];
}

// ── Message Bubble ─────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time =
        DateFormat('h:mm a').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser)
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: SaharaTheme.ember,
                  ),
                  child: const Center(
                    child: Text('🌿',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? SaharaTheme.ember
                        : isDark
                            ? SaharaTheme.darkCard
                            : SaharaTheme.sandDeep,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight:
                          Radius.circular(isUser ? 4 : 18),
                    ),
                  ),
                  child: message.isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          child: LoadingDots(),
                        )
                      : Text(
                          message.text,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            height: 1.55,
                            color: isUser
                                ? SaharaTheme.warmWhite
                                : isDark
                                    ? SaharaTheme.warmWhite
                                    : SaharaTheme.inkBrown,
                          ),
                        ),
                ),
              ),
            ],
          ),

          // Memories (AI only)
          if (!isUser && message.memories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Column(
                children: message.memories
                    .map((m) => MemoryCard(memory: m))
                    .toList(),
              ),
            ),

          // Disclaimer (AI only, non-loading)
          if (!isUser && !message.isLoading && message.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: const SafetyDisclaimer(),
            ),

          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              time,
              style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: SaharaTheme.mutedBrown),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input Bar ──────────────────────────────────────────────────────────
class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool recording;
  final void Function(String) onSend;
  final VoidCallback onVoiceStart;
  final VoidCallback onVoiceStop;

  const _InputBar({
    required this.controller,
    required this.recording,
    required this.onSend,
    required this.onVoiceStart,
    required this.onVoiceStop,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulse = Tween(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_InputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recording && !oldWidget.recording) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.recording) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: isDark
            ? SaharaTheme.darkSurface
            : SaharaTheme.sand,
        border: Border(
          top: BorderSide(
            color: SaharaTheme.mutedBrown.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Voice button
          GestureDetector(
            onTapDown: (_) => widget.onVoiceStart(),
            onTapUp: (_) => widget.onVoiceStop(),
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (ctx, child) => Transform.scale(
                scale: widget.recording ? _pulse.value : 1.0,
                child: child,
              ),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.recording
                      ? SaharaTheme.crisisRed
                      : SaharaTheme.ember.withOpacity(0.15),
                ),
                child: Icon(
                  widget.recording ? Icons.stop : Icons.mic,
                  color: widget.recording
                      ? Colors.white
                      : SaharaTheme.ember,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Text field
          Expanded(
            child: TextField(
              controller: widget.controller,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: widget.recording
                    ? 'Listening...'
                    : 'Share a memory or ask something...',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              onSubmitted: widget.onSend,
            ),
          ),
          const SizedBox(width: 10),

          // Send button
          GestureDetector(
            onTap: () => widget.onSend(widget.controller.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: SaharaTheme.ember,
              ),
              child: const Icon(Icons.send,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Crisis Button ──────────────────────────────────────────────────────
class _CrisisButton extends StatelessWidget {
  final String name;
  final String number;
  const _CrisisButton({required this.name, required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: SaharaTheme.crisisRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: SaharaTheme.crisisRed.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone,
              color: SaharaTheme.crisisRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: SaharaTheme.crisisRed)),
                Text(number,
                    style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: SaharaTheme.crisisRed)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
