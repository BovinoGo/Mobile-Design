import 'package:flutter/material.dart';
import 'package:vacapp/features/ranches/data/datasources/ranch_service.dart';
import 'package:vacapp/features/ranches/data/models/ranch_dto.dart';

class RanchesOverviewWidget extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  const RanchesOverviewWidget({super.key, this.onNavigateToTab});

  @override
  State<RanchesOverviewWidget> createState() => _RanchesOverviewWidgetState();
}

class _RanchesOverviewWidgetState extends State<RanchesOverviewWidget> {
  static const _green = Color(0xFF00695C);
  static const _lightGreen = Color(0xFFE8F5E8);

  List<RanchDto> _ranches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ranches = await RanchService().fetchMine();
      if (mounted) setState(() { _ranches = ranches; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_green, Color(0xFF00897B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.home_work_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mis Ranchos',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(
                        _loading ? 'Cargando...' : '${_ranches.length} ${_ranches.length == 1 ? 'rancho' : 'ranchos'} registrados',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
                if (!_loading && _error == null)
                  GestureDetector(
                    onTap: () => widget.onNavigateToTab?.call(3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Ver todos',
                          style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(color: _green),
      ));
    }
    if (_error != null) {
      return _errorWidget();
    }
    if (_ranches.isEmpty) {
      return _emptyWidget();
    }
    return Column(
      children: _ranches.take(3).map((r) => _ranchTile(r)).toList(),
    );
  }

  Widget _ranchTile(RanchDto ranch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lightGreen.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.landscape_outlined, color: _green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ranch.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _green)),
                Text('${ranch.country} · ${ranch.region} · ${ranch.productionType}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (ranch.capacityBovines != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${ranch.capacityBovines} bovinos',
                  style: const TextStyle(fontSize: 10, color: _green, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _emptyWidget() {
    return GestureDetector(
      onTap: () => widget.onNavigateToTab?.call(3),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _lightGreen.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _green.withValues(alpha: 0.2), style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: _green.withValues(alpha: 0.7), size: 20),
            const SizedBox(width: 8),
            const Text('Crear mi primer rancho', style: TextStyle(color: _green, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _errorWidget() {
    return Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade600, fontSize: 13))),
        IconButton(
          icon: const Icon(Icons.refresh, color: _green, size: 18),
          onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
        ),
      ],
    );
  }
}
