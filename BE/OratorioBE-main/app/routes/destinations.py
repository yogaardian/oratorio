from flask import Blueprint, request, jsonify
from db import get_connection
from datetime import datetime
import json

# === CREATE BLUEPRINT ===
destinations_bp = Blueprint("destinations", __name__)

# Helper: konversi ISO -> datetime string MySQL
def _iso_to_sql(iso_str):
    try:
        if not iso_str:
            return None
        dt = datetime.fromisoformat(iso_str.replace('Z', '+00:00'))
        return dt.strftime("%Y-%m-%d %H:%M:%S")
    except Exception as e:
        print(f"[HISTORY] _iso_to_sql error: {e}")
        return None

# ===== HISTORY ENDPOINTS =====

@destinations_bp.route("/history", methods=["POST"])
def add_history():
    data = request.json or {}
    user_id = data.get("user_id")
    user_email = data.get("user_email")
    destination_id = data.get("destination_id")
    action = data.get("action", "scan_start")
    model_type = data.get("model_type", "AR")
    started_at = data.get("started_at")
    ended_at = data.get("ended_at")
    duration_seconds = data.get("duration_seconds")
    metadata = data.get("metadata")

    print(f"[HISTORY] Raw payload: {json.dumps(data, indent=2)}")
    print(f"[HISTORY] Received: user_id={user_id}, destination_id={destination_id}, action={action}, started_at={started_at}")

    # Normalize timestamps — PENTING: fallback ke server time jika frontend tidak kirim
    started_at_sql = _iso_to_sql(started_at)
    if not started_at_sql:
        started_at_sql = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[HISTORY] started_at NULL, using server time: {started_at_sql}")
    
    ended_at_sql = _iso_to_sql(ended_at) if ended_at else None

    conn = get_connection()
    if not conn:
        print("[HISTORY] DB connection failed")
        return jsonify({"message":"DB connection failed"}), 500

    cursor = conn.cursor()
    try:
        # Upsert logic: update jika sudah ada (user_id, destination_id)
        if user_id is not None and destination_id is not None:
            cursor.execute(
                "SELECT history_id FROM history WHERE user_id = %s AND destination_id = %s LIMIT 1",
                (user_id, destination_id)
            )
            existing = cursor.fetchone()
            if existing:
                hid = existing[0]
                print(f"[HISTORY] Updating existing record {hid}")
                if action == "scan_start":
                    cursor.execute("""
                        UPDATE history SET action=%s, model_type=%s, started_at=%s, ended_at=NULL, duration_seconds=NULL, metadata=%s
                        WHERE history_id=%s
                    """, (action, model_type, started_at_sql, json.dumps(metadata) if metadata else None, hid))
                else:
                    cursor.execute("""
                        UPDATE history SET action=%s, model_type=%s, ended_at=%s, duration_seconds=%s, metadata=%s
                        WHERE history_id=%s
                    """, (action, model_type, ended_at_sql, duration_seconds, json.dumps(metadata) if metadata else None, hid))
                conn.commit()
                cursor.close()
                conn.close()
                print(f"[HISTORY] Updated successfully")
                return jsonify({"message":"updated","history_id":hid}), 200

        # Insert baru jika tidak ada
        print(f"[HISTORY] Inserting new record with started_at={started_at_sql}")
        cursor.execute("""
            INSERT INTO history (user_id, user_email, destination_id, action, model_type, started_at, ended_at, duration_seconds, metadata)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            user_id, user_email, destination_id, action, model_type,
            started_at_sql, ended_at_sql, duration_seconds,
            json.dumps(metadata) if metadata else None
        ))
        conn.commit()
        hid = cursor.lastrowid
        cursor.close()
        conn.close()
        print(f"[HISTORY] Inserted new record {hid}")
        return jsonify({"message":"created","history_id":hid}), 201

    except Exception as e:
        print(f"[HISTORY] Error in POST: {e}")
        import traceback
        traceback.print_exc()
        try:
            cursor.close()
            conn.close()
        except:
            pass
        return jsonify({"message": str(e)}), 500


@destinations_bp.route("/history", methods=["GET"])
def get_all_history():
    print("[HISTORY] GET /history (all records)")
    conn = get_connection()
    if not conn:
        print("[HISTORY] DB connection failed")
        return jsonify({"message":"DB connection failed"}), 500
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
        cursor.close()
        conn.close()
        print(f"[HISTORY] Fetched {len(rows)} total records")
        return jsonify(rows), 200
    except Exception as e:
        print(f"[HISTORY] Error in GET /history: {e}")
        import traceback
        traceback.print_exc()
        try:
            cursor.close()
            conn.close()
        except:
            pass
        return jsonify({"message": str(e)}), 500


@destinations_bp.route("/history/user/<int:user_id>", methods=["GET"])
def get_history_by_user(user_id):
    print(f"[HISTORY] GET /history/user/{user_id}")
    conn = get_connection()
    if not conn:
        print(f"[HISTORY] DB connection failed for user {user_id}")
        return jsonify({"message":"DB connection failed"}), 500
    cursor = conn.cursor(dictionary=True)
    try:
        print(f"[HISTORY] Executing query for user_id={user_id}")
        cursor.execute("""
            SELECT h.*, d.name as destination_name
            FROM history h
            LEFT JOIN ar_destinations d ON h.destination_id = d.id
            WHERE h.user_id = %s
            ORDER BY h.started_at DESC
            LIMIT 200
        """, (user_id,))
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        
        print(f"[HISTORY] Fetched {len(rows) if rows else 0} records for user {user_id}")
        if rows:
            print(f"[HISTORY] Sample record: {rows[0] if rows else 'None'}")
        
        # Pastikan return JSON array, bukan None
        result = rows if rows else []
        return jsonify(result), 200
    except Exception as e:
        print(f"[HISTORY] Error in GET /history/user/{user_id}: {e}")
        import traceback
        traceback.print_exc()
        try:
            cursor.close()
            conn.close()
        except:
            pass
        return jsonify({"message": str(e)}), 500