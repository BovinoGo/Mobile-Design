import 'package:flutter/material.dart';
import 'package:vacapp/features/stables/data/repositories/stable_repository.dart';
import 'package:vacapp/features/stables/data/models/stable_dto.dart';
import 'package:vacapp/features/stables/presentation/pages/create_stable_page.dart';
import 'package:vacapp/features/animals/data/dataasources/animals_service.dart';
import 'package:vacapp/features/animals/data/models/animal_dto.dart';

Future<Map<String, dynamic>> showDeleteStableDialog({
  required BuildContext context,
  required int stableId,
  required String stableName,
  required StableRepository repository,
  VoidCallback? onStablesUpdated, // Callback para actualizar establos en segundo plano
}) async {
  // Verificar si hay animales en el establo
  final animalsService = AnimalsService();
  final animals = await animalsService.fetchAnimalByStableId(stableId);
  
  // Verificar que el contexto siga siendo válido después de la operación async
  if (!context.mounted) return {'deleted': false, 'newStable': null};
  
  if (animals.isEmpty) {
    // Si no hay animales, mostrar diálogo simple de confirmación
    final deleted = await _showSimpleDeleteDialog(context, stableId, stableName, repository);
    return {'deleted': deleted, 'newStable': null};
  } else {
    // Si hay animales, mostrar diálogo para mover animales
    return await _showMoveAnimalsDialog(context, stableId, stableName, animals, repository, onStablesUpdated);
  }
}

Future<bool> _showSimpleDeleteDialog(
  BuildContext context,
  int stableId,
  String stableName,
  StableRepository repository,
) async {
  const primary = Color(0xFF002D26);
  
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono principal con animación
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.red.withValues(alpha: 0.1),
                            Colors.red.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 32,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Título
              const Text(
                'Eliminar Establo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primary,
                  letterSpacing: -0.5,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Descripción en 2 líneas
              const Text(
                '¿Estás seguro de que deseas\neliminar este establo?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Card del establo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.05),
                      Colors.green.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.warehouse_rounded,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stableName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                              Text(
                                'ID: $stableId',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Sin animales\nListo para eliminar',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Advertencia
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF002D26).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF002D26).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFF002D26),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Esta acción no se puede deshacer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF002D26),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        shadowColor: Colors.red.withValues(alpha: 0.3),
                      ),
                      child: const Text(
                        'Eliminar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
    },
  );

  if (confirmed == true) {
    // ignore: use_build_context_synchronously
    return await _deleteStable(context, stableId, repository);
  }
  
  return false;
}

Future<Map<String, dynamic>> _showMoveAnimalsDialog(
  BuildContext context,
  int stableId,
  String stableName,
  List<AnimalDto> animals,
  StableRepository repository,
  VoidCallback? onStablesUpdated,
) async {
  const primary = Color(0xFF002D26);
  
  final wantToMove = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        elevation: 10,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = MediaQuery.of(context).size.height * 0.8;
            return Container(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: maxHeight,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header fijo con icono a la izquierda y título a la derecha
                  Padding(
                    padding: const EdgeInsets.only(left: 28, right: 28, top: 28, bottom: 16),
                    child: Row(
                      children: [
                        // Icono a la izquierda
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFF002D26).withValues(alpha: 0.1),
                                      const Color(0xFF002D26).withValues(alpha: 0.05),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF002D26).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFF002D26),
                                    size: 20,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        
                        // Título a la derecha
                        const Expanded(
                          child: Text(
                            'Establo con Animales',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Contenido scrolleable
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Descripción principal
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(text: 'El establo '),
                                TextSpan(
                                  text: '"$stableName"',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: ' tiene ${animals.length} ${animals.length == 1 ? 'animal' : 'animales'}.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Card del establo con animales
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF002D26).withValues(alpha: 0.05),
                                  const Color(0xFF002D26).withValues(alpha: 0.02),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF002D26).withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF002D26).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.warehouse_rounded,
                                        color: Color(0xFF002D26),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            stableName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: primary,
                                            ),
                                          ),
                                          Text(
                                            'ID: $stableId',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Lista de animales en pills (compacta)
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: animals.take(8).map((animal) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.blue.withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.pets,
                                            size: 12,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            animal.displayName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                                
                                if (animals.length > 8) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '+${animals.length - 8} más',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Opciones (compactas)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Opciones disponibles:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                
                                _buildOptionItem(
                                  icon: Icons.move_up_rounded,
                                  title: 'Mover animales',
                                  description: 'Transferir todos los animales a otro establo',
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 6),
                                _buildOptionItem(
                                  icon: Icons.cancel_rounded,
                                  title: 'Cancelar',
                                  description: 'Mantener el establo sin cambios',
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  
                  // Botones fijos al final
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(true),
                            icon: const Icon(Icons.move_up_rounded, size: 20),
                            label: const Text(
                              'Mover Animales',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                              shadowColor: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
  
  if (wantToMove == true) {
    // ignore: use_build_context_synchronously
    return await _showMoveToStableOptions(context, stableId, stableName, animals, repository, onStablesUpdated);
  }
  
  return {'deleted': false, 'newStable': null};
}

// Widget helper para mostrar opciones en el diálogo
Widget _buildOptionItem({
  required IconData icon,
  required String title,
  required String description,
  required Color color,
}) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Future<Map<String, dynamic>> _showMoveToStableOptions(
  BuildContext context,
  int stableId,
  String stableName,
  List<AnimalDto> animals,
  StableRepository repository,
  VoidCallback? onStablesUpdated,
) async {
  // Verificar que el contexto siga siendo válido antes de mostrar el diálogo
  if (!context.mounted) return {'deleted': false, 'newStable': null};
  
  // Función para crear y mostrar el diálogo de selección dinámico
  return await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _MoveToStableDialog(
        stableId: stableId,
        stableName: stableName,
        animals: animals,
        repository: repository,
        onStablesUpdated: onStablesUpdated,
      );
    },
  ) ?? {'deleted': false, 'newStable': null};
}

class _MoveToStableDialog extends StatefulWidget {
  final int stableId;
  final String stableName;
  final List<AnimalDto> animals;
  final StableRepository repository;
  final VoidCallback? onStablesUpdated;

  const _MoveToStableDialog({
    required this.stableId,
    required this.stableName,
    required this.animals,
    required this.repository,
    this.onStablesUpdated,
  });

  @override
  State<_MoveToStableDialog> createState() => _MoveToStableDialogState();
}

class _MoveToStableDialogState extends State<_MoveToStableDialog> {
  static const primary = Color(0xFF002D26);
  List<StableDto>? _stables;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStables();
  }

  Future<void> _loadStables() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stables = await widget.repository.getStables();
      if (mounted) {
        setState(() {
          _stables = stables;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createNewStable() async {
    if (!mounted) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateStablePage(repository: widget.repository),
      ),
    );

    if (result != null && result is StableDto && mounted) {
      // Actualizar la lista de establos inmediatamente
      setState(() {
        _stables?.add(result);
      });
      
      // Mostrar mensaje de éxito y auto-seleccionar el nuevo establo
      _showNewStableCreatedDialog(result);
    }
  }

  Future<void> _showNewStableCreatedDialog(StableDto newStable) async {
    final shouldMoveAnimals = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con icono de éxito
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Título
                const Text(
                  'Establo Creado',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF002D26),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Contenido
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF6F1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF002D26).withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.home_work,
                            color: Color(0xFF002D26),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nuevo establo "${newStable.name}" creado',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF002D26),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '¿Deseas mover los animales al nuevo establo ahora?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'No, Gracias',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF002D26),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Sí, Mover',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
      ),
    );

    if (shouldMoveAnimals == true && mounted) {
      // Auto-seleccionar el nuevo establo y mover
      await _moveToStable(newStable);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: const Text(
        'Seleccionar Destino',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: Column(
          children: [
            Text(
              '¿Dónde deseas mover los ${widget.animals.length} ${widget.animals.length == 1 ? 'animal' : 'animales'}?',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            
            // Opción: Crear nuevo establo
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: _createNewStable,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Crear Nuevo Establo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            const Divider(),
            
            // Lista de establos existentes
            Expanded(
              child: _buildStablesList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop({'deleted': false, 'newStable': null}),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildStablesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text('Error al cargar establos: $_error'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadStables,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final availableStables = _stables?.where((s) => s.id != widget.stableId).toList() ?? [];

    if (availableStables.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No hay otros establos disponibles.\nCrea uno nuevo usando el botón de arriba.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'O selecciona un establo existente:',
          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: availableStables.length,
            itemBuilder: (context, index) {
              final stable = availableStables[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: const Color(0xFFFDF6F1),
                  title: Text(stable.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('Límite: ${stable.limit} animales', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: primary),
                  onTap: () => _moveToStable(stable),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _moveToStable(StableDto targetStable) async {
    final deleted = await _moveAnimalsToStable(
      context, 
      widget.stableId, 
      targetStable.id, 
      widget.animals, 
      widget.repository,
      widget.onStablesUpdated,
    );
    
    if (mounted) {
      Navigator.of(context).pop({
        'deleted': deleted, 
        'newStable': null,
        'movedAnimals': deleted,
        'targetStableId': targetStable.id,
      });
    }
  }
}

Future<bool> _moveAnimalsToStable(
  BuildContext context,
  int fromStableId,
  int toStableId,
  List<AnimalDto> animals,
  StableRepository repository,
  VoidCallback? onStablesUpdated,
) async {
  // Verificar que el contexto siga siendo válido
  if (!context.mounted) return false;
  
  // Mostrar confirmación final
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con icono
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF002D26).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.swap_horiz,
                  color: Color(0xFF002D26),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              
              // Título
              const Text(
                'Confirmar Movimiento',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002D26),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Contenido
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF6F1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF002D26).withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF002D26).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Color(0xFF002D26),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${animals.length} ${animals.length == 1 ? 'animal será movido' : 'animales serán movidos'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF002D26),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'El establo será eliminado después',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF002D26),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF002D26).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF002D26).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFF002D26),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta acción no se puede deshacer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF002D26),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF002D26),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    ),
  );
  
  if (confirmed == true && context.mounted) {
    // Mostrar loading moderno
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icono animado
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF002D26).withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF002D26).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Icon(
                              Icons.swap_horizontal_circle,
                              color: Color(0xFF002D26),
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Título
                      const Text(
                        'Procesando...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002D26),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Descripción con animación
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1500),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, opacity, child) {
                          return Opacity(
                            opacity: opacity,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.pets,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Moviendo animales...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Eliminando establo...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Advertencia
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF002D26).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF002D26),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'No cerrar la aplicación',
                              style: TextStyle(
                                color: Color(0xFF002D26),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);

    try {
      // Mover todos los animales al nuevo establo
      final animalsService = AnimalsService();
      int movedAnimals = 0;
      
      for (final animal in animals) {
        try {
          await animalsService.updateBovine(animal.id, {
            if (animal.name != null) 'name': animal.name,
            'breed': animal.breed,
          });
          movedAnimals++;
          debugPrint('✅ Animal ${animal.id} moved to stable $toStableId');
        } catch (e) {
          debugPrint('❌ Error moving animal ${animal.id}: $e');
        }
      }
      
      debugPrint('✅ Moved $movedAnimals/${animals.length} animals from stable $fromStableId to $toStableId');
      
      // Solo eliminar el establo si se movieron todos los animales exitosamente
      bool stableDeleted = false;
      if (movedAnimals == animals.length) {
        await repository.deleteStable(fromStableId);
        stableDeleted = true;
        debugPrint('✅ Stable $fromStableId deleted after moving all animals');
        
        // Actualizar la UI de establos en segundo plano ANTES de remover el overlay
        if (onStablesUpdated != null) {
          onStablesUpdated();
          debugPrint('✅ UI de establos actualizada en segundo plano');
        }
      } else {
        debugPrint('⚠️ Not all animals were moved, keeping stable $fromStableId');
      }
      
      // Remover loading
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
      
      if (context.mounted) {
        // Las notificaciones visuales ya se muestran en el overlay de procesamiento
        // No necesitamos SnackBars adicionales aquí
        debugPrint('✅ Proceso completado: $movedAnimals animales movidos de ${animals.length}');
      }
      
      return stableDeleted;
    } catch (e) {
      debugPrint('❌ Error moving animals or deleting stable: $e');
      
      // Remover loading en caso de error
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
      
      if (context.mounted) {
        // Los errores se manejan silenciosamente, el overlay ya se removió
        // No necesitamos notificaciones adicionales aquí
        debugPrint('❌ Error durante el proceso de mover animales');
      }
      
      return false;
    }
  }
  
  return false;
}

Future<bool> _deleteStable(
  BuildContext context,
  int stableId,
  StableRepository repository,
) async {
  // Crear un overlay para mostrar loading
  final overlay = Overlay.of(context);
  OverlayEntry? overlayEntry;
  
  overlayEntry = OverlayEntry(
    builder: (context) => Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono animado de eliminación
              TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 2),
                tween: Tween(begin: 0.0, end: 6.28),
                builder: (context, rotation, child) {
                  return Transform.rotate(
                    angle: rotation * 0.3,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.red.withValues(alpha: 0.2),
                            Colors.red.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.delete_sweep,
                          color: Colors.red,
                          size: 32,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Eliminando Establo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002D26),
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 12),
              
              const Text(
                'Procesando solicitud...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Barra de progreso animada
              Container(
                width: 200,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF6F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 2),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, progress, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  
  overlay.insert(overlayEntry);

  try {
    await repository.deleteStable(stableId);
    debugPrint('✅ Stable $stableId deleted');
    
    // Asegurar que el overlay se elimine
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Establo eliminado exitosamente'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
    
    return true;
  } catch (e) {
    debugPrint('❌ Error deleting stable $stableId: $e');
    
    // Asegurar que el overlay se elimine en caso de error
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar establo: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
    
    return false;
  }
}
