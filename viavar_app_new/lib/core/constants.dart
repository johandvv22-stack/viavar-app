class ApiConstants {
  //static const String baseUrl = "http://localhost:8000";
  static const String baseUrl =
      "http://178.128.229.252"; // Tu IP de DigitalOcean
  //static const String baseUrl = 'http://192.168.101.3:8000'; // chimichangas

  static const String login = '/api/token/';
  static const String refresh = '/api/token/refresh/';
  static const String dashboard = '/api/dashboard/';
  static const String maquinas = '/api/maquinas/';
  static const String productos = '/api/productos/';
  static const String visitas = '/api/visitas/';
  static const String gastos = '/api/gastos/';
  static const String cierres = '/api/cierres/';
  static const String esp32 = '/api/esp32/v1/';
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  static const Map<String, String> headersJson = {
    "Content-Type": "application/json",
  };
}

class AppConstants {
  static const String appName = "ViaVar Control";
  static const String storageTokenKey = "auth_token";
  static const String storageRefreshKey = "refresh_token";
  static const String storageUserKey = "user_data";
  static const String storageRoleKey = "user_role";
}
