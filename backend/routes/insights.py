from flask import Blueprint, jsonify
from database import get_db
from utils.helpers import login_required, build_daily_insights, build_course_suggestions

insights_bp = Blueprint("insights", __name__)

@insights_bp.route("/daily", methods=["GET"])
@login_required
def daily_insights(uid):
    insights = build_daily_insights(uid)
    return jsonify({"insights": insights, "count": len(insights)})

@insights_bp.route("/courses", methods=["GET"])
@login_required
def course_suggestions(uid):
    db = get_db()
    prof = db.execute("SELECT * FROM profiles WHERE user_id=?", (uid,)).fetchone()
    db.close()
    courses = build_course_suggestions(dict(prof) if prof else {})
    return jsonify({"courses": courses, "count": len(courses)})