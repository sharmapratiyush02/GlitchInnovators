import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/biometric_service.dart';
import 'lock_screen.dart';

class AuthGate extends StatefulWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initLock() async {
    final enabled = await BiometricService.instance.isEnabled();
    setState(() {
      _isLocked = enabled;
      _initialised = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // Record time of backgrounding
    } else if (state == AppLifecycleState.resumed) {
      _checkRelock();
    }
  }

  Future<void> _checkRelock() async {
    final enabled = await BiometricService.instance.isEnabled();
    if (!enabled) return;
    final should = await BiometricService.instance.shouldRelock();
    if (should && mounted) {
      setState(() => _isLocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialised) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isLocked) {
      return LockScreen(
        onUnlocked: () => setState(() => _isLocked = false),
      );
    }

    return widget.child;
  }
}
