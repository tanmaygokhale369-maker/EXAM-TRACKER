import 'package:flutter/material.dart';
import '../services/api.dart';
import '../utils/constants.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kDark1,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Admin Panel',
            style: TextStyle(fontWeight: FontWeight.w700)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: kHeaderGradient,
                begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: kAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Stats'),
            Tab(icon: Icon(Icons.list_alt_rounded),  text: 'Exams'),
            Tab(icon: Icon(Icons.campaign_rounded),  text: 'Broadcast'),
            Tab(icon: Icon(Icons.people_rounded),    text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _StatsTab(),
          _ExamsTab(),
          _BroadcastTab(),
          _UsersTab(),
        ],
      ),
    );
  }
}

// ── STATS ─────────────────────────────────────────────────────────────
class _StatsTab extends StatefulWidget {
  const _StatsTab();
  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final r = await Api.get('/admin/stats');
    if (!mounted) return;
    setState(() { _stats = r.containsKey('error') ? {} : r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kPrimary));
    return RefreshIndicator(
      onRefresh: _load,
      color: kPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _stat('Users',      _stats['users'] ?? 0,         Icons.people_rounded,       kPrimary),
              _stat('Exams',      _stats['exams_total'] ?? 0,    Icons.assignment_rounded,   kSecondary),
              _stat('Active',     _stats['exams_active'] ?? 0,   Icons.check_circle_rounded, kSuccess),
              _stat('Bookmarks',  _stats['bookmarks'] ?? 0,      Icons.bookmark_rounded,     kWarning),
              _stat('Alerts',     _stats['notifications'] ?? 0,  Icons.notifications_rounded,kPink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$value', style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: kText)),
            Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}

// ── EXAMS ─────────────────────────────────────────────────────────────
class _ExamsTab extends StatefulWidget {
  const _ExamsTab();
  @override
  State<_ExamsTab> createState() => _ExamsTabState();
}

class _ExamsTabState extends State<_ExamsTab> {
  List<dynamic> _exams = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await Api.get('/admin/exams');
    if (!mounted) return;
    setState(() { _exams = r['exams'] as List? ?? []; _loading = false; });
  }

  Future<void> _openEditor({Map<String, dynamic>? exam}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ExamEditor(exam: exam),
    );
    if (result == true) _load();
  }

  Future<void> _delete(int id) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this exam?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: kUrgent))),
        ],
      ),
    );
    if (sure != true) return;
    await Api.delete('/admin/exams/$id');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kPrimary));
    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: kPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Exam', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: _exams.length,
          itemBuilder: (_, i) {
            final e = _exams[i] as Map<String, dynamic>;
            final active = (e['is_active'] ?? 0) == 1;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder)),
              child: ListTile(
                leading: Container(
                  width: 44, height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                  child: Text(categoryIcon(e['category']),
                      style: const TextStyle(fontSize: 20)),
                ),
                title: Text(e['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${e['category'] ?? '-'} · Last: ${e['last_date'] ?? ''}${active ? '' : ' · INACTIVE'}',
                  style: TextStyle(color: active ? kMuted : kUrgent, fontSize: 12),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _openEditor(exam: e);
                    if (v == 'delete') _delete(e['id'] as int);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete',
                        child: Text('Delete', style: TextStyle(color: kUrgent))),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── EXAM EDITOR ───────────────────────────────────────────────────────
class _ExamEditor extends StatefulWidget {
  final Map<String, dynamic>? exam;
  const _ExamEditor({this.exam});
  @override
  State<_ExamEditor> createState() => _ExamEditorState();
}

class _ExamEditorState extends State<_ExamEditor> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  String _category = 'Engineering';
  String _minQual  = '12th';
  String _mode     = 'Online';
  String _streams  = 'ALL';
  bool _active     = true;
  bool _saving     = false;

  @override
  void initState() {
    super.initState();
    final e = widget.exam ?? {};
    _c = {
      'name':        TextEditingController(text: e['name']?.toString() ?? ''),
      'description': TextEditingController(text: e['description']?.toString() ?? ''),
      'start_date':  TextEditingController(text: e['start_date']?.toString() ?? ''),
      'last_date':   TextEditingController(text: e['last_date']?.toString() ?? ''),
      'exam_date':   TextEditingController(text: e['exam_date']?.toString() ?? ''),
      'website':     TextEditingController(text: e['website']?.toString() ?? ''),
      'min_age':     TextEditingController(text: (e['min_age'] ?? 0).toString()),
      'max_age':     TextEditingController(text: (e['max_age'] ?? 99).toString()),
      'min_10th':    TextEditingController(text: (e['min_10th'] ?? 0).toString()),
      'min_12th':    TextEditingController(text: (e['min_12th'] ?? 0).toString()),
      'fee':         TextEditingController(text: (e['fee'] ?? 0).toString()),
      'seats':       TextEditingController(text: (e['seats'] ?? 0).toString()),
    };
    _category = e['category']?.toString() ?? 'Engineering';
    _minQual  = e['min_qual']?.toString() ?? '12th';
    _mode     = e['mode']?.toString() ?? 'Online';
    _streams  = e['streams']?.toString() ?? 'ALL';
    _active   = (e['is_active'] ?? 1) == 1;
  }

  @override
  void dispose() {
    for (final c in _c.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'name': _c['name']!.text.trim(),
      'description': _c['description']!.text.trim(),
      'category': _category,
      'start_date': _c['start_date']!.text.trim(),
      'last_date': _c['last_date']!.text.trim(),
      'exam_date': _c['exam_date']!.text.trim(),
      'website': _c['website']!.text.trim(),
      'min_age': int.tryParse(_c['min_age']!.text) ?? 0,
      'max_age': int.tryParse(_c['max_age']!.text) ?? 99,
      'streams': _streams,
      'min_qual': _minQual,
      'min_10th': double.tryParse(_c['min_10th']!.text) ?? 0,
      'min_12th': double.tryParse(_c['min_12th']!.text) ?? 0,
      'fee': double.tryParse(_c['fee']!.text) ?? 0,
      'seats': int.tryParse(_c['seats']!.text) ?? 0,
      'mode': _mode,
      'is_active': _active,
    };
    final res = widget.exam == null
        ? await Api.post('/admin/exams', body)
        : await Api.put('/admin/exams/${widget.exam!['id']}', body);
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error']), backgroundColor: kUrgent));
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (_, scroll) => Form(
          key: _form,
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(20),
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: kBorder,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(widget.exam == null ? 'New Exam' : 'Edit Exam',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
              const SizedBox(height: 16),
              _field('name', 'Exam name *', required: true),
              _field('description', 'Description'),
              _drop('Category', _category,
                  ['Engineering','Medical','Government','Banking','Law','Defence','Management','Teaching','Other'],
                  (v) => setState(() => _category = v!)),
              Row(children: [
                Expanded(child: _field('start_date', 'Start (YYYY-MM-DD)')),
                const SizedBox(width: 10),
                Expanded(child: _field('last_date', 'Last date *', required: true)),
              ]),
              _field('exam_date', 'Exam date (YYYY-MM-DD)'),
              _field('website', 'Website URL'),
              Row(children: [
                Expanded(child: _field('min_age', 'Min age', number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field('max_age', 'Max age', number: true)),
              ]),
              _drop('Streams', _streams,
                  ['ALL','["PCM"]','["PCB"]','["PCM","PCB"]','["Commerce"]','["Arts"]'],
                  (v) => setState(() => _streams = v!)),
              _drop('Min qualification', _minQual,
                  ['10th','12th','Diploma','UG','PG'],
                  (v) => setState(() => _minQual = v!)),
              Row(children: [
                Expanded(child: _field('min_10th', 'Min 10th %', number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field('min_12th', 'Min 12th %', number: true)),
              ]),
              Row(children: [
                Expanded(child: _field('fee', 'Fee (₹)', number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field('seats', 'Seats', number: true)),
              ]),
              _drop('Mode', _mode, ['Online','Offline','Both'],
                  (v) => setState(() => _mode = v!)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: kSuccess,
                value: _active,
                title: const Text('Active'),
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(widget.exam == null ? 'Create' : 'Save',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String key, String hint, {bool required = false, bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: _c[key],
        keyboardType: number ? TextInputType.number : TextInputType.text,
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
        decoration: InputDecoration(
          labelText: hint, filled: true, fillColor: kCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder)),
        ),
      ),
    );
  }

  Widget _drop(String label, String value, List<String> items, ValueChanged<String?> onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        onChanged: onChange,
        decoration: InputDecoration(
          labelText: label, filled: true, fillColor: kCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder)),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      ),
    );
  }
}

// ── BROADCAST ─────────────────────────────────────────────────────────
class _BroadcastTab extends StatefulWidget {
  const _BroadcastTab();
  @override
  State<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends State<_BroadcastTab> {
  final _title = TextEditingController();
  final _body  = TextEditingController();
  String _priority = 'medium';
  bool _sending = false;

  @override
  void dispose() { _title.dispose(); _body.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Title and body required'), backgroundColor: kUrgent));
      return;
    }
    setState(() => _sending = true);
    final res = await Api.post('/admin/broadcast', {
      'title': _title.text.trim(),
      'body':  _body.text.trim(),
      'priority': _priority,
    });
    if (!mounted) return;
    setState(() => _sending = false);
    if (res.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error']), backgroundColor: kUrgent));
      return;
    }
    _title.clear(); _body.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Sent'), backgroundColor: kSuccess));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: kPrimaryGradient),
            borderRadius: BorderRadius.circular(16)),
          child: const Row(children: [
            Icon(Icons.campaign_rounded, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('Send a notification to every registered user.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          ]),
        ),
        const SizedBox(height: 20),
        TextField(controller: _title,
          decoration: const InputDecoration(labelText: 'Title',
              filled: true, fillColor: kCard, border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _body, maxLines: 4,
          decoration: const InputDecoration(labelText: 'Body',
              filled: true, fillColor: kCard, border: OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _priority,
          decoration: const InputDecoration(labelText: 'Priority',
              filled: true, fillColor: kCard, border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'high',   child: Text('High')),
            DropdownMenuItem(value: 'medium', child: Text('Medium')),
            DropdownMenuItem(value: 'low',    child: Text('Low')),
          ],
          onChanged: (v) => setState(() => _priority = v ?? 'medium'),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _sending ? null : _send,
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: _sending
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded),
            label: Text(_sending ? 'Sending...' : 'Send to all users',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

// ── USERS ─────────────────────────────────────────────────────────────
class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await Api.get('/admin/users');
    if (!mounted) return;
    setState(() { _users = r['users'] as List? ?? []; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kPrimary));
    return RefreshIndicator(
      onRefresh: _load,
      color: kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (_, i) {
          final u = _users[i] as Map<String, dynamic>;
          final isAdmin = (u['is_admin'] ?? 0) == 1;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isAdmin
                    ? kUrgent.withOpacity(0.15) : kPrimary.withOpacity(0.15),
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                  color: isAdmin ? kUrgent : kPrimary,
                ),
              ),
              title: Text(u['full_name'] ?? u['email'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${u['email']} · ${u['stream'] ?? '-'} · ${u['qualification'] ?? '-'}',
                  style: const TextStyle(fontSize: 12)),
              trailing: isAdmin ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: kUrgent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('ADMIN',
                    style: TextStyle(color: kUrgent, fontSize: 10, fontWeight: FontWeight.w700)),
              ) : null,
            ),
          );
        },
      ),
    );
  }
}