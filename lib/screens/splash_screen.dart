import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'pin_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;
  final List<Map<String, double>> _stars = [];

  @override
  void initState() {
    super.initState();
    _generateStars();
    _rotateCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 12),
    )..repeat();
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  void _generateStars() {
    final rng = Random();
    for (int i = 0; i < 100; i++) {
      _stars.add({
        'x': rng.nextDouble(),
        'y': rng.nextDouble(),
        'size': rng.nextDouble() * 2 + 0.5,
        'opacity': rng.nextDouble() * 0.7 + 0.2,
      });
    }
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final loggedIn = await Api.isLoggedIn();
    if (!loggedIn) {
      _go(const LoginScreen());
      return;
    }
    final hasProfile = await Api.hasProfile();
    if (!hasProfile) { _go(const ProfileScreen()); return; }
    final hasPin = await Api.hasPin();
    final pinPassed = await Api.pinPassed();
    if (hasPin && !pinPassed) { _go(const PinUnlockScreen()); return; }
    _go(const HomeScreen());
  }

  void _go(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // Stars
          CustomPaint(
            painter: _SplashStarPainter(_stars),
            size: Size.infinite,
          ),
          // Nebula blobs
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimary.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -60, left: -60,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAccent.withOpacity(0.04),
              ),
            ),
          ),
          // Center content
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rotating orbit ring + planet
                  AnimatedBuilder(
                    animation: _rotateCtrl,
                    builder: (_, __) {
                      return SizedBox(
                        width: 140, height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Orbit ring
                            Transform.rotate(
                              angle: _rotateCtrl.value * 2 * pi,
                              child: Container(
                                width: 130, height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: kPrimary.withOpacity(0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 0, left: 55,
                                      child: Container(
                                        width: 10, height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: kAccent,
                                          boxShadow: [
                                            BoxShadow(
                                              color: kAccent.withOpacity(0.8),
                                              blurRadius: 8,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Planet
                            AnimatedBuilder(
                              animation: _pulseCtrl,
                              builder: (_, __) => Transform.scale(
                                scale: _pulseAnim.value,
                                child: Container(
                                  width: 80, height: 80,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      center: Alignment(-0.3, -0.3),
                                      colors: [
                                        Color(0xFF9B7FFF),
                                        Color(0xFF3B1FA0),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text('🎓',
                                        style: TextStyle(fontSize: 32)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text('EXAM TRACKER',
                      style: TextStyle(
                        color: kPrimary, fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      )),
                  const SizedBox(height: 8),
                  const Text('Track · Apply · Succeed',
                      style: TextStyle(
                        color: kTextSub, fontSize: 14,
                        letterSpacing: 1,
                      )),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      color: kPrimary.withOpacity(0.6),
                      strokeWidth: 1.5,
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

class _SplashStarPainter extends CustomPainter {
  final List<Map<String, double>> stars;
  _SplashStarPainter(this.stars);
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      canvas.drawCircle(
          Offset(s['x']! * size.width, s['y']! * size.height),
          s['size']!,
          Paint()..color = Colors.white.withOpacity(s['opacity']!));
    }
  }
  @override
  bool shouldRepaint(_SplashStarPainter old) => false;
}