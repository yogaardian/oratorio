from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from db import get_connection # Diperlukan untuk koneksi DB
from routes.destinations import destinations_bp # Blueprint untuk rute CRUD Destinasi
import json
import logging

# Konfigurasi Logging
logging.basicConfig(level=logging.INFO)

app = Flask(__name__)
# Izinkan CORS untuk komunikasi dengan React Frontend (http://localhost:3000)
CORS(app)


# ---------------------------------------
# RUTE UTAMA (REGISTER & LOGIN)
# ---------------------------------------

# ---------------------------------------
# REGISTER
# ---------------------------------------
@app.route("/api/register", methods=["POST"])
def register():
    """Menangani pendaftaran pengguna baru."""
    data = request.json
    email = data.get("email")
    password = data.get("password")
    # Nama diambil dari input, atau default dari email
    name = data.get("name") or email.split("@")[0]

    if not email or not password:
        return jsonify({"status": "error", "message": "Field Email atau Password hilang"}), 400

    hashed = generate_password_hash(password)

    conn = get_connection()
    if not conn:
        return jsonify({"status": "error", "message": "Gagal terhubung ke database"}), 500

    cursor = conn.cursor(dictionary=True)

    try:
        # 1. Cek apakah email sudah terdaftar
        cursor.execute("SELECT * FROM users WHERE email=%s", (email,))
        exist = cursor.fetchone()

        if exist:
            return jsonify({"status": "error", "message": "Email sudah terdaftar"}), 400

        # 2. Insert user baru (default role: user)
        cursor.execute("""
            INSERT INTO users (name, email, password, role)
            VALUES (%s, %s, %s, %s)
        """, (name, email, hashed, "user"))

        conn.commit()
        return jsonify({"status": "ok", "message": "Registrasi berhasil"}), 201
    except Exception as e:
        logging.error(f"Error during registration: {e}")
        conn.rollback()
        return jsonify({"status": "error", "message": "Terjadi kesalahan saat menyimpan data"}), 500
    finally:
        cursor.close()
        conn.close()


# ---------------------------------------
# LOGIN
# ---------------------------------------
@app.route("/api/login", methods=["POST"])
def login():
    """Menangani proses login pengguna dan menentukan role (user/admin)."""
    data = request.json
    email = data.get("email")
    password = data.get("password")

    conn = get_connection()
    if not conn:
        return jsonify({"status": "error", "message": "Gagal terhubung ke database"}), 500

    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("SELECT * FROM users WHERE email=%s", (email,))
        user = cursor.fetchone()

        if not user:
            return jsonify({"status": "error", "message": "Email tidak ditemukan"}), 401

        if not check_password_hash(user["password"], password):
            return jsonify({"status": "error", "message": "Password salah"}), 401

        # -------------------------
        # LOGIKA PENENTUAN ROLE ADMIN
        # -------------------------
        # Gunakan email admin yang sudah ditentukan di kode kamu
        admin_email = "yogaardian114@student.uns.ac.id"
        if user["email"] == admin_email:
            user_role = "admin"
        else:
            # Gunakan role dari database jika bukan email admin spesial
            user_role = user["role"]
        # -------------------------

        # Membuat username dari email
        username = user["email"].split("@")[0]

        return jsonify({
            "status": "ok",
            "message": "Login berhasil",
            "user": {
                # Pastikan kolom di DB bernama 'user_id'
                "user_id": user.get("user_id"), 
                "email": user["email"],
                "username": username,
                "role": user_role
            }
        }), 200
    except Exception as e:
        logging.error(f"Error during login: {e}")
        return jsonify({"status": "error", "message": "Terjadi kesalahan server"}), 500
    finally:
        cursor.close()
        conn.close()


# ---------------------------------------
# BLUEPRINTS REGISTRATION (CRUD DESTINATIONS)
# ---------------------------------------
# Rute /api/destinations akan ditangani oleh destinations_bp
app.register_blueprint(destinations_bp, url_prefix="/api")


# ---------------------------------------
# RUN SERVER
# ---------------------------------------
if __name__ == "__main__":
    # Menggunakan port 5000 seperti yang ada di kode React kamu
    app.run(debug=True, port=5000)