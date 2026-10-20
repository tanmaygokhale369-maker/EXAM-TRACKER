from flask import Blueprint, jsonify
from database import get_db
from utils.helpers import (
    login_required, deadline_info, is_eligible,
    scan_and_generate_notifications,
)

dashboard_bp = Blueprint("dashboard", __name__)


@dashboard_bp.route("/", methods=["GET"])
@login_required
def dashboard(uid):
    scan_and_generate_notifications(uid)

    db   = get_db()
    prof = db.execute(
        "SELECT * FROM profiles WHERE user_id=?", (uid,)
    ).fetchone()
    p = dict(prof) if prof else None

    rows = db.execute(
        "SELECT * FROM exams WHERE is_active=1"
    ).fetchall()

    # Only eligible exams go into urgent/upcoming/recommended
    # Ineligible still tracked for "missed" awareness
    urgent, upcoming, missed, recommended = [], [], [], []

    for r in rows:
        ex = dict(r)
        dl = deadline_info(ex["last_date"])
        ex["deadline"] = dl

        # Eligibility check
        elig_result = {"ok": True, "reasons": [], "fee": 0}
        if p:
            elig_result = is_eligible(ex, p)

        ex["eligible"] = elig_result["ok"]
        ex["reasons"]  = elig_result["reasons"]
        ex["my_fee"]   = elig_result.get("fee", 0)
        ex["fees"] = {
            "General": ex.get("fee_general") or 0,
            "OBC":     ex.get("fee_obc")     or 0,
            "SC":      ex.get("fee_sc")      or 0,
            "ST":      ex.get("fee_st")      or 0,
            "PwD":     ex.get("fee_pwd")     or 0,
            "Female":  ex.get("fee_female")  or 0,
        }
        ex["fees"] = {k: v for k, v in ex["fees"].items() if v > 0}

        # Bookmark status
        bm = db.execute(
            "SELECT id FROM bookmarks WHERE user_id=? AND exam_id=?",
            (uid, ex["id"])
        ).fetchone()
        ex["bookmarked"] = bm is not None

        status   = dl["status"]
        priority = dl["priority"]

        if status == "expired":
            # Only show missed if they were eligible
            if ex["eligible"]:
                missed.append(ex)
        elif ex["eligible"]:
            # Only eligible exams in urgent/upcoming
            if priority == "high":
                urgent.append(ex)
            else:
                upcoming.append(ex)
            recommended.append(ex)

    # Sort by deadline proximity
    urgent.sort(key=lambda x: x["deadline"].get("days") or 99)
    upcoming.sort(key=lambda x: x["deadline"].get("days") or 99)
    missed.sort(key=lambda x: x["deadline"].get("days") or -99, reverse=True)

    unread = db.execute(
        "SELECT COUNT(*) FROM notifications WHERE user_id=? AND is_read=0",
        (uid,)
    ).fetchone()[0]

    db.close()

    return jsonify({
        "urgent":           urgent[:5],
        "upcoming":         upcoming[:15],
        "missed":           missed[:5],
        "expired":          missed[:5],
        "recommended":      recommended[:10],
        "urgent_count":     len(urgent),
        "upcoming_count":   len(upcoming),
        "missed_count":     len(missed),
        "unread_alerts":    unread,
        "profile_complete": p is not None,
        "profile":          p,
    })