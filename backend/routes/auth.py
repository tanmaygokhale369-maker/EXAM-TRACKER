import jwt
import datetime
from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from database import get_db
from utils.helpers import get_jwt_secret, login_required

auth = Blueprint('auth', __name__)


@auth.route('/register', methods=['POST'])
def register():
    d = request.get_json() or {}
    email    = (d.get('email') or '').strip().lower()
    password = d.get('password') or ''
    if not email or not password:
        return jsonify({'error': 'Email and password required'}), 400
    db = get_db()
    if db.execute('SELECT id FROM users WHERE email=?', (email,)).fetchone():
        db.close()
        return jsonify({'error': 'Email already registered'}), 400
    db.execute('INSERT INTO users(email, password) VALUES(?,?)',
               (email, generate_password_hash(password)))
    db.commit()
    uid = db.execute('SELECT id FROM users WHERE email=?', (email,)).fetchone()['id']
    token = jwt.encode(
        {'user_id': uid,
         'exp': datetime.datetime.utcnow() + datetime.timedelta(days=30)},
        get_jwt_secret(), algorithm='HS256'
    )
    db.close()
    return jsonify({'token': token, 'user_id': uid}), 201


@auth.route('/login', methods=['POST'])
def login():
    d = request.get_json() or {}
    email    = (d.get('email') or '').strip().lower()
    password = d.get('password') or ''
    db  = get_db()
    row = db.execute('SELECT * FROM users WHERE email=?', (email,)).fetchone()
    db.close()
    if not row or not check_password_hash(row['password'], password):
        return jsonify({'error': 'Invalid email or password'}), 401
    token = jwt.encode(
        {'user_id': row['id'],
         'exp': datetime.datetime.utcnow() + datetime.timedelta(days=30)},
        get_jwt_secret(), algorithm='HS256'
    )
    return jsonify({
        'token':    token,
        'user_id':  row['id'],
        'is_admin': bool(row['is_admin']),
    })


@auth.route('/fcm-token', methods=['POST'])
@login_required
def save_fcm_token(uid):
    d     = request.get_json() or {}
    token = d.get('fcm_token')
    if not token:
        return jsonify({'error': 'fcm_token required'}), 400
    db = get_db()
    db.execute('UPDATE users SET fcm_token=? WHERE id=?', (token, uid))
    db.commit()
    db.close()
    print(f'✅ FCM token saved for user {uid}')
    return jsonify({'message': 'FCM token saved'})


@auth.route('/set-pin', methods=['POST'])
@login_required
def set_pin(uid):
    d   = request.get_json() or {}
    pin = d.get('pin')
    if not pin or len(str(pin)) != 4:
        return jsonify({'error': 'PIN must be 4 digits'}), 400
    db = get_db()
    db.execute('UPDATE users SET pin=? WHERE id=?',
               (generate_password_hash(str(pin)), uid))
    db.commit()
    db.close()
    return jsonify({'message': 'PIN set successfully'})


@auth.route('/verify-pin', methods=['POST'])
@login_required
def verify_pin(uid):
    d   = request.get_json() or {}
    pin = str(d.get('pin') or '')
    db  = get_db()
    row = db.execute('SELECT pin FROM users WHERE id=?', (uid,)).fetchone()
    db.close()
    if not row or not row['pin']:
        return jsonify({'error': 'No PIN set'}), 400
    if check_password_hash(row['pin'], pin):
        return jsonify({'message': 'PIN verified', 'valid': True})
    return jsonify({'error': 'Incorrect PIN', 'valid': False}), 401


@auth.route('/remove-pin', methods=['POST'])
@login_required
def remove_pin(uid):
    db = get_db()
    db.execute('UPDATE users SET pin=NULL WHERE id=?', (uid,))
    db.commit()
    db.close()
    return jsonify({'message': 'PIN removed'})


@auth.route('/me', methods=['GET'])
@login_required
def me(uid):
    db  = get_db()
    row = db.execute(
        'SELECT id, email, is_admin, fcm_token FROM users WHERE id=?',
        (uid,)
    ).fetchone()
    db.close()
    if not row:
        return jsonify({'error': 'User not found'}), 404
    return jsonify({
        'id':       row['id'],
        'email':    row['email'],
        'is_admin': bool(row['is_admin']),
        'has_fcm':  bool(row['fcm_token']),
    })