import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api.dart';
import '../models/exam.dart';
import '../utils/constants.dart';
import '../utils/url_helper.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused   = DateTime.now();
  DateTime? _selected = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;
  final Map<DateTime, List<Exam>> _eventsMap = {};
  List<Exam> _eligibleExams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await Api.get('/exams/eligible');
    if (!mounted) return;

    final eligible = (res['eligible'] as List? ?? [])
        .map((e) => Exam.fromJson(e as Map<String, dynamic>))
        .toList();

    _eventsMap.clear();
    for (final e in eligible) {
      if (e.lastDate.isEmpty) continue;
      try {
        final d   = DateTime.parse(e.lastDate);
        final key = DateTime(d.year, d.month, d.day);
        _eventsMap.putIfAbsent(key, () => []).add(e);
      } catch (_) {}
    }

    setState(() {
      _eligibleExams = eligible;
      _loading = false;
    });
  }

  List<Exam> _eventsForDay(DateTime day) =>
      _eventsMap[DateTime(day.year, day.month, day.day)] ?? [];

  @override
  Widget build(BuildContext context) {
    final selected = _selected == null ? <Exam>[] : _eventsForDay(_selected!);

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // Custom header (replaces AppBar to avoid flexibleSpace issues)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: kHeaderGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    // Back button (only when pushed as separate screen)
                    if (Navigator.canPop(context))
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36, height: 36,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Eligible Exam Calendar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          Text(
                            '${_eligibleExams.length} eligible exams tracked',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Refresh button
                    GestureDetector(
                      onTap: _load,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimary))
                : Column(
                    children: [
                      // Info banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        color: kSuccess.withOpacity(0.08),
                        child: Row(children: [
                          const Icon(Icons.verified_rounded,
                              size: 16, color: kSuccess),
                          const SizedBox(width: 8),
                          Text(
                            'Showing ${_eligibleExams.length} exams you are eligible for',
                            style: const TextStyle(
                                color: kSuccess,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ]),
                      ),
                      // Calendar
                      _calendarWidget(),
                      // Day list
                      Expanded(child: _dayList(selected)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _calendarWidget() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TableCalendar<Exam>(
        firstDay: DateTime(2020),
        lastDay: DateTime(2030, 12, 31),
        focusedDay: _focused,
        selectedDayPredicate: (d) =>
            _selected != null && isSameDay(_selected, d),
        onDaySelected: (sel, focus) =>
            setState(() {
              _selected = sel;
              _focused  = focus;
            }),
        eventLoader: _eventsForDay,
        calendarFormat: _format,
        onFormatChanged: (f) => setState(() => _format = f),
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(10),
          ),
          formatButtonTextStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
          titleTextStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: kText),
          leftChevronIcon:
              const Icon(Icons.chevron_left_rounded, color: kPrimary),
          rightChevronIcon:
              const Icon(Icons.chevron_right_rounded, color: kPrimary),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
              color: kAccent.withOpacity(0.35), shape: BoxShape.circle),
          selectedDecoration: const BoxDecoration(
              gradient: LinearGradient(colors: kPrimaryGradient),
              shape: BoxShape.circle),
          markerDecoration:
              const BoxDecoration(color: kUrgent, shape: BoxShape.circle),
          markersMaxCount: 3,
          weekendTextStyle: const TextStyle(color: kPink),
          outsideDaysVisible: false,
        ),
      ),
    );
  }

  Widget _dayList(List<Exam> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded,
                size: 48, color: kMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              _selected == null
                  ? 'Select a date to see eligible deadlines'
                  : 'No eligible exams closing on '
                    '${_selected!.day}/${_selected!.month}/${_selected!.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text('${_eligibleExams.length} eligible exams total',
                style: const TextStyle(color: kMuted, fontSize: 11)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            const Icon(Icons.event_rounded, size: 16, color: kPrimary),
            const SizedBox(width: 6),
            Text(
              'Deadlines — ${events.length} exam(s)',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: kText, fontSize: 14),
            ),
          ]),
        ),
        ...events.map(_eventCard),
      ],
    );
  }

  Widget _eventCard(Exam e) {
    final gradients = {
      'high':   [const Color(0xFFFF6B6B), const Color(0xFFEE0979)],
      'medium': [const Color(0xFFFFB347), const Color(0xFFFF8C00)],
      'low':    [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    };
    final g = gradients[e.priority] ?? gradients['low']!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: g[0].withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: g[0].withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: [
        // Gradient top bar
        Container(
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: g),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: g,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(categoryIcon(e.category),
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: kText,
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.schedule_rounded,
                            size: 12, color: g[0]),
                        const SizedBox(width: 4),
                        Text(e.label,
                            style: TextStyle(
                                color: g[0],
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ]),
                    ],
                  ),
                ),
                // Days badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: g),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(children: [
                    Text('${e.days}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const Text('days',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 9)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              // Info chips
              Row(children: [
                _chip(Icons.currency_rupee_rounded,
                    e.myFee == 0 ? 'Free' : '₹${e.myFee.toInt()}',
                    kSuccess),
                const SizedBox(width: 8),
                if (e.seats > 0)
                  _chip(Icons.people_rounded, _fmtSeats(e.seats), kPrimary),
                const SizedBox(width: 8),
                _chip(Icons.computer_rounded, e.mode, kMuted),
              ]),
              // Apply Now button
              if (e.website.isNotEmpty) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async => await openUrl(e.website),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: g),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_browser_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text('Apply Now',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      );

  String _fmtSeats(int s) {
    if (s >= 100000) return '${(s / 100000).toStringAsFixed(1)}L';
    if (s >= 1000)   return '${(s / 1000).toStringAsFixed(0)}K';
    return '$s';
  }
}