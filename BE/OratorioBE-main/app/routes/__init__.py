# # D:\yogss\oratorio\BE\OratorioBE-main\app\__init__.py

# import os
# import logging
# from flask import Flask, request, jsonify
# from functools import wraps
# import jwt
# from datetime import timedelta
# # Asumsi db dan migrate diinisialisasi di app/extensions.py
# from app.extensions import db, migrate 

# logging.basicConfig(level=logging.INFO)

# # --- SECURITY CONSTANTS & UTILITY ---
# # PENTING: DEFINE DI SINI (Level 1) AGAR BISA DIAKSES OLEH routes/user_routes.py
# SECRET_KEY = 'your_secret_key_here_for_jwt' # ⚠️ Ganti dengan key yang aman
# TOKEN_LIFESPAN = timedelta(hours=24) 

# def token_required(f):
#     """
#     Decorator untuk memeriksa JWT token di header Authorization.
#     Menyimpan user_id ke request.current_user_id jika token valid.
#     """
#     @wraps(f)
#     def decorated(*args, **kwargs):
#         token = request.headers.get('Authorization')
        
#         if not token or not token.startswith('Bearer '):
#             return jsonify({'message': 'Authorization header is missing or malformed!'}), 401
        
#         try:
#             token = token.split(" ")[1] # Ambil bagian token setelah 'Bearer '
            
#             data = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
#             # 🎯 MENYIMPAN USER_ID ke objek request
#             # Di user_routes.py, Anda mengaksesnya sebagai request.current_user_id
#             request.current_user_id = data['user_id']
            
#         except jwt.ExpiredSignatureError:
#             return jsonify({'message': 'Token has expired!'}), 401
#         except jwt.InvalidTokenError:
#             return jsonify({'message': 'Token is invalid!'}), 401
#         except Exception as e:
#             logging.error(f"JWT Decoding Error: {e}")
#             return jsonify({'message': 'Invalid token format or server error!'}), 401
            
#         return f(*args, **kwargs)
#     return decorated
# # --- END SECURITY UTILITY ---


# def create_app(config_object='config'):
#     app = Flask(__name__,
#                 static_url_path="/assets",
#                 static_folder=os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets"))

#     # Muat konfigurasi dari config.py
#     app.config.from_object(config_object)
#     app.config['SECRET_KEY'] = SECRET_KEY 

#     # Inisialisasi ekstensi ke aplikasi
#     db.init_app(app) 
#     migrate.init_app(app, db) 

#     # ------------------------------------
#     # DAFTARKAN BLUEPRINTS (ROUTES) DI DALAM APP FACTORY
#     # Ini memutus circular import yang terjadi sebelumnya.
#     # ------------------------------------
#     try:
#         # Impor dilakukan di sini (setelah db dan app diinisialisasi)
#         from .routes.user_routes import user_bp 
#         # Asumsi ada file destinations.py yang berisi destinations_bp
#         from .routes.destinations import destinations_bp 
        
#         app.register_blueprint(user_bp, url_prefix="/api/users")
#         app.register_blueprint(destinations_bp, url_prefix="/api")
#         logging.info("Registered user and destination blueprints.")
#     except Exception as e:
#         # Jika import blueprint gagal, log error tersebut
#         logging.error(f"Blueprint import failed: {e}")
    
#     return app

# # Perintah migrasi sekarang akan memanggil fungsi create_app() dari paket ini.