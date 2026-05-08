import 'package:flutter/material.dart';
import 'package:vacapp/features/stables/data/models/stable_dto.dart';
import 'package:vacapp/features/stables/data/repositories/stable_repository.dart';
import 'package:vacapp/features/stables/data/datasources/stables_service.dart';
import 'package:vacapp/features/stables/presentation/pages/create_stable_page.dart';
import 'package:vacapp/features/stables/presentation/pages/edit_stable_page.dart';
import 'package:vacapp/features/stables/presentation/pages/delete_stable.dart';
import 'package:vacapp/features/animals/data/dataasources/animals_service.dart';
import 'package:vacapp/core/widgets/island_notification.dart';

class StablePage extends StatefulWidget {
  const StablePage({super.key});

  @override
  State<StablePage> createState() => _StablePageState();
}

class _StablePageState extends State<StablePage> with SingleTickerProviderStateMixin {
  late final StableRepository _repository;
  late final AnimalsService _animalsService;
  List<StableDto> _stables = [];
  bool _isLoading = true;
  Map<int, double> _animatedBovinoPercent = {};
  Map<int, int> _bovinoCount = {};

  @override
  void initState() {
    super.initState();
    _repository = StableRepository(StablesService());
    _animalsService = AnimalsService();
    _loadStables();
  }

  Future<void> _loadStables() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final stables = await _repository.getStables();
      await _loadBovinoCounts(stables);

      if (mounted) {
        setState(() {
          _stables = stables;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading stables');
      if (mounted) {
        setState(() {
          _stables = [];
          _isLoading = false;
          _bovinoCount = {};
        });
      }
    }
  }

  Future<void> _loadBovinoCounts(List<StableDto> stables) async {
    Map<int, int> counts = {};
    Map<int, double> percent = {};

    for (final stable in stables) {
      try {
        final animals = await _animalsService.fetchAnimalByStableId(stable.id);
        final count = animals.length;
        counts[stable.id] = count;
        percent[stable.id] = stable.limit > 0 ? count / stable.limit : 0.0;
      } catch (e) {
        debugPrint('Error loading animals for stable ${stable.id}');
        counts[stable.id] = 0;
        percent[stable.id] = 0.0;
      }
    }

    if (mounted) {
      setState(() {
        _bovinoCount = counts;
        _animatedBovinoPercent = percent;
      });
    }
  }

  Future<void> _refreshStables() async {
    await _loadStables();
  }

  // Actualizar establos en segundo plano sin mostrar indicadores de carga
  Future<void> _refreshStablesInBackground() async {
    try {
      final stables = await _repository.getStables();
      await _loadBovinoCounts(stables);

      if (mounted) {
        setState(() {
          _stables = stables;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading stables in background: $e');
      // En caso de error, usar el método de refresh regular
      await _refreshStables();
    }
  }

  void _addStableLocally(StableDto stable) {
    if (mounted) {
      setState(() {
        _stables.add(stable);
        _bovinoCount[stable.id] = 0;
        _animatedBovinoPercent[stable.id] = 0.0;
      });
      IslandNotification.showSuccess(context, message: 'Establo "${stable.name}" creado exitosamente');
    }
  }

  void _updateStableLocally(StableDto updatedStable) {
    if (mounted) {
      setState(() {
        final index = _stables.indexWhere((s) => s.id == updatedStable.id);
        if (index != -1) {
          _stables[index] = updatedStable;
          // Actualizar también los datos de capacidad si es necesario
          final currentCount = _bovinoCount[updatedStable.id] ?? 0;
          _animatedBovinoPercent[updatedStable.id] = 
              updatedStable.limit > 0 ? currentCount / updatedStable.limit : 0.0;
        }
      });
      IslandNotification.showSuccess(context, message: 'Establo "${updatedStable.name}" actualizado');
    }
  }

  void _removeStableLocally(int stableId, String stableName) {
    if (mounted) {
      setState(() {
        _stables.removeWhere((s) => s.id == stableId);
        _bovinoCount.remove(stableId);
        _animatedBovinoPercent.remove(stableId);
      });
      IslandNotification.showSuccess(context, message: 'Establo "$stableName" eliminado');
    }
  }

  Future<void> _goToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateStablePage(repository: _repository),
      ),
    );
    
    if (result != null && result is StableDto) {
      _addStableLocally(result);
      
      // Opcional: refrescar para asegurar sincronización
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _updateStableAnimalCount(result.id);
        }
      });
    }
  }

  Future<void> _goToEdit(StableDto stable) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditStablePage(repository: _repository, stable: stable),
      ),
    );
    if (result == true) {
      try {
        final stables = await _repository.getStables();
        final updatedStable = stables.firstWhere((s) => s.id == stable.id);
        _updateStableLocally(updatedStable);
      } catch (e) {
        await _refreshStables();
      }
    }
  }

  Future<void> _goToDelete(StableDto stable) async {
    final result = await showDeleteStableDialog(
      context: context,
      stableId: stable.id,
      stableName: stable.name,
      repository: _repository,
      onStablesUpdated: _refreshStablesInBackground, // Callback para actualizar en segundo plano
    );
    
    // Manejar la respuesta del diálogo de manera más robusta
    if (result['deleted'] == true) {
      _removeStableLocally(stable.id, stable.name);
      
      // Actualizar la UI después de eliminar
      await _refreshStables();
    }
    
    // Si se creó un nuevo establo, agregarlo a la lista local y refrescar
    if (result['newStable'] != null) {
      final newStable = result['newStable'] as StableDto;
      _addStableLocally(newStable);
      
      // Actualizar la UI después de crear nuevo establo
      await _refreshStables();
    }
    
    // Si se movieron animales, actualizar las barras de capacidad de manera inteligente
    if (result['movedAnimals'] == true) {
      // Actualizar el establo destino si se especificó
      if (result['targetStableId'] != null) {
        final targetStableId = result['targetStableId'] as int;
        
        // Actualizar específicamente los establos involucrados
        await _updateStableAnimalCount(targetStableId);
        
        // También actualizar el establo original si no fue eliminado
        if (result['deleted'] != true) {
          await _updateStableAnimalCount(stable.id);
        }
        
        // Mostrar notificación de éxito
        if (mounted) {
          IslandNotification.showSuccess(
            context, 
            message: 'Animales movidos exitosamente'
          );
        }
      } else {
        // Si no se especificó establo destino, actualizar todos por seguridad
        await _updateAllStableAnimalCounts();
        
        // Mostrar notificación genérica
        if (mounted) {
          IslandNotification.showSuccess(
            context, 
            message: 'Operación completada exitosamente'
          );
        }
      }
    }
  }

  // Método para ver los animales de un establo específico
  Future<void> _goToViewAnimals(StableDto stable) async {
    await _showStableAnimalsModal(stable);
  }

  // Método para actualizar el conteo de animales en todos los establos
  Future<void> _updateAllStableAnimalCounts() async {
    final futures = _stables.map((stable) => _updateStableAnimalCount(stable.id));
    await Future.wait(futures);
  }

  // Método para actualizar el conteo de animales en un establo específico
  Future<void> _updateStableAnimalCount(int stableId) async {
    try {
      final animals = await _animalsService.fetchAnimalByStableId(stableId);
      final count = animals.length;
      
      // Buscar el establo en la lista actual
      final stableIndex = _stables.indexWhere((s) => s.id == stableId);
      if (stableIndex == -1) {
        debugPrint('⚠️ Establo con ID $stableId no encontrado en la lista local');
        return;
      }
      
      final stable = _stables[stableIndex];
      final percentage = stable.limit > 0 ? count / stable.limit : 0.0;
      
      if (mounted) {
        setState(() {
          _bovinoCount[stableId] = count;
          _animatedBovinoPercent[stableId] = percentage;
        });
        
        debugPrint('✅ Establo ${stable.name} actualizado: $count/$stable.limit animales (${(percentage * 100).toStringAsFixed(1)}%)');
      }
    } catch (e) {
      debugPrint('❌ Error updating animal count for stable $stableId: $e');
      
      // En caso de error, intentar refrescar toda la página
      if (mounted) {
        await _refreshStables();
      }
    }
  }

  // Modal para mostrar los animales de un establo específico
  Future<void> _showStableAnimalsModal(StableDto stable) async {
    const primary = Color(0xFF00695C);
    const lightGreen = Color(0xFFE8F5E8);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header moderno con gradiente
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primary, primary.withValues(alpha: 0.8)],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        // Indicador de arrastrar
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.pets,
                                size: 32,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stable.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_bovinoCount[stable.id] ?? 0} / ${stable.limit} animales',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista de animales
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: _animalsService.fetchAnimalByStableId(stable.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error al cargar animales',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        final animals = snapshot.data ?? [];
                        
                        if (animals.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: lightGreen.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    '🐄',
                                    style: TextStyle(fontSize: 48),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay animales en este establo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'El establo está disponible para nuevos animales',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.85,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final animal = animals[index];
                                    
                                    // Función para mostrar el género en español
                                    String getGenderDisplay(String? gender) {
                                      if (gender == null || gender.isEmpty) return 'No especificado';
                                      return gender.toLowerCase() == 'male' ? 'Macho' : 'Hembra';
                                    }
                                    
                                    // Función para formatear la fecha
                                    String formatBirthDate(String? birthDate) {
                                      if (birthDate == null || birthDate.isEmpty) return 'No especificado';
                                      try {
                                        final date = DateTime.parse(birthDate);
                                        final months = [
                                          'ene', 'feb', 'mar', 'abr', 'may', 'jun',
                                          'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
                                        ];
                                        return '${date.day} ${months[date.month - 1]} ${date.year}';
                                      } catch (e) {
                                        return birthDate;
                                      }
                                    }
                                    
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white,
                                            const Color(0xFFFAFAFA),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: primary.withValues(alpha: 0.15),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primary.withValues(alpha: 0.12),
                                            blurRadius: 15,
                                            offset: const Offset(0, 4),
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Header con Código y indicador
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        primary.withValues(alpha: 0.15),
                                                        primary.withValues(alpha: 0.08),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: primary.withValues(alpha: 0.2),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.qr_code_2,
                                                        size: 12,
                                                        color: primary,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '# ${animal.id}',
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: primary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [primary, primary.withValues(alpha: 0.7)],
                                                    ),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: primary.withValues(alpha: 0.3),
                                                        blurRadius: 3,
                                                        offset: const Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            
                                            // Nombre del animal destacado
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: lightGreen.withValues(alpha: 0.3),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: primary.withValues(alpha: 0.1),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                animal.name ?? 'Sin nombre',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: primary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            // Información compacta sin overflow
                                            Column(
                                              children: [
                                                // Raza
                                                if (animal.breed != null && animal.breed!.isNotEmpty)
                                                  _buildCompactInfoRow(
                                                    'Raza',
                                                    animal.breed!,
                                                    Icons.category_outlined,
                                                    primary,
                                                  ),
                                                
                                                // Género
                                                if (animal.gender != null && animal.gender!.isNotEmpty)
                                                  _buildCompactInfoRow(
                                                    'Género',
                                                    getGenderDisplay(animal.gender),
                                                    animal.gender?.toLowerCase() == 'male' 
                                                        ? Icons.male_rounded 
                                                        : Icons.female_rounded,
                                                    primary,
                                                  ),
                                                
                                                // Ubicación
                                                if (animal.location != null && animal.location!.isNotEmpty)
                                                  _buildCompactInfoRow(
                                                    'Ubicación',
                                                    animal.location!,
                                                    Icons.location_on_outlined,
                                                    primary,
                                                  ),
                                              ],
                                            ),
                                            
                                            const Spacer(),
                                            
                                            // Footer con fecha de nacimiento mejorada
                                            if (animal.birthDate != null && animal.birthDate!.isNotEmpty) 
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.grey.shade50,
                                                      Colors.grey.shade100,
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.grey.shade200,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.cake_outlined,
                                                      size: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        formatBirthDate(animal.birthDate),
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.grey.shade700,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
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
                                  childCount: animals.length,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Animación de carga simplificada y centrada
  Widget _buildLoadingAnimation() {
    const primary = Color(0xFF00695C);
    const lightGreen = Color(0xFFE8F5E8);
    
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icono principal simple con pulso suave
            TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 2),
              tween: Tween(begin: 0.9, end: 1.1),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: const Icon(
                        Icons.home_work,
                        size: 48,
                        color: primary,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            
            // Texto centrado simple
            const Text(
              'Cargando establos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            Text(
              'Preparando información...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Barra de progreso visual y atractiva
            Container(
              width: 250,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 3),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Stack(
                    children: [
                      // Barra de progreso con gradiente
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 250 * value,
                        height: 6,
                        decoration: BoxDecoration(                        gradient: LinearGradient(
                          colors: [
                            primary,
                            primary.withValues(alpha: 0.7),
                            primary,
                          ],
                        ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      
                      // Efecto de brillo sutil
                      if (value > 0.1)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          left: (250 * value) - 30,
                          child: Container(
                            width: 30,
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.5),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Porcentaje centrado
            TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 3),
              tween: Tween(begin: 0.0, end: 100.0),
              builder: (context, percentage, child) {
                return Text(
                  '${percentage.toInt()}%',                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primary.withValues(alpha: 0.7),
                ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget para el estado vacío cuando no hay establos
  Widget _buildEmptyState() {
    const primary = Color(0xFF00695C);
    const lightGreen = Color(0xFFE8F5E8);
    
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icono principal con animación suave
              TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 3),
                tween: Tween(begin: 0.8, end: 1.0),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            lightGreen.withValues(alpha: 0.3),
                            lightGreen.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.home_work_outlined,
                          size: 64,
                          color: primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // Título principal
              const Text(
                'No hay establos creados',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Subtítulo descriptivo
              Text(
                'Comienza agregando tu primer establo\npara gestionar tus animales',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Botón de crear establo centrado y destacado
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 280),
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _goToCreate,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Crear mi primer establo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Texto adicional motivacional
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: lightGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Un establo te permitirá organizar y administrar tus animales de manera eficiente',
                        style: TextStyle(
                          fontSize: 13,
                          color: primary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00695C);
    const lightGreen = Color(0xFFE8F5E8);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8F9FA),
              lightGreen.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header estilo "isla" compacto
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Gestión de Establos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: primary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Administra tus espacios',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary, primary.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _goToCreate,
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido principal
              Expanded(
                child: _isLoading
                    ? _buildLoadingAnimation()
                    : _stables.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _refreshStables,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemCount: _stables.length,
                              itemBuilder: (context, index) {
                                final stable = _stables[index];
                                final bovinoCount = _bovinoCount[stable.id] ?? 0;
                                final percentage = _animatedBovinoPercent[stable.id] ?? 0.0;
                                final isAlmostFull = percentage >= 0.8; // 80% o más
                                final isFull = percentage >= 1.0; // 100% o más
                                final spacesLeft = stable.limit - bovinoCount;
                                final isNearlyFull = spacesLeft <= 2 && spacesLeft > 0; // 1 o 2 espacios restantes

                                return TweenAnimationBuilder<double>(
                                  duration: Duration(seconds: (isAlmostFull || isNearlyFull) ? 2 : 1),
                                  tween: Tween(begin: 0.98, end: (isAlmostFull || isNearlyFull) ? 1.02 : 1.0),
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: (isAlmostFull || isNearlyFull) ? 600 : 300),
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20), // Bordes más redondeados
                                          border: (isAlmostFull || isNearlyFull)
                                              ? Border.all(
                                                  color: isFull ? Colors.red.shade300 : Colors.orange.shade300,
                                                  width: 2,
                                                )
                                              : Border.all(
                                                  color: Colors.grey.shade200, // Borde sutil siempre presente
                                                  width: 1,
                                                ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isAlmostFull || isNearlyFull)
                                                  ? (isFull ? Colors.red.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2))
                                                  : Colors.black.withValues(alpha: 0.08), // Sombra más sutil
                                              blurRadius: (isAlmostFull || isNearlyFull) ? 15 : 12,
                                              offset: const Offset(0, 6), // Sombra ligeramente más pronunciada
                                              spreadRadius: 0,
                                            ),
                                            // Sombra adicional para más profundidad
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.04),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Header con icono, información del establo y botón de ver animales
                                            Row(
                                              children: [
                                                // Icono del establo
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    Icons.home_work_outlined,
                                                    size: 24,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                // Información del establo
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        stable.name,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Establo ID: ${stable.id}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey.shade600,
                                                        ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Botón Ver animales en la esquina superior derecha
                                  GestureDetector(
                                    onTap: () => _goToViewAnimals(stable),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green.shade800, // o tu color `primary`
                                          width: 1.4,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Ver animales',
                                            style: TextStyle(
                                              color: Colors.green.shade800,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Barra de capacidad con nuevo diseño
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Título + cantidad en una sola fila
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Capacidad',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$bovinoCount / ${stable.limit}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,                                            color: isFull 
                                                ? Colors.red.shade700
                                                : (isAlmostFull || isNearlyFull)
                                                    ? Colors.orange.shade700
                                                    : Colors.black87,
                                            ),
                                          ),
                                          // Indicador de estado crítico
                                          if (isAlmostFull || isNearlyFull)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: Icon(
                                                isFull ? Icons.warning : Icons.warning_amber,
                                                color: isFull ? Colors.red.shade600 : Colors.orange.shade600,
                                                size: 16,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Barra de progreso con animación especial para estados críticos
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Stack(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 800),
                                          width: MediaQuery.of(context).size.width * percentage.clamp(0.0, 1.0),
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isFull 
                                                ? Colors.red.shade600 
                                                : (isAlmostFull || isNearlyFull)
                                                    ? Colors.orange.shade600 
                                                    : primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        // Efecto pulsante para estados críticos
                                        if (isAlmostFull || isNearlyFull)
                                          TweenAnimationBuilder<double>(
                                            duration: const Duration(seconds: 1),
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            builder: (context, value, child) {
                                              return Positioned(
                                                left: 0,
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 500),
                                                  width: (MediaQuery.of(context).size.width * percentage.clamp(0.0, 1.0)) * 
                                                         (0.7 + 0.3 * value),
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        (isFull ? Colors.red : Colors.orange).withValues(alpha: 0.6),
                                                        (isFull ? Colors.red : Colors.orange).withValues(alpha: 0.0),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Mensaje de estado del establo con animación
                              if (isFull || isNearlyFull)
                                TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 1500),
                                  tween: Tween(begin: 0.95, end: 1.05),
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isFull 
                                              ? Colors.red.shade50
                                              : Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isFull 
                                                ? Colors.red.shade200
                                                : Colors.orange.shade200,
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isFull ? Colors.red : Colors.orange).withValues(alpha: 0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isFull ? Icons.error : Icons.warning_amber,
                                              size: 14,
                                              color: isFull 
                                                  ? Colors.red.shade600
                                                  : Colors.orange.shade600,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isFull 
                                                  ? '¡Establo lleno!'
                                                  : spacesLeft == 1 
                                                      ? '¡Solo queda 1 espacio!'
                                                      : '¡Solo quedan $spacesLeft espacios!',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isFull 
                                                    ? Colors.red.shade700
                                                    : Colors.orange.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 20),
                              
                              // Botones de acción - solo Editar y Eliminar
                              Row(
                                children: [
                                  // Botón Editar
                                  Expanded(
                                    child: Container(
                                      height: 44,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: primary, width: 1.5),
                                        borderRadius: BorderRadius.circular(12), // Bordes más redondeados
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: primary.withValues(alpha: 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(12), // Consistente con el contenedor
                                          onTap: () => _goToEdit(stable),
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.edit_outlined,
                                                  size: 16,
                                                  color: primary,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Editar',
                                                  style: TextStyle(
                                                    color: primary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Botón Eliminar
                                  Expanded(
                                    child: Container(
                                      height: 44,
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.red.shade400, width: 1.5),
                                        borderRadius: BorderRadius.circular(12), // Bordes más redondeados
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withValues(alpha: 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(12), // Consistente con el contenedor
                                          onTap: () => _goToDelete(stable),
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.delete_outline,
                                                  size: 16,
                                                  color: Colors.red.shade600,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Eliminar',
                                                  style: TextStyle(
                                                    color: Colors.red.shade600,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
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
                          },
                        );
                      },
                    ),
            
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Función helper para construir las filas de información del animal de forma compacta
  Widget _buildCompactInfoRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
