import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/vaccines/data/models/vaccines_dto.dart';
import 'package:vacapp/features/vaccines/data/repositories/vaccines_repository.dart';
import 'package:vacapp/features/vaccines/data/datasources/vaccines_services.dart';
import 'package:vacapp/features/vaccines/presentation/pages/create_vaccines.dart';
import 'package:vacapp/features/vaccines/presentation/pages/update_vaccines.dart';
import 'package:vacapp/features/vaccines/presentation/pages/delete_vaccines.dart';
import 'package:vacapp/features/animals/data/models/animal_dto.dart';
import 'package:vacapp/features/animals/data/dataasources/animals_service.dart';
import 'package:vacapp/core/widgets/island_notification.dart';

class VaccinesPage extends StatefulWidget {
  const VaccinesPage({super.key});

  @override
  State<VaccinesPage> createState() => _VaccinesPageState();
}

class _VaccinesPageState extends State<VaccinesPage> 
    with TickerProviderStateMixin {
  late final VaccinesRepository _repository;
  late final AnimalsService _animalsService;
  List<VaccinesDto> _vaccines = [];
  List<VaccinesDto> _filteredVaccines = [];
  Map<String, AnimalDto> _animalsMap = {};
  bool _isLoading = true;
  late AnimationController _animationController;
  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotationAnimation;
  final TextEditingController _searchController = TextEditingController();
  
  // Variables para filtros avanzados
  String _selectedVaccineType = 'all';
  bool _isFilterExpanded = false;

  // Paleta institucional moderna
  static const Color primary = Color(0xFF00695C);
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color lightGreen = Color(0xFFE8F5E8);
  static const Color accent = Color(0xFF26A69A);
  static const Color cardShadow = Color(0x1A000000);

  @override
  void initState() {
    super.initState();
    _repository = VaccinesRepository(VaccinesService());
    _animalsService = AnimalsService();
    
    // Controladores de animación
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Animaciones principales
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
          parent: _animationController, 
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)
        ));
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(
          parent: _animationController, 
          curve: const Interval(0.2, 0.8, curve: Curves.elasticOut)
        ));
    
    _slideAnimation = Tween<double>(begin: 100.0, end: 0.0)
        .animate(CurvedAnimation(
          parent: _animationController, 
          curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)
        ));
    
    // Animación de carga
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
          parent: _loadingController,
          curve: Curves.linear
        ));
    
    _loadInitialData();
    _searchController.addListener(_filterVaccines);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    
    _loadingController.repeat();
    
    await Future.wait([
      _loadVaccines(),
      _loadAnimals(),
    ]);
    
    _loadingController.stop();
    _animationController.forward();
  }

  Future<void> _loadAnimals() async {
    try {
      final animals = await _animalsService.fetchAnimals();
      if (mounted) {
        setState(() {
          _animalsMap = {for (var animal in animals) animal.id: animal};
        });
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] Error loading animals: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loadingController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVaccines() async {
    try {
      final hasToken = await TokenService.instance.hasValidToken();
      if (!hasToken) {
        throw Exception('No hay token válido');
      }

      final vaccines = await _repository.getVaccines();

      if (mounted) {
        setState(() {
          _vaccines = vaccines;
          _filteredVaccines = vaccines;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] Error loading vaccines: $e');
      if (mounted) {
        setState(() {
          _vaccines = [];
          _filteredVaccines = [];
          _isLoading = false;
        });
      }
    }
  }

  void _filterVaccines() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVaccines = _vaccines.where((vaccine) {
        final matchesSearch = query.isEmpty ||
            vaccine.name.toLowerCase().contains(query) ||
            vaccine.vaccineType.toLowerCase().contains(query);

        final matchesType = _selectedVaccineType == 'all' ||
            vaccine.vaccineType.toLowerCase().contains(_selectedVaccineType.toLowerCase());

        return matchesSearch && matchesType;
      }).toList();
    });
  }

  Future<void> _refreshVaccines() async {
    HapticFeedback.mediumImpact();
    await _loadInitialData();
  }

  Future<void> _goToCreate() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CreateVaccinesPage(repository: _repository),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
    
    if (result == true) {
      await _refreshVaccines();
      if (mounted) {
        IslandNotification.showSuccess(context, message: 'Vacuna creada exitosamente');
      }
    }
  }

  Future<void> _goToUpdate(VaccinesDto vaccine) async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            UpdateVaccinesPage(repository: _repository, vaccine: vaccine),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
    
    if (result == true) {
      await _refreshVaccines();
      if (mounted) {
        IslandNotification.showSuccess(context, message: 'Vacuna actualizada exitosamente');
      }
    }
  }

  Future<void> _goToDelete(VaccinesDto vaccine) async {
    HapticFeedback.mediumImpact();
    final result = await showDeleteVaccineDialog(
      context: context,
      vaccine: vaccine,
      repository: _repository,
    );
    
    if (result == true) {
      await _refreshVaccines();
      if (mounted) {
        IslandNotification.showSuccess(context, message: 'Vacuna eliminada exitosamente');
      }
    }
  }







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8F9FA),
              lightGreen.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildModernHeader(),
              Expanded(
                child: _isLoading
                    ? _buildModernLoadingWidget()
                    : _filteredVaccines.isEmpty
                        ? _buildEmptyWidget()
                        : _buildVaccinesList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildModernHeader() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Título y navegación
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: cardShadow,
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: primary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vacunas',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '${_filteredVaccines.length} ${_filteredVaccines.length == 1 ? 'vacuna' : 'vacunas'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Botón de filtros moderno
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _isFilterExpanded = !_isFilterExpanded;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isFilterExpanded ? primary : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _isFilterExpanded 
                                    ? primary.withValues(alpha: 0.3) 
                                    : cardShadow,
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: _isFilterExpanded ? Colors.white : primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Barra de búsqueda moderna
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cardShadow,
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar vacunas...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: lightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.search_rounded, color: primary, size: 20),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),

                  // Filtros avanzados
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    height: _isFilterExpanded ? null : 0,
                    child: _isFilterExpanded ? _buildAdvancedFilters() : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvancedFilters() {
    final vaccineTypes = _vaccines.map((v) => v.vaccineType).toSet().toList();
    
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.filter_alt_rounded, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Filtrar por tipo de vacuna',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Filtro por tipo de vacuna como lista
          _buildVaccineTypeFilter(vaccineTypes),
        ],
      ),
    );
  }

  Widget _buildVaccineTypeFilter(List<String> vaccineTypes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.vaccines_rounded, color: primary, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Filtrar por tipo de vacuna',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: primary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de tipos de vacuna
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Opción "Todos"
              _buildVaccineTypeItem(
                'Todos los tipos',
                'all',
                _selectedVaccineType == 'all',
                Icons.checklist_rounded,
                Colors.grey.shade600,
              ),
              
              // Separador
              if (vaccineTypes.isNotEmpty)
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.grey.shade200,
                ),
              
              // Lista de tipos específicos
              ...vaccineTypes.asMap().entries.map((entry) {
                final index = entry.key;
                final type = entry.value;
                final isLast = index == vaccineTypes.length - 1;
                
                return Column(
                  children: [
                    _buildVaccineTypeItem(
                      type,
                      type,
                      _selectedVaccineType == type,
                      Icons.medical_services_rounded,
                      _getVaccineTypeColor(type),
                    ),
                    if (!isLast)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.grey.shade100,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVaccineTypeItem(
    String label,
    String value,
    bool isSelected,
    IconData icon,
    Color iconColor,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedVaccineType = value;
          });
          _filterVaccines();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Icono del tipo
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? primary.withValues(alpha: 0.2) : iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? primary : iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              
              // Texto del tipo
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? primary : Colors.grey.shade700,
                  ),
                ),
              ),
              
              // Contador de vacunas de este tipo
              if (value != 'all') ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_vaccines.where((v) => v.vaccineType == value).length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_vaccines.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(width: 8),
              
              // Indicador de selección
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? primary : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getVaccineTypeColor(String type) {
    // Asignar colores basados en el tipo de vacuna
    switch (type.toLowerCase()) {
      case 'antiparasitaria':
      case 'antiparasitario':
        return Colors.orange.shade600;
      case 'antibiótico':
      case 'antibiotico':
        return Colors.red.shade600;
      case 'vitamina':
      case 'vitaminas':
        return Colors.green.shade600;
      case 'vacuna':
      case 'inmunización':
        return Colors.blue.shade600;
      case 'hormonal':
        return Colors.purple.shade600;
      case 'analgésico':
      case 'analgesico':
        return Colors.teal.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildModernLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Spinner moderno con gradiente
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primaryLight, accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.vaccines_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          
          // Texto con animación de pulso
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1500),
            tween: Tween(begin: 0.5, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: const Text(
                  'Cargando vacunas...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primary,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Indicador de progreso lineal
          Container(
            width: 200,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _loadingController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: null,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [lightGreen.withValues(alpha: 0.3), lightGreen.withValues(alpha: 0.1)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.vaccines_outlined,
                      size: 80,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'No hay vacunas registradas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Comienza agregando una nueva vacuna',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVaccinesList() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: RefreshIndicator(
              onRefresh: _refreshVaccines,
              color: primary,
              backgroundColor: Colors.white,
              displacement: 40,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                physics: const BouncingScrollPhysics(),
                itemCount: _filteredVaccines.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final vaccine = _filteredVaccines[index];
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(100 * (1 - value), 0),
                        child: Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Opacity(
                            opacity: value,
                            child: _buildModernVaccineCard(vaccine),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernVaccineCard(VaccinesDto vaccine) {
    // Obtener el animal específico de esta vacuna
    final animal = _animalsMap[vaccine.bovineId.toString()];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            lightGreen.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: lightGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header de la vacuna
                Row(
                  children: [
                    // Imagen de la vacuna con overlay moderno
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: vaccine.vaccineImg.isEmpty 
                            ? LinearGradient(
                                colors: [primary.withValues(alpha: 0.1), lightGreen],
                              )
                            : null,
                        image: vaccine.vaccineImg.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(vaccine.vaccineImg),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: vaccine.vaccineImg.isEmpty
                          ? const Icon(
                              Icons.vaccines_outlined,
                              color: primary,
                              size: 35,
                            )
                          : null,
                    ),
                    const SizedBox(width: 20),
                    
                    // Información de la vacuna
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vaccine.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primary.withValues(alpha: 0.1), accent.withValues(alpha: 0.1)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              vaccine.vaccineType,
                              style: const TextStyle(
                                fontSize: 12,
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
                
                const SizedBox(height: 20),
                
                // Información del animal vacunado
                if (animal != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isMale(animal.gender) ? Icons.male : Icons.female,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                animal.displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_translateGender(animal.gender)} • ${_calculateAge(animal.birthDate)} años',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primary.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Vacunado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Información de fecha de vencimiento
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightGreen.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fecha de Vencimiento',
                            style: TextStyle(
                              fontSize: 12,
                              color: primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(vaccine.vaccineDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Botones de acción modernos
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.edit_rounded,
                        label: 'Editar',
                        color: accent,
                        onTap: () => _goToUpdate(vaccine),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.delete_rounded,
                        label: 'Eliminar',
                        color: Colors.red.shade400,
                        onTap: () => _goToDelete(vaccine),
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
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFAB() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: _goToCreate,
            backgroundColor: primary,
            elevation: 8,
            highlightElevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            label: const Text(
              'Nueva Vacuna',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper methods
  bool _isMale(String gender) {
    return gender.toLowerCase() == 'male' || gender.toLowerCase() == 'macho';
  }

  String _translateGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Macho';
      case 'female':
        return 'Hembra';
      case 'macho':
        return 'Macho';
      case 'hembra':
        return 'Hembra';
      default:
        return gender;
    }
  }

  int _calculateAge(String birthDateString) {
    try {
      final birthDate = DateTime.parse(birthDateString);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      
      // Verificar si aún no ha cumplido años este año
      if (now.month < birthDate.month || 
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      
      return age;
    } catch (e) {
      return 0;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
