// lib/screens/aasman/aasman_hub.dart
// ─────────────────────────────────────────────────────────────
// Main Aasman screen with tab-based navigation across
// Sky, Diya Wall, Whispers, and Ritual.
// Uses AasmanService (ChangeNotifier) for reactive state.
// ─────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/aasman_service.dart';

// ── Colours ───────────────────────────────────────────────────
const kNight  = Color(0xFF0A0806);
const kDeep   = Color(0xFF1A1008);
const kEmber  = Color(0xFFD4874E);
const kDusk   = Color(0xFFC4956A);
const kSand   = Color(0xFFF5EDE0);
const kMuted  = Color(0xFF7A6550);
const kGold   = Color(0xFFE8B86D);
const kRose   = Color(0xFFC4756A);
const kTeal   = Color(0xFF5A9E8A);

const kDiyaColors = [
  Color(0xFFD4874E), Color(0xFFE8B86D), Color(0xFFC4756A),
  Color(0xFF5A9E8A), Color(0xFF6A8EC4), Color(0xFF9A7AC4),
];

// ══════════════════════════════════════════════════════════════
// HUB — entry point, wraps all Aasman tabs
// ══════════════════════════════════════════════════════════════

class AasmanHub extends StatefulWidget {
  const AasmanHub({super.key});

  @override
  State<AasmanHub> createState() => _AasmanHubState();
}

class _AasmanHubState extends State<AasmanHub> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final svc = AasmanService.instance;
    svc.connectRealtime();
    svc.loadSky();
  }

  @override
  void dispose() {
    AasmanService.instance.leaveRitual();
    super.dispose();
  }

  final _tabs = const [
    SkyScreen(),
    DiyaWallScreen(),
    WhisperScreen(),
    RitualScreen(),
  ];

  void _onTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: AasmanService.instance,
      child: Scaffold(
        backgroundColor: kNight,
        body: IndexedStack(index: _tab, children: _tabs),
        bottomNavigationBar: _BottomNav(current: _tab, onTap: _onTab),
      ),
    );
  }
}

// ── Bottom nav ───────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.onTap});
  final int current;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.public_outlined,      'Sky'),
      (Icons.local_fire_department_outlined, 'Diyas'),
      (Icons.chat_bubble_outline,  'Whispers'),
      (Icons.brightness_3_outlined,'Ritual'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: kNight,
        border: Border(top: BorderSide(color: Color(0x22C4956A))),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Row(
        children: items.asMap().entries.map((e) {
          final active = e.key == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(e.key),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40, height: 28,
                    decoration: BoxDecoration(
                      color: active ? kEmber.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(e.value.$1,
                      size: 18,
                      color: active ? kEmber : kMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(e.value.$2,
                    style: TextStyle(
                      fontSize: 10,
                      color: active ? kEmber : kMuted,
                      fontWeight: active ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SKY SCREEN
// ══════════════════════════════════════════════════════════════

class SkyScreen extends StatelessWidget {
  const SkyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AasmanService>(
      builder: (context, svc, _) {
        final stats = svc.skyStats;
        return Stack(
          children: [
            // Star background
            const _StarCanvas(),
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20,12,20,0),
                    child: Row(
                      children: [
                        const Text('आसमान',
                          style: TextStyle(
                            fontFamily: 'serif', fontSize: 24,
                            color: kSand, fontWeight: FontWeight.w300,
                          ),
                        ),
                        const Spacer(),
                        // Ritual moon
                        GestureDetector(
                          onTap: () {},  // switch to ritual tab
                          child: _RitualMoon(ritual: svc.ritual),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Stats + actions
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, kNight.withOpacity(0.95)],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _StatBox(
                              val: '${stats?.starsTonight ?? 247}',
                              label: 'Stars tonight',
                            ),
                            const SizedBox(width: 10),
                            _StatBox(
                              val: svc.diyaLitToday ? '🕯️' : '—',
                              label: 'Your diya',
                            ),
                            const SizedBox(width: 10),
                            _StatBox(
                              val: '${stats?.whispersTonight ?? 84}',
                              label: 'Whispers',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _ActionBtn(
                                label: '🪔  Light Diya',
                                primary: true,
                                onTap: () => _showDiyaSheet(context, svc),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ActionBtn(
                                label: '✦ Whisper',
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDiyaSheet(BuildContext context, AasmanService svc) {
    if (svc.diyaLitToday) {
      _showToast(context, '🕯️ Your diya is already burning');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DiyaSheet(svc: svc),
    );
  }

  static void _showToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF2A1F0E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ── Ritual moon widget ────────────────────────────────────────
class _RitualMoon extends StatelessWidget {
  const _RitualMoon({this.ritual});
  final RitualInfo? ritual;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [kSand, kDusk],
        ),
        boxShadow: [
          BoxShadow(color: kDusk.withOpacity(0.4), blurRadius: 14, spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌙', style: TextStyle(fontSize: 16)),
          if (ritual != null)
            Text(
              ritual!.isActive ? 'Live' : ritual!.countdownFormatted,
              style: const TextStyle(fontSize: 8, color: kNight, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

// ── Stat box ──────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  const _StatBox({required this.val, required this.label});
  final String val, label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kDusk.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(val, style: const TextStyle(
              fontFamily: 'serif', fontSize: 20, color: kEmber,
            )),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9.5, color: kMuted)),
          ],
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.onTap, this.primary = false});
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: primary
            ? const LinearGradient(colors: [kDusk, kEmber])
            : null,
          color: primary ? null : Colors.white.withOpacity(0.06),
          border: primary ? null : Border.all(color: kDusk.withOpacity(0.25)),
          boxShadow: primary ? [
            BoxShadow(color: kEmber.withOpacity(0.3), blurRadius: 12, offset: const Offset(0,4)),
          ] : null,
        ),
        child: Center(
          child: Text(label,
            style: TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w500,
              color: primary ? Colors.white : kSand,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Star canvas ───────────────────────────────────────────────
class _StarCanvas extends StatefulWidget {
  const _StarCanvas();

  @override
  State<_StarCanvas> createState() => _StarCanvasState();
}

class _StarCanvasState extends State<_StarCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _rand = Random();
  late List<_StarData> _stars;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(80, (_) => _StarData(_rand));
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _StarPainter(_stars, _ctrl.value),
        child: Container(color: kNight),
      ),
    );
  }
}

class _StarData {
  final double x, y, radius, speed, phase;
  final Color color;

  _StarData(Random r)
    : x      = r.nextDouble(),
      y      = r.nextDouble() * 0.75,
      radius = 0.5 + r.nextDouble() * 1.5,
      speed  = 0.3 + r.nextDouble() * 0.7,
      phase  = r.nextDouble() * 3.14159 * 2,
      color  = [
        const Color(0xFFD4874E), const Color(0xFFE8B86D),
        const Color(0xFFC4756A), const Color(0xFF5A9E8A),
        const Color(0xFFF5EDE0),
      ][r.nextInt(5)];
}

class _StarPainter extends CustomPainter {
  final List<_StarData> stars;
  final double t;
  const _StarPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final opacity = 0.3 + 0.5 * sin(t * 2 * pi * s.speed + s.phase).abs();
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        Paint()..color = s.color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════
// DIYA WALL SCREEN
// ══════════════════════════════════════════════════════════════

class DiyaWallScreen extends StatefulWidget {
  const DiyaWallScreen({super.key});

  @override
  State<DiyaWallScreen> createState() => _DiyaWallScreenState();
}

class _DiyaWallScreenState extends State<DiyaWallScreen> {
  @override
  void initState() {
    super.initState();
    AasmanService.instance.loadDiyas();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AasmanService>(
      builder: (context, svc, _) {
        return Scaffold(
          backgroundColor: kNight,
          appBar: _AasmanAppBar(
            title: 'Diya Wall',
            subtitle: '${svc.skyStats?.starsTonight ?? 247} flames burning tonight',
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20,16,20,4),
                child: Text(
                  'Every flame is a person — anonymous, present, not alone.',
                  style: TextStyle(fontSize: 13, color: kMuted, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: svc.diyas.isEmpty
                  ? _buildEmptyGrid(svc)
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 12,
                      ),
                      itemCount: min(svc.diyas.length + 8, 32),
                      itemBuilder: (_, i) {
                        if (i < svc.diyas.length) {
                          return _DiyaCell(diya: svc.diyas[i], isLit: true);
                        }
                        return _DiyaCell(isLit: false, onTap: () => _showDiyaSheet(context, svc));
                      },
                    ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16,12,16,32),
            decoration: const BoxDecoration(
              color: kNight,
              border: Border(top: BorderSide(color: Color(0x22C4956A))),
            ),
            child: ElevatedButton(
              onPressed: svc.diyaLitToday ? null : () => _showDiyaSheet(context, svc),
              style: ElevatedButton.styleFrom(
                backgroundColor: kEmber,
                disabledBackgroundColor: kMuted.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                svc.diyaLitToday ? '✦ Your Diya is Lit' : '🪔  Light Your Diya',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyGrid(AasmanService svc) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 12,
      ),
      itemCount: 32,
      itemBuilder: (_, i) => _DiyaCell(
        isLit: false,
        onTap: () => _showDiyaSheet(context, svc),
      ),
    );
  }

  void _showDiyaSheet(BuildContext context, AasmanService svc) {
    if (svc.diyaLitToday) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DiyaSheet(svc: svc),
    );
  }
}

class _DiyaCell extends StatelessWidget {
  const _DiyaCell({this.diya, required this.isLit, this.onTap});
  final Diya?       diya;
  final bool        isLit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = diya != null
        ? Color(int.parse(diya!.color.replaceFirst('#', '0xFF')))
        : kMuted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isLit ? color.withOpacity(0.08) : Colors.white.withOpacity(0.03),
          border: Border.all(
            color: isLit ? color.withOpacity(0.35) : kDusk.withOpacity(0.15),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isLit ? '🪔' : '—', style: TextStyle(fontSize: 22, color: isLit ? null : kMuted.withOpacity(0.3))),
            if (isLit && diya != null) ...[
              const SizedBox(height: 4),
              Text(
                diya!.intent.isEmpty ? '🌸' : diya!.intent,
                style: TextStyle(fontSize: 8.5, color: color, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Diya bottom sheet ─────────────────────────────────────────
class _DiyaSheet extends StatefulWidget {
  const _DiyaSheet({required this.svc});
  final AasmanService svc;

  @override
  State<_DiyaSheet> createState() => _DiyaSheetState();
}

class _DiyaSheetState extends State<_DiyaSheet> {
  Color _selectedColor = kEmber;
  final _intentCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _intentCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF14100A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0x22C4956A))),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: kDusk.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 18),
          const Text('Light Your Diya 🪔', style: TextStyle(fontFamily: 'serif', fontSize: 24, color: kSand)),
          const SizedBox(height: 6),
          const Text('Choose a colour and join the sky', style: TextStyle(fontSize: 13, color: kMuted)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: kDiyaColors.map((c) {
              final sel = c == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c,
                    boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)] : null,
                    border: sel ? Border.all(color: Colors.white, width: 2) : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _intentCtrl,
            maxLength: 60,
            style: const TextStyle(fontFamily: 'serif', fontSize: 15, fontStyle: FontStyle.italic, color: kSand),
            decoration: InputDecoration(
              hintText: 'Set an intention (optional)…',
              hintStyle: TextStyle(color: kMuted.withOpacity(0.7), fontStyle: FontStyle.italic),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: kDusk.withOpacity(0.3))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: kDusk.withOpacity(0.25))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kDusk)),
              counterStyle: const TextStyle(color: kMuted),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedColor,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Light & Join the Sky ✦', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final colorHex = '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';
    final result = await widget.svc.lightDiya(
      color:  colorHex,
      intent: _intentCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case AasmanSuccess():
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🪔 Your diya is burning in the sky')),
        );
      case AasmanCrisis(:final response):
        Navigator.pop(context);
        _showCrisisDialog(response);
      case AasmanError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red.shade800),
        );
    }
  }

  void _showCrisisDialog(CrisisResponse cr) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D1F0E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('💛 We\'re here for you', style: TextStyle(color: kSand, fontFamily: 'serif', fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cr.message, style: const TextStyle(color: kSand, fontSize: 13.5, height: 1.6)),
            const SizedBox(height: 16),
            ...cr.resources.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r['name'] ?? '', style: const TextStyle(color: kEmber, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(r['number'] ?? '', style: const TextStyle(color: kSand, fontSize: 13)),
                ])),
              ]),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I understand', style: TextStyle(color: kEmber)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WHISPER SCREEN
// ══════════════════════════════════════════════════════════════

class WhisperScreen extends StatefulWidget {
  const WhisperScreen({super.key});

  @override
  State<WhisperScreen> createState() => _WhisperScreenState();
}

class _WhisperScreenState extends State<WhisperScreen> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    AasmanService.instance.loadWhispers();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<AasmanService>(
      builder: (context, svc, _) => Scaffold(
        backgroundColor: kNight,
        appBar: _AasmanAppBar(
          title: 'Whispers',
          subtitle: 'Anonymous · No replies · Only echoes',
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: svc.whispers.length,
                itemBuilder: (_, i) => _WhisperCard(
                  whisper: svc.whispers[i],
                  onEcho: () => svc.toggleEcho(svc.whispers[i]),
                ),
              ),
            ),
            _WhisperCompose(
              ctrl: _ctrl,
              sent: svc.whisperSentToday,
              onSend: () => _send(svc),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(AasmanService svc) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final result = await svc.sendWhisper(text: text);
    if (!mounted) return;
    switch (result) {
      case AasmanSuccess():
        _ctrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✦ Your whisper joins the sky')),
        );
      case AasmanCrisis(:final response):
        _showCrisisSnack(response.message);
      case AasmanError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
    }
  }

  void _showCrisisSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF4A1515),
        duration: const Duration(seconds: 8),
      ),
    );
  }
}

class _WhisperCard extends StatelessWidget {
  const _WhisperCard({required this.whisper, required this.onEcho});
  final Whisper whisper;
  final VoidCallback onEcho;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.tryParse(whisper.color.replaceFirst('#','0xFF')) ?? 0xFFD4874E);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"${whisper.text}"',
            style: const TextStyle(
              fontFamily: 'serif', fontSize: 16, fontStyle: FontStyle.italic,
              color: kSand, height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onEcho,
                child: Row(
                  children: [
                    Icon(
                      whisper.echoedByMe ? Icons.favorite : Icons.favorite_border,
                      size: 14,
                      color: whisper.echoedByMe ? color : kMuted,
                    ),
                    const SizedBox(width: 5),
                    Text('${whisper.echoes} echoed',
                      style: TextStyle(fontSize: 11, color: whisper.echoedByMe ? color : kMuted),
                    ),
                  ],
                ),
              ),
              Text(whisper.sentAt.length > 10 ? whisper.sentAt.substring(11,16) : whisper.sentAt,
                style: const TextStyle(fontSize: 10.5, color: kMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhisperCompose extends StatefulWidget {
  const _WhisperCompose({required this.ctrl, required this.sent, required this.onSend});
  final TextEditingController ctrl;
  final bool sent;
  final VoidCallback onSend;

  @override
  State<_WhisperCompose> createState() => _WhisperComposeState();
}

class _WhisperComposeState extends State<_WhisperCompose> {
  int _len = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kNight,
        border: Border(top: BorderSide(color: Color(0x22C4956A))),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kDusk.withOpacity(0.25)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: TextField(
              controller: widget.ctrl,
              maxLength: 120,
              enabled: !widget.sent,
              onChanged: (v) => setState(() => _len = v.length),
              style: const TextStyle(fontFamily: 'serif', fontSize: 15, fontStyle: FontStyle.italic, color: kSand),
              decoration: InputDecoration(
                hintText: widget.sent ? 'You whispered today…' : 'Release a thought into the sky…',
                hintStyle: TextStyle(color: kMuted.withOpacity(0.7), fontStyle: FontStyle.italic),
                border: InputBorder.none,
                counterText: '',
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('$_len/120', style: const TextStyle(fontSize: 11, color: kMuted)),
              const Spacer(),
              ElevatedButton(
                onPressed: widget.sent ? null : widget.onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kEmber,
                  disabledBackgroundColor: kMuted.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  elevation: 0,
                ),
                child: const Text('Release ✦', style: TextStyle(color: Colors.white, fontSize: 13.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// RITUAL SCREEN
// ══════════════════════════════════════════════════════════════

class RitualScreen extends StatefulWidget {
  const RitualScreen({super.key});

  @override
  State<RitualScreen> createState() => _RitualScreenState();
}

class _RitualScreenState extends State<RitualScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathCtrl;
  int _phaseIndex = 0;
  final _breathPhases = ['breathe in…', 'hold…', 'breathe out…', 'rest…'];
  final _breathDurations = [4000, 2000, 6000, 2000];

  @override
  void initState() {
    super.initState();
    AasmanService.instance.loadRitual();
    AasmanService.instance.joinRitual();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: false);
    _cycleBreathe();
  }

  void _cycleBreathe() {
    Future.delayed(Duration(milliseconds: _breathDurations[_phaseIndex]), () {
      if (!mounted) return;
      setState(() => _phaseIndex = (_phaseIndex + 1) % _breathPhases.length);
      _cycleBreathe();
    });
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    AasmanService.instance.leaveRitual();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AasmanService>(
      builder: (context, svc, _) {
        final ritual = svc.ritual;
        return Scaffold(
          backgroundColor: kNight,
          appBar: _AasmanAppBar(
            title: 'Evening Ritual',
            subtitle: 'Tonight at 8:00 PM · ${svc.ritualParticipants} gathering',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                const Text('Breathe together',
                  style: TextStyle(fontFamily: 'serif', fontSize: 28, color: kSand, fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Every evening at 8 PM, everyone in Aasman breathes together for 5 minutes. You are never doing this alone.',
                  style: TextStyle(fontSize: 13, color: kMuted, height: 1.65),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Breathing orb
                _BreathingOrb(ctrl: _breathCtrl),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    _breathPhases[_phaseIndex],
                    key: ValueKey(_phaseIndex),
                    style: const TextStyle(fontFamily: 'serif', fontSize: 18, color: kDusk, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 28),

                // Who is here
                _WhoIsHere(count: svc.ritualParticipants),
                const SizedBox(height: 14),

                // Tonight's prompt
                if (ritual?.prompt.isNotEmpty == true) ...[
                  _PromptCard(prompt: ritual!.prompt),
                  const SizedBox(height: 14),
                ],

                // Countdown
                if (ritual != null)
                  _CountdownCard(ritual: ritual),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BreathingOrb extends StatelessWidget {
  const _BreathingOrb({required this.ctrl});
  final AnimationController ctrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ctrl.value;
        final scale = 0.85 + 0.3 * sin(t * pi * 2 * 0.5).abs();
        final glow  = 0.2 + 0.4 * sin(t * pi * 2 * 0.5).abs();
        return Container(
          width: 150, height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: kEmber.withOpacity(glow), blurRadius: 40, spreadRadius: 8),
              BoxShadow(color: kDusk.withOpacity(glow * 0.5), blurRadius: 70, spreadRadius: 16),
            ],
          ),
          child: Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kDeep, kNight],
                  center: const Alignment(-0.3, -0.3),
                ),
                border: Border.all(color: kDusk.withOpacity(0.4)),
              ),
              child: const Center(child: Text('🫁', style: TextStyle(fontSize: 40))),
            ),
          ),
        );
      },
    );
  }
}

class _WhoIsHere extends StatelessWidget {
  const _WhoIsHere({required this.count});
  final int count;

  static const _emojis = ['🌸','🌿','☁️','🌙','⭐','🍃','🌺','🕊️','🌾','🌼'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kDusk.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HERE WITH YOU RIGHT NOW',
            style: TextStyle(fontSize: 10, letterSpacing: 0.08, color: kMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              ..._emojis.map((e) => Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kDeep,
                  border: Border.all(color: kDusk.withOpacity(0.3)),
                ),
                child: Center(child: Text(e, style: const TextStyle(fontSize: 16))),
              )),
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kEmber.withOpacity(0.1),
                  border: Border.all(color: kEmber.withOpacity(0.3)),
                ),
                child: Center(child: Text('+${max(0,count-10)}', style: const TextStyle(fontSize: 10, color: kEmber, fontWeight: FontWeight.w500))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt});
  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kEmber.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kEmber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✦ TONIGHT\'S REFLECTION',
            style: TextStyle(fontSize: 10, letterSpacing: 0.08, color: kEmber),
          ),
          const SizedBox(height: 8),
          Text('"$prompt"',
            style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontStyle: FontStyle.italic, color: kSand, height: 1.65),
          ),
        ],
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.ritual});
  final RitualInfo ritual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDusk.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ritual.isActive ? 'Gathering is live now' : ritual.countdownFormatted,
                style: const TextStyle(fontFamily: 'serif', fontSize: 20, color: kDusk),
              ),
              Text(
                ritual.isActive ? 'Join the breathing ritual' : 'until tonight\'s gathering',
                style: const TextStyle(fontSize: 11, color: kMuted),
              ),
            ],
          ),
          if (ritual.isActive) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kEmber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kEmber.withOpacity(0.3)),
              ),
              child: const Text('Live', style: TextStyle(fontSize: 12, color: kEmber, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared app bar ────────────────────────────────────────────
class _AasmanAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AasmanAppBar({required this.title, required this.subtitle});
  final String title, subtitle;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kNight,
        border: Border(bottom: BorderSide(color: Color(0x22C4956A))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              BackButton(color: kDusk, onPressed: () => Navigator.maybePop(context)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: const TextStyle(fontFamily: 'serif', fontSize: 19, color: kSand, fontWeight: FontWeight.w400),
                  ),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: kMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}