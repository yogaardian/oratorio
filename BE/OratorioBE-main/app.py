# D:\yogss\oratorio\BE\OratorioBE-main\app.py (FILE TUNGGAL)

import os
import logging
import json
from datetime import datetime, timedelta
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
from db import get_connection  # Asumsi db.py ada
import jwt
from functools import wraps

logging.basicConfig(level=logging.INFO)

# --- APLIKASI UTAMA ---
app = Flask(
    __name__,
    static_url_path="/assets",
    static_folder=os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets")
)
CORS(app)

# --- SECURITY CONSTANTS & UTILITY ---
SECRET_KEY = 'your_secret_key_here_for_jwt'  # Ganti dengan key yang aman
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
# === START USER ROUTES ===================================================
# =========================================================================

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
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


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
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


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
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


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
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


# =========================================================================
# === AR API (CRUD) =======================================================
# =========================================================================

# GET semua wisata
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


# GET detail wisata
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


# POST tambah wisata
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


# PUT update wisata
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
                set_parts.append("name=%s")
                params.append(name)
            if description is not None:
                set_parts.append("description=%s")
                params.append(description)
            if location is not None:
                set_parts.append("location=%s")
                params.append(location)

            if 'marker' in request.files:
                marker_filename = save_file(request.files['marker'])
                set_parts.append("marker_image=%s")
                params.append(marker_filename)
            if 'mind' in request.files:
                mind_filename = save_file(request.files['mind'])
                set_parts.append("mind_file=%s")
                params.append(mind_filename)
            if 'model' in request.files:
                model_filename = save_file(request.files['model'])
                set_parts.append("glb_model=%s")
                params.append(model_filename)

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


# DELETE wisata
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


# =========================================================================
# === HISTORY API =========================================================
# =========================================================================

@app.route('/api/history', methods=['POST'])
def add_history():
    """Endpoint untuk mencatat history scan - tanpa authentication untuk testing"""
    try:
        data = request.get_json()
        print(f"📥 Received history data: {data}")
        
        # Validasi data yang diperlukan
        required_fields = ['user_id', 'destination_id', 'action']
        for field in required_fields:
            if field not in data:
                print(f"❌ Missing required field: {field}")
                return jsonify({
                    "error": f"Missing required field: {field}",
                    "received_data": data
                }), 400
        
        user_id = data.get('user_id')
        destination_id = data.get('destination_id')
        action = data.get('action', 'scan_success')
        model_type = data.get('model_type', 'AR')
        user_email = data.get('user_email', '')
        
        # Jika tidak ada user_email, cari dari database
        if not user_email:
            try:
                conn_temp = get_connection()
                cursor_temp = conn_temp.cursor(dictionary=True)
                cursor_temp.execute("SELECT email FROM users WHERE user_id = %s", (user_id,))
                user = cursor_temp.fetchone()
                if user:
                    user_email = user['email']
                cursor_temp.close()
                conn_temp.close()
            except Exception:
                user_email = f"user_{user_id}@example.com"
        
        # Timestamp
        started_at = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
        
        # Simpan ke database
        conn = get_connection()
        if not conn:
            return jsonify({"message": "DB connection failed"}), 500
            
        cursor = conn.cursor()
        query = """
            INSERT INTO history (user_id, user_email, destination_id, action, model_type, started_at)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        cursor.execute(query, (
            user_id,
            user_email,
            destination_id,
            action,
            model_type,
            started_at
        ))
        
        conn.commit()
        history_id = cursor.lastrowid
        
        cursor.close()
        conn.close()
        
        print(f"✅ History recorded: user_id={user_id}, destination_id={destination_id}, action={action}")
        
        return jsonify({
            "message": "History recorded successfully",
            "history_id": history_id,
            "data": {
                "user_id": user_id,
                "user_email": user_email,
                "destination_id": destination_id,
                "action": action,
                "model_type": model_type,
                "timestamp": started_at
            }
        }), 201
        
    except Exception as e:
        print(f"❌ Error in /api/history: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/history/auth', methods=['POST'])
@token_required
def add_history_with_auth():
    """Endpoint untuk mencatat history scan - dengan authentication"""
    try:
        data = request.get_json()
        user_id_from_token = request.current_user_id
        print(f"📥 [AUTH] Received history data: {data}, user_id_from_token: {user_id_from_token}")
        
        # Validasi minimal
        if 'destination_id' not in data:
            return jsonify({
                "error": "Missing required field: destination_id",
                "received_data": data
            }), 400
        
        destination_id = data.get('destination_id')
        action = data.get('action', 'scan_success')
        model_type = data.get('model_type', 'AR')
        
        # Cari user_email dari database
        user_email = ""
        try:
            conn_temp = get_connection()
            cursor_temp = conn_temp.cursor(dictionary=True)
            cursor_temp.execute("SELECT email FROM users WHERE user_id = %s", (user_id_from_token,))
            user = cursor_temp.fetchone()
            if user:
                user_email = user['email']
            cursor_temp.close()
            conn_temp.close()
        except Exception:
            user_email = f"user_{user_id_from_token}@example.com"
        
        # Timestamp
        started_at = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
        
        # Simpan ke database
        conn = get_connection()
        if not conn:
            return jsonify({"message": "DB connection failed"}), 500
            
        cursor = conn.cursor()
        query = """
            INSERT INTO history (user_id, user_email, destination_id, action, model_type, started_at)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        cursor.execute(query, (
            user_id_from_token,
            user_email,
            destination_id,
            action,
            model_type,
            started_at
        ))
        
        conn.commit()
        history_id = cursor.lastrowid
        
        cursor.close()
        conn.close()
        
        print(f"✅ [AUTH] History recorded: user_id={user_id_from_token}, destination_id={destination_id}")
        
        return jsonify({
            "message": "History recorded successfully",
            "history_id": history_id
        }), 201
        
    except Exception as e:
        print(f"❌ [AUTH] Error in /api/history/auth: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/history', methods=['GET'])
@token_required
def get_all_history():
    conn = get_connection()
    if not conn:
        return jsonify({"message": "DB connection failed"}), 500
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT h.*, d.name as destination_name 
            FROM history h 
            LEFT JOIN ar_destinations d ON h.destination_id = d.id 
            ORDER BY h.started_at DESC 
            LIMIT 1000
        """)
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
        return jsonify({"message": "DB connection failed"}), 500
    cursor = conn.cursor(dictionary=True)
    try:
        if request.current_user_id != user_id:
            return jsonify({'message': 'Akses ditolak: Tidak diizinkan melihat history pengguna lain.'}), 403

        cursor.execute("""
            SELECT h.*, d.name as destination_name 
            FROM history h 
            LEFT JOIN ar_destinations d ON h.destination_id = d.id 
            WHERE h.user_id = %s 
            ORDER BY h.started_at DESC 
            LIMIT 500
        """, (user_id,))
        rows = cursor.fetchall()
        return jsonify(rows), 200
    except Exception as e:
        logging.error("Error get_history_by_user: %s", e)
        return jsonify({"message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()


# =========================================================================
# === AUTH ROUTES =========================================================
# =========================================================================

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


# =========================================================================
# === HEALTH CHECK & UTILITY ==============================================
# =========================================================================

@app.route('/')
def home():
    """Health check endpoint"""
    return jsonify({
        "message": "Flask server is running",
        "timestamp": datetime.utcnow().isoformat(),
        "endpoints": {
            "/api/wisata": "GET - Get all destinations",
            "/api/login": "POST - User login",
            "/api/register": "POST - User registration",
            "/api/history": "POST - Add history record (no auth)",
            "/api/history/auth": "POST - Add history record (with auth)",
            "/api/users/profile": "GET - Get user profile"
        }
    }), 200


@app.route('/health')
def health_check():
    """Simple health check"""
    return jsonify({"status": "healthy", "timestamp": datetime.utcnow().isoformat()}), 200


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)