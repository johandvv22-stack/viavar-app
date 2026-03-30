import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "./services/auth_service.dart";
import "./screens/login_screen.dart";
import "./screens/home_screen.dart";
import './services/notification_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🟢 Inicializando NotificationManager...');
  await NotificationManager().initialize();
  print('✅ NotificationManager inicializado correctamente');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService()..loadStoredCredentials(),
      child: MaterialApp(
        title: "ViaVar Control",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Mostrar loading mientras verifica autenticación
    if (authService.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Verificar si está autenticado
    if (authService.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
