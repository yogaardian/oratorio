from flask import Blueprint, request, jsonify
from db import get_connection

destinations_bp = Blueprint("destinations", __name__)

# --- READ ALL (GET) ---
@destinations_bp.route("/destinations", methods=["GET"])
def get_all_destinations():
    conn = get_connection()
    if not conn:
        return jsonify({"message": "Gagal terhubung ke database."}), 500
    
    # AMBIL QUERY PARAMETER CATEGORY (HARUS ADA DARI FRONTEND)
    category_filter = request.args.get('category')
    
    # KARENA FRONTEND SELALU MENGIRIM PARAMETER (FAVORIT, AR, VR), 
    # MAKA KITA SELALU MENAMBAHKAN KLAUSA WHERE.
    if not category_filter:
         # Jika parameter category hilang, kembalikan error agar Front-end tahu
         return jsonify({"message": "Parameter kategori hilang dari permintaan."}), 400
        
    cursor = conn.cursor(dictionary=True)
    
    # Gunakan filter WHERE category=%s setiap saat
    query = "SELECT * FROM destinations WHERE category = %s ORDER BY destination_id DESC"
    params = [category_filter]

    try:
        cursor.execute(query, tuple(params))
        destinations = cursor.fetchall()
        return jsonify(destinations)
    except Exception as e:
        print(f"Error fetching destinations: {e}") 
        return jsonify({"message": f"Gagal mengambil data dari tabel 'destinations'. Error: {e}"}), 500
    finally:
        cursor.close()
        conn.close()

# --- CREATE (POST) ---
@destinations_bp.route("/destinations", methods=["POST"])
def add_destination():
    data = request.json
    
    conn = get_connection()
    if not conn:
        return jsonify({"message": "Gagal terhubung ke database."}), 500

    fields = [
        data.get("destination_name"),
        data.get("location"),
        data.get("description"),
        data.get("image_url"),
        data.get("total_visits", 0), 
        data.get("recent_visits", 0),
        data.get("rating", 0.0),
        data.get("reviews_count", 0),
        data.get("category", "FAVORIT") 
    ]

    if not data.get("destination_name") or not data.get("location"):
        return jsonify({"message": "Nama dan Lokasi destinasi wajib diisi"}), 400

    cursor = conn.cursor(dictionary=True)
    
    query = """
    INSERT INTO destinations 
    (destination_name, location, description, image_url, total_visits, recent_visits, rating, reviews_count, category) 
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    try:
        cursor.execute(query, tuple(fields))
        conn.commit()
        return jsonify({"message": "Destinasi berhasil ditambahkan!", "id": cursor.lastrowid}), 201
    except Exception as e:
        print(f"Error adding destination: {e}")
        conn.rollback()
        return jsonify({"message": "Gagal menyimpan ke database. Cek konfigurasi DB dan tabel."}), 500
    finally:
        cursor.close()
        conn.close()


# --- UPDATE (PUT) ---
@destinations_bp.route("/destinations/<int:id>", methods=["PUT"])
def update_destination(id):
    data = request.json
    
    conn = get_connection()
    if not conn:
        return jsonify({"message": "Gagal terhubung ke database."}), 500

    # Pastikan 'category' termasuk dalam daftar field yang dapat diupdate
    update_fields = [
        "destination_name", "location", "description", "image_url", 
        "total_visits", "recent_visits", "rating", "reviews_count", "category"
    ]
    
    set_clauses = []
    params = []
    
    for field in update_fields:
        if field in data:
            set_clauses.append(f"{field} = %s")
            params.append(data[field])

    if not set_clauses:
        return jsonify({"message": "Tidak ada data untuk diubah"}), 400

    params.append(id)
    
    cursor = conn.cursor(dictionary=True)
    
    query = f"UPDATE destinations SET {', '.join(set_clauses)} WHERE destination_id = %s"
    
    try:
        cursor.execute(query, tuple(params))
        conn.commit()
        if cursor.rowcount == 0:
            return jsonify({"message": "ID destinasi tidak ditemukan"}), 404
        return jsonify({"message": "Destinasi berhasil diperbarui!"})
    except Exception as e:
        print(f"Error updating destination: {e}")
        conn.rollback()
        return jsonify({"message": "Gagal memperbarui database"}), 500
    finally:
        cursor.close()
        conn.close()


# --- DELETE (DELETE) ---
@destinations_bp.route("/destinations/<int:id>", methods=["DELETE"])
def delete_destination(id):
    conn = get_connection()
    if not conn:
        return jsonify({"message": "Gagal terhubung ke database."}), 500 # Handle koneksi gagal

    cursor = conn.cursor(dictionary=True)
    
    query = "DELETE FROM destinations WHERE destination_id = %s"
    
    try:
        cursor.execute(query, (id,))
        conn.commit()
        if cursor.rowcount == 0:
            return jsonify({"message": "ID destinasi tidak ditemukan"}), 404
        return jsonify({"message": "Destinasi berhasil dihapus!"})
    except Exception as e:
        print(f"Error deleting destination: {e}")
        conn.rollback()
        return jsonify({"message": "Gagal menghapus dari database"}), 500
    finally:
        cursor.close()
        conn.close()