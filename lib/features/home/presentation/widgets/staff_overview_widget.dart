import 'package:flutter/material.dart';
import 'package:vacapp/features/staff/data/repositories/staff_repository.dart';
import 'package:vacapp/features/staff/data/datasources/staff_service.dart';
import 'package:vacapp/features/staff/data/models/staff_dto.dart';
import 'package:vacapp/core/services/connectivity_service.dart';
import 'package:vacapp/features/staff/presentation/pages/staff_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:vacapp/features/staff/presentation/bloc/staff_event.dart';

class StaffOverviewWidget extends StatefulWidget {
  const StaffOverviewWidget({super.key});

  @override
  State<StaffOverviewWidget> createState() => _StaffOverviewWidgetState();
}

class _StaffOverviewWidgetState extends State<StaffOverviewWidget> {
  late StaffRepository _repository;
  final ConnectivityService _connectivityService = ConnectivityService();
  List<StaffDto> _staffList = [];
  bool _isLoading = true;
  String? _error;

  // Paleta de colores moderna
  static const Color primary = Color(0xFF00695C);
  static const Color accent = Color(0xFF26A69A);
  static const Color cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _repository = StaffRepository(StaffService());
    _loadStaff();
  }

  Future<void> _loadStaff() async {
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

      final staffList = await _repository.getAllStaffs();
      if (mounted) {
        setState(() {
          _staffList = staffList;
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
            _error = 'Error al cargar personal';
          }
          _isLoading = false;
        });
      }
    }
  }

  int get _inCampaignCount => _staffList.where((staff) => staff.employeeStatus == 2).length;
  int get _availableCount => _staffList.where((staff) => staff.employeeStatus == 1).length;
  int get _vacationCount => _staffList.where((staff) => staff.employeeStatus == 3).length;

  String _getStatusName(int status) {
    switch (status) {
      case 1:
        return 'Disponible';
      case 2:
        return 'En Campaña';
      case 3:
        return 'Vacaciones';
      default:
        return 'Desconocido';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.check_circle;
      case 2:
        return Icons.work;
      case 3:
        return Icons.beach_access;
      default:
        return Icons.help;
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
                    Icons.people_outline_rounded,
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
                        'Personal',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      Text(
                        'Gestión de empleados',
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
              _buildStaffContent(),
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

  Widget _buildStaffContent() {
    return Column(
      children: [
        // Estado del personal
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildStatCard(
                'Campaña',
                _inCampaignCount.toString(),
                Icons.work,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildStatCard(
                'Disponible',
                _availableCount.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildStatCard(
                'Vacaciones',
                _vacationCount.toString(),
                Icons.beach_access,
                Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Personal reciente
        if (_staffList.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Personal Reciente',
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
                      builder: (context) => BlocProvider(
                        create: (context) => StaffBloc(_repository)..add(LoadStaffs()),
                        child: const StaffPage(),
                      ),
                    ),
                  );
                },
                child: Text(
                  'Ver todos',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_staffList.take(3).map((staff) => _buildStaffItem(staff)).toList()),
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
                  'No hay personal disponible',
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
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildStaffItem(StaffDto staff) {
    final statusColor = _getStatusColor(staff.employeeStatus);
    final statusIcon = _getStatusIcon(staff.employeeStatus);
    final statusName = _getStatusName(staff.employeeStatus);
    
    String getInitials(String name) {
      if (name.isEmpty) return '?';
      final words = name.split(' ');
      if (words.length == 1) {
        return words[0].substring(0, 1).toUpperCase();
      }
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
    }
    
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
          // Avatar con iniciales
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                getInitials(staff.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
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
                  'ID: ${staff.id}',
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
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  size: 12,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  statusName,
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
