// lib/screens/chat_screen.dart
// ─────────────────────────────────────────────────────────────
// Sahara — Chat Screen (Web-compatible, fixed empty bubble)
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum MessageSender { user, sahara }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime time;
  final bool isWelcome;

  ChatMessage({
    required this.text,
    required this.sender,
    DateTime? time,
    this.isWelcome = false,
  }) : time = time ?? DateTime.now();
}

class ChatScreen extends StatefulWidget {
  final String lovedOneName;
  const ChatScreen({super.key, this.lovedOneName = 'Mumma'});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  static const _baseUrl = 'http://localhost:5000';

  final _textController  = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isLoading   = false;
  bool _isConnected = false;
  bool _isRecording = false;

  late AnimationController _typingController;
  late Animation<double>   _typingAnimation;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _typingAnimation = Tween(begin: 0.3, end: 1.0).animate(_typingController);
    _addWelcomeMessage();
    _checkConnection();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: 'Namaste 🎙 I\'m Sahara. I\'m here to help you revisit warm memories of ${widget.lovedOneName}.\n\n'
            'You can ask me anything — a favourite moment, a shared joke, something they always said. '
            'I\'ll gently surface what I find from your conversations.',
      sender: MessageSender.sahara,
      isWelcome: true,
    ));
  }

  Future<void> _checkConnection() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      if (mounted) setState(() => _isConnected = res.statusCode == 200);
    } catch (_) {
      if (mounted) setState(() => _isConnected = false);
    }
  }

  // ── Send text ──────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, sender: MessageSender.user));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': text}),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // ✅ FIX: check isNotEmpty so empty string "" doesn't pass through
        String? reply;
        for (final key in ['response', 'answer', 'result', 'message']) {
          final val = data[key]?.toString().trim();
          if (val != null && val.isNotEmpty) {
            reply = val;
            break;
          }
        }
        _addSaharaMessage(reply ?? 'Please import your WhatsApp chat first so I can find memories for you.');

      } else {
        try {
          final errData = jsonDecode(res.body);
          _addSaharaMessage('Backend error: ${errData['error'] ?? res.statusCode}');
        } catch (_) {
          _addSaharaMessage('Error ${res.statusCode} — check the backend terminal.');
        }
      }
    } catch (e) {
      _addSaharaMessage('Connection error — is the backend running?\n$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ FIX: never add empty bubbles
  void _addSaharaMessage(String text) {
    if (!mounted) return;
    final safe = text.trim().isEmpty
        ? 'Please import your WhatsApp chat first, then I can help you revisit memories.'
        : text.trim();
    setState(() {
      _messages.add(ChatMessage(text: safe, sender: MessageSender.sahara));
    });
    _scrollToBottom();
  }

  // ── Voice (web-disabled) ───────────────────────────────────

  Future<void> _toggleRecording() async {
    if (kIsWeb) {
      _addSaharaMessage('Voice input is not available in the web version. Please type your message.');
      return;
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime t) {
    final h      = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m      = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6CC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_isLoading) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF5E6CC),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sahara',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3D1F0A),
              letterSpacing: -0.3,
            ),
          ),
          Row(
            children: [
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color: _isConnected
                      ? const Color(0xFF4A8C6A)
                      : const Color(0xFFB5652A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _isConnected ? 'Connected' : 'Connecting...',
                style: TextStyle(
                  fontSize: 12,
                  color: _isConnected
                      ? const Color(0xFF4A8C6A)
                      : const Color(0xFFB5652A),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextButton.icon(
            onPressed: _showHelpDialog,
            icon: const Icon(Icons.favorite, size: 14, color: Color(0xFFB5652A)),
            label: const Text(
              'Help',
              style: TextStyle(
                color: Color(0xFFB5652A),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (ctx, i) {
        final msg      = _messages[i];
        final showTime = i == _messages.length - 1;
        return _buildMessageItem(msg, showTime);
      },
    );
  }

  Widget _buildMessageItem(ChatMessage msg, bool showTime) {
    final isSahara = msg.sender == MessageSender.sahara;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSahara) ...[
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB5652A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: isSahara
                    ? _buildSaharaBubble(msg)
                    : Align(
                        alignment: Alignment.centerRight,
                        child: _buildUserBubble(msg),
                      ),
              ),
              if (!isSahara) ...[
                const SizedBox(width: 10),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB5652A).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 18, color: Color(0xFFB5652A)),
                ),
              ],
            ],
          ),

          if (msg.isWelcome) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite_border,
                          size: 12,
                          color: const Color(0xFF8B6E4E).withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Sahara uses only your saved memories. It is not a substitute for professional grief support.',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF8B6E4E).withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'iCall: 9152987821 | Vandrevala: 1860-2662-345',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF8B6E4E).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (showTime)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 46),
              child: Text(
                _formatTime(msg.time),
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF8B6E4E).withOpacity(0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaharaBubble(ChatMessage msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFE8D5A8),
        borderRadius: BorderRadius.only(
          topLeft:     Radius.circular(4),
          topRight:    Radius.circular(20),
          bottomLeft:  Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Text(
        msg.text,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF3D1F0A),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildUserBubble(ChatMessage msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFB5652A),
        borderRadius: BorderRadius.only(
          topLeft:     Radius.circular(20),
          topRight:    Radius.circular(4),
          bottomLeft:  Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Text(
        msg.text,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.white,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 62, bottom: 8),
      child: Row(
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _typingAnimation,
            builder: (_, __) => Container(
              margin: const EdgeInsets.only(right: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFB5652A).withOpacity(
                  i == 0
                      ? _typingAnimation.value
                      : i == 1
                          ? _typingAnimation.value * 0.7
                          : _typingAnimation.value * 0.4,
                ),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: const BoxDecoration(color: Color(0xFFF5E6CC)),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _isRecording
                    ? const Color(0xFFB5652A)
                    : const Color(0xFFD4956A),
                shape: BoxShape.circle,
                boxShadow: _isRecording
                    ? [BoxShadow(
                        color: const Color(0xFFB5652A).withOpacity(0.4),
                        blurRadius: 12, spreadRadius: 2)]
                    : [],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white, size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(fontSize: 15, color: Color(0xFF3D1F0A)),
                decoration: InputDecoration(
                  hintText: 'Share a memory or ask something...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF8B6E4E).withOpacity(0.5),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
                maxLines: 4,
                minLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48, height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFB5652A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDFAF5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'If you need support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D1F0A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sahara is a memory companion, not a crisis service. If you\'re struggling, please reach out:',
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF8B6E4E),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _helpLine('iCall',                '9152987821'),
            _helpLine('Vandrevala Foundation', '9999666555'),
            _helpLine('AASRA',                '9820466627'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _helpLine(String name, String number) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3D1F0A),
              )),
          const Spacer(),
          Text(number,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB5652A),
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }
}