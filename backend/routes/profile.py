from flask import Blueprint, request, jsonify
from database import get_db
from utils.helpers import login_required

profile_bp = Blueprint("profile", __name__)


@profile_bp.route("/", methods=["GET"])
@login_required
def get_profile(uid):
    db   = get_db()
    user = db.execute("SELECT id, email FROM users WHERE id=?", (uid,)).fetchone()
    prof = db.execute("SELECT * FROM profiles WHERE user_id=?", (uid,)).fetchone()
    db.close()
    return jsonify({
        "user":             dict(user) if user else None,
        "profile":          dict(prof) if prof else None,
        "profile_complete": prof is not None,
    })


@profile_bp.route("/", methods=["POST"])
@login_required
def save_profile(uid):
    d = request.get_json() or {}
    if not d.get("full_name"):
        return jsonify({"error": "full_name is required"}), 400
    db     = get_db()
    exists = db.execute("SELECT id FROM profiles WHERE user_id=?", (uid,)).fetchone()
    vals   = (
        d.get("full_name"), d.get("age"), d.get("gender"),
        d.get("location"), d.get("marks_10th", 0), d.get("marks_12th", 0),
        d.get("stream"), d.get("qualification"),
        d.get("status", "Studying"),
        d.get("caste", "General"),
        uid
    )
    if exists:
        db.execute("""
            UPDATE profiles SET
                full_name=?, age=?, gender=?, location=?,
                marks_10th=?, marks_12th=?, stream=?,
                qualification=?, status=?, caste=?
            WHERE user_id=?
        """, vals)
    else:
        db.execute("""
            INSERT INTO profiles
                (full_name, age, gender, location, marks_10th, marks_12th,
                 stream, qualification, status, caste, user_id)
            VALUES (?,?,?,?,?,?,?,?,?,?,?)
        """, vals)
    db.commit()
    db.close()
    return jsonify({"message": "Profile saved successfully!"})