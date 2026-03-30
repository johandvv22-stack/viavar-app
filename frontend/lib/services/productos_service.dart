import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/producto.dart';
import 'auth_service.dart';

class ProductosService {
  final AuthService _authService = AuthService();

  // Obtener listado de productos
  Future<List<Producto>> getProductos({
    int page = 1,
    int pageSize = 20,
    String? categoria,
    String? search,
    bool? estado,
  }) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/productos/";
      url += "?page=$page&page_size=$pageSize";
      
      if (categoria != null && categoria.isNotEmpty) {
        url += "&categoria=$categoria";
      }
      
      if (search != null && search.isNotEmpty) {
        url += "&search=$search";
      }
      
      if (estado != null) {
        url += "&estado=$estado";
      }

      print(" Llamando a API para obtener productos: $url");

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
        
        List<Producto> productos = [];
        for (var item in results) {
          productos.add(Producto.fromJson(item));
        }

        print(" Productos obtenidos: ${productos.length}");
        return productos;
      } else {
        print(" Error en API: ${response.statusCode}");
        throw Exception("Error al obtener productos: ${response.statusCode}");
      }
    } catch (e) {
      print(" Excepción en getProductos: $e");
      rethrow;
    }
  }

  // Obtener un producto por ID
  Future<Producto> getProductoById(int id) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/productos/$id/";

      print(" Llamando a API para obtener producto $id: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${await _authService.getToken()}",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print(" Producto $id obtenido");
        return Producto.fromJson(data);
      } else {
        print(" Error en API: ${response.statusCode}");
        throw Exception("Error al obtener producto: ${response.statusCode}");
      }
    } catch (e) {
      print(" Excepción en getProductoById: $e");
      rethrow;
    }
  }

  // Crear nuevo producto
  Future<Producto> createProducto(Map<String, dynamic> datos) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/productos/";

      print(" Llamando a API para crear producto: $url");
      print(" Datos: $datos");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${await _authService.getToken()}",
        },
        body: json.encode(datos),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        print(" Producto creado exitosamente");
        return Producto.fromJson(data);
      } else {
        print(" Error en API: ${response.statusCode}");
        print(" Respuesta: ${response.body}");
        throw Exception("Error al crear producto: ${response.statusCode}");
      }
    } catch (e) {
      print(" Excepción en createProducto: $e");
      rethrow;
    }
  }

  // Actualizar producto
  Future<Producto> updateProducto(int id, Map<String, dynamic> datos) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/productos/$id/";

      print(" Llamando a API para actualizar producto $id: $url");
      print(" Datos: $datos");

      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${await _authService.getToken()}",
        },
        body: json.encode(datos),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print(" Producto $id actualizado");
        return Producto.fromJson(data);
      } else {
        print(" Error en API: ${response.statusCode}");
        throw Exception("Error al actualizar producto: ${response.statusCode}");
      }
    } catch (e) {
      print(" Excepción en updateProducto: $e");
      rethrow;
    }
  }

  // Eliminar producto (soft delete)
  Future<void> deleteProducto(int id) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/productos/$id/";

      print(" Llamando a API para eliminar producto $id: $url");

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${await _authService.getToken()}",
        },
      );

      if (response.statusCode == 204) {
        print(" Producto $id eliminado");
      } else {
        print(" Error en API: ${response.statusCode}");
        throw Exception("Error al eliminar producto: ${response.statusCode}");
      }
    } catch (e) {
      print(" Excepción en deleteProducto: $e");
      rethrow;
    }
  }

  // Obtener categorías de productos disponibles
  Future<List<String>> getCategorias() async {
    try {
      String url = "${ApiConstants.baseUrl}/api/productos/categorias/";

      print(" Llamando a API para obtener categorías: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${await _authService.getToken()}",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print(" Categorías obtenidas: ${data.length}");
        return data.map((item) => item.toString()).toList();
      } else {
        print(" Error en API: ${response.statusCode}");
        throw Exception("Error al obtener categorías: ${response.statusCode}");
      }
    } catch (e) {
      print(" Excepción en getCategorias: $e");
      rethrow;
    }
  }
}
