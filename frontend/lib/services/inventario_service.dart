import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'auth_service.dart';
import '../models/inventario_maquina.dart';

class InventarioService {
  final AuthService _authService = AuthService();

  Future<List<InventarioMaquina>> getInventarioCompleto() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/inventario/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results.map((e) => InventarioMaquina.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error en getInventarioCompleto: $e');
      return [];
    }
  }
}
