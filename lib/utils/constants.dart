import 'package:flutter/material.dart';

// ── Space Cosmos Core Palette ─────────────────────────────────────────────
const Color kBg        = Color(0xFF080B14);
const Color kBgMid     = Color(0xFF0D1528);
const Color kCard      = Color(0xFF111D35);
const Color kCardBorder= Color(0xFF1E3A5F);
const Color kPrimary   = Color(0xFF7B61FF);
const Color kAccent    = Color(0xFF3BECA0);
const Color kUrgent    = Color(0xFFFF6B6B);
const Color kWarning   = Color(0xFFF6AD55);
const Color kSuccess   = Color(0xFF3BECA0);
const Color kText      = Color(0xFFE2E8F0);
const Color kTextSub   = Color(0xFF8892A4);
const Color kBorder    = Color(0xFF1E3A5F);
const Color kNavBg     = Color(0xFF0A0F1E);

// ── Legacy aliases (used by notifications, pin, settings, admin, calendar) ─
const Color kDark1     = Color(0xFF0D1528);
const Color kDark2     = Color(0xFF111D35);
const Color kDark3     = Color(0xFF080B14);
const Color kMuted     = Color(0xFF8892A4);
const Color kSecondary = Color(0xFF3BECA0);
const Color kPink      = Color(0xFFF472B6);
const Color kCardBg    = Color(0xFF111D35);

// ── Gradient constants ────────────────────────────────────────────────────
const List<Color> kHeaderGradient  = [Color(0xFF0D1528), Color(0xFF1E3A5F)];
const List<Color> kPrimaryGradient = [Color(0xFF7B61FF), Color(0xFF3BECA0)];

// ── Category colours ──────────────────────────────────────────────────────
const Color kEngColor   = Color(0xFF7B61FF);
const Color kMedColor   = Color(0xFFFF6B6B);
const Color kGovColor   = Color(0xFF3BECA0);
const Color kBankColor  = Color(0xFFF6AD55);
const Color kDefColor   = Color(0xFF60A5FA);
const Color kLawColor   = Color(0xFFF472B6);
const Color kMgmtColor  = Color(0xFFA78BFA);
const Color kRailColor  = Color(0xFF34D399);
const Color kTeachColor = Color(0xFFFBBF24);
const Color kDefaultCat = Color(0xFF94A3B8);

Color categoryColor(String? cat) {
  switch ((cat ?? '').toLowerCase()) {
    case 'engineering': return kEngColor;
    case 'medical':     return kMedColor;
    case 'government':  return kGovColor;
    case 'banking':     return kBankColor;
    case 'defence':     return kDefColor;
    case 'law':         return kLawColor;
    case 'management':  return kMgmtColor;
    case 'railway':     return kRailColor;
    case 'teaching':    return kTeachColor;
    default:            return kDefaultCat;
  }
}

String categoryEmoji(String? cat) {
  switch ((cat ?? '').toLowerCase()) {
    case 'engineering': return '⚙️';
    case 'medical':     return '🩺';
    case 'government':  return '🏛️';
    case 'banking':     return '🏦';
    case 'defence':     return '⚔️';
    case 'law':         return '⚖️';
    case 'management':  return '📊';
    case 'railway':     return '🚂';
    case 'teaching':    return '📚';
    case 'police':      return '🚔';
    case 'agriculture': return '🌾';
    case 'design':      return '🎨';
    case 'aviation':    return '✈️';
    case 'commerce':    return '📈';
    case 'science':     return '🔬';
    default:            return '📋';
  }
}

// Legacy alias used by older screens
String categoryIcon(String? c) => categoryEmoji(c);

Color priorityColor(String? p) {
  switch (p) {
    case 'high':   return kUrgent;
    case 'medium': return kWarning;
    default:       return kSuccess;
  }
}

Color colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return kPrimary;
  try {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return kPrimary;
  }
}

IconData iconFromName(String? name) {
  switch (name) {
    case 'wb_sunny':        return Icons.wb_sunny_rounded;
    case 'warning':         return Icons.warning_amber_rounded;
    case 'local_hospital':  return Icons.local_hospital_rounded;
    case 'engineering':     return Icons.engineering_rounded;
    case 'account_balance': return Icons.account_balance_rounded;
    case 'gavel':           return Icons.gavel_rounded;
    case 'science':         return Icons.science_rounded;
    case 'bar_chart':       return Icons.bar_chart_rounded;
    case 'school':          return Icons.school_rounded;
    case 'star':            return Icons.star_rounded;
    case 'trending_up':     return Icons.trending_up_rounded;
    case 'shield':          return Icons.shield_rounded;
    default:                return Icons.lightbulb_outline_rounded;
  }
}

const kSpaceGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF080B14), Color(0xFF0D1528), Color(0xFF080B14)],
);