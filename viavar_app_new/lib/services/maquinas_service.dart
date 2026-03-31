import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/maquina.dart';
import 'auth_service.dart';

class MaquinasService {
  final AuthService _authService = AuthService();

  // Obtener listado de máquinas
  Future<List<Maquina>> getMaquinas({
    int page = 1,
    int pageSize = 20,
    String? estado,
    String? search,
  }) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/maquinas/";
      url += "?page=$page&page_size=$pageSize";
      
      if (estado != null && estado.isNotEmpty) {
        url += "&estado=$estado";
      }
      
      if (search != null && search.isNotEmpty) {
        url += "&search=$search";
      }

      print(" Llamando a API para obtener máquinas: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${await _authService.getToken()}",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        
        List<Maquina> maquinas = [];
        for (var item in results) {
          maquinas.add(Maquina.fromJson(item));
        }

        print(" Máquinas obtenidas: ${maquinas.length}");
        return maquinas;
      } else {
        print(" Error en API: ${response.statusCode}");
        throw Exception("Error al obtener máquinas: ${response.statusCode}");
      }
    } catch (e) {
      print(" Excepción en getMaquinas: $e");
      rethrow;
    }
  }

  // Obtener una máquina por ID
  Future<Maquina> getMaquinaById(int id) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/maquinas/$id/";

      print(" Llamando a API para obtener máquina $id: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${await _authService.getToken()}",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print(" Máquina $id obtenida");
        return Maquina.fromJson(data);
      } else {
        print(" Error en API: ${response.statusCode}");
        throw Exception("Error al obtener máquina: ${response.statusCode}");
      }
    } catch (e) {
      print(" Excepción en getMaquinaById: $e");
      rethrow;
    }
  }
}

