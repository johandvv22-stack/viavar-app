import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../widgets/charts/top_products_bar_chart.dart';
import 'auth_service.dart';
import '../models/dashboard_data.dart';

class DashboardService {
  final AuthService _authService = AuthService();

  // ========== MÉTODO PRINCIPAL ==========
  Future<DashboardData> getDashboardData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception("No hay token de autenticación");
      }

      final startStr = _formatDateForApi(startDate);
      final endStr = _formatDateForApi(endDate);

      final url =
          "${ApiConstants.baseUrl}${ApiConstants.dashboard}?fecha_inicio=$startStr&fecha_fin=$endStr";

      print("📡 DashboardService.getDashboardData: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DashboardData.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception("Sesión expirada");
      } else {
        throw Exception("Error ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error crítico en getDashboardData: $e");
      rethrow;
    }
  }

// ========== MÉTODO PARA AJUSTAR FECHAS (CORRECCIÓN TEMPORAL) ==========
  DateTime _ajustarFecha(String fechaStr) {
    try {
      // Parsear la fecha
      DateTime fecha = DateTime.parse(fechaStr);

      // RESTAR UN DÍA para corregir el desfase
      // Esto es porque las ventas están guardadas con fecha de mañana
      DateTime fechaAjustada = fecha.subtract(const Duration(days: 1));

      print(
          "📅 Ajustando fecha: $fechaStr -> ${fechaAjustada.toIso8601String().split('T')[0]}");
      return fechaAjustada;
    } catch (e) {
      print("⚠️ Error ajustando fecha: $e");
      return DateTime.now();
    }
  }

  // ========== MÉTODO PARA VENTAS POR DÍA ==========
  // ========== MÉTODO CORREGIDO PARA VENTAS POR DÍA ==========
  Future<List<VentaDiaria>> getVentasPorDia({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      final startStr = _formatDateForApi(startDate);
      final endStr = _formatDateForApi(endDate);

      final url =
          "${ApiConstants.baseUrl}/api/ventas/reporte/?fecha_inicio=$startStr&fecha_fin=$endStr";

      print("📡 Consultando ventas por día: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> ventasPorDiaList = jsonData['ventas_por_dia'] ?? [];

        print("📊 ventas_por_dia del backend: ${ventasPorDiaList.length}");

        List<VentaDiaria> resultado = ventasPorDiaList.map((item) {
          // Parsear la fecha del backend (viene como YYYY-MM-DD)
          DateTime fechaBackend = DateTime.parse(item['fecha_simple']);

          // La fecha en el backend está en UTC, pero nosotros la queremos en hora local
          // No hacemos ajustes porque el backend ya debería devolverla en la zona correcta
          return VentaDiaria(
            fecha: fechaBackend,
            venta: (item['ventas'] ?? 0).toDouble(),
          );
        }).toList();

        // Ordenar por fecha
        resultado.sort((a, b) => a.fecha.compareTo(b.fecha));

        print("✅ ${resultado.length} días con ventas en el período");
        for (var v in resultado) {
          print(
              "   - ${v.fecha.toIso8601String().split('T')[0]}: \$${v.venta}");
        }

        return resultado;
      } else {
        print("❌ Error en getVentasPorDia: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Error en getVentasPorDia: $e");
      return [];
    }
  }

  // ========== MÉTODO PARA VENTAS POR MÁQUINA ==========
  Future<List<MaquinaVentas>> getVentasPorMaquina({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      final startStr = _formatDateForApi(startDate);
      final endStr = _formatDateForApi(endDate);

      final url =
          "${ApiConstants.baseUrl}/api/ventas/reporte/?fecha_inicio=$startStr&fecha_fin=$endStr";

      print("📡 Consultando ventas por máquina: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> ventasPorMaquinaList =
            jsonData['ventas_por_maquina'] ?? [];

        List<MaquinaVentas> resultado = ventasPorMaquinaList.map((item) {
          return MaquinaVentas(
            nombre: item['maquina__nombre'] ?? 'Sin nombre',
            ventas: (item['ventas'] ?? 0).toDouble(),
            ganancia: (item['ganancia'] ?? 0).toDouble(),
          );
        }).toList();

        resultado.sort((a, b) => b.ventas.compareTo(a.ventas));

        print("✅ ${resultado.length} máquinas con ventas");
        return resultado;
      } else {
        print("❌ Error en getVentasPorMaquina: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Error en getVentasPorMaquina: $e");
      return [];
    }
  }

  // ========== MÉTODO PARA VENTAS POR PRODUCTO ==========
  Future<List<TopProductoChartData>> getVentasPorProducto({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      final startStr = _formatDateForApi(startDate);
      final endStr = _formatDateForApi(endDate);

      final url =
          "${ApiConstants.baseUrl}/api/ventas/reporte/?fecha_inicio=$startStr&fecha_fin=$endStr";

      print("📡 Consultando ventas por producto (reporte): $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> productosData =
            jsonData['ventas_por_producto'] ?? [];

        List<TopProductoChartData> resultado = productosData.map((item) {
          String categoria = _determinarCategoria(
              item["producto__codigo"] ?? "", item["producto__nombre"] ?? "");

          return TopProductoChartData(
            nombre: item["producto__nombre"] ?? "",
            ventas: (item["ventas"] ?? 0).toDouble(),
            ganancia: (item["ganancia"] ?? 0).toDouble(),
            cantidad: item["cantidad"] ?? 0,
            categoria: categoria,
          );
        }).toList();

        print("✅ ${resultado.length} productos con ventas (desde reporte)");
        return resultado;
      } else {
        print("❌ Error en getVentasPorProducto: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Error en getVentasPorProducto: $e");
      return [];
    }
  }

  // ========== MÉTODOS HELPER ==========
  String _determinarCategoria(String codigo, String nombre) {
    String nombreLower = nombre.toLowerCase();
    String codigoUpper = codigo.toUpperCase();

    if (codigoUpper.contains("SNACK") ||
        nombreLower.contains("papas") ||
        nombreLower.contains("chocolatina") ||
        nombreLower.contains("snack")) {
      return "Snack";
    } else if (codigoUpper.contains("BEB") ||
        nombreLower.contains("agua") ||
        nombreLower.contains("gaseosa") ||
        nombreLower.contains("bebida")) {
      return "Bebida";
    } else if (nombreLower.contains("café") ||
        nombreLower.contains("cafe") ||
        nombreLower.contains("tinto")) {
      return "Café";
    } else if (nombreLower.contains("dulce") ||
        nombreLower.contains("chocolate") ||
        nombreLower.contains("gomita")) {
      return "Dulce";
    } else {
      return "Otro";
    }
  }

  String _formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
