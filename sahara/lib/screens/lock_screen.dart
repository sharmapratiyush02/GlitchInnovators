import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/biometric_service.dart';
import '../theme/sahara_theme.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _shakeCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _shakeAnim;

  bool _isAuthenticating = false;
  bool _failed = false;
  bool _success = false;
  String _errorMsg = '';
  bool _isFace = false;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseAnim = Tween(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _shakeAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    _checkCapabilities();
    // Auto-trigger after short delay
    Future.delayed(const Duration(milliseconds: 600), _authenticate);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkCapabilities() async {
    final face = await BiometricService.instance.isFaceAvailable();
    setState(() => _isFace = face);
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _failed = false;
      _errorMsg = '';
    });

    final result = await BiometricService.instance.authenticate(
      reason: 'Unlock Sahara to access your memories',
    );

    if (!mounted) return;

    if (result == AuthResult.success) {
      setState(() => _success = true);
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onUnlocked();
    } else {
      setState(() {
        _isAuthenticating = false;
        _failed = true;
        _errorMsg =
            BiometricService.instance.describeResult(result);
      });
      _shakeCtrl.forward().then((_) => _shakeCtrl.reset());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1208), Color(0xFF2D1E0A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Spacer(),

                // Logo
                Text(
                  'Sahara',
                  style: GoogleFonts.playfairDisplay(
                    color: SaharaTheme.warmWhite,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your private memory companion',
                  style: GoogleFonts.nunito(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 60),

                // Biometric orb
                AnimatedBuilder(
                  animation: Listenable.merge([_pulseAnim, _shakeAnim]),
                  builder: (ctx, child) {
                    final shake = _failed
                        ? (_shakeAnim.value * 20 *
                                (_shakeAnim.value < 0.5 ? 1 : -1))
                            .clamp(-16.0, 16.0)
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(shake, 0),
                      child: Transform.scale(
                        scale: _pulseAnim.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _success
                          ? SaharaTheme.sage.withOpacity(0.2)
                          : _failed
                              ? SaharaTheme.crisisRed.withOpacity(0.2)
                              : SaharaTheme.ember.withOpacity(0.2),
                      border: Border.all(
                        color: _success
                            ? SaharaTheme.sage
                            : _failed
                                ? SaharaTheme.crisisRed
                                : SaharaTheme.ember,
                        width: 2,
                      ),
                    ),
                    child: _isAuthenticating && !_success
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: SaharaTheme.ember,
                              strokeWidth: 2,
                            ),
                          )
                        : Center(
                            child: Icon(
                              _success
                                  ? Icons.check_circle_outline
                                  : _isFace
                                      ? Icons.face_retouching_natural
                                      : Icons.fingerprint,
                              color: _success
                                  ? SaharaTheme.sage
                                  : _failed
                                      ? SaharaTheme.crisisRed
                                      : SaharaTheme.ember,
                              size: 56,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 28),

                // Status text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _success
                        ? 'Welcome back 🌿'
                        : _failed
                            ? _errorMsg
                            : _isAuthenticating
                                ? 'Verifying...'
                                : _isFace
                                    ? 'Look at your device'
                                    : 'Touch the sensor',
                    key: ValueKey(_errorMsg + _failed.toString()),
                    style: GoogleFonts.nunito(
                      color: _failed
                          ? SaharaTheme.crisisRed
                          : _success
                              ? SaharaTheme.sage
                              : Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(),

                // Retry / Unlock button
                if (_failed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _authenticate,
                      child: Text(
                          _isFace ? 'Try Face ID Again' : 'Try Again'),
                    ),
                  ),

                if (!_failed && !_isAuthenticating)
                  TextButton(
                    onPressed: _authenticate,
                    child: Text(
                      'Tap to unlock',
                      style: GoogleFonts.nunito(
                          color: Colors.white38, fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
