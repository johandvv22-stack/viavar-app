import '../models/maquina.dart';
import '../models/inventario_maquina.dart';

class AlertConditionService {
  static const double stockCriticoPorcentaje = 20.0;
  static const int stockCriticoUnidades = 3;
  static const int diasInactividad = 3;

  List<Maquina> getMaquinasConStockCritico(
    List<Maquina> maquinas,
    List<InventarioMaquina> inventarios,
  ) {
    final Map<int, double> porcentajesPorMaquina = {};

    for (var inv in inventarios) {
      final porcentaje = inv.porcentajeStock;
      if (!porcentajesPorMaquina.containsKey(inv.maquinaId)) {
        porcentajesPorMaquina[inv.maquinaId] = porcentaje;
      }
    }

    return maquinas.where((m) {
      final porcentaje = porcentajesPorMaquina[m.id] ?? 100.0;
      return porcentaje < stockCriticoPorcentaje && m.estado == 'activo';
    }).toList();
  }

  double getPorcentajeMaquina(
      int maquinaId, List<InventarioMaquina> inventarios) {
    final inventariosMaquina =
        inventarios.where((i) => i.maquinaId == maquinaId).toList();
    if (inventariosMaquina.isEmpty) return 100.0;

    final totalActual =
        inventariosMaquina.fold<int>(0, (sum, i) => sum + i.stockActual);
    final totalMaximo =
        inventariosMaquina.fold<int>(0, (sum, i) => sum + i.stockMaximo);

    if (totalMaximo == 0) return 100.0;
    return (totalActual / totalMaximo) * 100;
  }

  List<Map<String, dynamic>> getProductosConStockCritico(
    List<InventarioMaquina> inventarios,
    List<Maquina> maquinas,
  ) {
    final Map<int, Maquina> maquinasMap = {for (var m in maquinas) m.id: m};
    final List<Map<String, dynamic>> criticos = [];

    for (var inv in inventarios) {
      final maquina = maquinasMap[inv.maquinaId];
      if (maquina == null || maquina.estado != 'activo') continue;

      if (inv.stockActual <= stockCriticoUnidades && inv.stockActual > 0) {
        criticos.add({
          'maquina': maquina,
          'producto_nombre': inv.productoNombre,
          'producto_codigo': inv.productoCodigo,
          'stock_actual': inv.stockActual,
          'codigo_espiral': inv.codigoEspiral,
          'inventario': inv,
        });
      }
    }

    return criticos;
  }

  Map<int, List<Map<String, dynamic>>> agruparProductosCriticosPorMaquina(
    List<Map<String, dynamic>> criticos,
  ) {
    final Map<int, List<Map<String, dynamic>>> agrupados = {};

    for (var item in criticos) {
      final maquinaId = (item['maquina'] as Maquina).id;
      agrupados.putIfAbsent(maquinaId, () => []);
      agrupados[maquinaId]!.add(item);
    }

    return agrupados;
  }

  List<Maquina> getMaquinasInactivas(List<Maquina> maquinas) {
    final ahora = DateTime.now();

    return maquinas.where((m) {
      if (m.estado != 'activo') return false;
      if (m.ultimaVenta == null) return true;

      final diasInactivos = ahora.difference(m.ultimaVenta!).inDays;
      return diasInactivos >= diasInactividad;
    }).toList();
  }

  String generarMensajeStockCritico(Maquina maquina, double porcentaje) {
    return '${maquina.nombre} tiene solo ${porcentaje.toStringAsFixed(0)}% de inventario';
  }

  String generarMensajeProductoCritico(Map<String, dynamic> item) {
    final maquina = item['maquina'] as Maquina;
    final productoNombre = item['producto_nombre'] as String;
    final stock = item['stock_actual'] as int;
    final codigoEspiral = item['codigo_espiral'] as String;

    return 'La máquina ${maquina.nombre} presenta stock bajo para el producto "$productoNombre" (${codigoEspiral}) con un stock actual de $stock unidades';
  }

  String generarMensajeMultiplesProductos(Maquina maquina, int cantidad) {
    return 'La máquina ${maquina.nombre} tiene $cantidad productos con stock bajo';
  }

  String generarMensajeInactividad(Maquina maquina) {
    final dias = DateTime.now().difference(maquina.ultimaVenta!).inDays;
    return '${maquina.nombre} no reporta actividad desde hace $dias días';
  }
}
