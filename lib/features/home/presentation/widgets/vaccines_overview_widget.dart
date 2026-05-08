import 'package:flutter/material.dart';
import 'package:vacapp/features/vaccines/data/repositories/vaccines_repository.dart';
import 'package:vacapp/features/vaccines/data/datasources/vaccines_services.dart';
import 'package:intl/intl.dart';
import 'package:vacapp/core/services/connectivity_service.dart';
import 'package:vacapp/features/vaccines/presentation/pages/vaccines_page.dart';

class VaccinesOverviewWidget extends StatefulWidget {
  const VaccinesOverviewWidget({super.key});

  @override
  State<VaccinesOverviewWidget> createState() => _VaccinesOverviewWidgetState();
}

class _VaccinesOverviewWidgetState extends State<VaccinesOverviewWidget> {
  late VaccinesRepository _repository;
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isLoading = true;
  String? _error;
  
  // Datos agrupados
  int _totalVaccines = 0;
  int _lastMonthVaccines = 0;
  Map<String, int> _vaccineTypes = {};

  // Paleta de colores moderna
  static const Color cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _repository = VaccinesRepository(VaccinesService());
    _loadVaccines();
  }

  Future<void> _loadVaccines() async {
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

      final vaccines = await _repository.getVaccines();
      if (mounted) {
        // Procesar datos para estadísticas
        final now = DateTime.now();
        final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
        
        // Agrupar por tipo
        final Map<String, int> vaccineTypes = {};
        
        // Contar vacunas del último mes
        int lastMonthCount = 0;
        
        // Contar pendientes (podría ser una estimación basada en animales sin vacunar)
        
        for (final vaccine in vaccines) {
          // Contar por tipo
          final type = vaccine.vaccineType;
          vaccineTypes[type] = (vaccineTypes[type] ?? 0) + 1;
          
          // Contar último mes
          try {
            // Intentar parsear la fecha (puede venir en varios formatos)
            DateTime? vaccineDate;
            try {
              // Intenta el formato yyyy-MM-dd
              vaccineDate = DateFormat('yyyy-MM-dd').parse(vaccine.vaccineDate);
            } catch (e) {
              try {
                // Intenta el formato dd/MM/yyyy
                vaccineDate = DateFormat('dd/MM/yyyy').parse(vaccine.vaccineDate);
              } catch (e) {
                // No se pudo parsear
              }
            }
            
            if (vaccineDate != null && vaccineDate.isAfter(oneMonthAgo)) {
              lastMonthCount++;
            }
          } catch (e) {
            // Error al parsear la fecha, ignoramos
          }
        }
        
        setState(() {

          _totalVaccines = vaccines.length;
          _lastMonthVaccines = lastMonthCount;
          _vaccineTypes = vaccineTypes;
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
            _error = 'Error al cargar vacunas';
          }
          _isLoading = false;
        });
      }
    }
  }

  // Obtener los 3 tipos de vacunas más comunes
  List<MapEntry<String, int>> get _topVaccineTypes {
    final sortedEntries = _vaccineTypes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.take(3).toList();
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
                      colors: [const Color(0xFF00695C), const Color(0xFF26A69A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.vaccines_rounded,
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
                        'Control de Vacunas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00695C),
                        ),
                      ),
                      Text(
                        'Seguimiento de vacunaciones',
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
              _buildVaccinesContent(),
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
          color: Colors.green,
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

  Widget _buildVaccinesContent() {
    return Column(
      children: [
        // Estadísticas principales
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                _totalVaccines.toString(),
                Icons.vaccines,
                const Color(0xFF00695C),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Último Mes',
                _lastMonthVaccines.toString(),
                Icons.calendar_month,
                const Color(0xFF26A69A),
              ),
            ),
            
          ],
        ),

        const SizedBox(height: 20),

        // Tipos de vacunas principales
        if (_topVaccineTypes.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Vacunas por tipo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VaccinesPage(),
                    ),
                  );
                },
                child: Text(
                  'Ver todas',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_topVaccineTypes.map((entry) => _buildVaccineTypeItem(entry.key, entry.value)).toList()),
          
          if (_vaccineTypes.length > 3) ...[
            const SizedBox(height: 8),
            Text(
              'y ${_vaccineTypes.length - 3} tipos más...',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
                  'No hay datos de vacunas',
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

  Widget _buildVaccineTypeItem(String type, int count) {
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.medication_rounded,
              color: Colors.green.shade700,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              type,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
