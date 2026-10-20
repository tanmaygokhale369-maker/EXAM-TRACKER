import 'package:flutter/material.dart';
import '../services/api.dart';
import '../utils/constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await Api.get('/notifications/');
    setState(() {
      _notifs = res['notifications'] ?? [];
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    await Api.post('/notifications/scan', {});
    _load();
  }

  Future<void> _delete(int id) async {
    await Api.delete('/notifications/$id');
    _load();
  }

  // ── Helper: color by notification type ─────────────────────────────────
  Color notifTypeColor(String? type) {
    switch (type) {
      case 'urgent':  return kUrgent;
      case 'medium':  return kWarning;
      case 'info':    return kPrimary;
      case 'missed':  return kPink;
      default:        return kAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // Header
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Notifications',
                              style: TextStyle(
                                color: Colors.white, fontSize: 18,
                                fontWeight: FontWeight.w800,
                              )),
                          Text(
                            '${_notifs.where((n) => n['is_read'] == 0).length} unread',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _markAllRead,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: kPrimary.withOpacity(0.4)),
                        ),
                        child: const Text('Mark all read',
                            style: TextStyle(
                              color: kPrimary, fontSize: 11,
                              fontWeight: FontWeight.w600,
                            )),
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
                : _notifs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 48,
                                color: kTextSub.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            const Text('No notifications yet',
                                style: TextStyle(
                                    color: kTextSub, fontSize: 14)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: kPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _notifs.length,
                          itemBuilder: (_, i) => _notifCard(_notifs[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _notifCard(Map<String, dynamic> n) {
    final type     = n['type']?.toString() ?? 'info';
    final priority = n['priority']?.toString() ?? 'low';
    final isRead   = n['is_read'] == 1;
    final typeColor = notifTypeColor(type);

    return Dismissible(
      key: Key('notif_${n['id']}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(n['id']),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: kUrgent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline_rounded,
            color: kUrgent, size: 22),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isRead ? kCard : kCard.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? kCardBorder.withOpacity(0.4)
                : typeColor.withOpacity(0.4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _typeIcon(type),
                  color: typeColor, size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n['title']?.toString() ?? '',
                            style: TextStyle(
                              color: kText,
                              fontSize: 13,
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: typeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n['body']?.toString() ?? '',
                      style: TextStyle(
                        color: kTextSub, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _chip(priority.toUpperCase(),
                            priorityColor(priority)),
                        const SizedBox(width: 6),
                        Text(
                          n['sent_at']?.toString().substring(0, 10) ?? '',
                          style: const TextStyle(
                              color: kTextSub, fontSize: 10),
                        ),
                      ],
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

  IconData _typeIcon(String type) {
    switch (type) {
      case 'urgent': return Icons.warning_amber_rounded;
      case 'medium': return Icons.schedule_rounded;
      case 'missed': return Icons.event_busy_rounded;
      default:       return Icons.notifications_rounded;
    }
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
            color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}