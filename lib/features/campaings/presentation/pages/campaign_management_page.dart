import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/features/campaings/data/datasources/campaign_services.dart';
import 'package:vacapp/features/campaings/data/repositories/campaign_repository.dart';
import 'package:vacapp/features/campaings/presentation/bloc/campaign_bloc.dart';
import 'package:vacapp/features/campaings/presentation/bloc/campaign_event.dart';
import 'package:vacapp/features/campaings/presentation/bloc/campaign_state.dart';
import 'package:vacapp/features/campaings/presentation/pages/create_campaign_page.dart';
import 'package:vacapp/features/campaings/presentation/widgets/campaign_card.dart';
import 'package:vacapp/core/widgets/island_notification.dart';
import 'package:vacapp/features/stables/data/datasources/stables_service.dart';

class CampaignManagementPage extends StatefulWidget {
  const CampaignManagementPage({super.key});

  @override
  State<CampaignManagementPage> createState() => _CampaignManagementPageState();
}

class _CampaignManagementPageState extends State<CampaignManagementPage> {
  late final CampaignBloc _campaignBloc;
  final StablesService _stablesService = StablesService();
  
  // Variables para el filtro
  List<dynamic> _allCampaigns = [];
  List<dynamic> _filteredCampaigns = [];
  int? _selectedStableId;
  List<dynamic> _stables = [];
  bool _isLoadingStables = false;
  bool _showFilter = false; // Controla si se muestra el filtro
  
  // Caché para nombres de establos
  final Map<int, String> _stableNamesCache = {};
  bool _stablesLoaded = false;

  @override
  void initState() {
    super.initState();
    _campaignBloc = CampaignBloc(CampaignRepository(CampaignServices()));
    _campaignBloc.add(LoadAllCampaigns());
    _loadStables();
  }

  @override
  void dispose() {
    _campaignBloc.close();
    super.dispose();
  }

  void _goToCreateCampaign() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _campaignBloc,
          child: const CreateCampaignPage(),
        ),
      ),
    );

    if (result == true) {
      _campaignBloc.add(RefreshCampaigns());
    }
  }

  // Método para cargar establos desde el servicio con caché
  Future<void> _loadStables() async {
    if (!mounted || _stablesLoaded) return;
    
    setState(() {
      _isLoadingStables = true;
    });

    try {
      final stables = await _stablesService.fetchStables();
      if (mounted) {
        setState(() {
          _stables = stables;
          _isLoadingStables = false;
          _stablesLoaded = true;
          
          // Llenar el caché de nombres
          _stableNamesCache.clear();
          for (var stable in stables) {
            _stableNamesCache[stable.id] = stable.name;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStables = false;
        });
      }
    }
  }

  // Método rápido para obtener el nombre del establo desde caché
  String getStableNameFromCache(int stableId) {
    return _stableNamesCache[stableId] ?? 'Establo $stableId';
  }

  // Método para filtrar campañas por establo
  void _filterCampaignsByStable(int? stableId) {
    setState(() {
      _selectedStableId = stableId;
      if (stableId == null) {
        _filteredCampaigns = List.from(_allCampaigns);
      } else {
        _filteredCampaigns = _allCampaigns
            .where((campaign) => campaign.stableId == stableId)
            .toList();
      }
    });
  }

  // Método para actualizar la lista de campañas cuando se cargan desde el BLoC
  void _updateCampaignsList(List<dynamic> campaigns) {
    setState(() {
      _allCampaigns = campaigns;
      if (_selectedStableId == null) {
        _filteredCampaigns = List.from(campaigns);
      } else {
        _filteredCampaigns = campaigns
            .where((campaign) => campaign.stableId == _selectedStableId)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          child: BlocProvider(
            create: (_) => _campaignBloc,
            child: BlocListener<CampaignBloc, CampaignState>(
              listener: (context, state) {
                if (state is CampaignCreated) {
                  IslandNotification.showSuccess(
                    context,
                    message: 'Campaña creada exitosamente',
                  );
                } else if (state is CampaignUpdated) {
                  IslandNotification.showSuccess(
                    context,
                    message: 'Estado actualizado exitosamente',
                  );
                } else if (state is CampaignDeleted) {
                  IslandNotification.showSuccess(
                    context,
                    message: state.message,
                  );
                } else if (state is CampaignError) {
                  IslandNotification.showError(
                    context,
                    message: 'Error: ${state.message}',
                  );
                }
              },
              child: BlocBuilder<CampaignBloc, CampaignState>(
                builder: (context, state) {
                  if (state is CampaignLoading) {
                    return _buildLoadingState();
                  } else if (state is CampaignEmpty) {
                    return _buildEmptyState();
                  } else if (state is CampaignLoaded) {
                    // Actualizar la lista de campañas cuando se cargan
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _updateCampaignsList(state.campaigns);
                    });
                    return _buildLoadedState(_filteredCampaigns.isNotEmpty ? _filteredCampaigns : state.campaigns);
                  } else if (state is CampaignError) {
                    return _buildErrorState(state.message);
                  }
                  
                  return _buildLoadingState();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget para el filtro de establos
  Widget _buildStableFilter() {
    const primary = Color(0xFF00695C);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.1),
            blurRadius: 10,
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
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.filter_list,
                  size: 18,
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Filtrar por Establo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
              const Spacer(),
              if (_selectedStableId != null)
              IconButton(
                onPressed: () {
                  setState(() {
                    _showFilter = false;
                  });
                },
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: Colors.grey,
                ),
                tooltip: 'Cerrar filtro',
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_isLoadingStables)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: primary),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Opción "Todos"
                FilterChip(
                  label: Text(
                    'Todos (${_allCampaigns.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _selectedStableId == null ? Colors.white : primary,
                    ),
                  ),
                  selected: _selectedStableId == null,
                  onSelected: (_) => _filterCampaignsByStable(null),
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: primary,
                  checkmarkColor: Colors.white,
                ),
                
                // Opciones de establos
                ..._stables.map((stable) {
                  final campaignCount = _allCampaigns
                      .where((campaign) => campaign.stableId == stable.id)
                      .length;
                  
                  return FilterChip(
                    label: Text(
                      '${stable.name} ($campaignCount)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _selectedStableId == stable.id ? Colors.white : primary,
                      ),
                    ),
                    selected: _selectedStableId == stable.id,
                    onSelected: (_) => _filterCampaignsByStable(stable.id),
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: primary,
                    checkmarkColor: Colors.white,
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    const primary = Color(0xFF00695C);
    const lightGreen = Color(0xFFE8F5E8);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
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
            child: const Center(
              child: CircularProgressIndicator(
                color: primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Cargando campañas...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    const primary = Color(0xFF00695C);
    const lightGreen = Color(0xFFE8F5E8);

    return Column(
      children: [
        // Header mejorado igual al del estado cargado
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Gestión de Campañas',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón de filtro (deshabilitado en estado vacío)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: null, // Deshabilitado cuando no hay campañas
                  icon: Icon(
                    Icons.filter_list,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Badge con total de campañas (0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      size: 16,
                      color: primary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '0',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Contenido del estado vacío
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
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
                    ),
                    child: Center(
                      child: Icon(
                        Icons.campaign_outlined,
                        size: 64,
                        color: primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'No hay campañas creadas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Comienza creando tu primera campaña\npara gestionar actividades',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
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
                        onTap: _goToCreateCampaign,
                        borderRadius: BorderRadius.circular(16),
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
                                'Crear mi primera campaña',
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadedState(campaigns) {
    const primary = Color(0xFF00695C);
    
    return RefreshIndicator(
      onRefresh: () async {
        _campaignBloc.add(RefreshCampaigns());
        // Solo recargar establos si no están cargados o han pasado más de 5 minutos
        if (!_stablesLoaded) {
          await _loadStables();
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: campaigns.length + (_showFilter ? 2 : 1), // +2 si filtro está activo, +1 solo header
        itemBuilder: (context, index) {
          if (index == 0) {
            // Header mejorado
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  // Header con botón de regresar y título
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: primary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Gestión de Campañas',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botón de filtro
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: _showFilter ? primary : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _showFilter = !_showFilter;
                                });
                              },
                              icon: Icon(
                                Icons.filter_list,
                                color: _showFilter ? Colors.white : primary,
                                size: 20,
                              ),
                            ),
                          ),
                          // Badge para filtro activo (solo cuando no hay selección específica)
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Badge con total de campañas
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.campaign_outlined,
                              size: 16,
                              color: primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_allCampaigns.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón para crear nueva campaña mejorado
                  Container(
                    width: double.infinity,
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
                        onTap: _goToCreateCampaign,
                        borderRadius: BorderRadius.circular(16),
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
                                'Crear Nueva Campaña',
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
                ],
              ),
            );
          }
          
          if (index == 1 && _showFilter) {
            // Widget de filtro solo si está activo
            return _buildStableFilter();
          }

          // Ajustar el índice de la campaña según si el filtro está visible
          final campaignIndex = _showFilter ? index - 2 : index - 1;
          final campaign = campaigns[campaignIndex];
          return CampaignCard(
            campaign: campaign,
            onDelete: (campaign) {
              _showDeleteDialog(campaign);
            },
            onStatusChange: (campaign, status) {
              _campaignBloc.add(UpdateCampaignStatus(campaign.id, status));
            },
            onAddGoal: (campaign, goalData) {
              // El diálogo moderno ya está integrado en CampaignCard
              // Los datos del goal se procesan directamente en el BLoC
              _campaignBloc.add(AddGoalToCampaign(campaign.id, goalData));
            },
            onAddChannel: (campaign, channelData) {
              // La lógica del diálogo ya está integrada en CampaignCard
              // Los datos del channel se procesan directamente en el BLoC
              _campaignBloc.add(AddChannelToCampaign(campaign.id, channelData));
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    const primary = Color(0xFF00695C);
    
    return Column(
      children: [
        // Header mejorado igual al del estado cargado
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Gestión de Campañas',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón de filtro (deshabilitado en estado de error)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: null, // Deshabilitado en estado de error
                  icon: Icon(
                    Icons.filter_list,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Badge con error
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Contenido del estado de error
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _campaignBloc.add(RefreshCampaigns());
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Método para obtener el nombre del establo (con caché optimizado)
  Future<String> _getStableName(int stableId) async {
    // Si ya tenemos el nombre en caché, devolverlo inmediatamente
    if (_stableNamesCache.containsKey(stableId)) {
      return _stableNamesCache[stableId]!;
    }
    
    // Si no está en caché, obtenerlo de la API
    try {
      final stableServices = StablesService();
      final stable = await stableServices.fetchStableById(stableId);
      
      // Guardar en caché para futuras consultas
      _stableNamesCache[stableId] = stable.name;
      
      return stable.name;
    } catch (e) {
      final fallbackName = 'Establo $stableId';
      _stableNamesCache[stableId] = fallbackName; // Cachear también el fallback
      return fallbackName;
    }
  }

  // Widget optimizado para mostrar nombres de establos
  Widget _buildStableName(int stableId, {TextStyle? style}) {
    // Si ya tenemos el nombre en caché, mostrarlo inmediatamente
    if (_stableNamesCache.containsKey(stableId)) {
      return Text(
        _stableNamesCache[stableId]!,
        style: style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    // Si no está en caché, usar FutureBuilder pero con un placeholder mejor
    return FutureBuilder<String>(
      future: _getStableName(stableId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            snapshot.data!,
            style: style,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        }
        
        // Mostrar placeholder mientras carga
        return Container(
          height: 16,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(campaign) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              // Header con ícono de advertencia
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  size: 32,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              
              // Título
              const Text(
                'Eliminar Campaña',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // Información de la campaña
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Nombre de la campaña
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00695C).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.campaign,
                            size: 16,
                            color: Color(0xFF00695C),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Campaña',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                campaign.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Código e información del establo
                    Row(
                      children: [
                        // Código de la campaña
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'CÓDIGO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '#${campaign.id.toString().padLeft(3, '0')}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                    fontFamily: 'Courier',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Establo
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00695C).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF00695C).withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.home_work,
                                      size: 14,
                                      color: Color(0xFF00695C),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'ESTABLO',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF00695C),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _buildStableName(
                                  campaign.stableId, 
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00695C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Mensaje de confirmación
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: '¿Estás seguro de que deseas eliminar esta campaña?'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Información adicional
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Esta acción no se puede deshacer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 28),
                        Expanded(
                          child: Text(
                            'Se eliminarán todos los objetivos y canales asociados',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _campaignBloc.add(DeleteCampaign(campaign.id));
                      },
                      icon: const Icon(Icons.delete_forever, size: 18),
                      label: const Text('Eliminar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    );
  }

    
}