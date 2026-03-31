import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'auth_service.dart';
import '../models/finanzas_modelos.dart';

class FinanzasService {
  final AuthService _authService = AuthService();

  // ========== ENDPOINTS DE FINANZAS ==========

  // Obtener resumen de gastos por categoría
  Future<ResumenGastos> getResumenGastos({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("No autenticado");

      final url =
          "${ApiConstants.baseUrl}/api/gastos/resumen/?fecha_inicio=${_formatDate(startDate)}&fecha_fin=${_formatDate(endDate)}";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return ResumenGastos.fromJson(json.decode(response.body));
      } else {
        throw Exception("Error ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error en getResumenGastos: $e");
      rethrow;
    }
  }

  // Obtener top facturación de máquinas
  Future<TopFacturacion> getTopFacturacion({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("No autenticado");

      final url =
          "${ApiConstants.baseUrl}/api/maquinas/top-facturacion/?fecha_inicio=${_formatDate(startDate)}&fecha_fin=${_formatDate(endDate)}";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return TopFacturacion.fromJson(json.decode(response.body));
      } else {
        throw Exception("Error ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error en getTopFacturacion: $e");
      rethrow;
    }
  }

  // Obtener evolución mensual
  Future<List<EvolucionMensual>> getEvolucionMensual() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception("No autenticado");

      final url = "${ApiConstants.baseUrl}/api/cierres/evolucion/";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => EvolucionMensual.fromJson(e)).toList();
      } else {
        throw Exception("Error ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error en getEvolucionMensual: $e");
      rethrow;
    }
  }

  // ========== CRUD CIERRES ==========
  Future<List<CierreMensual>> getCierres({int? mes, int? anio}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      String url = "${ApiConstants.baseUrl}/api/cierres/";

      // Usar 'año' con tilde en la URL (el backend espera eso)
      if (mes != null && anio != null) {
        url += "?mes=$mes&año=$anio";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results.map((c) => CierreMensual.fromJson(c)).toList();
      }
      return [];
    } catch (e) {
      print("❌ Error en getCierres: $e");
      return [];
    }
  }

  // Crear cierre
  // Crear cierre
  Future<CierreMensual?> crearCierre(Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;

      // Obtener el ID del usuario actual
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        print("❌ No se pudo obtener el ID del usuario");
        return null;
      }

      // El backend espera 'año' con tilde y 'responsable'
      final Map<String, dynamic> cleanedData = {
        'maquina': data['maquina'],
        'mes': data['mes'],
        'año': data['año'], // IMPORTANTE: usar 'año' con tilde
        'ventas_totales': data['ventas_totales'],
        'gastos_totales': data['gastos_totales'],
        'ganancia_neta': data['ganancia_neta'],
        'observaciones': data['observaciones'] ?? '',
        'responsable': userId, // ID del usuario logueado
      };

      print('📤 Enviando creación de cierre: $cleanedData');

      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/cierres/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(cleanedData),
      );

      print('📥 Respuesta: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        return CierreMensual.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print("❌ Error en crearCierre: $e");
      return null;
    }
  }

  // Actualizar cierre
  Future<bool> actualizarCierre(int id, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      // Obtener el ID del usuario actual
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        print("❌ No se pudo obtener el ID del usuario");
        return false;
      }

      final Map<String, dynamic> cleanedData = {
        'maquina': data['maquina'],
        'mes': data['mes'],
        'año': data['año'], // IMPORTANTE: usar 'año' con tilde
        'ventas_totales': data['ventas_totales'],
        'gastos_totales': data['gastos_totales'],
        'ganancia_neta': data['ganancia_neta'],
        'observaciones': data['observaciones'] ?? '',
        'responsable': userId, // ID del usuario logueado
      };

      print('📤 Enviando actualización de cierre: $cleanedData');

      final response = await http.put(
        Uri.parse("${ApiConstants.baseUrl}/api/cierres/$id/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(cleanedData),
      );

      print('📥 Respuesta: ${response.statusCode} - ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error en actualizarCierre: $e");
      return false;
    }
  }

  Future<bool> eliminarCierre(int id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse("${ApiConstants.baseUrl}/api/cierres/$id/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      print("❌ Error en eliminarCierre: $e");
      return false;
    }
  }

  // ========== CRUD GASTOS ==========
  Future<List<Gasto>> getGastos({
    DateTime? startDate,
    DateTime? endDate,
    String? tipo,
    int? maquinaId,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      List<String> params = [];
      if (startDate != null)
        params.add("fecha_inicio=${_formatDate(startDate)}");
      if (endDate != null) params.add("fecha_fin=${_formatDate(endDate)}");
      if (tipo != null) params.add("tipo=$tipo");
      if (maquinaId != null) params.add("maquina_id=$maquinaId");

      String url = "${ApiConstants.baseUrl}/api/gastos/";
      if (params.isNotEmpty) url += "?${params.join('&')}";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results.map((g) => Gasto.fromJson(g)).toList();
      }
      return [];
    } catch (e) {
      print("❌ Error en getGastos: $e");
      return [];
    }
  }

  Future<Gasto?> crearGasto(Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/gastos/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return Gasto.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print("❌ Error en crearGasto: $e");
      return null;
    }
  }

  // Método actualizarGasto (si es necesario)
  Future<bool> actualizarGasto(int id, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse("${ApiConstants.baseUrl}/api/gastos/$id/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(data),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error en actualizarGasto: $e");
      return false;
    }
  }

  Future<bool> eliminarGasto(int id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse("${ApiConstants.baseUrl}/api/gastos/$id/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      print("❌ Error en eliminarGasto: $e");
      return false;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
