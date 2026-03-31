import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/operario_models.dart';
import '../models/maquina.dart';
import 'auth_service.dart';

class OperarioService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Obtener ruta del operario (máquinas ordenadas por prioridad)
  Future<List<MaquinaRuta>> getRuta() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/api/maquinas/estado/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) {
          return MaquinaRuta(
            id: json['id'],
            codigo: json['codigo'] ?? '',
            nombre: json['nombre'] ?? '',
            ubicacion: json['ubicacion'] ?? '',
            porcentajeSurtido: (json['porcentaje_surtido'] ?? 0).toDouble(),
            estado: json['estado'] ?? 'inactiva',
            ultimaVisita: json['ultima_visita'],
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print("❌ Error en getRuta: $e");
      return [];
    }
  }

  // 2. OBTENER INVENTARIO DE UNA MÁQUINA ESPECÍFICA
  Future<List<ProductoInventario>> getInventarioMaquina(int maquinaId) async {
    try {
      print('🟢 Obteniendo inventario para máquina ID: $maquinaId');

      final headers = await _getHeaders();
      final url =
          '${ApiConstants.baseUrl}/api/inventario/?maquina_id=$maquinaId';

      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📡 Código: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];

        print(
            '✅ Inventario recibido: ${results.length} productos para máquina $maquinaId');

        return results.map((p) => ProductoInventario.fromJson(p)).toList();
      } else {
        print('❌ Error: ${response.statusCode} - ${response.body}');
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Excepción en getInventarioMaquina: $e');
      throw Exception('Error al cargar inventario: $e');
    }
  }

  // 3. OBTENER SOLO PRODUCTOS FALTANTES DE UNA MÁQUINA ESPECÍFICA
  Future<List<ProductoInventario>> getProductosFaltantes(int maquinaId) async {
    print('🟢 Obteniendo productos faltantes para máquina ID: $maquinaId');

    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/api/maquinas/$maquinaId/faltantes/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      print('📡 Código: ${response.statusCode}');
      print('📦 Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Productos faltantes recibidos: ${data.length}');
        return data.map((p) => ProductoInventario.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error en getProductosFaltantes: $e');
      return [];
    }
  }

  // 4. INICIAR VISITA
  Future<Map<String, dynamic>> iniciarVisita(int maquinaId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/visitas/iniciar/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({'maquina_id': maquinaId}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en iniciarVisita: $e');
      throw Exception('Error al iniciar visita: $e');
    }
  }

  // 5. FINALIZAR VISITA
  Future<bool> finalizarVisita(
      int visitaId, List<int> productosSurtidos) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/visitas/$visitaId/finalizar/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({'productos_surtidos': productosSurtidos}),
      );

      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error en finalizarVisita: $e');
      return false;
    }
  }

  // 6. OBTENER RESUMEN DE VISITAS
  Future<Map<String, dynamic>> getResumenVisitas() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'total_visitas': 0,
          'completadas': 0,
          'en_curso': 0,
          'canceladas': 0,
          'ultima_visita': null
        };
      }

      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/api/visitas/resumen/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'total_visitas': 0,
          'completadas': 0,
          'en_curso': 0,
          'canceladas': 0,
          'ultima_visita': null
        };
      }
    } catch (e) {
      developer.log('Error en getResumenVisitas: $e');
      return {
        'total_visitas': 0,
        'completadas': 0,
        'en_curso': 0,
        'canceladas': 0,
        'ultima_visita': null
      };
    }
  }

  // 7. OBTENER HISTORIAL DE VISITAS CON FILTROS
  Future<List<VisitaHistorial>> getHistorialVisitas({String? estado}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      String url = "${ApiConstants.baseUrl}/api/visitas/mis_visitas/";
      if (estado != null && estado != 'todas') {
        url += '?estado=$estado';
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

        return results.map((v) => VisitaHistorial.fromJson(v)).toList();
      } else {
        return [];
      }
    } catch (e) {
      developer.log('Error en getHistorialVisitas: $e');
      return [];
    }
  }

  // 8. REGISTRAR GASTO
  Future<Map<String, dynamic>> registrarGasto({
    required String concepto,
    required double valor,
    required String categoria,
    int? maquinaId,
    String? descripcion,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No autenticado');

      final descripcionFinal = descripcion ?? concepto;

      final Map<String, dynamic> body = {
        'tipo': categoria,
        'descripcion': descripcionFinal,
        'valor': valor,
      };

      if (maquinaId != null) {
        body['maquina'] = maquinaId;
      }

      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/gastos/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en registrarGasto: $e');
      throw Exception('Error al registrar gasto: $e');
    }
  }

  // 9. CANCELAR VISITA
  Future<bool> cancelarVisita(int visitaId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/visitas/$visitaId/cancelar/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({'motivo': 'Cancelada por el operario'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error en cancelarVisita: $e');
      return false;
    }
  }

  // 10. ACTUALIZAR PRECIO EN MÁQUINA ESPECÍFICA
  Future<bool> actualizarPrecio(int inventarioId, double nuevoPrecio) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse("${ApiConstants.baseUrl}/api/inventario/$inventarioId/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({'precio_venta': nuevoPrecio}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error en actualizarPrecio: $e');
      return false;
    }
  }

  // 11. REPORTAR PROBLEMA
  Future<bool> reportarProblema({
    required int maquinaId,
    required String descripcion,
    String? fotoBase64,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final body = {
        'maquina': maquinaId,
        'descripcion': descripcion,
      };

      if (fotoBase64 != null) {
        body['foto'] = fotoBase64;
      }

      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/reportes/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(body),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('❌ Error en reportarProblema: $e');
      return false;
    }
  }
}
