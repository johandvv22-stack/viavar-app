import 'notification_service.dart';
import 'alert_condition_service.dart';
import 'notification_storage_service.dart';
import 'inventario_service.dart';
import '../services/maquinas_service.dart';
import '../services/auth_service.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final NotificationService _notificationService = NotificationService();
  final AlertConditionService _alertConditionService = AlertConditionService();
  final NotificationStorageService _storageService =
      NotificationStorageService();
  final MaquinasService _maquinasService = MaquinasService();
  final InventarioService _inventarioService = InventarioService();
  final AuthService _authService = AuthService();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _notificationService.initialize();
    await _notificationService.requestPermissions();

    _notificationService.onNotificationTap = _handleNotificationTap;
    _isInitialized = true;
  }

  Future<void> checkAndNotify() async {
    try {
      final user = await _authService.getCurrentUser();
      final isAdmin = user?.rol == 'admin';

      final maquinas = await _maquinasService.getMaquinas();
      final inventarios = await _inventarioService.getInventarioCompleto();

      // TIPO 1: Stock crítico por máquina
      final maquinasCriticas = _alertConditionService
          .getMaquinasConStockCritico(maquinas, inventarios);

      for (var maquina in maquinasCriticas) {
        final porcentaje = _alertConditionService.getPorcentajeMaquina(
            maquina.id, inventarios);
        final key = NotificationStorageService.machineStockKey(maquina.id);

        if (await _storageService.shouldNotify(key)) {
          await _notificationService.showStockCriticoNotification(
              maquina, porcentaje, isAdmin);
          await _storageService.saveLastNotification(key, DateTime.now());
        }
      }

      // TIPO 2: Stock crítico por producto
      final productosCriticos = _alertConditionService
          .getProductosConStockCritico(inventarios, maquinas);
      final agrupados = _alertConditionService
          .agruparProductosCriticosPorMaquina(productosCriticos);

      for (var entry in agrupados.entries) {
        final maquinaId = entry.key;
        final criticos = entry.value;
        final maquina = maquinas.firstWhere((m) => m.id == maquinaId);
        final key = NotificationStorageService.productStockKey(maquinaId);

        if (await _storageService.shouldNotify(key,
            minInterval: const Duration(hours: 12))) {
          if (criticos.length == 1) {
            final item = criticos.first;
            await _notificationService.showProductoCriticoNotification(
              maquina: maquina,
              productoNombre: item['producto_nombre'],
              codigoEspiral: item['codigo_espiral'],
              stockActual: item['stock_actual'],
              isAdmin: isAdmin,
            );
          } else {
            await _notificationService.showMultiplesProductosNotification(
              maquina: maquina,
              cantidad: criticos.length,
              isAdmin: isAdmin,
            );
          }
          await _storageService.saveLastNotification(key, DateTime.now());
        }
      }

      // TIPO 3: Máquinas inactivas (solo admin)
      if (isAdmin) {
        final maquinasInactivas =
            _alertConditionService.getMaquinasInactivas(maquinas);
        for (var maquina in maquinasInactivas) {
          final key = NotificationStorageService.inactiveMachineKey(maquina.id);
          if (await _storageService.shouldNotify(key,
              minInterval: const Duration(hours: 48))) {
            await _notificationService.showMaquinaInactivaNotification(maquina);
            await _storageService.saveLastNotification(key, DateTime.now());
          }
        }
      }
    } catch (e) {
      print('❌ Error en checkAndNotify: $e');
    }
  }

  void _handleNotificationTap(String payload) {
    final parts = payload.split('|');
    if (parts.length < 2) return;

    final type = parts[0];
    final machineId = int.tryParse(parts[1]);
    final userRole = parts.length > 2 ? parts[2] : 'admin';

    print('🔔 Notificación tocada: $type, máquina: $machineId, rol: $userRole');
  }
}
