from flask import Blueprint, request, jsonify
from database import get_db
from utils.helpers import admin_required

admin_bp = Blueprint("admin", __name__)


@admin_bp.route("/exams", methods=["GET"])
@admin_required
def list_all_exams(uid):
    db   = get_db()
    rows = db.execute("SELECT * FROM exams ORDER BY created_at DESC").fetchall()
    db.close()
    return jsonify({"exams": [dict(r) for r in rows], "count": len(rows)})


@admin_bp.route("/exams", methods=["POST"])
@admin_required
def create_exam(uid):
    d = request.get_json() or {}
    if not d.get("name") or not d.get("last_date"):
        return jsonify({"error": "name and last_date are required"}), 400
    db  = get_db()
    cur = db.execute("""
        INSERT INTO exams
          (name,description,category,start_date,last_date,exam_date,website,
           min_age,max_age,streams,min_qual,min_10th,min_12th,
           fee_general,fee_obc,fee_sc,fee_st,fee_pwd,fee_female,
           seats,mode,gender_allowed,eligibility_note,is_active)
        VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    """, (
        d.get("name"), d.get("description",""), d.get("category","Other"),
        d.get("start_date"), d.get("last_date"), d.get("exam_date"),
        d.get("website",""),
        int(d.get("min_age",0) or 0), int(d.get("max_age",99) or 99),
        d.get("streams","ALL"), d.get("min_qual","10th"),
        float(d.get("min_10th",0) or 0), float(d.get("min_12th",0) or 0),
        float(d.get("fee_general", d.get("fee",0)) or 0),
        float(d.get("fee_obc",    d.get("fee",0)) or 0),
        float(d.get("fee_sc",  0) or 0), float(d.get("fee_st",  0) or 0),
        float(d.get("fee_pwd", 0) or 0),
        float(d.get("fee_female", d.get("fee",0)) or 0),
        int(d.get("seats",0) or 0), d.get("mode","Online"),
        d.get("gender_allowed","ALL"), d.get("eligibility_note",""),
        1 if d.get("is_active", True) else 0,
    ))
    db.commit()
    row = db.execute("SELECT * FROM exams WHERE id=?", (cur.lastrowid,)).fetchone()
    db.close()
    return jsonify({"message":"Exam created","exam":dict(row)}), 201


@admin_bp.route("/exams/<int:eid>", methods=["PUT"])
@admin_required
def update_exam(uid, eid):
    d  = request.get_json() or {}
    db = get_db()
    if not db.execute("SELECT id FROM exams WHERE id=?", (eid,)).fetchone():
        db.close()
        return jsonify({"error":"Exam not found"}), 404
    allowed = ["name","description","category","start_date","last_date","exam_date",
               "website","min_age","max_age","streams","min_qual","min_10th","min_12th",
               "fee_general","fee_obc","fee_sc","fee_st","fee_pwd","fee_female",
               "seats","mode","gender_allowed","eligibility_note","is_active"]
    for key in allowed:
        if key in d:
            val = 1 if (key=="is_active" and d[key]) else (0 if key=="is_active" else d[key])
            db.execute(f"UPDATE exams SET {key}=? WHERE id=?", (val, eid))
    db.commit()
    row = db.execute("SELECT * FROM exams WHERE id=?", (eid,)).fetchone()
    db.close()
    return jsonify({"message":"Exam updated","exam":dict(row)})


@admin_bp.route("/exams/<int:eid>", methods=["DELETE"])
@admin_required
def delete_exam(uid, eid):
    db = get_db()
    if not db.execute("SELECT id FROM exams WHERE id=?", (eid,)).fetchone():
        db.close()
        return jsonify({"error":"Exam not found"}), 404
    db.execute("DELETE FROM exams WHERE id=?", (eid,))
    db.execute("DELETE FROM bookmarks WHERE exam_id=?", (eid,))
    db.execute("DELETE FROM notifications WHERE exam_id=?", (eid,))
    db.commit()
    db.close()
    return jsonify({"message":"Exam deleted"})


@admin_bp.route("/users", methods=["GET"])
@admin_required
def list_users(uid):
    db   = get_db()
    rows = db.execute("""
        SELECT u.id, u.email, u.is_admin, u.created_at,
               p.full_name, p.stream, p.qualification, p.status, p.caste
        FROM users u LEFT JOIN profiles p ON p.user_id=u.id
        ORDER BY u.created_at DESC
    """).fetchall()
    db.close()
    return jsonify({"users":[dict(r) for r in rows],"count":len(rows)})


@admin_bp.route("/broadcast", methods=["POST"])
@admin_required
def broadcast(uid):
    d = request.get_json() or {}
    if not d.get("title") or not d.get("body"):
        return jsonify({"error":"title and body required"}), 400
    db    = get_db()
    users = db.execute("SELECT id FROM users").fetchall()
    for u in users:
        db.execute("""INSERT INTO notifications(user_id,title,body,type,priority)
                      VALUES(?,?,?,?,?)""",
                   (u["id"], d["title"], d["body"],
                    d.get("type","info"), d.get("priority","medium")))
    db.commit()
    db.close()
    return jsonify({"message":f"Broadcast sent to {len(users)} users",
                    "recipients":len(users)})


@admin_bp.route("/stats", methods=["GET"])
@admin_required
def stats(uid):
    db = get_db()
    r  = {
        "users":        db.execute("SELECT COUNT(*) FROM users").fetchone()[0],
        "exams_total":  db.execute("SELECT COUNT(*) FROM exams").fetchone()[0],
        "exams_active": db.execute("SELECT COUNT(*) FROM exams WHERE is_active=1").fetchone()[0],
        "bookmarks":    db.execute("SELECT COUNT(*) FROM bookmarks").fetchone()[0],
        "notifications":db.execute("SELECT COUNT(*) FROM notifications").fetchone()[0],
    }
    db.close()
    return jsonify(r)