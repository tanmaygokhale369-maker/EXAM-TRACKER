import 'dart:math';
import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../services/api.dart';
import '../utils/constants.dart';
import '../utils/url_helper.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'calendar_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _tab = 0;
  bool _loading = true;
  String _userName = '';
  String _userStream = '';
  bool _isAdmin = false;
  int _unread = 0;

  // Exam lists
  List<Exam> _urgent = [];
  List<Exam> _upcoming = [];
  List<Exam> _allExams = [];
  List<Exam> _eligible = [];
  List<Exam> _insights = [];

  // Animation controllers
  late AnimationController _starCtrl;
  late AnimationController _rocketCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _rocketAnim;
  late Animation<double> _pulseAnim;

  // Stars data
  final List<Map<String, double>> _stars = [];

  @override
  void initState() {
    super.initState();
    _generateStars();
    _initAnimations();
    _loadAll();
  }

  void _generateStars() {
    final rng = Random();
    for (int i = 0; i < 80; i++) {
      _stars.add({
        'x': rng.nextDouble(),
        'y': rng.nextDouble() * 0.6,
        'size': rng.nextDouble() * 2 + 0.5,
        'opacity': rng.nextDouble() * 0.7 + 0.2,
        'twinkle': rng.nextDouble(),
      });
    }
  }

  void _initAnimations() {
    _starCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _rocketCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rocketAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _rocketCtrl, curve: Curves.easeInOut),
    );

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _starCtrl.dispose();
    _rocketCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        Api.get('/dashboard/'),
        Api.get('/exams/'),
        Api.get('/exams/eligible'),
        Api.get('/insights/daily'),
        Api.get('/notifications/'),
        Api.get('/profile/'),
      ]);

      final dash = results[0];
      final allRaw = results[1];
      final eligRaw = results[2];
      final insRaw = results[3];
      final notifs = results[4];
      final profile = results[5];

      setState(() {
        _urgent = (dash['urgent'] as List? ?? [])
            .map((e) => Exam.fromJson(e)).toList();
        _upcoming = (dash['upcoming'] as List? ?? [])
            .map((e) => Exam.fromJson(e)).toList();
        _allExams = (allRaw['exams'] as List? ?? [])
            .map((e) => Exam.fromJson(e)).toList();
        _eligible = (eligRaw['exams'] as List? ?? [])
            .map((e) => Exam.fromJson(e)).toList();
        _insights = (insRaw['insights'] as List? ?? [])
            .map((e) => Exam.fromJson(e)).toList();
        _unread = (notifs['notifications'] as List? ?? [])
            .where((n) => n['is_read'] == 0).length;
        _userName = profile['full_name'] ?? 'Student';
        _userStream = profile['stream'] ?? '';
        _loading = false;
      });
      _isAdmin = await Api.isAdmin();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // Animated starfield background
          _buildStarfield(),
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _loading
                      ? _buildLoader()
                      : IndexedStack(
                          index: _tab,
                          children: [
                            _buildDashboard(),
                            _buildExamsList(_eligible, 'Eligible Exams'),
                            _buildExamsList(_allExams, 'All Exams'),
                            _buildInsights(),
                          ],
                        ),
                ),
                _buildNavBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Starfield ──────────────────────────────────────────────────────────
  Widget _buildStarfield() {
    return AnimatedBuilder(
      animation: _starCtrl,
      builder: (_, __) {
        return CustomPaint(
          painter: _StarfieldPainter(_stars, _starCtrl.value),
          size: Size.infinite,
        );
      },
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Logo + greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('✦ ', style: TextStyle(color: kPrimary, fontSize: 14)),
                    Text('EXAM TRACKER',
                        style: TextStyle(
                          color: kPrimary, fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        )),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Hello, ${_userName.split(' ').first} 👋',
                  style: const TextStyle(
                    color: kText, fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Stream chip
          if (_userStream.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPrimary.withOpacity(0.4)),
              ),
              child: Text(_userStream,
                  style: const TextStyle(
                    color: kPrimary, fontSize: 11,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          // Notification bell
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            child: Stack(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kCardBorder),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: kText, size: 20),
                ),
                if (_unread > 0)
                  Positioned(
                    top: 4, right: 4,
                    child: Container(
                      width: 14, height: 14,
                      decoration: const BoxDecoration(
                        color: kUrgent, shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('$_unread',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 8,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kCardBorder),
              ),
              child: const Icon(Icons.settings_outlined, color: kTextSub, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _statChip('${_urgent.length}', 'Urgent', kUrgent),
          const SizedBox(width: 8),
          _statChip('${_eligible.length}', 'Eligible', kAccent),
          const SizedBox(width: 8),
          _statChip('${_allExams.length}', 'Total', kPrimary),
        ],
      ),
    );
  }

  Widget _statChip(String n, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(n,
                style: TextStyle(
                  color: color, fontSize: 20,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 10, fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  // ── Dashboard ─────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: kPrimary,
      backgroundColor: kCard,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          _buildStatsRow(),
          if (_urgent.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionLabel('🚀  LAUNCH NOW', kUrgent),
            const SizedBox(height: 8),
            ..._urgent.map((e) => _buildRocketCard(e)),
          ],
          if (_upcoming.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionLabel('✦  ELIGIBLE UPCOMING', kAccent),
            const SizedBox(height: 8),
            ..._upcoming.map((e) => _buildExamCard(e)),
          ],
          if (_urgent.isEmpty && _upcoming.isEmpty)
            _buildEmptyState(),
        ],
      ),
    );
  }

  // ── Rocket Card (Urgent) ──────────────────────────────────────────────
  Widget _buildRocketCard(Exam exam) {
    final days = exam.daysLeft;
    return GestureDetector(
      onTap: () => _showDetail(exam),
      child: AnimatedBuilder(
        animation: _rocketCtrl,
        builder: (_, __) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x44FF6B6B), Color(0x110D1528)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kUrgent.withOpacity(0.5), width: 1),
            ),
            child: Stack(
              children: [
                // Glow orb
                Positioned(
                  right: -20, top: -20,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kUrgent.withOpacity(0.08),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Animated rocket
                      Transform.translate(
                        offset: Offset(0, _rocketAnim.value),
                        child: _buildRocketWidget(),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: kUrgent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('LAUNCH NOW',
                                      style: TextStyle(
                                        color: kUrgent, fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      )),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(exam.name,
                                style: const TextStyle(
                                  color: kText, fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(
                              '${exam.category}  ·  ${exam.mode}',
                              style: const TextStyle(
                                  color: kTextSub, fontSize: 11),
                            ),
                            if (exam.myFee != null && exam.myFee! > 0) ...[
                              const SizedBox(height: 4),
                              Text('₹${exam.myFee!.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: kAccent, fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                            const SizedBox(height: 8),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: days <= 0 ? 1.0 : (30 - days) / 30,
                                backgroundColor: kUrgent.withOpacity(0.15),
                                valueColor: const AlwaysStoppedAnimation(kUrgent),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Days countdown
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: kUrgent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: kUrgent.withOpacity(0.5)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  days <= 0 ? '0' : '$days',
                                  style: const TextStyle(
                                    color: kUrgent, fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  days == 1 ? 'day' : 'days',
                                  style: const TextStyle(
                                    color: kUrgent, fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRocketWidget() {
    return SizedBox(
      width: 44, height: 60,
      child: CustomPaint(painter: _RocketPainter()),
    );
  }

  // ── Exam Card ────────────────────────────────────────────────────────
  Widget _buildExamCard(Exam exam, {bool showEligBadge = false}) {
    final color = categoryColor(exam.category);
    final days = exam.daysLeft;
    final isUrgent = days <= 7 && days >= 0;

    return GestureDetector(
      onTap: () => _showDetail(exam),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUrgent
                ? kUrgent.withOpacity(0.4)
                : kCardBorder.withOpacity(0.6),
          ),
        ),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 4, height: 62,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16)),
              ),
            ),
            const SizedBox(width: 12),
            // Emoji icon
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  categoryEmoji(exam.category),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam.name,
                        style: const TextStyle(
                          color: kText, fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(exam.category ?? '',
                            style: const TextStyle(
                                color: kTextSub, fontSize: 10)),
                        if (exam.myFee != null && exam.myFee! > 0) ...[
                          Text('  ·  ',
                              style: const TextStyle(
                                  color: kTextSub, fontSize: 10)),
                          Text('₹${exam.myFee!.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                        if (showEligBadge && (exam.isEligible ?? false)) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: kAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('✓ Eligible',
                                style: TextStyle(
                                  color: kAccent, fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Days badge
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _daysColor(days).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _daysColor(days).withOpacity(0.3)),
                ),
                child: Text(
                  days < 0
                      ? 'Missed'
                      : days == 0
                          ? 'Today!'
                          : '${days}d',
                  style: TextStyle(
                    color: _daysColor(days),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _daysColor(int days) {
    if (days < 0) return kTextSub;
    if (days <= 3) return kUrgent;
    if (days <= 7) return kWarning;
    return kAccent;
  }

  // ── Exams List Tab ────────────────────────────────────────────────────
  Widget _buildExamsList(List<Exam> list, String title) {
    if (list.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
      itemCount: list.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) return _sectionLabel('✦  $title', kPrimary);
        final exam = list[i - 1];
        return _buildExamCard(exam, showEligBadge: true);
      },
    );
  }

  // ── Insights Tab ──────────────────────────────────────────────────────
  Widget _buildInsights() {
    if (_insights.isEmpty) return _buildEmptyState();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        _sectionLabel('✦  DAILY INSIGHTS', kAccent),
        const SizedBox(height: 4),
        Text(
          'Personalized for $_userStream stream',
          style: const TextStyle(color: kTextSub, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ..._insights.asMap().entries.map((entry) {
          final i = entry.key;
          final exam = entry.value;
          final color = categoryColor(exam.category);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline dot + line
                Column(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: color.withOpacity(0.5), blurRadius: 6),
                        ],
                      ),
                    ),
                    if (i < _insights.length - 1)
                      Container(
                        width: 1.5, height: 50,
                        color: kCardBorder,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Card
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showDetail(exam),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(exam.name,
                                    style: const TextStyle(
                                      color: kText, fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 3),
                                Text(
                                  '${exam.category}  ·  ${exam.daysLeft}d left',
                                  style: const TextStyle(
                                      color: kTextSub, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            categoryEmoji(exam.category),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────
  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          Text(text,
              style: TextStyle(
                color: color, fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              )),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: color.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🌌', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('All clear, cosmonaut!',
              style: TextStyle(
                color: kText, fontSize: 18,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          const Text('No exams match your profile right now.',
              style: TextStyle(color: kTextSub, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Loader ────────────────────────────────────────────────────────────
  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(
              color: kPrimary,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Scanning the cosmos...',
              style: TextStyle(color: kTextSub, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Nav Bar ───────────────────────────────────────────────────────────
  Widget _buildNavBar() {
    final items = [
      {'icon': Icons.rocket_launch_outlined, 'label': 'Home'},
      {'icon': Icons.verified_outlined, 'label': 'Eligible'},
      {'icon': Icons.grid_view_outlined, 'label': 'All'},
      {'icon': Icons.wb_sunny_outlined, 'label': 'Daily'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: kNavBg,
        border: Border(top: BorderSide(color: kCardBorder, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final active = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _tab = i);
                if (i == 1 && _eligible.isEmpty) _loadAll();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: active ? kPrimary : kTextSub,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: active ? kPrimary : kTextSub,
                      fontSize: 10,
                      fontWeight: active
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (active)
                    Container(
                      width: 20, height: 2,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(1),
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

  // ── Exam Detail Sheet ─────────────────────────────────────────────────
  void _showDetail(Exam exam) {
    final color = categoryColor(exam.category);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, sc) => Container(
          decoration: BoxDecoration(
            color: kBgMid,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: kCardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: color.withOpacity(0.4)),
                          ),
                          child: Center(
                            child: Text(categoryEmoji(exam.category),
                                style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exam.name,
                                  style: const TextStyle(
                                    color: kText, fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  )),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _detailChip(exam.category ?? '', color),
                                  const SizedBox(width: 6),
                                  _detailChip(exam.mode ?? 'Online',
                                      kTextSub),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Days left big badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.15),
                            color.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _infoItem('Last Date',
                              exam.lastDate?.toString().substring(0, 10) ?? '-',
                              color),
                          _infoItem('Days Left',
                              exam.daysLeft < 0
                                  ? 'Missed'
                                  : '${exam.daysLeft}d',
                              exam.daysLeft <= 3 ? kUrgent : color),
                          _infoItem('Seats',
                              exam.seats > 0 ? '${exam.seats}' : 'Open',
                              kTextSub),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fee table
                    if (_hasFees(exam)) ...[
                      Text('Fee Structure',
                          style: TextStyle(
                            color: kText, fontSize: 14,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 8),
                      _buildFeeTable(exam),
                      const SizedBox(height: 16),
                    ],

                    // Eligibility note
                    if (exam.eligibilityNote != null &&
                        exam.eligibilityNote!.isNotEmpty) ...[
                      Text('Eligibility',
                          style: TextStyle(
                            color: kText, fontSize: 14,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: kPrimary.withOpacity(0.2)),
                        ),
                        child: Text(exam.eligibilityNote!,
                            style: const TextStyle(
                                color: kTextSub, fontSize: 13)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Apply button
                    if (exam.website != null && exam.website!.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => openUrl(exam.website!),
                          icon: const Icon(Icons.rocket_launch_rounded,
                              size: 18),
                          label: const Text('Apply Now →',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              )),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
            color: color, fontSize: 10,
            fontWeight: FontWeight.w600,
          )),
    );
  }

  Widget _infoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              color: color, fontSize: 16,
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: kTextSub, fontSize: 10)),
      ],
    );
  }

  bool _hasFees(Exam exam) {
    return (exam.fees?.values.any((v) => v > 0) ?? false);
  }

  Widget _buildFeeTable(Exam exam) {
    final categories = [
      ['General', exam.fees?['general'] ?? 0],
      ['OBC', exam.fees?['obc'] ?? 0],
      ['SC', exam.fees?['sc'] ?? 0],
      ['ST', exam.fees?['st'] ?? 0],
      ['PwD', exam.fees?['pwd'] ?? 0],
      ['Female', exam.fees?['female'] ?? 0],
    ];
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCardBorder),
      ),
      child: Column(
        children: categories.asMap().entries.map((entry) {
          final i = entry.key;
          final cat = entry.value;
          final fee = (cat[1] as num).toDouble();
          final isYours = exam.myFee == fee && fee > 0;
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isYours
                  ? kAccent.withOpacity(0.08)
                  : (i % 2 == 0
                      ? Colors.transparent
                      : kCardBorder.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(i == 0
                  ? 12
                  : i == categories.length - 1
                      ? 12
                      : 0),
            ),
            child: Row(
              children: [
                Text(cat[0] as String,
                    style: TextStyle(
                      color: isYours ? kAccent : kTextSub,
                      fontSize: 13,
                      fontWeight: isYours
                          ? FontWeight.w700
                          : FontWeight.w400,
                    )),
                if (isYours) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: kAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('YOURS',
                        style: TextStyle(
                          color: kAccent, fontSize: 9,
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                ],
                const Spacer(),
                Text(
                  fee <= 0 ? 'Free' : '₹${fee.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isYours ? kAccent : kText,
                    fontSize: 13,
                    fontWeight: isYours
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Starfield Painter ─────────────────────────────────────────────────────
class _StarfieldPainter extends CustomPainter {
  final List<Map<String, double>> stars;
  final double animValue;

  _StarfieldPainter(this.stars, this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final twinkle = star['twinkle']!;
      final opacity = star['opacity']! *
          (0.6 + 0.4 * sin((animValue + twinkle) * pi));
      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity.clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(star['x']! * size.width, star['y']! * size.height),
        star['size']!,
        paint,
      );
    }

    // Nebula glow (purple)
    final nebulaPaint = Paint()
      ..color = const Color(0x157B61FF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.15), 120, nebulaPaint);

    // Nebula glow (teal)
    final tealPaint = Paint()
      ..color = const Color(0x0F3BECA0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.4), 100, tealPaint);
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => old.animValue != animValue;
}

// ── Rocket Painter ────────────────────────────────────────────────────────
class _RocketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // Body
    final bodyPaint = Paint()..color = const Color(0xFFFF8C94);
    final bodyPath = Path()
      ..moveTo(cx, 2)
      ..quadraticBezierTo(cx + 12, 20, cx + 12, 36)
      ..lineTo(cx - 12, 36)
      ..quadraticBezierTo(cx - 12, 20, cx, 2)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Window
    final windowPaint = Paint()
      ..color = const Color(0xFF0D1528)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, 20), 6, windowPaint);
    final windowRimPaint = Paint()
      ..color = const Color(0xFF7B61FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, 20), 6, windowRimPaint);

    // Left fin
    final finPaint = Paint()..color = const Color(0xFFFF4D5E);
    final leftFin = Path()
      ..moveTo(cx - 12, 28)
      ..lineTo(cx - 22, 40)
      ..lineTo(cx - 12, 38)
      ..close();
    canvas.drawPath(leftFin, finPaint);

    // Right fin
    final rightFin = Path()
      ..moveTo(cx + 12, 28)
      ..lineTo(cx + 22, 40)
      ..lineTo(cx + 12, 38)
      ..close();
    canvas.drawPath(rightFin, finPaint);

    // Fire
    final fire1 = Paint()
      ..color = const Color(0xFFF6AD55).withOpacity(0.85);
    final fire2 = Paint()..color = const Color(0xFFFED7AA);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 4, 44), width: 7, height: 12),
        fire1);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 4, 44), width: 7, height: 12),
        fire1);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, 46), width: 5, height: 9),
        fire2);
  }

  @override
  bool shouldRepaint(_RocketPainter old) => false;
}