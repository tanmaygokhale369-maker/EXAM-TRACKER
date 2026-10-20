import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class PinKeypad extends StatefulWidget {
  final Future<void> Function(String pin) onComplete;
  final String? error;
  const PinKeypad({super.key, required this.onComplete, this.error});
  @override
  State<PinKeypad> createState() => _PinKeypadState();
}

class _PinKeypadState extends State<PinKeypad> {
  String _pin = '';
  bool _busy = false;

  Future<void> _tap(String digit) async {
    if (_busy || _pin.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += digit);
    if (_pin.length == 4) {
      setState(() => _busy = true);
      await widget.onComplete(_pin);
      if (!mounted) return;
      setState(() { _pin = ''; _busy = false; });
    }
  }

  void _backspace() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < _pin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18, height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: filled ? kAccent : Colors.transparent,
                border: Border.all(color: kAccent, width: 2),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        if (widget.error != null)
          Text(widget.error!, style: const TextStyle(color: kUrgent, fontSize: 13)),
        const SizedBox(height: 28),
        _row(['1','2','3']),
        _row(['4','5','6']),
        _row(['7','8','9']),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 72, height: 72),
            _btn('0'),
            SizedBox(
              width: 72, height: 72,
              child: IconButton(
                onPressed: _backspace,
                icon: const Icon(Icons.backspace_outlined, color: Colors.white70),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(List<String> digits) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: digits.map(_btn).toList(),
  );

  Widget _btn(String d) => Container(
    width: 72, height: 72,
    margin: const EdgeInsets.all(6),
    child: Material(
      color: Colors.white.withOpacity(0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _tap(d),
        child: Center(
          child: Text(d, style: const TextStyle(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.w300)),
        ),
      ),
    ),
  );
}

// ── PIN SETUP ─────────────────────────────────────────────────────────
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});
  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String? _firstPin;
  String? _error;

  Future<void> _handle(String pin) async {
    if (_firstPin == null) {
      setState(() { _firstPin = pin; _error = null; });
      return;
    }
    if (pin != _firstPin) {
      setState(() { _error = 'PINs do not match. Try again.'; _firstPin = null; });
      return;
    }
    final res = await Api.post('/auth/set-pin', {'pin': pin});
    if (!mounted) return;
    if (res.containsKey('error')) {
      setState(() { _error = res['error']; _firstPin = null; });
      return;
    }
    await Api.setHasPin(true);
    await Api.setPinPassed(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN set!'), backgroundColor: kSuccess));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: kHeaderGradient,
              begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            const Spacer(),
            const Icon(Icons.lock_rounded, size: 48, color: kAccent),
            const SizedBox(height: 16),
            Text(
              _firstPin == null ? 'Create a 4-digit PIN' : 'Confirm your PIN',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('Use this to quickly unlock the app',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 40),
            PinKeypad(onComplete: _handle, error: _error),
            const Spacer(flex: 2),
          ]),
        ),
      ),
    );
  }
}

// ── PIN UNLOCK ────────────────────────────────────────────────────────
class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});
  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  String? _error;
  int _attempts = 0;

  Future<void> _verify(String pin) async {
    final res = await Api.post('/auth/verify-pin', {'pin': pin});
    if (!mounted) return;
    if (res.containsKey('error')) {
      _attempts++;
      setState(() => _error = _attempts >= 3
          ? 'Too many wrong attempts.'
          : 'Wrong PIN. ${3 - _attempts} attempt(s) left.');
      if (_attempts >= 5) {
        await Api.clearSession();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }
    await Api.setPinPassed(true);
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: kHeaderGradient,
              begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SafeArea(
          child: Column(children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded, size: 40, color: kAccent),
            ),
            const SizedBox(height: 20),
            const Text('Welcome back',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Enter your PIN to continue',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 40),
            PinKeypad(onComplete: _verify, error: _error),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                await Api.clearSession();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Use password instead',
                  style: TextStyle(color: kAccent)),
            ),
            const Spacer(),
          ]),
        ),
      ),
    );
  }
}