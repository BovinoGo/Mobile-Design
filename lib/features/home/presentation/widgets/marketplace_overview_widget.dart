import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vacapp/features/marketplace/data/datasources/marketplace_service.dart';
import 'package:vacapp/features/marketplace/data/models/publication_dto.dart';

class MarketplaceOverviewWidget extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  final bool isBuyer;
  const MarketplaceOverviewWidget({super.key, this.onNavigateToTab, this.isBuyer = false});

  @override
  State<MarketplaceOverviewWidget> createState() =>
      _MarketplaceOverviewWidgetState();
}

class _MarketplaceOverviewWidgetState
    extends State<MarketplaceOverviewWidget> {
  static const _teal = Color(0xFF00838F);
  static const _lightTeal = Color(0xFFE0F7FA);

  List<PublicationDto> _mine = [];
  List<PublicationDto> _market = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final service = MarketplaceService();
      final mine = await service.fetchMine();
      final market = await service.fetchPublished();
      if (mounted) {
        setState(() {
          _mine = mine;
          _market = market;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  int get _activePublications =>
      _mine.where((p) => p.publicationStatus == 'Publicada').length;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: 0.1),
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
                colors: [_teal, Color(0xFF006064)],
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
                  child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Feria Ganadera',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(
                        _loading ? 'Cargando...' : '${_market.length} bovinos disponibles',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => widget.onNavigateToTab?.call(2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Ir a la Feria',
                        style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: widget.isBuyer 
                  ? Row(
                      children: [
                        _statChip(
                          icon: Icons.shopping_cart_outlined,
                          label: 'En mercado',
                          value: '${_market.length}',
                          color: _teal,
                        ),
                        const SizedBox(width: 10),
                        _statChip(
                          icon: Icons.check_circle_outline,
                          label: 'Mis Compras',
                          value: '0', // Cambiar con data real de compras si existe
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 10),
                        _statChip(
                          icon: Icons.favorite_border_rounded,
                          label: 'Favoritos',
                          value: '0', // Cambiar con data real de favoritos si existe
                          color: Colors.red.shade700,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _statChip(
                          icon: Icons.sell_outlined,
                          label: 'Mis publicaciones',
                          value: '${_mine.length}',
                          color: _teal,
                        ),
                        const SizedBox(width: 10),
                        _statChip(
                          icon: Icons.check_circle_outline,
                          label: 'Activas',
                          value: '$_activePublications',
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 10),
                        _statChip(
                          icon: Icons.shopping_cart_outlined,
                          label: 'En mercado',
                          value: '${_market.length}',
                          color: Colors.blue.shade700,
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
      return Column(
        children: List.generate(2, (index) => _skeletonTile()),
      );
    }
    if (_error != null) {
      return Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade600, fontSize: 13))),
          IconButton(
            icon: const Icon(Icons.refresh, color: _teal, size: 18),
            onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
          ),
        ],
      );
    }

    if (widget.isBuyer) {
      // Buyer view: show latest from market
      if (_market.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('No hay publicaciones en el mercado actualmente.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        );
      }
      final latestMarket = _market.take(2).toList();
      return Column(children: latestMarket.map((p) => _publicationTile(p)).toList());
    } else {
      // Seller view
      if (_mine.isEmpty) {
        return _buildFirstPublicationButton();
      }
      // Show last 2 active publications
      final active = _mine.where((p) => p.publicationStatus == 'Publicada').take(2).toList();
      if (active.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('No tienes publicaciones activas actualmente.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        );
      }
      return Column(children: active.map((p) => _publicationTile(p)).toList());
    }
  }

  Widget _buildFirstPublicationButton() {
    return GestureDetector(
      onTap: () => widget.onNavigateToTab?.call(2),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _lightTeal.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _teal.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: _teal.withValues(alpha: 0.7), size: 20),
            const SizedBox(width: 8),
            const Text('Publicar mi primer bovino',
                style: TextStyle(color: _teal, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _skeletonTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lightTeal.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 14,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 12,
                    width: 120,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 20,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _publicationTile(PublicationDto pub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lightTeal.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.pets_rounded, color: _teal, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pub.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: _teal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${pub.price.toStringAsFixed(0)} ${pub.currency} · ${pub.salePurpose}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(pub.publicationStatus,
                style: const TextStyle(
                    fontSize: 10, color: Colors.green, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 11, color: color.withValues(alpha: 0.7)),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: color.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
