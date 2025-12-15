import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getInstance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Simpan data user setelah login
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await _getInstance();
    await prefs.setInt('user_id', userData['user_id'] as int);
    await prefs.setString('email', userData['email'] as String);
    await prefs.setString('username', userData['username'] as String);
    if (userData['jwt_token'] != null) {
      await prefs.setString('jwt_token', userData['jwt_token'] as String);
    }
  }

  // Ambil data user
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await _getInstance();
    final userId = prefs.getInt('user_id');
    final email = prefs.getString('email');
    final username = prefs.getString('username');
    
    if (userId == null || email == null) {
      return null;
    }
    
    return {
      'user_id': userId,
      'email': email,
      'username': username ?? 'Pengguna',
      'jwt_token': prefs.getString('jwt_token'),
    };
  }

  // Clear data (logout)
  static Future<void> clearUserData() async {
    final prefs = await _getInstance();
    await prefs.remove('user_id');
    await prefs.remove('email');
    await prefs.remove('username');
    await prefs.remove('jwt_token');
  }
}