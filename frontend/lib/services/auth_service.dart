import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/auth_response.dart';

class AuthService with ChangeNotifier {
  String? _token; // ← MANTENEMOS EL MISMO NOMBRE
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _currentUser != null;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.login}");

      print(" Conectando a: $url");
      print(" Usuario: $username");

      final response = await http.post(
        url,
        headers: ApiConstants.headersJson,
        body: json.encode({
          "username": username,
          "password": password,
        }),
      );

      print(" Respuesta HTTP: ${response.statusCode}");
      print(" Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final authResponse =
              AuthResponse.fromJson(json.decode(response.body));

          _token = authResponse.access;
          _currentUser = authResponse.user;

          // Guardar en almacenamiento local
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!); // ← MANTENEMOS 'token'

          // SOLUCIÓN: También guardamos como 'access_token' para ESP32
          await prefs.setString(
              'access_token', _token!); // ← SOLO ESTA LÍNEA EXTRA

          await prefs.setString(
              'user', json.encode(authResponse.user.toJson()));

          _isLoading = false;
          notifyListeners();
          return true;
        } catch (e) {
          _error = "Error parseando respuesta: $e";
          print(" $_error");
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _error = "Error ${response.statusCode}: ${response.body}";
        print(" $_error");
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Error de conexión: $e";
      print(" $_error");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('access_token'); // ← NUEVO
    await prefs.remove('user');

    _token = null;
    _currentUser = null;
    notifyListeners();
  }

  // Obtener perfil del usuario actual
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/api/profile/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("📥 Perfil obtenido: $data");
        return data;
      }
      return null;
    } catch (e) {
      print("❌ Error en getUserProfile: $e");
      return null;
    }
  }

  // Obtener ID del usuario actual
  Future<int?> getCurrentUserId() async {
    final profile = await getUserProfile();
    return profile?['id'];
  }

  Future<void> loadStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('token');
      final storedUser = prefs.getString('user');

      if (storedToken != null && storedUser != null) {
        _token = storedToken;
        _currentUser = User.fromJson(json.decode(storedUser));
        print(" Credenciales cargadas desde almacenamiento");
        print(" Usuario: ${_currentUser!.username}");
        notifyListeners();
      }
    } catch (e) {
      print(" Error cargando credenciales almacenadas: $e");
    }
  }

  // Método para obtener el token actual (para otros servicios)
  Future<String?> getToken() async {
    if (_token != null) {
      return _token;
    }

    // Intentar obtener del almacenamiento local
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');

      return _token;
    } catch (e) {
      print(" Error obteniendo token: $e");
      return null;
    }
  }

  // NUEVO: Método específico para ESP32 (busca access_token)
  Future<String?> getTokenForESP32() async {
    // Primero intentar con access_token
    try {
      final prefs = await SharedPreferences.getInstance();
      final espToken = prefs.getString('access_token');
      if (espToken != null) return espToken;
    } catch (e) {
      print(" Error obteniendo token ESP32: $e");
    }

    // Si no existe, usar el token normal
    return getToken();
  }

  // Método para obtener usuario actual (para otros servicios)
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    // Intentar obtener del almacenamiento local
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUser = prefs.getString('user');

      if (storedUser != null) {
        _currentUser = User.fromJson(json.decode(storedUser));
        return _currentUser;
      }
    } catch (e) {
      print(" Error obteniendo usuario: $e");
    }

    return null;
  }

  // Limpiar errores
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
