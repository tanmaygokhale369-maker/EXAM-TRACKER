from flask import Blueprint, request, jsonify
from database import get_db
from utils.helpers import login_required, scan_and_generate_notifications

notifications_bp = Blueprint("notifications", __name__)

@notifications_bp.route("/", methods=["GET"])
@login_required
def list_notifications(uid):
    scan_and_generate_notifications(uid)
    db = get_db()
    rows = db.execute("""
        SELECT n.*, e.name AS exam_name, e.website AS exam_website
        FROM notifications n
        LEFT JOIN exams e ON e.id = n.exam_id
        WHERE n.user_id=?
        ORDER BY n.is_read ASC, n.sent_at DESC
    """, (uid,)).fetchall()
    unread = db.execute(
        "SELECT COUNT(*) FROM notifications WHERE user_id=? AND is_read=0",
        (uid,)
    ).fetchone()[0]
    db.close()
    return jsonify({"notifications": [dict(r) for r in rows], "unread": unread, "total": len(rows)})

@notifications_bp.route("/read", methods=["POST"])
@login_required
def mark_read(uid):
    d = request.get_json() or {}
    db = get_db()
    if d.get("all"):
        db.execute("UPDATE notifications SET is_read=1 WHERE user_id=?", (uid,))
        msg = "All notifications marked as read"
    elif d.get("id"):
        db.execute("UPDATE notifications SET is_read=1 WHERE user_id=? AND id=?", (uid, d["id"]))
        msg = "Marked as read"
    else:
        db.close()
        return jsonify({"error": "Pass 'id' or 'all'"}), 400
    db.commit()
    db.close()
    return jsonify({"message": msg})

@notifications_bp.route("/<int:nid>", methods=["DELETE"])
@login_required
def delete_notification(uid, nid):
    db = get_db()
    db.execute("DELETE FROM notifications WHERE user_id=? AND id=?", (uid, nid))
    db.commit()
    db.close()
    return jsonify({"message": "Deleted"})

@notifications_bp.route("/scan", methods=["POST"])
@login_required
def trigger_scan(uid):
    created = scan_and_generate_notifications(uid)
    return jsonify({"message": f"Scan complete. {created} new alerts created.", "created": created})