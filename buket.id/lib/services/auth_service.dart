import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_service.dart';
import 'google_auth_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  SharedPreferences? _prefs;
  User? _currentUser;

  Future<SharedPreferences> _preferences() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> init() async {
    final prefs = await _preferences();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return;

    ApiService.setToken(token);
    try {
      final profile = await ApiService.getProfile();
      if (!profile.containsKey('error')) {
        _currentUser = _userFromJson(profile);
        await _storeUser(_currentUser!);
      }
    } catch (_) {
      // Keep the saved token so a temporary network issue does not log the
      // user out. The profile can be loaded again when the session is checked.
    }
  }

  User _userFromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: (json['username'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
    );
  }

  Future<void> _storeUser(User user) async {
    final prefs = await _preferences();
    await prefs.setString(_userKey, user.toJson().toString());
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_phone', user.phone);
    await prefs.setString('user_city', user.city);
  }

  Future<void> _storeSession(User user) async {
    final prefs = await _preferences();
    final token = ApiService.token;
    if (token == null || token.isEmpty) {
      throw Exception('Server tidak mengirim token sesi. Silakan coba lagi.');
    }
    _currentUser = user;
    await prefs.setString(_tokenKey, token);
    await _storeUser(user);
  }

  Future<bool> login({
    required String email,
    required String password,
    required String city,
  }) async {
    final result = await ApiService.login(
      email: email.trim().toLowerCase(),
      password: password,
    );

    if (result['success'] != true) {
      throw Exception(_friendlyError(result['error']));
    }

    final data = Map<String, dynamic>.from(result['data'] as Map);
    final user = _userFromJson(Map<String, dynamic>.from(data['user'] as Map));
    await _storeSession(user);

    if (city.trim().isNotEmpty && city.trim() != user.city) {
      await updateUserCity(city.trim());
    }
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String city,
  }) async {
    final result = await ApiService.register(
      email: email.trim().toLowerCase(),
      username: name.trim(),
      password: password,
      phone: phone.trim(),
      city: city.trim(),
    );

    if (result['success'] != true) {
      throw Exception(_friendlyError(result['error']));
    }

    final data = Map<String, dynamic>.from(result['data'] as Map);
    final user = _userFromJson(Map<String, dynamic>.from(data['user'] as Map));
    await _storeSession(user);
    return true;
  }

  Future<bool> loginWithGoogle({
    required String idToken,
    required String city,
  }) async {
    final result = await ApiService.signInWithGoogle(
      idToken: idToken,
      city: city.trim(),
    );
    if (result['success'] != true) {
      throw Exception(_friendlyError(result['error']));
    }

    final data = Map<String, dynamic>.from(result['data'] as Map);
    final user = _userFromJson(Map<String, dynamic>.from(data['user'] as Map));
    await _storeSession(user);
    if (city.trim().isNotEmpty && city.trim() != user.city) {
      await updateUserCity(city.trim());
    }
    return true;
  }

  String _friendlyError(dynamic error) {
    final message = error?.toString() ?? '';
    if (message.contains('already registered')) {
      return 'Email sudah terdaftar. Silakan login atau gunakan email lain.';
    }
    if (message.contains('required') || message.contains('min 3')) {
      return 'Periksa kembali nama, email, password, nomor telepon, dan kota.';
    }
    if (message.contains('SocketException') ||
        message.contains('Failed host lookup') ||
        message.contains('Connection refused')) {
      return 'Server tidak dapat dijangkau. Pastikan backend dan PostgreSQL sedang berjalan.';
    }
    if (message.contains('Internal server error')) {
      return 'Terjadi gangguan pada server. Coba lagi beberapa saat atau periksa koneksi PostgreSQL.';
    }
    return message.isEmpty
        ? 'Registrasi gagal. Silakan coba kembali.'
        : message;
  }

  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final prefs = await _preferences();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return null;

    ApiService.setToken(token);
    final profile = await ApiService.getProfile();
    if (profile.containsKey('error')) return null;

    _currentUser = _userFromJson(profile);
    await _storeUser(_currentUser!);
    return _currentUser;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await _preferences();
    return prefs.getString(_tokenKey)?.isNotEmpty ?? false;
  }

  Future<void> logout() async {
    final prefs = await _preferences();
    await GoogleAuthService.instance.signOut();
    ApiService.clearToken();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('user_city');
    _currentUser = null;
  }

  Future<void> updateUserCity(String city) async {
    final user = await getCurrentUser();
    if (user == null) throw Exception('Sesi login tidak ditemukan.');

    final result = await ApiService.updateProfile(
      username: user.name,
      phone: user.phone,
      city: city,
    );
    if (result['success'] != true) {
      throw Exception(_friendlyError(result['error']));
    }

    _currentUser = User(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      city: city,
    );
    await _storeUser(_currentUser!);
  }

  String? getUserCity() => _prefs?.getString('user_city');
}
