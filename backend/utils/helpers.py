import json
import os

import jwt
from datetime import date, datetime
from functools import wraps
from flask import request, jsonify
from database import get_db

QUAL   = {"10th": 1, "12th": 2, "Diploma": 3, "UG": 4, "PG": 5}
ENTRANCE_EXAMS = ["JEE", "NEET", "MHT-CET", "NDA", "CLAT",
                  "BITSAT", "KCET", "VITEEE", "AILET"]


def get_jwt_secret():
    secret = os.environ.get("JWT_SECRET")
    if not secret:
        raise RuntimeError("JWT_SECRET environment variable is required")
    return secret


# ================================================================
# AUTH DECORATORS
# ================================================================
def login_required(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        token = request.headers.get("Authorization", "").replace("Bearer ", "")
        if not token:
            return jsonify({"error": "Token missing"}), 401
        try:
            data = jwt.decode(token, get_jwt_secret(), algorithms=["HS256"])
        except Exception:
            return jsonify({"error": "Invalid or expired token"}), 401
        return f(data["user_id"], *args, **kwargs)
    return wrapper


def admin_required(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        token = request.headers.get("Authorization", "").replace("Bearer ", "")
        if not token:
            return jsonify({"error": "Token missing"}), 401
        try:
            data = jwt.decode(token, get_jwt_secret(), algorithms=["HS256"])
        except Exception:
            return jsonify({"error": "Invalid or expired token"}), 401
        uid = data["user_id"]
        db  = get_db()
        row = db.execute(
            "SELECT is_admin FROM users WHERE id=?", (uid,)
        ).fetchone()
        db.close()
        if not row or not row["is_admin"]:
            return jsonify({"error": "Admin access required"}), 403
        return f(uid, *args, **kwargs)
    return wrapper


# ================================================================
# DEADLINE INFO
# ================================================================
def deadline_info(last_date_str, hi=3, med=7):
    if not last_date_str:
        return {"status": "unknown", "days": None,
                "priority": "low", "label": "?"}
    try:
        d = date.fromisoformat(last_date_str)
    except Exception:
        return {"status": "unknown", "days": None,
                "priority": "low", "label": "?"}
    days = (d - date.today()).days
    if days < 0:
        return {"status": "expired", "days": days,
                "priority": "none",
                "label": f"Expired {abs(days)}d ago"}
    if days <= hi:
        return {"status": "urgent", "days": days,
                "priority": "high",
                "label": f"{days}d left - URGENT"}
    if days <= med:
        return {"status": "upcoming", "days": days,
                "priority": "medium",
                "label": f"{days} days left"}
    return {"status": "upcoming", "days": days,
            "priority": "low",
            "label": f"{days} days left"}


# ================================================================
# FEE CALCULATION
# ================================================================
def _get_fee(exam, gender, caste):
    caste  = (caste  or "General").strip()
    gender = (gender or "").strip()
    if gender == "Female":
        f = exam.get("fee_female") or 0
        if f and float(f) > 0:
            return float(f)
    if caste == "SC":  return float(exam.get("fee_sc")  or exam.get("fee_general") or 0)
    if caste == "ST":  return float(exam.get("fee_st")  or exam.get("fee_general") or 0)
    if caste == "OBC": return float(exam.get("fee_obc") or exam.get("fee_general") or 0)
    if caste == "PwD": return float(exam.get("fee_pwd") or exam.get("fee_general") or 0)
    return float(exam.get("fee_general") or 0)


# ================================================================
# ELIGIBILITY CHECK
# ================================================================
def is_eligible(exam, profile):
    reasons       = []
    name          = exam.get("name", "").upper()
    qualification = (profile.get("qualification") or "").strip()
    age           = profile.get("age") or 0
    gender        = (profile.get("gender") or "").strip()
    stream        = (profile.get("stream") or "").strip()
    caste         = (profile.get("caste") or "General").strip()
    marks_10th    = profile.get("marks_10th") or 0
    marks_12th    = profile.get("marks_12th") or 0
    status        = (profile.get("status") or "").strip()

    # Rule 1: Gender
    gender_allowed = (exam.get("gender_allowed") or "ALL").strip()
    if gender_allowed != "ALL" and gender and gender != gender_allowed:
        reasons.append(f"This exam is open for {gender_allowed} candidates only.")
        return {"ok": False, "reasons": reasons, "fee": 0}

    # Rule 2: JEE Advanced requires JEE Main first
    if "JEE ADVANCED" in name:
        reasons.append(
            "JEE Advanced requires qualifying JEE Main first "
            "and being among top 2.5 lakh scorers."
        )
        return {"ok": False, "reasons": reasons, "fee": 0}

    # Rule 3: UG graduates can't sit entrance exams
    is_grad     = QUAL.get(qualification, 0) >= QUAL.get("UG", 4)
    is_entrance = any(e in name for e in ENTRANCE_EXAMS)
    if is_grad and is_entrance and status != "Studying":
        reasons.append(
            f"You already hold a {qualification} degree. "
            f"This entrance exam is for 12th pass students."
        )
        return {"ok": False, "reasons": reasons, "fee": 0}

    # Rule 4: Qualification level
    user_level = QUAL.get(qualification, 0)
    need_level = QUAL.get(exam.get("min_qual") or "", 0)
    if user_level < need_level:
        reasons.append(
            f"Minimum qualification: {exam.get('min_qual')}. "
            f"Your qualification: {qualification or 'Not set'}."
        )

    # Rule 5: Stream check
    streams_raw = (exam.get("streams") or "ALL").strip()
    if streams_raw and streams_raw != "ALL":
        try:
            allowed_streams = json.loads(streams_raw)
            if stream and stream not in allowed_streams:
                reasons.append(
                    f"Required stream: {' or '.join(allowed_streams)}. "
                    f"Your stream: {stream}."
                )
        except Exception:
            pass

    # Rule 6: Age with caste relaxation
    min_age   = exam.get("min_age") or 0
    max_age   = exam.get("max_age") or 0
    age_relax = 0
    if caste == "OBC":          age_relax = 3
    elif caste in ("SC", "ST"): age_relax = 5
    elif caste == "PwD":        age_relax = 10
    if min_age and age and age < min_age:
        reasons.append(f"Minimum age: {min_age} years. Your age: {age}.")
    if max_age and max_age < 99 and age and age > (max_age + age_relax):
        reasons.append(
            f"Maximum age: {max_age + age_relax} yrs "
            f"({max_age}+{age_relax} relaxation). Your age: {age}."
        )

    # Rule 7: 10th marks (SC/ST get 5% relaxation)
    req_10th     = exam.get("min_10th") or 0
    relax_marks  = 5 if caste in ("SC", "ST") else 0
    if req_10th and marks_10th and marks_10th < (req_10th - relax_marks):
        reasons.append(
            f"Min 10th marks: {req_10th}% "
            f"({req_10th - relax_marks}% for {caste}). "
            f"Your marks: {marks_10th}%."
        )

    # Rule 8: 12th marks
    req_12th = exam.get("min_12th") or 0
    if req_12th and marks_12th and marks_12th < (req_12th - relax_marks):
        reasons.append(
            f"Min 12th marks: {req_12th}% "
            f"({req_12th - relax_marks}% for {caste}). "
            f"Your marks: {marks_12th}%."
        )

    fee = _get_fee(exam, gender, caste)
    return {"ok": len(reasons) == 0, "reasons": reasons, "fee": fee}


# ================================================================
# NOTIFICATION HELPERS
# ================================================================
def _has_notification(db, uid, exam_id, ntype):
    row = db.execute("""
        SELECT sent_at FROM notifications
        WHERE user_id=? AND exam_id=? AND type=?
        ORDER BY sent_at DESC LIMIT 1
    """, (uid, exam_id, ntype)).fetchone()
    return row is not None


def _get_prefs(db, uid):
    row = db.execute(
        "SELECT * FROM user_preferences WHERE user_id=?", (uid,)
    ).fetchone()
    if row:
        return dict(row)
    db.execute(
        "INSERT INTO user_preferences(user_id) VALUES(?)", (uid,)
    )
    db.commit()
    return {
        "user_id": uid, "alert_urgent": 1, "alert_medium": 1,
        "alert_low": 0, "alert_missed": 1, "daily_summary": 1,
        "language": "en",
    }


def scan_and_generate_notifications(uid):
    db      = get_db()
    prof    = db.execute(
        "SELECT * FROM profiles WHERE user_id=?", (uid,)
    ).fetchone()
    profile = dict(prof) if prof else None
    prefs   = _get_prefs(db, uid)
    exams   = db.execute(
        "SELECT * FROM exams WHERE is_active=1"
    ).fetchall()
    created = 0

    for row in exams:
        ex = dict(row)

        # Only notify for eligible exams
        if profile:
            e = is_eligible(ex, profile)
            if not e["ok"]:
                continue

        dl     = deadline_info(ex["last_date"])
        status = dl["status"]
        days   = dl["days"]
        ntype, priority, title, body = None, "low", "", ""

        if status == "expired" and prefs.get("alert_missed"):
            ntype, priority = "missed", "high"
            title = f"⚠ {ex['name']} - Deadline Missed"
            body  = f"The application deadline closed {abs(days)} days ago."

        elif status == "urgent" and prefs.get("alert_urgent"):
            ntype, priority = "urgent", "high"
            title = f"🔥 {ex['name']} - {days} day(s) left!"
            body  = (f"Last date: {ex['last_date']}. "
                     f"Apply at {ex.get('website', '')}")

        elif (status == "upcoming" and days is not None
              and days <= 7 and prefs.get("alert_medium")):
            ntype, priority = "upcoming", "medium"
            title = f"📅 {ex['name']} - {days} days left"
            body  = f"Apply before {ex['last_date']}."

        elif (status == "upcoming" and days is not None
              and days > 7 and prefs.get("alert_low")):
            ntype, priority = "upcoming", "low"
            title = f"ℹ {ex['name']} - {days} days to go"
            body  = f"Deadline on {ex['last_date']}."

        if not ntype:
            continue

        # For urgent: resend if older than 24 hours
        if ntype == "urgent":
            existing = db.execute("""
                SELECT sent_at FROM notifications
                WHERE user_id=? AND exam_id=? AND type='urgent'
                ORDER BY sent_at DESC LIMIT 1
            """, (uid, ex["id"])).fetchone()
            if existing:
                try:
                    sent      = datetime.fromisoformat(existing["sent_at"])
                    hours_ago = (datetime.utcnow() - sent).total_seconds() / 3600
                    if hours_ago < 24:
                        continue  # Already sent within 24 hours
                except Exception:
                    pass
        else:
            if _has_notification(db, uid, ex["id"], ntype):
                continue

        db.execute("""
            INSERT INTO notifications
                (user_id, exam_id, title, body, type, priority)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (uid, ex["id"], title, body, ntype, priority))
        created += 1

    db.commit()
    db.close()
    return created


# ================================================================
# DAILY INSIGHTS
# ================================================================
def build_daily_insights(uid):
    """
    Personalized daily insights filtered by stream.
    PCM students only see PCM exams. PCB only sees PCB. Etc.
    """
    db      = get_db()
    prof    = db.execute(
        "SELECT * FROM profiles WHERE user_id=?", (uid,)
    ).fetchone()
    profile = dict(prof) if prof else None
    stream  = (profile or {}).get("stream") or ""
    qual    = (profile or {}).get("qualification") or ""
    name_p  = (profile or {}).get("full_name") or "Student"
    caste   = (profile or {}).get("caste") or "General"

    rows = db.execute(
        "SELECT * FROM exams WHERE is_active=1"
    ).fetchall()

    urgent, medium, far = [], [], []
    for r in rows:
        ex = dict(r)
        if profile:
            e = is_eligible(ex, profile)
            if not e["ok"]:
                continue
            ex["my_fee"] = e.get("fee", 0)
        dl   = deadline_info(ex["last_date"])
        ex["deadline"] = dl
        days = dl["days"]
        if dl["status"] == "expired":
            continue
        if days is not None and days <= 3:
            urgent.append(ex)
        elif days is not None and days <= 7:
            medium.append(ex)
        else:
            far.append(ex)
    db.close()

    urgent.sort(key=lambda x: x["deadline"]["days"] or 99)
    medium.sort(key=lambda x: x["deadline"]["days"] or 99)
    far.sort(key=lambda x: x["deadline"]["days"] or 99)

    stream_tips = {
        "PCM":      "Focus on JEE, BITSAT, MHT-CET. Strong math/physics key.",
        "PCB":      "Focus on NEET UG. Biology + Chemistry marks matter most.",
        "Commerce": "Target CLAT, CAT, IBPS PO, SSC CGL. Commerce + aptitude.",
        "Arts":     "Target CLAT, UPSC, SSC, UGC NET. Reading + GK is key.",
    }
    tip = stream_tips.get(stream, "Keep checking new exams as they open.")

    insights = []

    # 9 AM
    insights.append({
        "time": "9:00 AM",
        "title": f"Good Morning, {name_p.split()[0]}! 🌅",
        "body": (f"{len(urgent)} urgent + {len(medium)} upcoming + "
                 f"{len(far)} long-term eligible exams. {tip}"),
        "icon_name": "wb_sunny", "color": "#FFB347",
        "priority": "medium", "website": "",
    })

    # 10 AM - Most urgent
    if urgent:
        ex      = urgent[0]
        fee_str = f"₹{int(ex.get('my_fee', 0))}" if ex.get('my_fee', 0) > 0 else "Free"
        insights.append({
            "time": "10:00 AM",
            "title": f"🔥 URGENT: {ex['name']}",
            "body": (f"Only {ex['deadline']['days']} day(s) left! "
                     f"Your fee: {fee_str}."),
            "icon_name": "warning_amber", "color": "#FF6B6B",
            "priority": "high", "website": ex.get("website", ""),
        })

    # 11 AM - Second urgent
    if len(urgent) > 1:
        ex = urgent[1]
        insights.append({
            "time": "11:00 AM",
            "title": f"⚠ Also Urgent: {ex['name']}",
            "body": f"{ex['deadline']['days']} day(s) left. Apply immediately.",
            "icon_name": "warning_amber", "color": "#EE0979",
            "priority": "high", "website": ex.get("website", ""),
        })

    # 12 PM - Medium
    if medium:
        ex = medium[0]
        insights.append({
            "time": "12:00 PM",
            "title": f"📅 This Week: {ex['name']}",
            "body": f"{ex['deadline']['days']} days left. Category: {ex.get('category', '')}.",
            "icon_name": "event", "color": "#FF8C00",
            "priority": "medium", "website": ex.get("website", ""),
        })

    # 2 PM - Study tip
    study_tips = {
        "PCM":      "Revise Physics formulas & Math calculus for JEE prep.",
        "PCB":      "Focus on NCERT Biology chapters for NEET. Diagrams matter.",
        "Commerce": "Practice aptitude + current affairs for banking exams.",
        "Arts":     "Read newspaper daily for UPSC + SSC GK sections.",
    }
    insights.append({
        "time": "2:00 PM",
        "title": f"💡 Study Tip for {stream or 'You'}",
        "body": study_tips.get(stream, "Set a daily study schedule. Consistency wins."),
        "icon_name": "lightbulb", "color": "#667EEA",
        "priority": "low", "website": "",
    })

    # 4 PM - Long term
    if far:
        ex = far[0]
        insights.append({
            "time": "4:00 PM",
            "title": f"📌 Plan Ahead: {ex['name']}",
            "body": (f"{ex['deadline']['days']} days away. "
                     f"Mode: {ex.get('mode', '')}. Start prep now."),
            "icon_name": "flag", "color": "#764BA2",
            "priority": "low", "website": ex.get("website", ""),
        })

    # 6 PM - Category benefits
    if caste in ("SC", "ST", "OBC", "PwD"):
        insights.append({
            "time": "6:00 PM",
            "title": f"ℹ {caste} Category Benefits",
            "body": (f"As a {caste} candidate: reduced fees, age relaxation, "
                     f"and lower cutoffs apply to most exams."),
            "icon_name": "info", "color": "#11998E",
            "priority": "low", "website": "",
        })

    # 8 PM - Summary
    insights.append({
        "time": "8:00 PM",
        "title": "📊 Evening Summary",
        "body": (f"{len(urgent)} urgent • {len(medium)} this week • "
                 f"{len(far)} upcoming. Check Notifications for alerts."),
        "icon_name": "bar_chart", "color": "#1A1A2E",
        "priority": "medium", "website": "",
    })

    return insights


# ================================================================
# COURSE SUGGESTIONS
# ================================================================
COURSE_CATALOG = [
    {"name": "B.Tech Computer Science", "stream": "PCM",
     "colleges": "IIT, NIT, BITS Pilani", "salary": "₹8-50 LPA",
     "for": "12th PCM students", "min_qual": "12th",
     "icon_name": "computer", "color": "#667EEA"},
    {"name": "B.Tech Electronics", "stream": "PCM",
     "colleges": "IIT, NIT, IIIT", "salary": "₹6-30 LPA",
     "for": "12th PCM students", "min_qual": "12th",
     "icon_name": "electrical_services", "color": "#764BA2"},
    {"name": "MBBS / BDS", "stream": "PCB",
     "colleges": "AIIMS, JIPMER, CMC", "salary": "₹8-80 LPA",
     "for": "12th PCB students", "min_qual": "12th",
     "icon_name": "local_hospital", "color": "#EE0979"},
    {"name": "B.Pharm / Pharm.D", "stream": "PCB",
     "colleges": "Manipal, JSS, KLE", "salary": "₹3-15 LPA",
     "for": "12th PCB students", "min_qual": "12th",
     "icon_name": "medication", "color": "#FF6B6B"},
    {"name": "B.Com + CA", "stream": "Commerce",
     "colleges": "SRCC, Christ, Loyola", "salary": "₹7-40 LPA",
     "for": "Commerce students", "min_qual": "12th",
     "icon_name": "account_balance", "color": "#11998E"},
    {"name": "BA LLB", "stream": "Arts",
     "colleges": "NLSIU, NALSAR, NLU", "salary": "₹5-30 LPA",
     "for": "Arts students", "min_qual": "12th",
     "icon_name": "gavel", "color": "#FFB347"},
    {"name": "M.Tech via GATE", "stream": "PCM",
     "colleges": "IIT, NIT, BITS", "salary": "₹10-60 LPA",
     "for": "B.Tech graduates", "min_qual": "UG",
     "icon_name": "science", "color": "#667EEA"},
    {"name": "MBA (IIMs)", "stream": "ALL",
     "colleges": "IIM A, IIM B, IIM C", "salary": "₹15-80 LPA",
     "for": "Any graduate", "min_qual": "UG",
     "icon_name": "trending_up", "color": "#764BA2"},
    {"name": "Data Science / AI", "stream": "ALL",
     "colleges": "IIT, IIIT-H, upGrad", "salary": "₹8-40 LPA",
     "for": "Any graduate", "min_qual": "UG",
     "icon_name": "psychology", "color": "#11998E"},
    {"name": "Civil Services IAS/IPS", "stream": "ALL",
     "colleges": "LBSNAA via UPSC", "salary": "₹56K-2.5L/month",
     "for": "Any graduate", "min_qual": "UG",
     "icon_name": "account_balance_wallet", "color": "#0F3460"},
]


def build_course_suggestions(profile):
    stream = (profile or {}).get("stream") or "ALL"
    qual   = (profile or {}).get("qualification") or ""
    ul     = QUAL.get(qual, 0)
    out    = []
    for c in COURSE_CATALOG:
        cs = c["stream"]
        cl = QUAL.get(c["min_qual"], 0)
        sm = cs == "ALL" or cs == stream or stream == "ALL"
        lm = cl <= ul + 1 and cl >= (ul if ul > 0 else 1)
        if sm and lm:
            out.append(c)
    return out


# ================================================================
# FCM — Firebase Cloud Messaging
# ================================================================
import os


def _get_firebase_app():
    """Initialize Firebase Admin app (only once)."""
    import firebase_admin
    from firebase_admin import credentials

    if not firebase_admin._apps:
        key_path = os.path.join(
            os.path.dirname(__file__), '..', 'serviceAccountKey.json'
        )
        if os.path.exists(key_path):
            cred = credentials.Certificate(key_path)
            firebase_admin.initialize_app(cred)
            print("✅ Firebase Admin initialized")
        else:
            print("⚠️ serviceAccountKey.json not found — FCM disabled")
            return None
    try:
        return firebase_admin.get_app()
    except Exception:
        return None


def send_fcm_notification(fcm_token, title, body, exam_id=None):
    """Send push notification to one device via FCM V1."""
    if not fcm_token:
        return False
    try:
        from firebase_admin import messaging
        app = _get_firebase_app()
        if not app:
            return False

        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    sound='default',
                    priority='high',
                    channel_id='exam_tracker_urgent',
                ),
            ),
            data={
                'exam_id':      str(exam_id) if exam_id else '',
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
            token=fcm_token,
        )
        response = messaging.send(message)
        print(f"✅ FCM sent: {response}")
        return True
    except Exception as e:
        print(f"❌ FCM error: {e}")
        return False


def scan_and_notify_all_users():
    """Scan all users and send FCM push for urgent eligible exams."""
    db    = get_db()
    users = db.execute(
        "SELECT id, fcm_token FROM users"
    ).fetchall()
    db.close()

    total_sent = 0
    for user in users:
        uid       = user["id"]
        fcm_token = user["fcm_token"]

        # Generate in-app notifications
        created = scan_and_generate_notifications(uid)

        # Send FCM push if token exists
        if fcm_token:
            db2    = get_db()
            notifs = db2.execute("""
                SELECT * FROM notifications
                WHERE user_id=? AND is_read=0
                AND priority='high'
                ORDER BY sent_at DESC LIMIT 3
            """, (uid,)).fetchall()
            db2.close()

            for n in notifs:
                sent = send_fcm_notification(
                    fcm_token=fcm_token,
                    title=n["title"],
                    body=n["body"],
                    exam_id=n["exam_id"],
                )
                if sent:
                    total_sent += 1

    print(f"✅ FCM scan complete: {total_sent} notifications sent")
    return total_sent