import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vacapp/features/stables/data/models/stable_dto.dart';
import 'package:vacapp/features/stables/data/datasources/stables_service.dart';
import 'package:vacapp/features/animals/data/dataasources/animals_service.dart';
import 'package:vacapp/core/themes/color_palette.dart';

class StableDropdown extends StatefulWidget {
  final int? selectedStableId;
  final ValueChanged<int?> onChanged;

  const StableDropdown({
    super.key,
    required this.selectedStableId,
    required this.onChanged,
  });

  @override
  State<StableDropdown> createState() => _StableDropdownState();
}

class _StableDropdownState extends State<StableDropdown> {
  List<_StableWithSpace> _availableStables = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableStables();
  }

  Future<void> _loadAvailableStables() async {
    try {
      final stables = await StablesService().fetchStables();
      final animalsService = AnimalsService();
      List<_StableWithSpace> available = [];

      for (final stable in stables) {
        // Verificar si el widget sigue montado antes de continuar
        if (!mounted) return;
        
        final animals = await animalsService.fetchAnimalByStableId(stable.id);
        final espacio = stable.limit - animals.length;
        if (espacio > 0) {
          available.add(_StableWithSpace(stable: stable, espacio: espacio, ocupados: animals.length));
        }
      }

      // Verificar si el widget sigue montado antes de llamar setState
      if (mounted) {
        setState(() {
          _availableStables = [
            _StableWithSpace(
              stable: StableDto(id: -1, name: 'Seleccionar establo', limit: 0),
              espacio: 0,
              ocupados: 0,
            ),
            ...available
          ];
          _loading = false;
        });
      }
    } catch (e) {
      // Manejar errores y verificar si el widget sigue montado
      if (mounted) {
        setState(() {
          _loading = false;
          _availableStables = [
            _StableWithSpace(
              stable: StableDto(id: -1, name: 'Seleccionar establo', limit: 0),
              espacio: 0,
              ocupados: 0,
            ),
          ];
        });
      }
      debugPrint('Error cargando establos disponibles: $e');
    }
  }

  void _showStablePicker(BuildContext context) {
    // Verificar que hay establos disponibles
    if (_availableStables.isEmpty) {
      return;
    }

    final initialIndex = widget.selectedStableId != null
        ? _availableStables.indexWhere((s) => s.stable.id == widget.selectedStableId)
        : 0;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext modalContext) => Container(
        height: 350,
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
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorPalette.primaryColor,
                    ColorPalette.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_work_rounded, 
                      color: Colors.white, 
                      size: 20
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seleccionar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Text(
                          'Elige establo',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(modalContext).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de establos
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: initialIndex >= 0 ? initialIndex : 0,
                ),
                itemExtent: 55,
                onSelectedItemChanged: (index) {
                  if (index < _availableStables.length) {
                    final selected = _availableStables[index];
                    widget.onChanged(selected.stable.id == -1 ? null : selected.stable.id);
                  }
                },
                children: _availableStables
                    .map((s) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: s.stable.id == -1 
                                ? Colors.grey.shade50 
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: s.stable.id == -1 
                                  ? Colors.grey.shade300 
                                  : ColorPalette.primaryColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                            boxShadow: s.stable.id == -1 ? [] : [
                              BoxShadow(
                                color: ColorPalette.primaryColor.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Icono del establo
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: s.stable.id == -1 
                                      ? Colors.grey.shade200 
                                      : ColorPalette.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  s.stable.id == -1 
                                      ? Icons.help_outline_rounded 
                                      : Icons.home_work_rounded,
                                  color: s.stable.id == -1 
                                      ? Colors.grey.shade500 
                                      : ColorPalette.primaryColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Información del establo en una línea
                              Expanded(
                                child: Row(
                                  children: [
                                    // Nombre del establo
                                    Expanded(
                                      child: Text(
                                        s.stable.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: s.stable.id == -1 
                                              ? Colors.grey.shade600 
                                              : Colors.black87,
                                          fontWeight: s.stable.id == -1 
                                              ? FontWeight.w400 
                                              : FontWeight.w600,
                                          decoration: TextDecoration.none,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    
                                    // Badges a la derecha
                                    if (s.stable.id != -1) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${s.espacio} disp.',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green.shade700,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${s.ocupados} ocup.',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade600,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              // Indicador de capacidad
                              if (s.stable.id != -1)
                                Container(
                                  width: 4,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.bottomCenter,
                                    heightFactor: s.ocupados / (s.ocupados + s.espacio),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            ColorPalette.primaryColor,
                                            ColorPalette.primaryColor.withValues(alpha: 0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            
            // Footer con botón de cerrar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade300,
                            Colors.grey.shade200,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(modalContext).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  color: Colors.black54,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Cerrar',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.none,
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Limpiar recursos si es necesario
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorPalette.primaryColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorPalette.primaryColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 1),
              tween: Tween(begin: 0.8, end: 1.2),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorPalette.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: ColorPalette.primaryColor,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Cargando establos...',
              style: TextStyle(
                color: ColorPalette.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 2),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 100 * value,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ColorPalette.primaryColor,
                              ColorPalette.primaryColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
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
    }

    // Buscar el establo seleccionado de manera más segura
    _StableWithSpace? selectedStable;
    try {
      selectedStable = _availableStables.firstWhere(
        (s) => s.stable.id == widget.selectedStableId,
      );
    } catch (e) {
      // Si no se encuentra el establo seleccionado, usar el primero (placeholder)
      selectedStable = _availableStables.isNotEmpty ? _availableStables.first : null;
    }

    // Si no hay establos disponibles, mostrar mensaje
    if (_availableStables.isEmpty || selectedStable == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.shade50,
              Colors.red.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sin establos',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Todos llenos',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 12,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showStablePicker(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedStable.stable.id == -1 
                ? Colors.grey.shade300 
                : ColorPalette.primaryColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorPalette.primaryColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showStablePicker(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // Icono del establo
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: selectedStable.stable.id == -1
                            ? [Colors.grey.shade200, Colors.grey.shade100]
                            : [
                                ColorPalette.primaryColor.withValues(alpha: 0.2),
                                ColorPalette.primaryColor.withValues(alpha: 0.1),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.home_work_rounded,
                      color: selectedStable.stable.id == -1 
                          ? Colors.grey.shade500 
                          : ColorPalette.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Información del establo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedStable.stable.id == -1
                              ? 'Seleccionar establo'
                              : selectedStable.stable.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: selectedStable.stable.id == -1 
                                ? Colors.grey.shade600 
                                : Colors.black87,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        if (selectedStable.stable.id != -1) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorPalette.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${selectedStable.espacio} disp.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: ColorPalette.primaryColor,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${selectedStable.ocupados} ocup.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Icono de dropdown
                  Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: selectedStable.stable.id == -1 
                          ? Colors.grey.shade500 
                          : ColorPalette.primaryColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StableWithSpace {
  final StableDto stable;
  final int espacio;
  final int ocupados;
  _StableWithSpace({required this.stable, required this.espacio, required this.ocupados});
}