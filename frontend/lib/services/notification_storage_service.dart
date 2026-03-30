import 'package:shared_preferences/shared_preferences.dart';

class NotificationStorageService {
  static const String _prefix = 'last_notification_';

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<void> saveLastNotification(String key, DateTime timestamp) async {
    final prefs = await _getPrefs();
    await prefs.setString('$_prefix$key', timestamp.toIso8601String());
  }

  Future<DateTime?> getLastNotification(String key) async {
    final prefs = await _getPrefs();
    final value = prefs.getString('$_prefix$key');
    if (value == null) return null;
    return DateTime.parse(value);
  }

  Future<bool> shouldNotify(String key,
      {Duration minInterval = const Duration(hours: 24)}) async {
    final last = await getLastNotification(key);
    if (last == null) return true;
    return DateTime.now().difference(last) >= minInterval;
  }

  static String machineStockKey(int machineId) => 'machine_stock_$machineId';
  static String productStockKey(int machineId) => 'product_stock_$machineId';
  static String inactiveMachineKey(int machineId) =>
      'inactive_machine_$machineId';
}
