import 'package:flutter/material.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/animals/presentation/pages/offline_animals_page.dart';

class NoConnectionDialog {
  static void show(BuildContext context, {VoidCallback? onRetry}) async {
    // Verificar si hay datos offline disponibles
    final hasOfflineData = await TokenService.instance.hasOfflineData();
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Imagen de No WiFi
                  Image.asset(
                    'assets/images/nowifi.png',
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(height: 20),
                  
                  // Título
                  const Text(
                    '¡Sin conexión!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00695C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Mensaje
                  const Text(
                    'Parece que no tienes conexión a internet. Verifica tu conexión WiFi o datos móviles para continuar.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  // Botón de reintentar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00695C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRetry?.call();
                      },
                      child: const Text(
                        'Reintentar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  // Mostrar botón "Ver datos guardados" solo si hay datos offline
                  if (hasOfflineData) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00695C), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navegar a la página de bovinos offline
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OfflineAnimalsPage()),
                          );
                        },
                        child: const Text(
                          'Ver datos guardados',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00695C),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Mostrar diálogo simple sin botón de reintentar
  static void showSimple(BuildContext context) {
    show(context);
  }

  /// Mostrar diálogo con acción personalizada de reintento
  static void showWithRetry(BuildContext context, VoidCallback onRetry) {
    show(context, onRetry: onRetry);
  }
}
