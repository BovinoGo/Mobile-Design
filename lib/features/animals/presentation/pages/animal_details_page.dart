import 'package:flutter/material.dart';
import 'package:vacapp/features/animals/data/models/animal_dto.dart';
import 'package:vacapp/features/animals/data/repositories/animal_repository.dart';
import 'package:vacapp/features/animals/domain/entitites/Animal.dart';

class AnimalDetailsPage extends StatefulWidget {
  final Animal animal;
  final AnimalRepository repository;
  const AnimalDetailsPage(
      {super.key, required this.animal, required this.repository});

  @override
  State<AnimalDetailsPage> createState() => _AnimalDetailsPageState();
}

class _AnimalDetailsPageState extends State<AnimalDetailsPage>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF00695C);
  static const _lightGreen = Color(0xFFE8F5E8);

  late TabController _tabController;
  bool _loadingHistory = false;
  List<VitalSignsResultDto> _history = [];
  List<CriticalAlertDto> _alerts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistory();
    _loadAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final history =
          await widget.repository.getVitalSignsHistory(widget.animal.id);
      if (mounted) setState(() => _history = history);
    } catch (_) {}
    if (mounted) setState(() => _loadingHistory = false);
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await widget.repository.getAlerts();
      if (mounted) {
        setState(() {
          _alerts = alerts
              .where((a) => a.bovineId == widget.animal.id)
              .toList();
        });
      }
    } catch (_) {}
  }


  @override
  Widget build(BuildContext context) {
    final a = widget.animal;
    final isCritical = a.vitalSignsStatus == 'Critico';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isCritical ? Colors.red.shade700 : _green,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                a.displayName,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isCritical
                        ? [Colors.red.shade700, Colors.red.shade900]
                        : [_green, const Color(0xFF00897B)],
                  ),
                ),
                child: a.photoUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(a.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox()),
                          Container(
                              color: Colors.black.withValues(alpha: 0.35)),
                        ],
                      )
                    : Center(
                        child: Icon(Icons.pets_rounded,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.3))),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Quick stats row
                _statsRow(a),
                // Tabs
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: _green,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: _green,
                    tabs: const [
                      Tab(text: 'Detalles'),
                      Tab(text: 'Signos Vitales'),
                      Tab(text: 'Alertas'),
                    ],
                  ),
                ),
                SizedBox(
                  height: 500,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _detailsTab(a),
                      _vitalSignsTab(),
                      _alertsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(Animal a) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _statChip(
              '${a.currentWeightKg.toStringAsFixed(0)} kg', Icons.scale_rounded),
          const SizedBox(width: 10),
          _statChip('${a.ageInMonths} meses', Icons.calendar_month_rounded),
          const SizedBox(width: 10),
          _healthChip(a.healthStatus),
          if (a.vitalSignsStatus != null) ...[
            const SizedBox(width: 10),
            _vitalChip(a.vitalSignsStatus!),
          ],
        ],
      ),
    );
  }

  Widget _statChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _green),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _green)),
        ],
      ),
    );
  }

  Widget _healthChip(String status) {
    final isHealthy = status == 'Sano';
    final color = isHealthy ? Colors.green.shade700 : Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isHealthy ? Colors.green : Colors.orange).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.health_and_safety, size: 14, color: color),
          const SizedBox(width: 4),
          Text(status,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _vitalChip(String status) {
    final isNormal = status == 'Normal';
    final color = isNormal ? Colors.blue.shade700 : Colors.red.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isNormal ? Colors.blue : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monitor_heart, size: 14, color: color),
          const SizedBox(width: 4),
          Text(status,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _detailsTab(Animal a) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _infoCard('Identificación', [
            _infoRow('Código de Arete', a.earTagCode),
            if (a.name != null) _infoRow('Nombre', a.name!),
            _infoRow('Raza', a.breed),
            _infoRow('Sexo', a.sex),
            _infoRow('Edad', '${a.ageInMonths} meses'),
          ]),
          const SizedBox(height: 12),
          _infoCard('Producción', [
            _infoRow('Peso actual', '${a.currentWeightKg.toStringAsFixed(1)} kg'),
            if (a.category != null) _infoRow('Categoría', a.category!),
            if (a.productivePurpose != null)
              _infoRow('Propósito productivo', a.productivePurpose!),
          ]),
          const SizedBox(height: 12),
          _infoCard('Estado', [
            _infoRow('Salud', a.healthStatus),
            _infoRow('Vida', a.lifeStatus),
            _infoRow('Activo', a.isActive ? 'Sí' : 'No'),
            if (a.vitalSignsStatus != null)
              _infoRow('Signos vitales', a.vitalSignsStatus!),
          ]),
          if (a.bodyTemperatureCelsius != null) ...[
            const SizedBox(height: 12),
            _infoCard('Últimos Signos Vitales', [
              if (a.bodyTemperatureCelsius != null)
                _infoRow(
                    'Temperatura', '${a.bodyTemperatureCelsius!.toStringAsFixed(1)}°C'),
              if (a.heartRateBpm != null)
                _infoRow('Frecuencia cardíaca', '${a.heartRateBpm} bpm'),
              if (a.respiratoryRateRpm != null)
                _infoRow('Frecuencia respiratoria', '${a.respiratoryRateRpm} rpm'),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _green.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _green,
                  letterSpacing: 0.3)),
          const Divider(height: 16),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _vitalSignsTab() {
    final a = widget.animal;
    final hasCurrentVitals = a.bodyTemperatureCelsius != null ||
        a.heartRateBpm != null ||
        a.respiratoryRateRpm != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Signos vitales actuales (solo lectura)
          if (hasCurrentVitals) ...[
            _infoCard('Signos Vitales Actuales', [
              if (a.vitalSignsStatus != null)
                _vitalReadRow('Estado', a.vitalSignsStatus!,
                    icon: Icons.monitor_heart,
                    valueColor: a.vitalSignsStatus == 'Normal'
                        ? Colors.green.shade700
                        : Colors.red.shade700),
              if (a.bodyTemperatureCelsius != null)
                _vitalReadRow(
                    'Temperatura', '${a.bodyTemperatureCelsius!.toStringAsFixed(1)} °C',
                    icon: Icons.thermostat),
              if (a.heartRateBpm != null)
                _vitalReadRow('Frecuencia cardíaca', '${a.heartRateBpm} bpm',
                    icon: Icons.favorite),
              if (a.respiratoryRateRpm != null)
                _vitalReadRow(
                    'Frecuencia respiratoria', '${a.respiratoryRateRpm} rpm',
                    icon: Icons.air),
            ]),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade500),
                  const SizedBox(width: 12),
                  Text('Sin signos vitales registrados aún.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Historial
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Historial de Signos Vitales',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: _green)),
              IconButton(
                icon: const Icon(Icons.refresh, color: _green, size: 20),
                onPressed: _loadHistory,
                tooltip: 'Actualizar historial',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingHistory)
            const Center(child: CircularProgressIndicator(color: _green))
          else if (_history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Sin historial registrado',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            )
          else
            ...(_history.take(10).map((h) => _historyCard(h))),
        ],
      ),
    );
  }

  Widget _vitalReadRow(String label, String value,
      {required IconData icon, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _green.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _historyCard(VitalSignsResultDto h) {
    final isCritical = h.vitalSignsStatus == 'Critico';
    final color = isCritical ? Colors.red.shade700 : Colors.green.shade700;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: (isCritical ? Colors.red : Colors.green)
                .withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(isCritical ? Icons.warning : Icons.check_circle,
              color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.vitalSignsStatus,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                Text(
                    '${h.temperature}°C · ${h.heartRate} bpm · ${h.respiratoryRate} rpm',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(
              h.simulatedAt.isNotEmpty
                  ? h.simulatedAt.substring(0, 10)
                  : '',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _alertsTab() {
    if (_alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 56, color: Colors.green.shade400),
            const SizedBox(height: 12),
            const Text('Sin alertas críticas',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _green)),
            const SizedBox(height: 6),
            const Text('Este bovino no tiene alertas activas',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      itemBuilder: (_, i) {
        final alert = _alerts[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_rounded,
                  color: Colors.red.shade600, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.message,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700)),
                    const SizedBox(height: 4),
                    Text(
                        alert.isRead ? 'Leída' : 'No leída',
                        style: TextStyle(
                            fontSize: 12,
                            color: alert.isRead
                                ? Colors.grey
                                : Colors.orange.shade700)),
                  ],
                ),
              ),
              if (!alert.isRead)
                TextButton(
                  onPressed: () async {
                    await widget.repository.markAlertRead(alert.id);
                    _loadAlerts();
                  },
                  child: const Text('Marcar leída',
                      style: TextStyle(color: _green, fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }
}
