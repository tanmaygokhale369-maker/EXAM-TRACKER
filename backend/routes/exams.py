from flask import Blueprint, request, jsonify
from database import get_db
from utils.helpers import login_required, deadline_info, is_eligible

exams_bp = Blueprint("exams", __name__)


def enrich(ex, profile=None, uid=None, db=None):
    ex["deadline"] = deadline_info(ex.get("last_date"))
    if profile:
        e = is_eligible(ex, profile)
        ex["eligible"] = e["ok"]
        ex["reasons"]  = e["reasons"]
        ex["my_fee"]   = e.get("fee", 0)
    else:
        ex["eligible"] = True
        ex["reasons"]  = []
        ex["my_fee"]   = ex.get("fee_general") or 0

    ex["fees"] = {
        "General": ex.get("fee_general") or 0,
        "OBC":     ex.get("fee_obc")     or 0,
        "SC":      ex.get("fee_sc")      or 0,
        "ST":      ex.get("fee_st")      or 0,
        "PwD":     ex.get("fee_pwd")     or 0,
        "Female":  ex.get("fee_female")  or 0,
    }
    # Remove zero-fee entries so UI only shows relevant rows
    ex["fees"] = {k: v for k, v in ex["fees"].items() if v > 0}

    if uid and db:
        bm = db.execute(
            "SELECT id FROM bookmarks WHERE user_id=? AND exam_id=?",
            (uid, ex["id"])
        ).fetchone()
        ex["bookmarked"] = bm is not None
    else:
        ex["bookmarked"] = False
    return ex


@exams_bp.route("/", methods=["GET"])
@login_required
def all_exams(uid):
    db   = get_db()
    prof = db.execute("SELECT * FROM profiles WHERE user_id=?", (uid,)).fetchone()
    p    = dict(prof) if prof else None
    rows = db.execute(
        "SELECT * FROM exams WHERE is_active=1 ORDER BY last_date"
    ).fetchall()
    result = [enrich(dict(r), profile=p, uid=uid, db=db) for r in rows]
    db.close()
    return jsonify({"exams": result, "count": len(result)})


@exams_bp.route("/eligible", methods=["GET"])
@login_required
def eligible_exams(uid):
    db   = get_db()
    prof = db.execute("SELECT * FROM profiles WHERE user_id=?", (uid,)).fetchone()
    if not prof:
        db.close()
        return jsonify({"error": "Please complete your profile first"}), 404
    p    = dict(prof)
    rows = db.execute(
        "SELECT * FROM exams WHERE is_active=1 ORDER BY last_date"
    ).fetchall()
    yes, no = [], []
    for r in rows:
        ex = enrich(dict(r), profile=p, uid=uid, db=db)
        (yes if ex["eligible"] else no).append(ex)
    db.close()
    return jsonify({"eligible": yes, "not_eligible": no})


@exams_bp.route("/<int:eid>", methods=["GET"])
@login_required
def exam_detail(uid, eid):
    db   = get_db()
    row  = db.execute("SELECT * FROM exams WHERE id=?", (eid,)).fetchone()
    if not row:
        db.close()
        return jsonify({"error": "Exam not found"}), 404
    prof = db.execute("SELECT * FROM profiles WHERE user_id=?", (uid,)).fetchone()
    ex   = enrich(dict(row), profile=dict(prof) if prof else None, uid=uid, db=db)
    db.close()
    return jsonify({"exam": ex})


@exams_bp.route("/search", methods=["GET"])
@login_required
def search(uid):
    q    = request.args.get("q", "")
    db   = get_db()
    prof = db.execute("SELECT * FROM profiles WHERE user_id=?", (uid,)).fetchone()
    p    = dict(prof) if prof else None
    rows = db.execute(
        "SELECT * FROM exams WHERE is_active=1 AND name LIKE ?",
        (f"%{q}%",)
    ).fetchall()
    result = [enrich(dict(r), profile=p, uid=uid, db=db) for r in rows]
    db.close()
    return jsonify({"exams": result})


@exams_bp.route("/bookmark/<int:eid>", methods=["POST"])
@login_required
def bookmark(uid, eid):
    db = get_db()
    bm = db.execute(
        "SELECT id FROM bookmarks WHERE user_id=? AND exam_id=?", (uid, eid)
    ).fetchone()
    if bm:
        db.execute("DELETE FROM bookmarks WHERE user_id=? AND exam_id=?", (uid, eid))
        msg, state = "Bookmark removed", False
    else:
        db.execute("INSERT INTO bookmarks(user_id,exam_id) VALUES(?,?)", (uid, eid))
        msg, state = "Bookmarked!", True
    db.commit()
    db.close()
    return jsonify({"message": msg, "bookmarked": state})