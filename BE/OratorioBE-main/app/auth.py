# D:\yogss\oratorio\BE\OratorioBE-main\app\auth.py

from flask import request, jsonify
from functools import wraps
import jwt
import logging

# Konstanta (import dari __init__.py jika perlu, tapi untuk hindari circular, define di sini)
SECRET_KEY = 'your_secret_key_here_for_jwt'  # ⚠️ Ganti dengan key yang aman

def token_required(f):
    """
    Decorator untuk memeriksa JWT token di header Authorization.
    Menyimpan user_id ke request.user_id jika token valid.
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        
        if not token or not token.startswith('Bearer '):
            return jsonify({'message': 'Authorization header is missing or malformed!'}), 401
        
        try:
            token = token.split(" ")[1]  # Ambil bagian token setelah 'Bearer '
            
            data = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
            # 🎯 MENYIMPAN USER_ID ke objek request
            request.user_id = data['user_id']
            
        except jwt.ExpiredSignatureError:
            return jsonify({'message': 'Token has expired!'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'message': 'Token is invalid!'}), 401
        except Exception as e:
            logging.error(f"JWT Decoding Error: {e}")
            return jsonify({'message': 'Invalid token format or server error!'}), 401
            
        return f(*args, **kwargs)
    return decorated