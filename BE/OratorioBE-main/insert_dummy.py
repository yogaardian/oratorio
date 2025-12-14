import os
from db import get_connection

def insert_dummy_data():
    conn = get_connection()
    if not conn:
        print("DB connection failed")
        return

    cursor = conn.cursor()
    try:
        # Insert dummy data
        cursor.execute("""
            INSERT INTO ar_destinations (name, description, location, marker_image, mind_file, glb_model)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            "Gunung Bromo",
            "Gunung berapi aktif dengan pemandangan sunrise yang spektakuler",
            "Jawa Timur",
            "bromo_marker.jpg",
            "bromo.mind",
            "bromo.glb"
        ))
        cursor.execute("""
            INSERT INTO ar_destinations (name, description, location, marker_image, mind_file, glb_model)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            "Borobudur",
            "Candi Buddha terbesar di dunia dengan arsitektur megah",
            "Magelang, Jawa Tengah",
            "borobudur_marker.jpg",
            "borobudur.mind",
            "borobudur.glb"
        ))
        cursor.execute("""
            INSERT INTO ar_destinations (name, description, location, marker_image, mind_file, glb_model)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            "Pantai Kuta",
            "Pantai terkenal di Bali dengan ombak yang cocok untuk surfing",
            "Bali",
            "kuta_marker.jpg",
            "kuta.mind",
            "kuta.glb"
        ))
        conn.commit()
        print("Dummy data inserted successfully")
    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    insert_dummy_data()