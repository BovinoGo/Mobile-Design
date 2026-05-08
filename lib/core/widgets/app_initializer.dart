import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../services/notification_service.dart';

class AppInitializer extends StatefulWidget {
  final Widget child;
  final bool requestPermissionsOnInit;

  const AppInitializer({
    super.key,
    required this.child,
    this.requestPermissionsOnInit = true,
  });

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _permissionsChecked = false;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    if (widget.requestPermissionsOnInit) {
      _checkAndRequestPermissions();
    } else {
      _permissionsChecked = true;
      _permissionsGranted = true;
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    try {
      final permissionService = PermissionService();
      
      // Verificar si ya tenemos los permisos
      final hasAllPermissions = await permissionService.hasAllPermissions();
      
      if (!hasAllPermissions && mounted) {
        // Solicitar permisos
        final granted = await permissionService.handleAppPermissions(context);
        setState(() {
          _permissionsGranted = granted;
          _permissionsChecked = true;
        });
        
        // Si se otorgaron los permisos de notificación, mostrar notificación de bienvenida
        if (granted) {
          final notificationService = NotificationService();
          final username = await _getCurrentUsername();
          if (username.isNotEmpty) {
            await notificationService.showWelcomeNotification(username);
          }
        }
      } else {
        setState(() {
          _permissionsGranted = true;
          _permissionsChecked = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      setState(() {
        _permissionsGranted = false;
        _permissionsChecked = true;
      });
    }
  }

  Future<String> _getCurrentUsername() async {
    try {
      // Aquí podrías obtener el username del TokenService o de donde lo tengas guardado
      return "Usuario"; // Placeholder
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsChecked) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF00695C),
              ),
              SizedBox(height: 16),
              Text(
                'Configurando permisos...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF00695C),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_permissionsGranted) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Permisos requeridos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00695C),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'VacApp necesita ciertos permisos para funcionar correctamente. Puedes otorgarlos en cualquier momento desde la configuración de la aplicación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _checkAndRequestPermissions();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00695C)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Reintentar',
                          style: TextStyle(
                            color: Color(0xFF00695C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _permissionsGranted = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00695C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Continuar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
