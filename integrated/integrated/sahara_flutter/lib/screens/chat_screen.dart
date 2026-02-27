import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _recorder   = AudioRecorder();

  bool _recording        = false;
  bool _backendAvailable = false;
  HealthStatus? _health;
  String? _recordingPath;

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
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _checkBackend() async {
    final h = await ApiService.checkHealth();
    if (mounted) {
      setState(() {
        _health           = h;
        _backendAvailable = h.isReady;
      });
    }
    // Retry every 15 s if not yet ready
    if (!h.isReady) {
      Future.delayed(const Duration(seconds: 15), _checkBackend);
    }
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

  // ── Send text message ──────────────────────────────────────────────
  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();

    final state     = context.read<AppState>();
    final userMsg   = ChatMessage(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    state.addMessage(userMsg);

    final loadingId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    state.addMessage(ChatMessage(
      id: loadingId,
      text: '',
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      isLoading: true,
    ));
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
          isCrisis: resp.isCrisis,
        );
        if (resp.isCrisis) _showCrisisSheet(context);
      } else {
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
        text: "I had trouble connecting. Please make sure Sahara's backend is running.",
        isLoading: false,
      );
    } finally {
      state.setTyping(false);
      _scrollToBottom(delay: 100);
    }
  }

  // ── Voice recording ────────────────────────────────────────────────
  Future<void> _startRecording() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required.')),
      );
      return;
    }

    final dir  = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/sahara_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _recordingPath!,
    );
    if (mounted) setState(() => _recording = true);
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    await _recorder.stop();
    if (mounted) setState(() => _recording = false);

    if (_recordingPath == null) return;
    final audioFile = File(_recordingPath!);
    if (!audioFile.existsSync()) return;

    await _sendVoice(audioFile);
  }

  Future<void> _sendVoice(File audioFile) async {
    final state     = context.read<AppState>();
    final loadingId = 'ai_${DateTime.now().millisecondsSinceEpoch}';

    state.addMessage(ChatMessage(
      id: loadingId,
      text: '',
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      isLoading: true,
    ));
    state.setTyping(true);
    _scrollToBottom();

    try {
      final lang = _langCodeForVosk(state.language);
      final resp = await ApiService.voiceQuery(audioFile, lang: lang);

      // Show what was transcribed as a user bubble first
      if (resp.transcription.isNotEmpty) {
        state.addMessage(ChatMessage(
          id: 'u_v_${DateTime.now().millisecondsSinceEpoch}',
          text: '🎙️ "${resp.transcription}"',
          sender: MessageSender.user,
          timestamp: DateTime.now(),
        ));
      }

      state.updateMessage(
        loadingId,
        text: resp.response,
        isLoading: false,
        memories: resp.memoriesSample,
        isCrisis: resp.isCrisis,
      );
      if (resp.isCrisis) _showCrisisSheet(context);
    } catch (e) {
      state.updateMessage(
        loadingId,
        text: "Voice processing failed. You can type your message instead.",
        isLoading: false,
      );
    } finally {
      state.setTyping(false);
      _scrollToBottom(delay: 100);
    }
  }

  String _langCodeForVosk(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hindi:
      case AppLanguage.hinglish:
      case AppLanguage.marathi:
        return 'hi';
      default:
        return 'en-in';
    }
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
    final state    = context.watch<AppState>();
    final messages = state.messages;

    String statusLabel;
    Color  statusColor;
    if (_health == null) {
      statusLabel = 'Connecting...';
      statusColor = Colors.orange;
    } else if (!_health!.isOnline) {
      statusLabel = 'Offline – demo mode';
      statusColor = Colors.orange;
    } else if (!_health!.llmLoaded) {
      statusLabel = 'Loading AI...';
      statusColor = Colors.orange;
    } else if (!_health!.memoriesIndexed) {
      statusLabel = 'No memories yet';
      statusColor = Colors.orange;
    } else {
      statusLabel = 'AI active';
      statusColor = SaharaTheme.sage;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sahara', style: Theme.of(context).textTheme.headlineMedium),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                ),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () => _showCrisisSheet(context),
              style: TextButton.styleFrom(
                backgroundColor: SaharaTheme.crisisRed.withOpacity(0.1),
                foregroundColor: SaharaTheme.crisisRed,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, size: 14),
                  const SizedBox(width: 4),
                  Text('Help',
                      style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (ctx, i) => _MessageBubble(message: messages[i]),
            ),
          ),
          _InputBar(
            controller: _inputCtrl,
            recording: _recording,
            onSend: _send,
            onVoiceStart: _startRecording,
            onVoiceStop: _stopRecording,
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: SaharaTheme.crisisRed, size: 40),
            const SizedBox(height: 16),
            Text('You are not alone.',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
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
            _CrisisButton(name: 'iCall', number: '9152987821'),
            const SizedBox(height: 12),
            _CrisisButton(name: 'Vandrevala Foundation', number: '1860-2662-345'),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ── Demo fallback ──────────────────────────────────────────────────
  String _demoResponse(String query, String name) {
    final q = query.toLowerCase();
    if (q.contains('chai') || q.contains('tea')) {
      return "I found a beautiful memory 🍵 — there was a rainy afternoon when $name made chai and you both sat by the window watching the rain.\n\n"
          "It sounds like those quiet moments together were really special.\n\n"
          "💛 Sahara uses only your saved memories. iCall: 9152987821";
    } else if (q.contains('laugh') || q.contains('funny')) {
      return "Oh, $name had such a warm laugh! There was a memory where they were teasing you about something silly and couldn't stop laughing. 💛\n\n"
          "iCall: 9152987821";
    } else {
      return "I searched through your memories with $name... There's so much warmth there. Would you like to tell me more about what you're thinking of? 🌿\n\n"
          "iCall: 9152987821";
    }
  }

  final List<Memory> _demoMemories = const [
    Memory(
      text: 'Made chai together, talked for hours. Best evening.',
      date: '14 Mar 2022',
      sender: 'Aai',
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
    final time   = DateFormat('h:mm a').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser)
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: SaharaTheme.ember),
                  child:
                      const Center(child: Text('🌿', style: TextStyle(fontSize: 16))),
                ),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                  ),
                  child: message.isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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

          // Memory cards (AI only)
          if (!isUser && message.memories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Column(
                  children: message.memories.map((m) => MemoryCard(memory: m)).toList()),
            ),

          // Disclaimer (AI only)
          if (!isUser && !message.isLoading && message.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: const SafetyDisclaimer(),
            ),

          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(time,
                style: GoogleFonts.nunito(fontSize: 11, color: SaharaTheme.mutedBrown)),
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

class _InputBarState extends State<_InputBar> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _pulse = Tween(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
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
        color: isDark ? SaharaTheme.darkSurface : SaharaTheme.sand,
        border: Border(
            top: BorderSide(color: SaharaTheme.mutedBrown.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          // Voice button – hold to record, release to send
          GestureDetector(
            onTapDown:  (_) => widget.onVoiceStart(),
            onTapUp:    (_) => widget.onVoiceStop(),
            onTapCancel:   widget.onVoiceStop,
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
                  color: widget.recording ? Colors.white : SaharaTheme.ember,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: widget.controller,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: widget.recording
                    ? 'Listening... release to send'
                    : 'Share a memory or ask something...',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: widget.onSend,
            ),
          ),
          const SizedBox(width: 10),

          GestureDetector(
            onTap: () => widget.onSend(widget.controller.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: SaharaTheme.ember),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
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
        border: Border.all(color: SaharaTheme.crisisRed.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone, color: SaharaTheme.crisisRed, size: 20),
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
