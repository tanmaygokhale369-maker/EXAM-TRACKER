from flask import Blueprint, request, jsonify
from database import get_db
from utils.helpers import login_required, _get_prefs

preferences_bp = Blueprint("preferences", __name__)

@preferences_bp.route("/", methods=["GET"])
@login_required
def get_preferences(uid):
    db = get_db()
    prefs = _get_prefs(db, uid)
    db.close()
    return jsonify({"preferences": prefs})

@preferences_bp.route("/", methods=["POST"])
@login_required
def update_preferences(uid):
    d = request.get_json() or {}
    allowed = ["alert_urgent", "alert_medium", "alert_low",
               "alert_missed", "daily_summary", "language"]
    db = get_db()
    _get_prefs(db, uid)
    for key in allowed:
        if key in d:
            val = d[key]
            if isinstance(val, bool):
                val = 1 if val else 0
            db.execute(f"UPDATE user_preferences SET {key}=? WHERE user_id=?", (val, uid))
    db.commit()
    prefs = _get_prefs(db, uid)
    db.close()
    return jsonify({"message": "Preferences updated", "preferences": prefs})