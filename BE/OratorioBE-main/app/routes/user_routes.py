# # D:\yogss\oratorio\BE\OratorioBE-main\app\routes\user_routes.py

# from flask import Blueprint, request, jsonify, current_app
# from db import get_connection
# from datetime import datetime

# # 🎯 SOLUSI IMPORT: Ambil token_required dari auth.py
# from ..auth import token_required 

# # Definisi Blueprint
# user_bp = Blueprint("user_bp", __name__)

# # =========================================================================
# # === CRUD DASHBOARD ADMIN (Umum) ===
# # =========================================================================

# # GET /api/users 
# @user_bp.route("/", methods=["GET"])
# @token_required # Lindungi endpoint ini
# def get_users():
#     # Perhatian: Idealnya, Anda harus menambahkan cek otorisasi Admin di sini:
#     # if request.current_user_role != 'admin': return jsonify({'message': 'Forbidden'}), 403
    
#     conn = get_connection()
#     if not conn:
#         return jsonify({"message": "DB connection failed"}), 500
#     cursor = conn.cursor(dictionary=True)
#     try:
#         # Menambahkan kolom yang baru di-migrate (diasumsikan)
#         cursor.execute("""
#             SELECT user_id, name, email, role, phone, dob, hometown 
#             FROM users 
#             WHERE is_active = 1
#             ORDER BY user_id DESC
#         """)
#         rows = cursor.fetchall()
#         print(f"[GET USERS] Fetched {len(rows)} active users")
#         return jsonify(rows or []), 200
#     except Exception as e:
#         print(f"[GET USERS] Error: {e}")
#         return jsonify({"message": str(e)}), 500
#     finally:
#         if 'cursor' in locals() and cursor: cursor.close()
#         if 'conn' in locals() and conn: conn.close()

# # DELETE /api/users/<id> -> soft delete (set is_active = 0)
# @user_bp.route("/<int:user_id>", methods=["DELETE"])
# @token_required # Lindungi endpoint ini
# def delete_user(user_id):
#     # Otorisasi Admin
#     conn = get_connection()
#     if not conn:
#         return jsonify({"message": "DB connection failed"}), 500
#     cursor = conn.cursor()
#     try:
#         cursor.execute("SELECT user_id, email FROM users WHERE user_id = %s", (user_id,))
#         row = cursor.fetchone()
#         if not row:
#             print(f"[DELETE] User {user_id} not found")
#             return jsonify({"message": "User not found"}), 404

#         # SOFT DELETE: set is_active = 0 
#         cursor.execute("UPDATE users SET is_active = 0 WHERE user_id = %s", (user_id,))
#         conn.commit()
#         print(f"[DELETE] Soft-deleted user {user_id} ({row[1]})")
        
#         return jsonify({"message": "User deleted"}), 200
#     except Exception as e:
#         print(f"[DELETE] Error: {e}")
#         conn.rollback()
#         return jsonify({"message": str(e)}), 500
#     finally:
#         if 'cursor' in locals() and cursor: cursor.close()
#         if 'conn' in locals() and conn: conn.close()

# # =========================================================================
# # === PROFILE ENDPOINTS (Menggunakan ID dari Token) ===
# # =========================================================================

# # GET /api/users/profile -> get current user profile
# @user_bp.route("/profile", methods=["GET"])
# @token_required
# def get_profile():
#     # 🎯 Ambil ID pengguna yang sudah diverifikasi dari token JWT
#     user_id = request.current_user_id 
    
#     conn = get_connection()
#     if not conn:
#         return jsonify({"message": "DB connection failed"}), 500
#     cursor = conn.cursor(dictionary=True)
#     try:
#         cursor.execute("""
#             SELECT user_id, name, email, phone, dob, hometown 
#             FROM users 
#             WHERE user_id = %s AND is_active = 1
#         """, (user_id,))
#         row = cursor.fetchone()
        
#         if not row:
#             return jsonify({"message": "User not found or inactive"}), 404
            
#         # Normalisasi data
#         name = row.get("name", "")
#         name_parts = name.split(" ")
#         firstName = name_parts[0] if name_parts and name_parts[0] else ""
#         lastName = " ".join(name_parts[1:]) if len(name_parts) > 1 else ""
        
#         profile = {
#             "firstName": firstName,
#             "lastName": lastName,
#             "username": name.replace(" ", "").lower() or row["email"].split("@")[0],
#             "email": row["email"],
#             "phone": row.get("phone") or "", 
#             # Konversi objek Date/Datetime ke string ISO jika perlu
#             "dob": row.get("dob").strftime('%Y-%m-%d') if row.get("dob") and isinstance(row["dob"], datetime) else row.get("dob") or "",
#             "hometown": row.get("hometown") or "" 
#         }
#         return jsonify(profile), 200
#     except Exception as e:
#         print(f"[GET PROFILE] Error: {e}")
#         return jsonify({"message": "Internal Server Error during profile retrieval. Check database columns."}), 500
#     finally:
#         if 'cursor' in locals() and cursor: cursor.close()
#         if 'conn' in locals() and conn: conn.close()

# # PUT /api/users/profile -> update profile
# @user_bp.route("/profile", methods=["PUT"])
# @token_required
# def update_profile():
#     # 🎯 Ambil ID pengguna yang sudah diverifikasi dari token JWT
#     user_id = request.current_user_id 
    
#     data = request.get_json()
#     conn = get_connection()
#     if not conn:
#         return jsonify({"message": "DB connection failed"}), 500
#     cursor = conn.cursor()
#     try:
#         # Kombinasikan nama depan dan belakang
#         name = f"{data.get('firstName', '')} {data.get('lastName', '')}".strip()
#         email = data.get('email', '')
#         phone = data.get('phone', '')
#         dob = data.get('dob', '')
#         hometown = data.get('hometown', '')
        
#         # Eksekusi UPDATE dengan semua kolom
#         cursor.execute("""
#             UPDATE users SET 
#             name = %s, 
#             email = %s,
#             phone = %s,
#             dob = %s,
#             hometown = %s
#             WHERE user_id = %s
#         """, (name, email, phone, dob, hometown, user_id))
        
#         conn.commit()
#         if cursor.rowcount == 0:
#             return jsonify({"message": "User not found or no changes made"}), 200 
            
#         return jsonify({"message": "Profile updated"}), 200
#     except Exception as e:
#         print(f"[UPDATE PROFILE] Error: {e}")
#         conn.rollback()
#         return jsonify({"message": "Internal Server Error during profile update. Check database columns."}), 500
#     finally:
#         if 'cursor' in locals() and cursor: cursor.close()
#         if 'conn' in locals() and conn: conn.close()