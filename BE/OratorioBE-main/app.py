from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from db import get_connection
from routes.destinations import destinations_bp
import logging
import os

# ================================
# Flask App + Static Files Config
# ================================
app = Flask(
    __name__,
    static_url_path="/assets",  
    static_folder=os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "assets"
    )
)
CORS(app)

# ================================
# Static Route for Images
# ================================
@app.route('/assets/<path:filename>')
def serve_assets(filename):
    return send_from_directory(os.path.join(app.root_path, "assets"), filename)

# ================================
# Logging
# ================================
logging.basicConfig(level=logging.INFO)

# ================================
# REGISTER
# ================================
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
        logging.error(f"Error during registration: {e}")
        conn.rollback()
        return jsonify({"status": "error", "message": "Terjadi kesalahan saat menyimpan data"}), 500

    finally:
        cursor.close()
        conn.close()

# ================================
# LOGIN
# ================================
@app.route("/api/login", methods=["POST"])
def login():
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

        admin_email = "yogaardian114@student.uns.ac.id"
        role = "admin" if user["email"] == admin_email else user["role"]

        return jsonify({
            "status": "ok",
            "message": "Login berhasil",
            "user": {
                "user_id": user.get("user_id"),
                "email": user["email"],
                "username": user["email"].split("@")[0],
                "role": role
            }
        }), 200

    except Exception as e:
        logging.error(f"Error during login: {e}")
        return jsonify({"status": "error", "message": "Terjadi kesalahan server"}), 500

    finally:
        cursor.close()
        conn.close()

# ================================
# REGISTER BLUEPRINTS
# ================================
app.register_blueprint(destinations_bp, url_prefix="/api")

# ================================
# RUN SERVER
# ================================
if __name__ == "__main__":
    app.run(debug=True, port=5000)
