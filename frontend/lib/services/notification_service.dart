import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/maquina.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int idStockCritico = 1000;
  static const int idProductoCritico = 2000;
  static const int idInactividad = 3000;

  Function(String)? onNotificationTap;

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    if (onNotificationTap != null && response.payload != null) {
      onNotificationTap!(response.payload!);
    }
  }

  Future<bool> requestPermissions() async {
    // En Android 13+, los permisos se solicitan en tiempo de ejecución
    // Por ahora, asumimos que están concedidos
    return true;
  }

  Future<void> showStockCriticoNotification(
    Maquina maquina,
    double porcentaje,
    bool isAdmin,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'stock_critico_channel',
      'Stock Crítico',
      channelDescription: 'Notificaciones de stock bajo en máquinas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload =
        'stock_critico|${maquina.id}|${isAdmin ? 'admin' : 'operario'}';

    await _flutterLocalNotificationsPlugin.show(
      idStockCritico + maquina.id,
      '⚠️ Stock crítico detectado',
      '${maquina.nombre} tiene solo ${porcentaje.toStringAsFixed(0)}% de inventario',
      details,
      payload: payload,
    );
  }

  Future<void> showProductoCriticoNotification({
    required Maquina maquina,
    required String productoNombre,
    required String codigoEspiral,
    required int stockActual,
    required bool isAdmin,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'producto_critico_channel',
      'Productos con Stock Bajo',
      channelDescription: 'Notificaciones de productos con stock bajo',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload =
        'producto_critico|${maquina.id}|${isAdmin ? 'admin' : 'operario'}';

    await _flutterLocalNotificationsPlugin.show(
      idProductoCritico + maquina.id,
      '⚠️ Atención: Stock bajo en máquina ${maquina.nombre}',
      'La máquina ${maquina.nombre} presenta stock bajo para el producto "$productoNombre" (${codigoEspiral}) con un stock actual de $stockActual unidades',
      details,
      payload: payload,
    );
  }

  Future<void> showMultiplesProductosNotification({
    required Maquina maquina,
    required int cantidad,
    required bool isAdmin,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'producto_critico_channel',
      'Productos con Stock Bajo',
      channelDescription: 'Notificaciones de productos con stock bajo',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload =
        'producto_critico|${maquina.id}|${isAdmin ? 'admin' : 'operario'}';

    await _flutterLocalNotificationsPlugin.show(
      idProductoCritico + maquina.id,
      '⚠️ Atención: Stock bajo en máquina ${maquina.nombre}',
      'La máquina ${maquina.nombre} tiene $cantidad productos con stock bajo',
      details,
      payload: payload,
    );
  }

  Future<void> showMaquinaInactivaNotification(Maquina maquina) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'inactividad_channel',
      'Máquinas Inactivas',
      channelDescription: 'Notificaciones de máquinas sin actividad',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    int diasInactivos = 0;
    if (maquina.ultimaVenta != null) {
      diasInactivos = DateTime.now().difference(maquina.ultimaVenta!).inDays;
    }

    final body = diasInactivos > 0
        ? '${maquina.nombre} no reporta actividad desde hace $diasInactivos días'
        : '${maquina.nombre} no tiene registros de actividad';

    final payload = 'inactividad|${maquina.id}|admin';

    await _flutterLocalNotificationsPlugin.show(
      idInactividad + maquina.id,
      '🔴 Máquina sin actividad',
      body,
      details,
      payload: payload,
    );
  }
}
