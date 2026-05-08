import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/animals/data/dataasources/animals_service.dart';
import 'package:vacapp/features/animals/data/models/animal_dto.dart';
import 'package:vacapp/features/animals/data/repositories/animal_repository.dart';
import 'package:vacapp/features/animals/presentation/pages/animal_details_page.dart';
import 'package:vacapp/features/animals/presentation/pages/create_animal_page.dart';

class AnimalPage extends StatefulWidget {
  const AnimalPage({super.key});

  @override
  State<AnimalPage> createState() => _AnimalPageState();
}

class _AnimalPageState extends State<AnimalPage> {
  static const _green = Color(0xFF00695C);
  static const _lightGreen = Color(0xFFE8F5E8);
  static const _accent = Color(0xFF4CAF50);

  late final AnimalRepository _repository;
  late Future<List<AnimalDto>> _futureAnimals;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<AnimalDto> _allAnimals = [];
  List<AnimalDto> _filteredAnimals = [];
  bool _showHeader = true;
  String _role = '';

  bool get _canCreate => _role != 'BuyerCustomer' && _role != 'CompanyWorker';

  @override
  void initState() {
    super.initState();
    _repository = AnimalRepository(AnimalsService());
    _futureAnimals = _repository.getAnimals();
    _searchCtrl.addListener(_onSearch);
    _scrollCtrl.addListener(_onScroll);
    TokenService.instance.getRole().then((v) {
      if (mounted) setState(() => _role = v);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredAnimals = q.isEmpty
          ? List.of(_allAnimals)
          : _allAnimals.where((a) {
              return a.displayName.toLowerCase().contains(q) ||
                  a.earTagCode.toLowerCase().contains(q) ||
                  a.breed.toLowerCase().contains(q) ||
                  a.sex.toLowerCase().contains(q);
            }).toList();
    });
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final show = _filteredAnimals.length <= 3 || _scrollCtrl.offset <= 120;
    if (show != _showHeader) setState(() => _showHeader = show);
  }

  Future<void> _refresh() async {
    final animals = await _repository.getAnimals();
    if (mounted) {
      setState(() {
        _allAnimals = animals;
        _filteredAnimals = List.of(animals);
      });
    }
  }

  Future<void> _goToCreate() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateAnimalPage(repository: _repository)),
    );
    if (result == true) await _refresh();
  }

  Future<void> _deactivate(AnimalDto animal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Desactivar Bovino'),
        content: Text('¿Seguro que deseas desactivar "${animal.displayName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desactivar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repository.deactivateAnimal(animal.id);
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Status helpers ──────────────────────────────────────────────────────────

  bool _isCritical(AnimalDto a) =>
      a.vitalSignsStatus?.toLowerCase() == 'crítico' ||
      a.vitalSignsStatus?.toLowerCase() == 'critico';

  bool _isInQuarantine(AnimalDto a) =>
      a.healthStatus.toLowerCase().contains('cuarentena');

  bool _isInVetCare(AnimalDto a) =>
      a.healthStatus.toLowerCase() == 'critico' ||
      a.healthStatus.toLowerCase() == 'crítico';

  bool _isSick(AnimalDto a) =>
      a.healthStatus.toLowerCase() == 'enfermo' ||
      a.healthStatus.toLowerCase() == 'enobservación' ||
      a.healthStatus.toLowerCase() == 'en observación';

  // ── Loading animation (original design) ────────────────────────────────────

  Widget _buildModernLoadingAnimation() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 2),
              tween: Tween(begin: 0.9, end: 1.1),
              builder: (_, scale, __) => Transform.scale(
                scale: scale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _lightGreen,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.pets_rounded, size: 40, color: _green),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Cargando animales',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: _green),
            ),
            const SizedBox(height: 8),
            Text('Preparando información...',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 32),
            // Barra de progreso con gradiente y efecto brillo
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
                builder: (_, value, __) => Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 250 * value,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_green, _green.withValues(alpha: 0.7), _green],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
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
                ),
              ),
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 3),
              tween: Tween(begin: 0.0, end: 100.0),
              builder: (_, pct, __) => Text(
                '${pct.toInt()}%',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _green.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Animal type label with status badges ────────────────────────────────────

  Widget _buildAnimalTypeLabel(AnimalDto animal) {
    final isQuarantine = _isInQuarantine(animal);
    final isVet = _isInVetCare(animal);
    final isSick = _isSick(animal);
    final isCritical = _isCritical(animal);

    String? badgeLabel;
    Color? badgeColor;
    IconData? badgeIcon;

    if (isQuarantine) {
      badgeLabel = 'Cuarentena';
      badgeColor = const Color(0xFFFF5722);
      badgeIcon = Icons.warning_rounded;
    } else if (isVet || isCritical) {
      badgeLabel = 'C. Veterinarios';
      badgeColor = const Color(0xFF2196F3);
      badgeIcon = Icons.medical_services_rounded;
    } else if (isSick) {
      badgeLabel = 'En Observación';
      badgeColor = Colors.orange;
      badgeIcon = Icons.visibility_rounded;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_lightGreen.withValues(alpha: 0.8), _lightGreen.withValues(alpha: 0.6)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _green.withValues(alpha: 0.2)),
          ),
          child: const Text('Bovino',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _green)),
        ),
        if (badgeLabel != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor!.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 12, color: badgeColor),
                const SizedBox(width: 4),
                Text(badgeLabel,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: badgeColor)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Status indicator (replaces vaccine indicator) ───────────────────────────

  Widget _buildStatusIndicator(AnimalDto animal) {
    final isCrit = _isCritical(animal);
    final isSick = animal.healthStatus.toLowerCase() != 'sano';

    if (isCrit) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(seconds: 3),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (_, animValue, __) {
          final pulseScale = 1.0 + (math.sin(animValue * math.pi * 4) * 0.03);
          return Transform.scale(
            scale: pulseScale,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFECB3).withValues(alpha: 0.95),
                    const Color(0xFFFFE0B2).withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFFF8F00).withValues(alpha: 0.7), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8F00).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TweenAnimationBuilder<int>(
                              duration: const Duration(milliseconds: 1500),
                              tween: IntTween(begin: 0, end: 18),
                              builder: (_, n, __) {
                                const text = 'SIGNOS CRÍTICOS';
                                return Text(
                                  text.substring(0, n.clamp(0, text.length)),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFE65100),
                                    letterSpacing: 0.6,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 3),
                            Text('Requiere atención inmediata',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(0xFFBF360C).withValues(alpha: 0.8),
                                    fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (_, s, __) => Transform.scale(
                          scale: 0.7 + s * 0.4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE65100).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.warning_amber_rounded,
                                size: 18, color: Color(0xFFE65100)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE65100).withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text('PRIORIDAD ALTA',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (isSick) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.health_and_safety_outlined,
                size: 14, color: Colors.orange.shade700),
            const SizedBox(width: 6),
            Text(animal.healthStatus,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: _lightGreen.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _green.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: _green),
          const SizedBox(width: 6),
          const Text('Sano',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _green)),
        ],
      ),
    );
  }

  // ── Animal card (original design adapted) ──────────────────────────────────

  Widget _buildAnimalCard(AnimalDto animal, int index) {
    final isCrit = _isCritical(animal);
    final isDanger = isCrit;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (_, value, __) => Transform.translate(
        offset: Offset(0, 30 * (1 - value)),
        child: Opacity(
          opacity: value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isDanger
                  ? [
                      BoxShadow(
                          color: const Color(0xFFFFEBEE).withValues(alpha: 0.8),
                          blurRadius: 25,
                          offset: const Offset(0, 10)),
                      BoxShadow(
                          color: const Color(0xFFE57373).withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5)),
                    ]
                  : [
                      BoxShadow(
                          color: _green.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8)),
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2)),
                    ],
              border: Border.all(
                color: isDanger
                    ? const Color(0xFFEF9A9A).withValues(alpha: 0.6)
                    : _lightGreen.withValues(alpha: 0.3),
                width: isDanger ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                // Banner "RIESGO ALTO" animado para signos críticos
                if (isDanger)
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(seconds: 2),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (_, animVal, __) => AnimatedContainer(
                        duration: Duration(
                            milliseconds: 1000 + (animVal * 200).toInt()),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.lerp(const Color(0xFFFFCDD2),
                                  const Color(0xFFFF8A80), animVal * 0.3)!,
                              Color.lerp(const Color(0xFFFFEBEE),
                                  const Color(0xFFFFCDD2), animVal * 0.2)!,
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8A80).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1500),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (_, s, __) => Transform.scale(
                                scale: 0.9 + s * 0.3,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD32F2F)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.health_and_safety_outlined,
                                    color: Color(0xFFD32F2F),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            TweenAnimationBuilder<int>(
                              duration: const Duration(milliseconds: 2000),
                              tween: IntTween(begin: 0, end: 11),
                              builder: (_, n, __) {
                                const text = 'RIESGO ALTO';
                                return Text(
                                  text.substring(0, n.clamp(0, text.length)),
                                  style: const TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    shadows: [
                                      Shadow(
                                          color: Color(0xFFFFCDD2),
                                          offset: Offset(1, 1),
                                          blurRadius: 2)
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Contenido principal
                Padding(
                  padding: EdgeInsets.fromLTRB(20, isDanger ? 68 : 20, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Foto del bovino
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: isDanger
                                  ? Border.all(
                                      color: const Color(0xFFEF9A9A)
                                          .withValues(alpha: 0.6),
                                      width: 2)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: (isDanger
                                          ? const Color(0xFFE57373)
                                          : Colors.black)
                                      .withValues(alpha: isDanger ? 0.3 : 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: animal.photoUrl != null &&
                                      animal.photoUrl!.isNotEmpty
                                  ? Image.network(
                                      animal.photoUrl!,
                                      height: 90, width: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _animalPlaceholder(isDanger),
                                    )
                                  : _animalPlaceholder(isDanger),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildAnimalTypeLabel(animal),
                                const SizedBox(height: 8),
                                Text(
                                  animal.displayName,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDanger
                                        ? const Color(0xFFD32F2F)
                                        : _green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      animal.sex.toLowerCase() == 'male'
                                          ? Icons.male_rounded
                                          : Icons.female_rounded,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${animal.sex == 'Male' ? 'Macho' : 'Hembra'} · ${animal.breed}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                _buildStatusIndicator(animal),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Botones de acción
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              label: 'Ver detalles',
                              icon: Icons.visibility_rounded,
                              gradient: [_green, _green.withValues(alpha: 0.8)],
                              shadow: _green,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AnimalDetailsPage(
                                    animal: animal.toDomain(),
                                    repository: _repository,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_canCreate) ...[
                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.red.shade300, width: 1.5),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _deactivate(animal),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(Icons.power_settings_new_rounded,
                                        color: Colors.red.shade600, size: 20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _animalPlaceholder(bool isDanger) => Container(
        height: 90, width: 90,
        decoration: BoxDecoration(
          color: isDanger
              ? const Color(0xFFFFCDD2).withValues(alpha: 0.8)
              : _lightGreen.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.pets_rounded,
            size: 40,
            color: isDanger
                ? const Color(0xFFE57373).withValues(alpha: 0.8)
                : _green.withValues(alpha: 0.7)),
      );

  Widget _actionButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required Color shadow,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: shadow.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Add button ──────────────────────────────────────────────────────────────

  Widget _addButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_green, _green.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _green.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _goToCreate,
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Agregar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty / Error states ────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_lightGreen.withValues(alpha: 0.8), _lightGreen.withValues(alpha: 0.4)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pets_rounded, size: 80, color: _green.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 32),
          const Text('No hay bovinos registrados',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: _green)),
          const SizedBox(height: 8),
          Text('Comienza agregando tu primer bovino',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          if (_canCreate) ...[
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_green, _green.withValues(alpha: 0.8)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: _green.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _goToCreate,
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Text('Agregar Bovino',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
                color: Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(Icons.error_outline_rounded,
                size: 80, color: Colors.red.shade400),
          ),
          const SizedBox(height: 32),
          const Text('Error al cargar bovinos',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: _green)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(error,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => setState(() => _futureAnimals = _repository.getAnimals()),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFF8F9FA), _lightGreen.withValues(alpha: 0.3)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: FutureBuilder<List<AnimalDto>>(
            future: _futureAnimals,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildModernLoadingAnimation();
              }
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              if (_allAnimals.isEmpty && snapshot.hasData) {
                _allAnimals = snapshot.data!;
                _filteredAnimals = List.of(_allAnimals);
              }

              if (_filteredAnimals.isEmpty && _allAnimals.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  // Header con animaciones multi-capa (original design)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOutCubicEmphasized,
                    height: _showHeader ? null : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeInOutQuint,
                      opacity: _showHeader ? 1.0 : 0.0,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutCubicEmphasized,
                        scale: _showHeader ? 1.0 : 0.95,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOutCubicEmphasized,
                          offset: _showHeader ? Offset.zero : const Offset(0, -0.2),
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                    color: _green.withValues(alpha: 0.15),
                                    blurRadius: 25,
                                    offset: const Offset(0, 8)),
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2)),
                              ],
                              border: Border.all(
                                  color: _lightGreen.withValues(alpha: 0.3)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _green.withValues(alpha: 0.15),
                                          _accent.withValues(alpha: 0.1)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.pets_rounded,
                                        color: _green, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Gestión de Bovinos',
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: _green)),
                                        Text('Administra tu ganado bovino',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _lightGreen.withValues(alpha: 0.8),
                                          _lightGreen.withValues(alpha: 0.6)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: _green.withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      'Total: ${_filteredAnimals.length}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: _green,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Barra búsqueda + botón agregar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOutCubicEmphasized,
                    margin: EdgeInsets.fromLTRB(
                        20, _showHeader ? 0 : 20, 20, 0),
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeInOutCubicEmphasized,
                      offset: _showHeader ? Offset.zero : const Offset(0, -0.1),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _lightGreen.withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(
                                      color: _green.withValues(alpha: 0.08),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5))
                                ],
                              ),
                              child: TextField(
                                controller: _searchCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Buscar por nombre, raza...',
                                  hintStyle: TextStyle(
                                      color: Colors.grey.shade500, fontSize: 14),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.search_rounded,
                                        color: _green, size: 20),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),
                          ),
                          if (_canCreate) ...[
                            const SizedBox(width: 16),
                            _addButton(),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      physics: const ClampingScrollPhysics(),
                      itemCount: _filteredAnimals.length,
                      itemBuilder: (_, i) =>
                          _buildAnimalCard(_filteredAnimals[i], i),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
