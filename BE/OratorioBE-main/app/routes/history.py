from flask import Blueprint, request, jsonify
from db import get_connection
from datetime import datetime
import json

history_bp = Blueprint("history", __name__)

# POST /api/history  -> insert new event (scan_start / scan_end)
@history_bp.route("/history", methods=["POST"])
def add_history():
    data = request.json or {}
    user_id = data.get("user_id")
    user_email = data.get("user_email")
    destination_id = data.get("destination_id")
    action = data.get("action", "scan_start")
    model_type = data.get("model_type", "AR")
    started_at = data.get("started_at")  # ISO string optional
    ended_at = data.get("ended_at")
    duration_seconds = data.get("duration_seconds")
    metadata = data.get("metadata")

    # fallback timestamps
    if started_at:
        try:
            started_at_dt = datetime.fromisoformat(started_at)
            started_at_str = started_at_dt.strftime('%Y-%m-%d %H:%M:%S')
        except:
            started_at_str = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
    else:
        started_at_str = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')

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
            started_at_str,
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
        print("Error add_history:", e)
        return jsonify({"message": str(e)}), 500

# GET /api/history/user/<user_id> -> get user history
@history_bp.route("/history/user/<int:user_id>", methods=["GET"])
def get_history_by_user(user_id):
    try:
        conn = get_connection()
        if not conn:
            return jsonify({"message":"DB connection failed"}), 500
        cursor = conn.cursor(dictionary=True)
        query = "SELECT h.*, d.name as destination_name FROM history h LEFT JOIN ar_destinations d ON h.destination_id = d.id WHERE h.user_id = %s ORDER BY h.started_at DESC LIMIT 200"
        cursor.execute(query, (user_id,))
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(rows), 200
    except Exception as e:
        print("Error get_history_by_user:", e)
        return jsonify({"message": str(e)}), 500

# GET /api/history -> admin list (all)
@history_bp.route("/history", methods=["GET"])
def get_all_history():
    try:
        conn = get_connection()
        if not conn:
            return jsonify({"message":"DB connection failed"}), 500
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT h.*, d.name as destination_name FROM history h LEFT JOIN ar_destinations d ON h.destination_id = d.id ORDER BY h.started_at DESC LIMIT 1000")
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(rows), 200
    except Exception as e:
        print("Error get_all_history:", e)
        return jsonify({"message": str(e)}), 500