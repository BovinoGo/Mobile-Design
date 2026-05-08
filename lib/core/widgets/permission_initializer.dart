import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vacapp/core/services/permission_service.dart';

const Color primary = Color(0xFF00695C);
const Color accent = Color(0xFF4CAF50);

class PermissionInitializer extends StatefulWidget {
  final Widget child;
  
  const PermissionInitializer({
    super.key,
    required this.child,
  });

  @override
  State<PermissionInitializer> createState() => _PermissionInitializerState();
}

class _PermissionInitializerState extends State<PermissionInitializer> {
  bool _permissionsChecked = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    try {
      debugPrint('🔐 [PERMISSION] Verificando permisos...');
      
      final permissionService = PermissionService();
      
      // Verificar si ya tenemos los permisos críticos
      final hasCritical = await permissionService.hasAllCriticalPermissions();
      
      if (hasCritical) {
        debugPrint('✅ [PERMISSION] Todos los permisos críticos ya están concedidos');
        setState(() {
          _permissionsChecked = true;
        });
        return;
      }

      debugPrint('⚠️ [PERMISSION] Solicitando permisos críticos directamente del sistema...');
      
      // Solicitar permisos críticos directamente sin diálogos personalizados
      final statuses = await permissionService.requestCriticalPermissions();
      
      // Log de resultados
      List<String> grantedPermissions = [];
      List<String> deniedPermissions = [];
      
      for (var entry in statuses.entries) {
        final permissionName = permissionService.getPermissionName(entry.key);
        if (entry.value == PermissionStatus.granted) {
          grantedPermissions.add(permissionName);
        } else {
          deniedPermissions.add(permissionName);
        }
      }

      if (grantedPermissions.isNotEmpty) {
        debugPrint('✅ [PERMISSION] Permisos concedidos: ${grantedPermissions.join(', ')}');
      }
      
      if (deniedPermissions.isNotEmpty) {
        debugPrint('⚠️ [PERMISSION] Permisos denegados: ${deniedPermissions.join(', ')}');
        debugPrint('ℹ️ [PERMISSION] La app continuará con funcionalidad limitada');
      }

      setState(() {
        _permissionsChecked = true;
      });
      
    } catch (e) {
      debugPrint('❌ [PERMISSION] Error verificando permisos: $e');
      setState(() {
        _permissionsChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsChecked) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary.withValues(alpha: 0.1),
                      accent.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_rounded,
                  size: 64,
                  color: primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'VacApp',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Configurando permisos...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
