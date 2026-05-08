import 'package:flutter/material.dart';
import 'package:vacapp/features/stables/data/models/stable_dto.dart';
import 'package:vacapp/features/stables/data/datasources/stables_service.dart';
import 'package:vacapp/features/animals/data/dataasources/animals_service.dart';

class CampaignStableDropdown extends StatefulWidget {
  final int? selectedStableId;
  final Function(int?) onChanged;

  const CampaignStableDropdown({
    super.key,
    required this.selectedStableId,
    required this.onChanged,
  });

  @override
  State<CampaignStableDropdown> createState() => _CampaignStableDropdownState();
}

class _CampaignStableDropdownState extends State<CampaignStableDropdown> {
  List<_StableInfo> _stables = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStables();
  }

  Future<void> _loadStables() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final stables = await StablesService().fetchStables();
      final animalsService = AnimalsService();
      List<_StableInfo> stableInfoList = [];

      for (final stable in stables) {
        if (!mounted) return;
        
        final animals = await animalsService.fetchAnimalByStableId(stable.id);
        stableInfoList.add(_StableInfo(
          stable: stable,
          currentAnimals: animals.length,
        ));
      }

      if (mounted) {
        setState(() {
          _stables = stableInfoList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar establos: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildDropdown(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.home_work,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Cargando establos...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Error al cargar establos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _error ?? 'Error desconocido',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadStables,
            icon: const Icon(
              Icons.refresh,
              color: Colors.red,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    if (_stables.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.home_work,
                color: Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No hay establos disponibles',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      // ignore: deprecated_member_use
      value: widget.selectedStableId,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: InputBorder.none,
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.home_work,
            color: Colors.orange,
            size: 20,
          ),
        ),
        hintText: 'Selecciona un establo',
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
      ),
      items: _stables.map((stableInfo) {
        return DropdownMenuItem<int>(
          value: stableInfo.stable.id,
          child: _buildStableItem(stableInfo, false),
        );
      }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return _stables.map((stableInfo) {
          return _buildStableItem(stableInfo, true);
        }).toList();
      },
      onChanged: widget.onChanged,
      dropdownColor: Colors.white,
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: Colors.grey.shade400,
      ),
      isExpanded: true,
    );
  }

  Widget _buildStableItem(_StableInfo stableInfo, bool isSelected) {
    final stable = stableInfo.stable;
    final currentAnimals = stableInfo.currentAnimals;
    
    // Calcular porcentaje de ocupación
    double occupancyPercentage = stable.limit > 0 
        ? (currentAnimals / stable.limit) * 100 
        : 0;
    
    Color statusColor = _getStatusColor(occupancyPercentage);
    String statusText = _getStatusText(occupancyPercentage);

    if (isSelected) {
      // Vista para cuando está seleccionado - solo el nombre
      return Row(
        children: [
          // Icono del establo
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.home_work,
              color: statusColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          // Solo el nombre del establo
          Expanded(
            child: Text(
              stable.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      // Vista para el dropdown - más compacta
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Icono del establo
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.home_work,
                color: statusColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            // Información del establo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del establo
                  Text(
                    stable.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Capacidad y ocupación
                  Row(
                    children: [
                      Text(
                        '$currentAnimals/${stable.limit} animales',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Indicador visual de capacidad
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.bottomCenter,
                heightFactor: occupancyPercentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getStatusColor(double occupancyPercentage) {
    if (occupancyPercentage >= 90) {
      return Colors.red; // Lleno - necesita atención
    } else if (occupancyPercentage >= 60) {
      return Colors.orange; // Medio - capacidad media
    } else if (occupancyPercentage >= 25) {
      return Colors.blue; // Casi vacío - poca ocupación
    } else {
      return Colors.green; // Vacío - mucho espacio
    }
  }

  String _getStatusText(double occupancyPercentage) {
    if (occupancyPercentage >= 90) {
      return 'Lleno';
    } else if (occupancyPercentage >= 60) {
      return 'Medio';
    } else if (occupancyPercentage >= 25) {
      return 'Casi vacío';
    } else {
      return 'Vacío';
    }
  }
}

class _StableInfo {
  final StableDto stable;
  final int currentAnimals;

  _StableInfo({
    required this.stable,
    required this.currentAnimals,
  });
}
