import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'pin_screens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  bool _obscure2 = true;

  final _email = TextEditingController();
  final _pass  = TextEditingController();
  final _pass2 = TextEditingController();

  late AnimationController _starCtrl;
  late AnimationController _floatCtrl;
  late Animation<double>   _floatAnim;
  final List<Map<String, double>> _stars = [];

  @override
  void initState() {
    super.initState();
    _generateStars();
    _starCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _floatCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  void _generateStars() {
    final rng = Random();
    for (int i = 0; i < 60; i++) {
      _stars.add({
        'x':       rng.nextDouble(),
        'y':       rng.nextDouble(),
        'size':    rng.nextDouble() * 1.5 + 0.5,
        'opacity': rng.nextDouble() * 0.6 + 0.2,
        'twinkle': rng.nextDouble(),
      });
    }
  }

  @override
  void dispose() {
    _starCtrl.dispose();
    _floatCtrl.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: err ? kUrgent : kSuccess,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _submit() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      _snack('Please fill all fields', err: true);
      return;
    }
    if (!_isLogin && _pass.text != _pass2.text) {
      _snack('Passwords do not match', err: true);
      return;
    }
    setState(() => _loading = true);
    final endpoint = _isLogin ? '/auth/login' : '/auth/register';
    final res = await Api.post(endpoint, {
      'email':    _email.text.trim(),
      'password': _pass.text,
    });
    setState(() => _loading = false);

    if (res.containsKey('error')) {
      _snack(res['error'], err: true);
      return;
    }

    // Save session
    await Api.setToken(res['token'] ?? '');
    if (res['is_admin'] == true) await Api.setAdmin();

    // Try to save FCM token if available
    try {
      final fcmToken = await Api.getFcmToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await Api.post('/auth/fcm-token', {'fcm_token': fcmToken});
      }
    } catch (_) {}

    if (!mounted) return;
    final hasProfile = await Api.hasProfile();
    final hasPin     = await Api.hasPin();

    if (!hasProfile) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()));
    } else if (hasPin) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const PinUnlockScreen()));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // Animated starfield
          AnimatedBuilder(
            animation: _starCtrl,
            builder: (_, __) => CustomPaint(
              painter: _StarPainter(_stars, _starCtrl.value),
              size: Size.infinite,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Floating planet
                  AnimatedBuilder(
                    animation: _floatCtrl,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: _buildPlanet(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Title
                  const Text('EXAM TRACKER',
                      style: TextStyle(
                        color: kPrimary, fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Welcome back, cosmonaut' : 'Join the mission',
                    style: const TextStyle(
                      color: kText, fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Track · Apply · Succeed',
                      style: TextStyle(color: kTextSub, fontSize: 13)),
                  const SizedBox(height: 28),

                  // Tab toggle
                  Container(
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kCardBorder),
                    ),
                    child: Row(
                      children: [
                        _tabBtn('Login', _isLogin),
                        _tabBtn('Register', !_isLogin),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Fields
                  _field(_email, 'Email', Icons.alternate_email),
                  const SizedBox(height: 12),
                  _field(_pass, 'Password', Icons.lock_outline,
                      obscure: _obscure,
                      toggle: () => setState(() => _obscure = !_obscure)),
                  if (!_isLogin) ...[
                    const SizedBox(height: 12),
                    _field(_pass2, 'Confirm Password', Icons.lock_outline,
                        obscure: _obscure2,
                        toggle: () =>
                            setState(() => _obscure2 = !_obscure2)),
                  ],
                  const SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        disabledBackgroundColor: kPrimary.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _isLogin ? 'Launch 🚀' : 'Create Account 🚀',
                              style: const TextStyle(
                                color: Colors.white, fontSize: 15,
                                fontWeight: FontWeight.w700,
                              )),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? 'New here? Create account'
                          : 'Already have an account? Login',
                      style: const TextStyle(color: kPrimary, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanet() {
    return SizedBox(
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.3, -0.3),
                colors: [Color(0xFF9B7FFF), Color(0xFF3B1FA0)],
              ),
            ),
            child: const Center(
              child: Text('🎓', style: TextStyle(fontSize: 30)),
            ),
          ),
          SizedBox(
            width: 110, height: 28,
            child: CustomPaint(painter: _RingPainter()),
          ),
          const Positioned(
            top: 8, right: 35,
            child: Text('✦', style: TextStyle(color: kPrimary, fontSize: 12)),
          ),
          const Positioned(
            bottom: 10, left: 28,
            child: Text('✦', style: TextStyle(color: kAccent, fontSize: 8)),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isLogin = label == 'Login'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  color: active ? Colors.white : kTextSub,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 14,
                )),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool obscure = false,
    VoidCallback? toggle,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: kText, fontSize: 14),
      keyboardType: hint == 'Email'
          ? TextInputType.emailAddress
          : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kTextSub, fontSize: 14),
        prefixIcon: Icon(icon, color: kTextSub, size: 20),
        suffixIcon: toggle != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: kTextSub, size: 20,
                ),
                onPressed: toggle,
              )
            : null,
        filled: true,
        fillColor: kCard,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: kCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: kCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final List<Map<String, double>> stars;
  final double t;
  _StarPainter(this.stars, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final opacity = s['opacity']! *
          (0.5 + 0.5 * (0.5 + 0.5 * (2 * t - 1).abs()));
      canvas.drawCircle(
          Offset(s['x']! * size.width, s['y']! * size.height),
          s['size']!,
          Paint()..color = Colors.white.withOpacity(opacity.clamp(0.0, 1.0)));
    }
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.15), 70,
        Paint()
          ..color = const Color(0x1A7B61FF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50));
    canvas.drawCircle(
        Offset(size.width * 0.08, size.height * 0.65), 55,
        Paint()
          ..color = const Color(0x123BECA0)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40));
  }
  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width,
            height: size.height),
        Paint()
          ..color = const Color(0x809B7FFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
  }
  @override
  bool shouldRepaint(_RingPainter old) => false;
}