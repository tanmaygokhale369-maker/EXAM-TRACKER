import 'package:flutter/material.dart';
import '../services/api.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name     = TextEditingController();
  final _age      = TextEditingController();
  final _location = TextEditingController();
  final _m10      = TextEditingController();
  final _m12      = TextEditingController();

  String? _gender, _stream, _qual, _status, _caste;
  bool _loading = false;

  final _streams  = ['PCM', 'PCB', 'Commerce', 'Arts', 'Other'];
  final _quals    = ['10th', '12th', 'Diploma', 'UG', 'PG'];
  final _statuses = ['Studying', 'Passout'];
  final _castes   = ['General', 'OBC', 'SC', 'ST', 'PwD'];

  void _snack(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: err ? kUrgent : kSuccess,
    ));
  }

  Future<void> _save() async {
    if (_name.text.isEmpty) {
      _snack('Full name is required', err: true);
      return;
    }
    setState(() => _loading = true);
    final res = await Api.post('/profile/', {
      'full_name':     _name.text,
      'age':           int.tryParse(_age.text),
      'gender':        _gender,
      'location':      _location.text,
      'marks_10th':    double.tryParse(_m10.text),
      'marks_12th':    double.tryParse(_m12.text),
      'stream':        _stream,
      'qualification': _qual,
      'status':        _status,
      'caste':         _caste ?? 'General',
    });
    setState(() => _loading = false);
    if (res.containsKey('error')) {
      _snack(res['error'], err: true);
      return;
    }
    await Api.setProfileComplete();
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: kDark1,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: kHeaderGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.person_rounded, color: kAccent, size: 36),
                        SizedBox(height: 8),
                        Text('Setup Your Profile',
                            style: TextStyle(color: Colors.white,
                                fontSize: 22, fontWeight: FontWeight.w800)),
                        Text('Used to find exams you are eligible for',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('Personal Information'),
                  _label('Full Name *'),
                  _field(_name, 'Enter your full name', icon: Icons.person_outline_rounded),
                  _label('Age'),
                  _field(_age, 'Your age', num: true, icon: Icons.cake_rounded),
                  _label('Gender'),
                  _drop(_gender, 'Select gender', ['Male', 'Female', 'Other'],
                      Icons.wc_rounded, (v) => setState(() => _gender = v)),
                  _label('Location'),
                  _field(_location, 'City, State', icon: Icons.location_on_outlined),

                  _section('Academic Details'),
                  _label('10th Marks (%)'),
                  _field(_m10, 'e.g. 85.5', num: true, icon: Icons.grade_rounded),
                  _label('12th Marks (%)'),
                  _field(_m12, 'e.g. 78.0', num: true, icon: Icons.grade_rounded),
                  _label('Stream'),
                  _drop(_stream, 'Select stream', _streams,
                      Icons.science_rounded, (v) => setState(() => _stream = v)),
                  _label('Highest Qualification'),
                  _drop(_qual, 'Select qualification', _quals,
                      Icons.school_rounded, (v) => setState(() => _qual = v)),
                  _label('Student Status'),
                  _drop(_status, 'Select status', _statuses,
                      Icons.timeline_rounded, (v) => setState(() => _status = v)),

                  _section('Category'),
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kPrimary.withOpacity(0.2)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: kPrimary),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        'SC/ST: +5% marks relaxation, +5 yrs age. '
                        'OBC: +3 yrs age. PwD: +10 yrs age.',
                        style: TextStyle(color: kPrimary, fontSize: 11, height: 1.4),
                      )),
                    ]),
                  ),
                  _label('Caste / Category'),
                  _drop(_caste, 'Select category', _castes,
                      Icons.category_rounded, (v) => setState(() => _caste = v)),

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_rounded),
                      label: Text(_loading ? 'Saving...' : 'Save & Continue',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Row(children: [
      Container(width: 4, height: 18,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: kPrimaryGradient),
          borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w800, color: kText)),
    ]),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(t, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600, color: kText)),
  );

  Widget _field(TextEditingController c, String hint,
      {bool num = false, IconData? icon}) {
    return TextField(
      controller: c,
      keyboardType: num ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: kMuted, size: 20) : null,
        filled: true, fillColor: kCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 2)),
      ),
    );
  }

  Widget _drop(String? val, String hint, List<String> items,
      IconData icon, ValueChanged<String?> cb) {
    return DropdownButtonFormField<String>(
      value: val,
      hint: Text(hint, style: const TextStyle(color: kMuted)),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: kMuted, size: 20),
        filled: true, fillColor: kCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder)),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: cb,
    );
  }
}