class Exam {
  final int    id;
  final String name, description, category;
  final String lastDate, examDate, website, mode;
  final double myFee;
  final Map<String, double> fees;
  final int    seats;
  final bool   eligible, bookmarked;
  final List<String> reasons;
  final Map<String, dynamic> deadline;
  final String eligibilityNote;
  final String genderAllowed;

  Exam({
    required this.id,
    required this.name,
    this.description     = '',
    this.category        = '',
    this.lastDate        = '',
    this.examDate        = '',
    this.website         = '',
    this.mode            = 'Online',
    this.myFee           = 0,
    this.fees            = const {},
    this.seats           = 0,
    this.eligible        = true,
    this.bookmarked      = false,
    this.reasons         = const [],
    this.deadline        = const {},
    this.eligibilityNote = '',
    this.genderAllowed   = 'ALL',
  });

  factory Exam.fromJson(Map<String, dynamic> j) {
    // Parse fees map
    final rawFees = j['fees'];
    final Map<String, double> feesMap = {};
    if (rawFees is Map) {
      rawFees.forEach((k, v) {
        final d = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;
        if (d > 0) feesMap[k.toString()] = d;
      });
    }
    return Exam(
      id:              j['id']               ?? 0,
      name:            j['name']             ?? '',
      description:     j['description']      ?? '',
      category:        j['category']         ?? '',
      lastDate:        j['last_date']        ?? '',
      examDate:        j['exam_date']        ?? '',
      website:         j['website']          ?? '',
      mode:            j['mode']             ?? 'Online',
      myFee:           (j['my_fee']          ?? j['fee'] ?? 0).toDouble(),
      fees:            feesMap,
      seats:           j['seats']            ?? 0,
      eligible:        j['eligible']         ?? true,
      bookmarked:      j['bookmarked']       ?? false,
      reasons:         List<String>.from(j['reasons'] ?? []),
      deadline:        Map<String, dynamic>.from(j['deadline'] ?? {}),
      eligibilityNote: j['eligibility_note'] ?? '',
      genderAllowed:   j['gender_allowed']   ?? 'ALL',
    );
  }

  // Getters used by old screens
  String get status   => deadline['status']   ?? 'upcoming';
  String get priority => deadline['priority'] ?? 'low';
  int    get days     => deadline['days']     ?? 0;
  String get label    => deadline['label']    ?? '';
  String get myFeeStr => myFee == 0 ? 'Free' : '₹${myFee.toInt()}';

  // Getters used by new Space Cosmos screens
  int  get daysLeft   => days;
  bool get isEligible => eligible;
}