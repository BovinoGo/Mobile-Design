import 'package:flutter/material.dart';
import 'package:vacapp/features/home/presentation/blocs/statistics_bloc.dart';

class AlertStatsCard extends StatelessWidget {
  final HomeStatistics statistics;

  const AlertStatsCard({super.key, required this.statistics});

  static const _red = Color(0xFFB71C1C);
  static const _orange = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    final criticals = statistics.criticalBovines;
    final unread = statistics.unreadAlerts;
    final total = criticals + unread;

    if (total == 0) return const SizedBox.shrink();

    final isCritical = criticals > 0;
    final color1 = isCritical ? _red : _orange;
    final color2 = isCritical ? const Color(0xFFE57373) : const Color(0xFFFF8A65);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color1.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCritical
                        ? Icons.monitor_heart_rounded
                        : Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Atención Requerida!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildSubtitle(criticals, unread),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Critical bovines list
            if (statistics.animalsWithoutVaccinesList.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_rounded,
                            color: Colors.white.withValues(alpha: 0.9), size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'Bovinos con signos vitales críticos:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...statistics.animalsWithoutVaccinesList.take(3).map(
                          (animal) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${animal.displayName} · ${animal.breed}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    animal.vitalSignsStatus ?? 'Crítico',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (statistics.animalsWithoutVaccinesList.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+${statistics.animalsWithoutVaccinesList.length - 3} bovinos más...',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Unread alerts count
            if (unread > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_outlined,
                        color: Colors.white.withValues(alpha: 0.8), size: 14),
                    const SizedBox(width: 8),
                    Text(
                      '$unread ${unread == 1 ? 'alerta no leída' : 'alertas no leídas'} — revisa la sección de Bovinos',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(int criticals, int unread) {
    final parts = <String>[];
    if (criticals > 0) {
      parts.add('$criticals ${criticals == 1 ? 'bovino' : 'bovinos'} con signos críticos');
    }
    if (unread > 0) {
      parts.add('$unread ${unread == 1 ? 'alerta' : 'alertas'} no leída${unread == 1 ? '' : 's'}');
    }
    return parts.join(' · ');
  }
}
