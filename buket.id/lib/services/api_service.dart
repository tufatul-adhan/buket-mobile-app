import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiService {
  static String get baseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) return configuredUrl;
    if (kIsWeb) return 'http://${Uri.base.host}:8080/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static String? _token;
  static String? get token => _token;

  // Set token after login
  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // Return a readable fallback if a proxy/server responds with HTML.
    }
    return {
      'error':
          'Server mengirim respons yang tidak valid (${response.statusCode}).'
    };
  }

  static Map<String, String> _getHeaders({bool withAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (withAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // ==================== AUTH ====================

  static Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
    required String phone,
    required String city,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
          'phone': phone,
          'city': city,
        }),
      );

      if (response.statusCode == 201) {
        final data = _decodeResponse(response);
        if (data['token'] is! String || data['user'] is! Map) {
          return {
            'success': false,
            'error': 'Respons registrasi dari server tidak lengkap.'
          };
        }
        setToken(data['token'] as String);
        return {'success': true, 'data': data};
      } else {
        final errorData = _decodeResponse(response);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Registrasi gagal. Coba lagi.'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = _decodeResponse(response);
        if (data['token'] is! String || data['user'] is! Map) {
          return {
            'success': false,
            'error': 'Respons login dari server tidak lengkap.'
          };
        }
        setToken(data['token'] as String);
        return {'success': true, 'data': data};
      } else {
        final errorData = _decodeResponse(response);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Login failed'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> signInWithGoogle({
    required String idToken,
    required String city,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: _getHeaders(),
        body: jsonEncode({'idToken': idToken, 'city': city}),
      );

      final data = _decodeResponse(response);
      if (response.statusCode == 200 &&
          data['token'] is String &&
          data['user'] is Map) {
        setToken(data['token'] as String);
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': data['error'] ?? 'Login Google gagal. Silakan coba lagi.',
      };
    } catch (error) {
      return {'success': false, 'error': error.toString()};
    }
  }

  // ==================== PRODUCTS ====================

  static Future<List<dynamic>> getAllProducts({
    String? city,
    String? category,
  }) async {
    try {
      String url = '$baseUrl/products';
      final params = <String, String>{};

      if (city != null) params['city'] = city;
      if (category != null) params['category'] = category;

      if (params.isNotEmpty) {
        url += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(withAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getProductDetail(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId'),
        headers: _getHeaders(withAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Product not found'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<List<dynamic>> searchProducts(String keyword) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/search?q=$keyword'),
        headers: _getHeaders(withAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // ==================== CART ====================

  static Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
        headers: _getHeaders(withAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to fetch cart'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> addToCart({
    required int productId,
    required int quantity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart'),
        headers: _getHeaders(withAuth: true),
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Product added to cart'};
      } else {
        return {'success': false, 'error': jsonDecode(response.body)['error']};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateCartItem({
    required int cartItemId,
    required int quantity,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/cart/$cartItemId'),
        headers: _getHeaders(withAuth: true),
        body: jsonEncode({'quantity': quantity}),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false};
      }
    } catch (e) {
      return {'success': false};
    }
  }

  static Future<Map<String, dynamic>> removeFromCart(int cartItemId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/$cartItemId'),
        headers: _getHeaders(withAuth: true),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false};
      }
    } catch (e) {
      return {'success': false};
    }
  }

  static Future<Map<String, dynamic>> clearCart() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart'),
        headers: _getHeaders(withAuth: true),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false};
      }
    } catch (e) {
      return {'success': false};
    }
  }

  // ==================== ORDERS ====================

  static Future<List<dynamic>> getOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: _getHeaders(withAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) ?? [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: _getHeaders(withAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Order not found'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createOrder(
      List<Map<String, int>> items) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _getHeaders(withAuth: true),
        body: jsonEncode({'items': items}),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': jsonDecode(response.body)['error']};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== PROFILE ====================

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: _getHeaders(withAuth: true),
      );

      if (response.statusCode == 200) {
        return _decodeResponse(response);
      } else {
        final data = _decodeResponse(response);
        return {'error': data['error'] ?? 'Gagal memuat profil.'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String username,
    required String phone,
    required String city,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: _getHeaders(withAuth: true),
        body: jsonEncode({
          'username': username,
          'phone': phone,
          'city': city,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = _decodeResponse(response);
        return {
          'success': false,
          'error': data['error'] ?? 'Gagal memperbarui profil.'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
