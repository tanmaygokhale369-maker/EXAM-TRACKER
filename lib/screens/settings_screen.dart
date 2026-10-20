import 'package:flutter/material.dart';
import '../services/api.dart';
import '../utils/constants.dart';
import 'pin_screens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic> _prefs = {};
  bool _loading = true;
  bool _hasPin = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await Api.get('/preferences/');
    final hasPin = await Api.hasPin();
    if (!mounted) return;
    setState(() {
      _prefs = Map<String, dynamic>.from(res['preferences'] ?? {});
      _hasPin = hasPin;
      _loading = false;
    });
  }

  Future<void> _toggle(String key, bool value) async {
    setState(() => _prefs[key] = value ? 1 : 0);
    await Api.post('/preferences/', {key: value});
  }

  Future<void> _setPin() async {
    final ok = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const PinSetupScreen()));
    if (ok == true && mounted) setState(() => _hasPin = true);
  }

  Future<void> _removePin() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove PIN?'),
        content: const Text('You will need your password to log in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove', style: TextStyle(color: kUrgent))),
        ],
      ),
    );
    if (sure != true) return;
    await Api.post('/auth/remove-pin', {});
    await Api.setHasPin(false);
    if (!mounted) return;
    setState(() => _hasPin = false);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN removed'), backgroundColor: kSuccess));
  }

  Future<void> _logout() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log out', style: TextStyle(color: kUrgent))),
        ],
      ),
    );
    if (sure != true) return;
    await Api.clearSession();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kDark1,
        foregroundColor: Colors.white,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: kHeaderGradient,
                begin: Alignment.topLeft, end: Alignment.bottomRight)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header('Alert Priority', 'Choose which alerts you want'),
                _switch(Icons.warning_amber_rounded, kUrgent,
                    'Urgent alerts', '1-3 days', 'alert_urgent'),
                _switch(Icons.event_rounded, kWarning,
                    'Medium alerts', '4-7 days', 'alert_medium'),
                _switch(Icons.info_outline_rounded, kSuccess,
                    'Low alerts', '8+ days', 'alert_low'),
                _switch(Icons.event_busy_rounded, kPink,
                    'Missed alerts', 'Past deadline', 'alert_missed'),
                _switch(Icons.wb_sunny_rounded, kPrimary,
                    'Daily summary', 'Morning & evening digest', 'daily_summary'),
                const SizedBox(height: 24),
                _header('Security', 'Quick unlock with a 4-digit PIN'),
                Container(
                  decoration: BoxDecoration(color: kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBorder)),
                  child: Column(children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.lock_rounded, color: kPrimary),
                      ),
                      title: Text(_hasPin ? 'PIN enabled' : 'Set a PIN'),
                      subtitle: Text(_hasPin ? 'Required on app open' : 'Not set up yet'),
                      trailing: Icon(
                        _hasPin ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                        color: _hasPin ? kSuccess : kMuted,
                      ),
                      onTap: _hasPin ? null : _setPin,
                    ),
                    if (_hasPin) ...[
                      Container(color: kBorder.withOpacity(0.3), height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kUrgent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.lock_open_rounded, color: kUrgent),
                        ),
                        title: const Text('Remove PIN', style: TextStyle(color: kUrgent)),
                        onTap: _removePin,
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 24),
                _header('Account', ''),
                Container(
                  decoration: BoxDecoration(color: kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBorder)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kUrgent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.logout_rounded, color: kUrgent),
                    ),
                    title: const Text('Log out', style: TextStyle(color: kUrgent)),
                    onTap: _logout,
                  ),
                ),
                const SizedBox(height: 32),
                const Center(child: Text('Exam Tracker v2.0',
                    style: TextStyle(color: kMuted, fontSize: 12))),
              ],
            ),
    );
  }

  Widget _header(String title, String sub) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800, color: kText)),
      if (sub.isNotEmpty)
        Text(sub, style: const TextStyle(color: kMuted, fontSize: 12)),
    ]),
  );

  Widget _switch(IconData icon, Color color, String title, String sub, String key) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: kCard,
          borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
      child: SwitchListTile(
        activeColor: color,
        value: (_prefs[key] ?? 1) == 1,
        onChanged: (v) => _toggle(key, v),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: kText)),
        subtitle: Text(sub, style: const TextStyle(color: kMuted, fontSize: 12)),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}