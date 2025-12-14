# D:\yogss\oratorio\BE\OratorioBE-main\app.py (FILE TUNGGAL)

import os
import logging
import json
from datetime import datetime, timedelta
from flask import Flask, request, jsonify, send_from_directory, Blueprint
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
from db import get_connection # Asumsi db.py ada
import jwt
from functools import wraps

# --- INI ADALAH INISIALISASI FLASK-SQLAlchemy DAN FLASK-MIGRATE ---
# Karena kita tidak menggunakan app/extensions.py, kita inisialisasi di sini.
# Pastikan Anda sudah menginstal: pip install Flask-SQLAlchemy Flask-Migrate
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

db = SQLAlchemy()
migrate = Migrate()
# -----------------------------------------------------------------

logging.basicConfig(level=logging.INFO)

# --- APLIKASI UTAMA ---
app = Flask(
    __name__,
    static_url_path="/assets",
    static_folder=os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets")
)
CORS(app)

# Konfigurasi database untuk Flask-SQLAlchemy (ANDA HARUS MENGUBAH INI)
# Ganti dengan koneksi database Anda yang sebenarnya
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://user:password@localhost/your_db' 
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Inisialisasi ekstensi ke aplikasi
db.init_app(app)
migrate.init_app(app, db)


# --- SECURITY CONSTANTS & UTILITY ---
SECRET_KEY = 'your_secret_key_here_for_jwt' # Ganti dengan key yang aman
TOKEN_LIFESPAN = timedelta(hours=24) 

def token_required(f):
    """Decorator untuk memeriksa JWT token dan menyimpan user_id ke request.current_user_id."""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        
        if not token or not token.startswith('Bearer '):
            return jsonify({'message': 'Authorization header is missing or malformed!'}), 401
        
        try:
            token = token.split(" ")[1]
            data = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
            # Menyimpan user_id ke objek request
            request.current_user_id = data['user_id']
            
        except jwt.ExpiredSignatureError:
            return jsonify({'message': 'Token has expired!'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'message': 'Token is invalid!'}), 401
        except Exception as e:
            logging.error(f"JWT Decoding Error: {e}")
            return jsonify({'message': 'Invalid token format or server error!'}), 401
            
        return f(*args, **kwargs)
    return decorated
# --- END SECURITY UTILITY ---


# UPLOAD FOLDER
UPLOAD_FOLDER = os.path.join(app.root_path, 'static', 'uploads')
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

def save_file(file):
    filename = secure_filename(file.filename)
    path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    file.save(path)
    return filename

# Static serving helpers
@app.route('/assets/<path:filename>')
def serve_assets(filename):
    return send_from_directory(os.path.join(app.root_path, "assets"), filename)

@app.route('/static/uploads/<path:filename>')
def serve_uploads(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# =========================================================================
# === START USER ROUTES (BP) ==============================================
# =========================================================================

# Kita menggunakan objek 'app' langsung, bukan Blueprint, karena ini file tunggal.

# GET /api/users -> list semua user aktif
@app.route("/api/users", methods=["GET"])
@token_required 
def get_users():
    conn = get_connection()
    if not conn:
        return jsonify({"message": "DB connection failed"}), 500
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT user_id, name, email, role, phone, dob, hometown 
            FROM users 
            WHERE is_active = 1
            ORDER BY user_id DESC
        """)
        rows = cursor.fetchall()
        print(f"[GET USERS] Fetched {len(rows)} active users")
        return jsonify(rows or []), 200
    except Exception as e:
        print(f"[GET USERS] Error: {e}")
        return jsonify({"message": str(e)}), 500
    finally:
        if 'cursor' in locals() and cursor: cursor.close()
        if 'conn' in locals() and conn: conn.close()

# DELETE /api/users/<id> -> soft delete (set is_active = 0)
@app.route("/api/users/<int:user_id>", methods=["DELETE"])
@token_required 
def delete_user(user_id):
    conn = get_connection()
    if not conn:
        return jsonify({"message": "DB connection failed"}), 500
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT user_id, email FROM users WHERE user_id = %s", (user_id,))
        row = cursor.fetchone()
        if not row:
            print(f"[DELETE] User {user_id} not found")
            return jsonify({"message": "User not found"}), 404

        cursor.execute("UPDATE users SET is_active = 0 WHERE user_id = %s", (user_id,))
        conn.commit()
        print(f"[DELETE] Soft-deleted user {user_id} ({row[1]})")
        
        return jsonify({"message": "User deleted"}), 200
    except Exception as e:
        print(f"[DELETE] Error: {e}")
        conn.rollback()
        return jsonify({"message": str(e)}), 500
    finally:
        if 'cursor' in locals() and cursor: cursor.close()
        if 'conn' in locals() and conn: conn.close()

# GET /api/users/profile -> get current user profile
@app.route("/api/users/profile", methods=["GET"])
@token_required
def get_profile():
    # Ambil ID pengguna yang sudah diverifikasi dari token JWT
    user_id = request.current_user_id 
    
    conn = get_connection()
    if not conn:
        return jsonify({"message": "DB connection failed"}), 500
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT user_id, name, email, phone, dob, hometown 
            FROM users 
            WHERE user_id = %s AND is_active = 1
        """, (user_id,))
        row = cursor.fetchone()
        
        if not row:
            return jsonify({"message": "User not found or inactive"}), 404
            
        # Normalisasi data
        name = row.get("name", "")
        name_parts = name.split(" ")
        firstName = name_parts[0] if name_parts and name_parts[0] else ""
        lastName = " ".join(name_parts[1:]) if len(name_parts) > 1 else ""
        
        profile = {
            "firstName": firstName,
            "lastName": lastName,
            "username": name.replace(" ", "").lower() or row["email"].split("@")[0],
            "email": row["email"],
            "phone": row.get("phone") or "", 
            "dob": row.get("dob").strftime('%Y-%m-%d') if row.get("dob") and isinstance(row["dob"], datetime) else row.get("dob") or "",
            "hometown": row.get("hometown") or "" 
        }
        return jsonify(profile), 200
    except Exception as e:
        print(f"[GET PROFILE] Error: {e}")
        return jsonify({"message": "Internal Server Error during profile retrieval. Check database columns."}), 500
    finally:
        if 'cursor' in locals() and cursor: cursor.close()
        if 'conn' in locals() and conn: conn.close()

# PUT /api/users/profile -> update profile
@app.route("/api/users/profile", methods=["PUT"])
@token_required
def update_profile():
    user_id = request.current_user_id 
    
    data = request.get_json()
    conn = get_connection()
    if not conn:
        return jsonify({"message": "DB connection failed"}), 500
    cursor = conn.cursor()
    try:
        name = f"{data.get('firstName', '')} {data.get('lastName', '')}".strip()
        email = data.get('email', '')
        phone = data.get('phone', '')
        dob = data.get('dob', '')
        hometown = data.get('hometown', '')
        
        cursor.execute("""
            UPDATE users SET 
            name = %s, 
            email = %s,
            phone = %s,
            dob = %s,
            hometown = %s
            WHERE user_id = %s
        """, (name, email, phone, dob, hometown, user_id))
        
        conn.commit()
        if cursor.rowcount == 0:
            return jsonify({"message": "User not found or no changes made"}), 200 
            
        return jsonify({"message": "Profile updated"}), 200
    except Exception as e:
        print(f"[UPDATE PROFILE] Error: {e}")
        conn.rollback()
        return jsonify({"message": "Internal Server Error during profile update. Check database columns."}), 500
    finally:
        if 'cursor' in locals() and cursor: cursor.close()
        if 'conn' in locals() and conn: conn.close()
        
# =========================================================================
# === END USER ROUTES / START AR API (CRUD) ===============================
# =========================================================================

# ... (Semua route API AR, History, dan Auth yang tersisa)

# -----------------------
# AR API (CRUD)
# -----------------------

@app.route('/api/wisata', methods=['GET'])
def get_all_wisata():
    conn = get_connection()
    if not conn:
        return jsonify({"status": "error", "message": "Database connection failed"}), 500
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT * FROM ar_destinations ORDER BY id DESC")
        items = cursor.fetchall()
        return jsonify(items), 200
    except Exception as e:
        logging.error("Error fetching wisata: %s", e)
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/api/wisata/<int:id>', methods=['GET'])
def get_wisata_detail(id):
    conn = get_connection()
    if not conn:
        return jsonify({"status": "error", "message": "Database connection failed"}), 500
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT * FROM ar_destinations WHERE id = %s", (id,))
        item = cursor.fetchone()
        if item:
            return jsonify(item), 200
        return jsonify({"status": "error", "message": "Not found"}), 404
    except Exception as e:
        logging.error("Error fetching wisata detail: %s", e)
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/api/wisata', methods=['POST'])
def add_wisata():
    if 'marker' not in request.files or 'mind' not in request.files or 'model' not in request.files:
        return jsonify({"status": "error", "message": "Files marker/mind/model required"}), 400

    name = request.form.get('name') or ""
    description = request.form.get('description') or ""
    location = request.form.get('location') or ""

    marker = request.files['marker']
    mind = request.files['mind']
    model = request.files['model']

    try:
        marker_filename = save_file(marker)
        mind_filename = save_file(mind)
        model_filename = save_file(model)

        conn = get_connection()
        if not conn:
            return jsonify({"status": "error", "message": "DB connection failed"}), 500
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO ar_destinations (name, description, location, marker_image, mind_file, glb_model)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (name, description, location, marker_filename, mind_filename, model_filename))
        conn.commit()
        new_id = cursor.lastrowid
        return jsonify({"status": "ok", "message": "Created", "id": new_id}), 201
    except Exception as e:
        logging.error("Error adding wisata: %s", e)
        if 'conn' in locals():
            conn.rollback()
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'conn' in locals():
            conn.close()

@app.route('/api/wisata/<int:id>', methods=['PUT'])
def update_wisata(id):
    conn = get_connection()
    if not conn:
        return jsonify({"status": "error", "message": "DB connection failed"}), 500
    cursor = conn.cursor()
    try:
        if request.content_type and request.content_type.startswith('multipart/form-data'):
            name = request.form.get('name')
            description = request.form.get('description')
            location = request.form.get('location')

            set_parts = []
            params = []

            if name is not None:
                set_parts.append("name=%s"); params.append(name)
            if description is not None:
                set_parts.append("description=%s"); params.append(description)
            if location is not None:
                set_parts.append("location=%s"); params.append(location)

            if 'marker' in request.files:
                marker_filename = save_file(request.files['marker'])
                set_parts.append("marker_image=%s"); params.append(marker_filename)
            if 'mind' in request.files:
                mind_filename = save_file(request.files['mind'])
                set_parts.append("mind_file=%s"); params.append(mind_filename)
            if 'model' in request.files:
                model_filename = save_file(request.files['model'])
                set_parts.append("glb_model=%s"); params.append(model_filename)

            if not set_parts:
                return jsonify({"status": "error", "message": "No fields to update"}), 400

            params.append(id)
            query = f"UPDATE ar_destinations SET {', '.join(set_parts)} WHERE id = %s"
            cursor.execute(query, tuple(params))
            conn.commit()
            if cursor.rowcount == 0:
                return jsonify({"status": "error", "message": "Not found"}), 404
            return jsonify({"status": "ok", "message": "Updated"}), 200
        else:
            data = request.json or {}
            allowed = ['name', 'description', 'location']
            set_parts = []
            params = []
            for k in allowed:
                if k in data:
                    set_parts.append(f"{k}=%s")
                    params.append(data[k])
            if not set_parts:
                return jsonify({"status": "error", "message": "No fields to update"}), 400
            params.append(id)
            query = f"UPDATE ar_destinations SET {', '.join(set_parts)} WHERE id = %s"
            cursor.execute(query, tuple(params))
            conn.commit()
            if cursor.rowcount == 0:
                return jsonify({"status": "error", "message": "Not found"}), 404
            return jsonify({"status": "ok", "message": "Updated"}), 200
    except Exception as e:
        logging.error("Error updating wisata: %s", e)
        conn.rollback()
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/api/wisata/<int:id>', methods=['DELETE'])
def delete_wisata(id):
    conn = get_connection()
    if not conn:
        return jsonify({"status": "error", "message": "DB connection failed"}), 500
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT marker_image, mind_file, glb_model FROM ar_destinations WHERE id = %s", (id,))
        row = cursor.fetchone()
        if not row:
            return jsonify({"status": "error", "message": "Not found"}), 404

        cursor.execute("DELETE FROM ar_destinations WHERE id = %s", (id,))
        conn.commit()

        for key in ("marker_image", "mind_file", "glb_model"):
            fname = row.get(key)
            if fname:
                try:
                    os.remove(os.path.join(app.config['UPLOAD_FOLDER'], fname))
                except Exception:
                    pass

        return jsonify({"status": "ok", "message": "Deleted"}), 200
    except Exception as e:
        logging.error("Error deleting wisata: %s", e)
        conn.rollback()
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

# -----------------------
# History API (new)
# -----------------------
@app.route('/api/history', methods=['POST'])
@token_required 
def add_history():
    user_id_from_token = request.current_user_id 
    
    data = request.json or {}
    user_id = data.get('user_id')
    user_email = data.get('user_email') 
    
    destination_id = data.get('destination_id')
    action = data.get('action', 'scan_start')
    model_type = data.get('model_type', 'AR')
    started_at = data.get('started_at') 
    ended_at = data.get('ended_at')
    duration_seconds = data.get('duration_seconds')
    metadata = data.get('metadata')

    if not user_id or not destination_id:
        return jsonify({"message": "user_id dan destination_id diperlukan"}), 400

    try:
        if started_at:
            started_str = datetime.fromisoformat(started_at).strftime('%Y-%m-%d %H:%M:%S')
        else:
            started_str = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
    except Exception:
        started_str = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')

    try:
        conn = get_connection()
        if not conn:
            return jsonify({"message":"DB connection failed"}), 500
        cursor = conn.cursor()
        query = """
            INSERT INTO history (user_id, user_email, destination_id, action, model_type, started_at, ended_at, duration_seconds, metadata)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(query, (
            user_id,
            user_email,
            destination_id,
            action,
            model_type,
            started_str,
            ended_at if ended_at else None,
            duration_seconds,
            json.dumps(metadata) if metadata else None
        ))
        conn.commit()
        hid = cursor.lastrowid
        cursor.close()
        conn.close()
        return jsonify({"message":"ok","history_id":hid}), 201
    except Exception as e:
        logging.error("Error add_history: %s", e)
        return jsonify({"message": str(e)}), 500

@app.route('/api/history', methods=['GET'])
@token_required 
def get_all_history():
    conn = get_connection()
    if not conn:
        return jsonify({"message":"DB connection failed"}), 500
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT h.*, d.name as destination_name FROM history h LEFT JOIN ar_destinations d ON h.destination_id = d.id ORDER BY h.started_at DESC LIMIT 1000")
        rows = cursor.fetchall()
        return jsonify(rows), 200
    except Exception as e:
        logging.error("Error get_all_history: %s", e)
        return jsonify({"message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/api/history/user/<int:user_id>', methods=['GET'])
@token_required 
def get_history_by_user(user_id):
    conn = get_connection()
    if not conn:
        return jsonify({"message":"DB connection failed"}), 500
    cursor = conn.cursor(dictionary=True)
    try:
        if request.current_user_id != user_id:
             return jsonify({'message': 'Akses ditolak: Tidak diizinkan melihat history pengguna lain.'}), 403
             
        cursor.execute("SELECT h.*, d.name as destination_name FROM history h LEFT JOIN ar_destinations d ON h.destination_id = d.id WHERE h.user_id = %s ORDER BY h.started_at DESC LIMIT 500", (user_id,))
        rows = cursor.fetchall()
        return jsonify(rows), 200
    except Exception as e:
        logging.error("Error get_history_by_user: %s", e)
        return jsonify({"message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

# -----------------------
# AUTH routes
# -----------------------
@app.route("/api/register", methods=["POST"])
def register():
    data = request.json
    email = data.get("email")
    password = data.get("password")
    name = data.get("name") or (email.split("@")[0] if email else None)

    if not email or not password:
        return jsonify({"status": "error", "message": "Field Email atau Password hilang"}), 400

    hashed_password = generate_password_hash(password)

    conn = get_connection()
    if not conn:
        return jsonify({"status": "error", "message": "Gagal terhubung ke database"}), 500

    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT * FROM users WHERE email=%s", (email,))
        if cursor.fetchone():
            return jsonify({"status": "error", "message": "Email sudah terdaftar"}), 400

        # Catatan: Pastikan kolom 'phone', 'dob', 'hometown' memiliki nilai default atau nullable
        cursor.execute("""
            INSERT INTO users (name, email, password, role)
            VALUES (%s, %s, %s, %s)
        """, (name, email, hashed_password, "user"))
        conn.commit()
        return jsonify({"status": "ok", "message": "Registrasi berhasil"}), 201
    except Exception as e:
        logging.error("Error during registration: %s", e)
        conn.rollback()
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route("/api/login", methods=["POST"])
def login():
    data = request.json
    email = data.get("email")
    password = data.get("password")

    conn = get_connection()
    if not conn:
        return jsonify({"status": "error", "message": "Gagal terhubung ke database."}), 500

    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT user_id, email, password, role, name FROM users WHERE email=%s", (email,))
        user = cursor.fetchone()
        if not user:
            return jsonify({"status": "error", "message": "Email tidak ditemukan"}), 401

        if not check_password_hash(user["password"], password):
            return jsonify({"status": "error", "message": "Password salah"}), 401

        admin_email = "yogaardian114@student.uns.ac.id"
        role = "admin" if user["email"] == admin_email else user.get("role", "user")

        # Generate JWT token
        token = jwt.encode({
            'user_id': user['user_id'],
            'exp': datetime.utcnow() + TOKEN_LIFESPAN
        }, SECRET_KEY, algorithm='HS256')

        return jsonify({
            "status": "ok",
            "message": "Login berhasil",
            "token": token,
            "user": {
                "user_id": user.get("user_id"),
                "email": user["email"],
                "username": user.get("name") or user["email"].split("@")[0],
                "role": role
            }
        }), 200
    except Exception as e:
        logging.error("Error during login: %s", e)
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)