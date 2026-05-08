import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vacapp/features/vaccines/data/models/vaccines_dto.dart';
import 'package:vacapp/features/vaccines/data/repositories/vaccines_repository.dart';
import 'package:vacapp/core/widgets/island_notification.dart';

// Función para mostrar el diálogo de eliminación
Future<bool?> showDeleteVaccineDialog({
  required BuildContext context,
  required VaccinesDto vaccine,
  required VaccinesRepository repository,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _DeleteVaccineDialog(
      vaccine: vaccine,
      repository: repository,
    ),
  );
}

class _DeleteVaccineDialog extends StatefulWidget {
  final VaccinesDto vaccine;
  final VaccinesRepository repository;

  const _DeleteVaccineDialog({
    required this.vaccine,
    required this.repository,
  });

  @override
  State<_DeleteVaccineDialog> createState() => _DeleteVaccineDialogState();
}

class _DeleteVaccineDialogState extends State<_DeleteVaccineDialog>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Paleta institucional
  static const Color primary = Color(0xFF00695C);
  static const Color lightGreen = Color(0xFFE8F5E8);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _deleteVaccine() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.repository.deleteVaccine(widget.vaccine.id);
      
      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        IslandNotification.showError(context, message: 'Error al eliminar vacuna: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de advertencia
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.shade200,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.warning_rounded,
                size: 35,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 20),
            
            // Título
            const Text(
              '¿Eliminar Vacuna?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Descripción
            Text(
              'Esta acción no se puede deshacer',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Información de la vacuna compacta
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Imagen de la vacuna
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: widget.vaccine.vaccineImg.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(widget.vaccine.vaccineImg),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: widget.vaccine.vaccineImg.isEmpty ? lightGreen : null,
                    ),
                    child: widget.vaccine.vaccineImg.isEmpty
                        ? const Icon(
                            Icons.vaccines_outlined,
                            color: primary,
                            size: 25,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  
                  // Información de la vacuna
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.vaccine.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.vaccine.vaccineType,
                            style: const TextStyle(
                              fontSize: 11,
                              color: primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Botones de acción
            Row(
              children: [
                // Botón Cancelar
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : () => Navigator.pop(context, false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Botón Eliminar
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade600,
                          Colors.red.shade500,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _deleteVaccine,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Eliminar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Mantener la clase antigua para compatibilidad, pero redirigir al diálogo
class DeleteVaccinesPage extends StatelessWidget {
  final VaccinesRepository repository;
  final VaccinesDto vaccine;

  const DeleteVaccinesPage({
    super.key,
    required this.repository,
    required this.vaccine,
  });

  @override
  Widget build(BuildContext context) {
    // Mostrar el diálogo inmediatamente y cerrar esta página
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await showDeleteVaccineDialog(
        context: context,
        vaccine: vaccine,
        repository: repository,
      );
      if (context.mounted) {
        Navigator.pop(context, result);
      }
    });

    // Página transparente mientras se muestra el diálogo
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }
}
