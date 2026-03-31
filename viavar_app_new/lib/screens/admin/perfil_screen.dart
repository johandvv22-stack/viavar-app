import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _notificaciones = true;
  bool _sonido = true;
  bool _vibracion = false;
  String _idioma = 'Español';
  String _tema = 'Claro';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ========== PERFIL ==========
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF0D47A1),
                    child: Text(
                      user?.username[0].toUpperCase() ?? 'A',
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.username ?? 'Administrador',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0D47A1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 16,
                          color: const Color(0xFF0D47A1),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ADMINISTRADOR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D47A1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ========== CONFIGURACIÓN ==========
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: const Color(0xFF0D47A1)),
                        const SizedBox(width: 8),
                        const Text(
                          'Configuración',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Tema
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.palette, color: Colors.amber),
                    ),
                    title: const Text('Tema'),
                    subtitle: Text(_tema),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (value) {
                        setState(() {
                          _tema = value;
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'Claro',
                          child: Text('🌞 Claro'),
                        ),
                        const PopupMenuItem(
                          value: 'Oscuro',
                          child: Text('🌙 Oscuro'),
                        ),
                        const PopupMenuItem(
                          value: 'Sistema',
                          child: Text('⚙️ Seguir sistema'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 72),

                  // Idioma
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language, color: Colors.green),
                    ),
                    title: const Text('Idioma'),
                    subtitle: Text(_idioma),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (value) {
                        setState(() {
                          _idioma = value;
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'Español',
                          child: Text('🇨🇴 Español'),
                        ),
                        const PopupMenuItem(
                          value: 'English',
                          child: Text('🇺🇸 English'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ========== NOTIFICACIONES ==========
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.notifications,
                            color: const Color(0xFF0D47A1)),
                        const SizedBox(width: 8),
                        const Text(
                          'Notificaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Activar notificaciones
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.notifications_active,
                          color: Colors.blue[700]),
                    ),
                    title: const Text('Notificaciones'),
                    subtitle: const Text('Recibir alertas de stock crítico'),
                    value: _notificaciones,
                    onChanged: (value) {
                      setState(() {
                        _notificaciones = value;
                      });
                    },
                  ),
                  const Divider(height: 1, indent: 72),

                  // Sonido
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.volume_up, color: Colors.orange),
                    ),
                    title: const Text('Sonido'),
                    subtitle:
                        const Text('Reproducir sonido al recibir alertas'),
                    value: _sonido,
                    onChanged: (value) {
                      setState(() {
                        _sonido = value;
                      });
                    },
                  ),
                  const Divider(height: 1, indent: 72),

                  // Vibración
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.vibration, color: Colors.purple),
                    ),
                    title: const Text('Vibración'),
                    subtitle: const Text('Vibrar al recibir alertas'),
                    value: _vibracion,
                    onChanged: (value) {
                      setState(() {
                        _vibracion = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ========== SOPORTE ==========
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildOption(
                    icon: Icons.help_outline,
                    title: 'Centro de Ayuda',
                    subtitle: 'Preguntas frecuentes y soporte técnico',
                    color: Colors.blue,
                    onTap: () {
                      _showHelpDialog(context);
                    },
                  ),
                  _buildDivider(),
                  _buildOption(
                    icon: Icons.description,
                    title: 'Términos y Condiciones',
                    subtitle: 'Leer términos de uso',
                    color: Colors.teal,
                    onTap: () {
                      _showTermsDialog(context);
                    },
                  ),
                  _buildDivider(),
                  _buildOption(
                    icon: Icons.privacy_tip,
                    title: 'Política de Privacidad',
                    subtitle: 'Protección de datos',
                    color: Colors.indigo,
                    onTap: () {
                      _showPrivacyDialog(context);
                    },
                  ),
                  _buildDivider(),
                  _buildOption(
                    icon: Icons.info_outline,
                    title: 'Acerca de',
                    subtitle: 'Versión 1.0.0 - Viavar',
                    color: Colors.grey,
                    onTap: () {
                      _showAboutDialog(context);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ========== CERRAR SESIÓN ==========
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildOption(
                icon: Icons.logout,
                title: 'Cerrar Sesión',
                subtitle: 'Salir de la aplicación',
                color: Colors.red,
                textColor: Colors.red,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cerrar Sesión'),
                      content: const Text(
                        '¿Estás seguro que deseas cerrar sesión?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Cerrar Sesión'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await authService.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ),

            const SizedBox(height: 30),

            // ========== VERSIÓN ==========
            Text(
              'Versión 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2026 Viavar - Todos los derechos reservados',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.grey[900],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: Colors.grey[200],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📘 Centro de Ayuda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(Icons.help, '¿Cómo crear un cierre?'),
            _buildHelpItem(Icons.receipt, 'Gestión de gastos'),
            _buildHelpItem(Icons.inventory, 'Control de inventario'),
            _buildHelpItem(Icons.monetization_on, 'Cálculo de utilidades'),
            const Divider(),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.email, color: Colors.blue),
              title: Text('soporte@viavar.com'),
              subtitle: Text('Correo de soporte'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.phone, color: Colors.green),
              title: Text('+57 601 234 5678'),
              subtitle: Text('Línea de atención'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String text) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: Colors.blue[700]),
      title: Text(text, style: const TextStyle(fontSize: 14)),
      dense: true,
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📄 Términos y Condiciones'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: const [
              Text(
                'Versión 1.0 - 2026\n\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '1. Uso de la aplicación\n'
                'Esta aplicación es de uso exclusivo para la gestión de máquinas dispensadoras Viavar.\n\n'
                '2. Datos\n'
                'La información registrada es confidencial y de propiedad de la empresa.\n\n'
                '3. Responsabilidades\n'
                'El usuario es responsable de la veracidad de los datos ingresados.\n\n'
                '4. Modificaciones\n'
                'Viavar se reserva el derecho de actualizar estos términos.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔒 Política de Privacidad'),
        content: const Text(
          'Tus datos personales y financieros están protegidos bajo la ley de protección de datos.\n\n'
          '• No compartimos información con terceros\n'
          '• Los datos se almacenan de forma segura\n'
          '• Solo usuarios autorizados tienen acceso\n'
          '• Puedes solicitar la eliminación de tus datos',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Viavar',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF0D47A1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.inventory,
          size: 40,
          color: Colors.white,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'Sistema integral de control de inventario y contabilidad\n'
          'para máquinas dispensadoras tipo espiral.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildAboutRow('Desarrollado por:', 'Viavar Tech'),
              _buildAboutRow('Última actualización:', 'Febrero 2026'),
              _buildAboutRow('Licencia:', 'Comercial'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
