import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/esp32_estado.dart';
import '../core/constants.dart';

class Esp32Service {
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

  // ========== ESTADO MAESTRO ==========
  Future<Esp32Estado> getEstado(int maquinaId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/api/maquinas/$maquinaId/esp32-estado/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Esp32Estado.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return Esp32Estado(
          id: 0,
          maquinaId: maquinaId,
          estado: 'offline',
          memoriaOcupada: 0,
          intervaloActual: 900,
          batchPendientes: 0,
          online: false,
        );
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error en getEstado: $e');
      rethrow;
    }
  }

  // ========== SLAVES (BANDEJAS) ==========
  Future<List<Esp32Slave>> getSlaves(int maquinaId) async {
    try {
      final headers = await _getHeaders();
      final url =
          '${ApiConstants.baseUrl}/api/esp32-slaves/?maquina=$maquinaId';
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // La respuesta tiene estructura paginada: {count, next, previous, results}
        final List<dynamic> data = jsonResponse['results'] ?? [];
        return data.map((e) => Esp32Slave.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      developer.log('Error en getSlaves: $e');
      return [];
    }
  }

  Future<Esp32Slave?> getSlaveDetail(int slaveId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/esp32-slaves/$slaveId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Esp32Slave.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      developer.log('Error en getSlaveDetail: $e');
      return null;
    }
  }

  // Enviar comando a una bandeja específica
  Future<Map<String, dynamic>> enviarComando(
    int slaveId,
    String comando, {
    Map<String, dynamic> parametros = const {},
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}/api/esp32-slaves/$slaveId/enviar_comando/'),
        headers: headers,
        body: json.encode({
          'comando': comando,
          'parametros': parametros,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      developer.log('Error en enviarComando: $e');
      rethrow;
    }
  }

  // ========== LOGS ==========
  Future<List<Esp32Log>> getLogs({
    required int maquinaId,
    int? slaveId,
    String? nivel,
    int limit = 100,
  }) async {
    try {
      final headers = await _getHeaders();
      var url =
          '${ApiConstants.baseUrl}/api/esp32-logs/?maquina=$maquinaId&limit=$limit';
      if (slaveId != null) url += '&slave=$slaveId';
      if (nivel != null) url += '&nivel=$nivel';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // La respuesta tiene estructura paginada: {count, next, previous, results}
        final List<dynamic> data = jsonResponse['results'] ?? [];
        return data.map((e) => Esp32Log.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      developer.log('Error en getLogs: $e');
      return [];
    }
  }

  // Obtener resumen de logs por nivel
  Future<Map<String, int>> getLogsResumen(int maquinaId) async {
    final logs = await getLogs(maquinaId: maquinaId);
    return {
      'INFO': logs.where((l) => l.nivel == 'INFO').length,
      'WARNING': logs.where((l) => l.nivel == 'WARNING').length,
      'ERROR': logs.where((l) => l.nivel == 'ERROR').length,
    };
  }

  // ========== ACCIONES GLOBALES ==========
  Future<Map<String, dynamic>> forzarConteo(int maquinaId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}/api/maquinas/$maquinaId/forzar-conteo/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Error ${response.statusCode}');
    } catch (e) {
      developer.log('Error en forzarConteo: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> configurarIntervalo(
      int maquinaId, int segundos) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(
            '${ApiConstants.baseUrl}/api/maquinas/$maquinaId/config-esp32/'),
        headers: headers,
        body: json.encode({'intervalo_segundos': segundos}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Error ${response.statusCode}');
    } catch (e) {
      developer.log('Error en configurarIntervalo: $e');
      rethrow;
    }
  }

  // ========== COMANDOS GLOBALES A TODAS LAS BANDEJAS ==========
  Future<List<Map<String, dynamic>>> enviarComandoBroadcast(
    int maquinaId,
    String comando, {
    Map<String, dynamic> parametros = const {},
  }) async {
    final slaves = await getSlaves(maquinaId);
    final List<Map<String, dynamic>> resultados = [];

    for (var slave in slaves) {
      try {
        final result = await enviarComando(
          slave.id,
          comando,
          parametros: parametros,
        );
        resultados.add({
          'slaveId': slave.id,
          'posicion': slave.posicion,
          'success': true,
          'response': result,
        });
      } catch (e) {
        resultados.add({
          'slaveId': slave.id,
          'posicion': slave.posicion,
          'success': false,
          'error': e.toString(),
        });
      }
    }

    return resultados;
  }
}
