from flask import Flask
from flask_cors import CORS
import threading
import time

from database import init_db
from utils.helpers import get_jwt_secret
from routes.auth          import auth
from routes.profile       import profile_bp
from routes.exams         import exams_bp
from routes.dashboard     import dashboard_bp
from routes.notifications import notifications_bp
from routes.preferences   import preferences_bp
from routes.insights      import insights_bp
from routes.admin         import admin_bp


def create_app() -> Flask:
    get_jwt_secret()
    app = Flask(__name__)
    CORS(app, origins="*")

    app.register_blueprint(auth,             url_prefix="/api/auth")
    app.register_blueprint(profile_bp,       url_prefix="/api/profile")
    app.register_blueprint(exams_bp,         url_prefix="/api/exams")
    app.register_blueprint(dashboard_bp,     url_prefix="/api/dashboard")
    app.register_blueprint(notifications_bp, url_prefix="/api/notifications")
    app.register_blueprint(preferences_bp,   url_prefix="/api/preferences")
    app.register_blueprint(insights_bp,      url_prefix="/api/insights")
    app.register_blueprint(admin_bp,         url_prefix="/api/admin")

    @app.route("/")
    def index():
        return {
            "status": "Exam Tracker API running!",
            "version": "2.0",
            "fcm": "enabled",
        }

    return app


def _fcm_scheduler():
    """
    Background thread:
    - Runs immediately on start (after 5 seconds)
    - Then repeats every 1 hour
    """
    from utils.helpers import scan_and_notify_all_users
    print("✅ FCM scheduler started")

    # First run after just 5 seconds so we don't wait 1 hour to test
    time.sleep(5)
    print("🔔 Running first FCM scan...")
    try:
        count = scan_and_notify_all_users()
        print(f"✅ First scan done — {count} notifications sent")
    except Exception as e:
        print(f"❌ First scan error: {e}")

    # Then repeat every 1 hour
    while True:
        time.sleep(3600)
        print("🔔 Hourly FCM scan running...")
        try:
            count = scan_and_notify_all_users()
            print(f"✅ Hourly scan done — {count} sent")
        except Exception as e:
            print(f"❌ Scheduler error: {e}")


if __name__ == "__main__":
    init_db()
    app = create_app()

    # Start FCM background scheduler thread
    t = threading.Thread(target=_fcm_scheduler, daemon=True)
    t.start()

    app.run(debug=False, host="0.0.0.0", port=5000)