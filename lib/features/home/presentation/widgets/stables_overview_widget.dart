import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vacapp/features/stables/data/repositories/stable_repository.dart';
import 'package:vacapp/features/stables/data/datasources/stables_service.dart';
import 'package:vacapp/features/stables/data/models/stable_dto.dart';
import 'package:vacapp/features/animals/data/dataasources/animals_service.dart';
import 'package:vacapp/core/services/connectivity_service.dart';

class StablesOverviewWidget extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const StablesOverviewWidget({super.key, this.onNavigateToTab});

  @override
  State<StablesOverviewWidget> createState() => _StablesOverviewWidgetState();
}

class _StablesOverviewWidgetState extends State<StablesOverviewWidget> {
  late StableRepository _repository;
  late AnimalsService _animalsService;
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isLoading = true;
  String? _error;

  // Datos agrupados
  int _totalStables = 0;
  int _totalCapacity = 0;
  int _availableSpace = 0;
  List<StableDto> _recentStables = [];
  Map<int, int> _bovinoCount = {};

  // Paleta de colores moderna
  static const Color primary = Color(0xFF00695C);
  static const Color accent = Color(0xFF26A69A);
  static const Color cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _repository = StableRepository(StablesService());
    _animalsService = AnimalsService();
    _loadStables();
  }

  Future<void> _loadStables() async {
    try {
      // Verificar conectividad primero
      if (!_connectivityService.isConnected) {
        if (mounted) {
          setState(() {
            _error = 'No hay conexión de red';
            _isLoading = false;
          });
        }
        return;
      }

      final stables = await _repository.getStables();
      await _loadBovinoCounts(stables);
      
      if (mounted) {
        // Ordenar por reciente (asumimos que ID más grande = más reciente)
        final sortedStables = List<StableDto>.from(stables)
          ..sort((a, b) => b.id.compareTo(a.id));
        
        int totalCapacity = 0;
        int totalOccupied = 0;
        
        for (final stable in stables) {
          totalCapacity += stable.limit;
          totalOccupied += _bovinoCount[stable.id] ?? 0;
        }
        
        setState(() {
          _totalStables = stables.length;
          _totalCapacity = totalCapacity;
          _availableSpace = totalCapacity - totalOccupied;
          _recentStables = sortedStables.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Verificar si es un error de conectividad
          if (e.toString().contains('network') || 
              e.toString().contains('connection') ||
              e.toString().contains('internet') ||
              !_connectivityService.isConnected) {
            _error = 'No hay conexión de red';
          } else {
            _error = 'Error al cargar establos';
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBovinoCounts(List<StableDto> stables) async {
    Map<int, int> counts = {};

    for (final stable in stables) {
      try {
        final animals = await _animalsService.fetchAnimalByStableId(stable.id);
        counts[stable.id] = animals.length;
      } catch (e) {
        debugPrint('Error loading animals for stable ${stable.id}');
        counts[stable.id] = 0;
      }
    }

    if (mounted) {
      setState(() {
        _bovinoCount = counts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.home_work_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Establos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      Text(
                        'Gestión de espacios',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (_isLoading)
              _buildLoadingState()
            else if (_error != null && !_error!.contains('network') && !_error!.contains('connection'))
              _buildErrorState()
            else if (_error != null)
              _buildOfflineState()
            else
              _buildStablesContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(
          color: primary,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No hay WiFi',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStablesContent() {
    return Column(
      children: [
        // Estadísticas principales
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                _totalStables.toString(),
                Icons.home_work_rounded,
                primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Espacio',
                _totalCapacity.toString(),
                Icons.pets_rounded,
                accent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Vacío',
                _availableSpace.toString(),
                Icons.check_circle_outline,
                Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Establos recientes
        if (_recentStables.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Establos recientes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Cambiar al tab de establos (índice 3) en lugar de navegar
                  if (widget.onNavigateToTab != null) {
                    // Agregar haptic feedback para mejor UX
                    HapticFeedback.selectionClick();
                    widget.onNavigateToTab!(3);
                  }
                },
                child: Text(
                  'Ver todos',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_recentStables.map((stable) => _buildStableItem(stable)).toList()),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'No hay datos de establos',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStableItem(StableDto stable) {
    // Obtener datos reales de ocupación
    final ocupado = _bovinoCount[stable.id] ?? 0;
    final porcentaje = stable.limit > 0 ? ((ocupado / stable.limit) * 100).round() : 0;
    final available = stable.limit - ocupado;
    final isFull = porcentaje >= 100;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFull ? Colors.red.shade300 : Colors.grey.shade200,
          width: isFull ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isFull ? Colors.red.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con información del establo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.home_rounded,
                  color: primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stable.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Establo ID: ${stable.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge de ocupación
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getOcupacionColor(porcentaje).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$porcentaje% ocupado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getOcupacionColor(porcentaje),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Información de capacidad
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
                children: [
                  Text(
                    '$ocupado / ${stable.limit}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isFull ? Colors.red.shade700 : Colors.black87,
                    ),
                  ),
                  if (isFull) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.warning,
                      color: Colors.red.shade600,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: porcentaje / 100,
              backgroundColor: Colors.grey.shade200,
              color: _getOcupacionColor(porcentaje),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          
          // Información adicional
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Capacidad: ${stable.limit}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'Disponible: $available',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          // Mensaje de estado si está lleno
          if (isFull) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error,
                    size: 14,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '¡Establo lleno!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Color _getOcupacionColor(int porcentaje) {
    if (porcentaje < 60) return Colors.green;
    if (porcentaje < 85) return Colors.orange;
    return Colors.red;
  }
}
