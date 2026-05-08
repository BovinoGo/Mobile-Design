import 'package:flutter/material.dart';
import 'package:vacapp/features/campaings/data/repositories/campaign_repository.dart';
import 'package:vacapp/features/campaings/data/datasources/campaign_services.dart';
import 'package:vacapp/features/campaings/data/models/campaings_dto.dart';
import 'package:vacapp/core/services/connectivity_service.dart';
import 'package:vacapp/features/campaings/presentation/pages/campaign_management_page.dart';

class CampaignsOverviewWidget extends StatefulWidget {
  const CampaignsOverviewWidget({super.key});

  @override
  State<CampaignsOverviewWidget> createState() => _CampaignsOverviewWidgetState();
}

class _CampaignsOverviewWidgetState extends State<CampaignsOverviewWidget> {
  late CampaignRepository _repository;
  final ConnectivityService _connectivityService = ConnectivityService();
  List<CampaingsDto> _campaigns = [];
  bool _isLoading = true;
  String? _error;

  // Paleta de colores moderna
  static const Color primary = Color(0xFF00695C);
  static const Color accent = Color(0xFF26A69A);
  static const Color cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _repository = CampaignRepository(CampaignServices());
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
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

      final campaigns = await _repository.getAllCampaigns();
      if (mounted) {
        setState(() {
          _campaigns = campaigns;
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
            _error = 'Error al cargar campañas';
          }
          _isLoading = false;
        });
      }
    }
  }

  int get _activeCampaignsCount => _campaigns.where((c) => 
    c.status.toLowerCase() == 'active' || 
    c.status.toLowerCase() == 'activa'
  ).length;

  int get _completedCampaignsCount => _campaigns.where((c) => 
    c.status.toLowerCase() == 'completed' || 
    c.status.toLowerCase() == 'completada'
  ).length;

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]}';
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
                    Icons.campaign_rounded,
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
                        'Campañas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      Text(
                        'Gestión de campañas activas',
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
              _buildCampaignsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
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

  Widget _buildCampaignsContent() {
    return Column(
      children: [
        // Estadísticas principales
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Activas',
                _activeCampaignsCount.toString(),
                Icons.play_circle_outline,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Completadas',
                _completedCampaignsCount.toString(),
                Icons.check_circle_outline,
                Colors.blue,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Campañas recientes
        if (_campaigns.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Campañas Recientes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CampaignManagementPage(),
                    ),
                  );
                },
                child: Text(
                  'Ver todas',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_campaigns.take(3).map((campaign) => _buildCampaignItem(campaign)).toList()),
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
                  'No hay campañas disponibles',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignItem(CampaingsDto campaign) {
    final isActive = campaign.status.toLowerCase() == 'active' || 
                    campaign.status.toLowerCase() == 'activa';
    final statusColor = isActive ? Colors.green : Colors.grey;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(campaign.startDate)} - ${_formatDate(campaign.endDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              campaign.status,
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
