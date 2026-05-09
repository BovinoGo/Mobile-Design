import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/marketplace/data/models/publication_dto.dart';
import 'package:vacapp/features/marketplace/presentation/blocs/marketplace_bloc.dart';
import 'package:vacapp/features/marketplace/presentation/blocs/marketplace_event.dart';
import 'package:vacapp/features/marketplace/presentation/blocs/marketplace_state.dart';
import 'package:vacapp/features/marketplace/presentation/pages/publish_bovine_page.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

// ─── Filter model ────────────────────────────────────────────────────────────
class _MarketFilter {
  String? status;
  String? salePurpose;
  bool? includesTransport;
  bool? negotiable;
  double? minPrice;
  double? maxPrice;

  bool get isActive =>
      status != null ||
      salePurpose != null ||
      includesTransport != null ||
      negotiable != null ||
      minPrice != null ||
      maxPrice != null;

  List<PublicationDto> apply(List<PublicationDto> list) {
    return list.where((p) {
      if (status != null && p.publicationStatus != status) return false;
      if (salePurpose != null && p.salePurpose != salePurpose) return false;
      if (includesTransport != null &&
          p.includesTransport != includesTransport) return false;
      if (negotiable != null && p.negotiablePrice != negotiable) return false;
      if (minPrice != null && p.price < minPrice!) return false;
      if (maxPrice != null && p.price > maxPrice!) return false;
      return true;
    }).toList();
  }

  void reset() {
    status = null;
    salePurpose = null;
    includesTransport = null;
    negotiable = null;
    minPrice = null;
    maxPrice = null;
  }
}

// ─── Page ────────────────────────────────────────────────────────────────────
class _MarketplacePageState extends State<MarketplacePage>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF00695C);
  static const _lightGreen = Color(0xFFE8F5E8);
  static const _darkBg = Color(0xFFF2F4F5);

  late TabController _tabController;
  String? _myUserId;
  String _accountType = '';
  String _role = '';

  // Selection
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  // Filters
  final _filter = _MarketFilter();
  bool _showFilterBar = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _load();
    TokenService.instance.getUserId().then((id) {
      if (mounted) setState(() => _myUserId = id);
    });
    TokenService.instance.getAccountType().then((v) {
      if (mounted) setState(() => _accountType = v);
    });
    TokenService.instance.getRole().then((v) {
      if (mounted) setState(() => _role = v);
    });
  }

  bool get _canPublish =>
      _accountType != 'BuyerCustomer' && _role != 'CompanyWorker';

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    _clearSelection();
    if (_tabController.index == 0) {
      context.read<MarketplaceBloc>().add(LoadPublicationsEvent());
    } else {
      if (_accountType == 'BuyerCustomer') {
        setState(() {});
      } else {
        context.read<MarketplaceBloc>().add(LoadMyPublicationsEvent());
      }
    }
  }

  void _load() =>
      context.read<MarketplaceBloc>().add(LoadPublicationsEvent());

  void _goToPublish() async {
    final bloc = context.read<MarketplaceBloc>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const PublishBovinePage(),
        ),
      ),
    );
    if (mounted) bloc.add(LoadMyPublicationsEvent());
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
        _selectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: BlocConsumer<MarketplaceBloc, MarketplaceState>(
        listener: (context, state) {
          if (state is MarketplaceOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: _green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            );
          }
          if (state is MarketplaceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // ── Island header ──────────────────────────────────────────
              _IslandHeader(
                selectionMode: _selectionMode,
                selectedCount: _selectedIds.length,
                canPublish: _canPublish,
                filterActive: _filter.isActive,
                showFilterBar: _showFilterBar,
                onPublish: _goToPublish,
                onCancelSelection: _clearSelection,
                onToggleFilter: () =>
                    setState(() => _showFilterBar = !_showFilterBar),
                tabController: _tabController,
                accountType: _accountType,
              ),

              // ── Animated filter bar ────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _showFilterBar
                    ? _FilterBar(
                        filter: _filter,
                        publications: state is PublicationsLoaded
                            ? state.publications
                            : [],
                        onChanged: () => setState(() {}),
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Active filter chips ────────────────────────────────────
              if (_filter.isActive)
                _ActiveFilterChips(
                  filter: _filter,
                  onClear: () => setState(() => _filter.reset()),
                  onRemoveOne: () => setState(() {}),
                ),

              // ── Body content ───────────────────────────────────────────
              Expanded(child: _buildBody(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(MarketplaceState state) {
    if (state is MarketplaceLoading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: 5,
        itemBuilder: (_, i) => _skeletonCard(),
      );
    }

    if (state is PublicationsLoaded) {
      final filtered = _filter.apply(state.publications);

      if (_tabController.index == 1 && _accountType == 'BuyerCustomer') {
        return _emptyPurchasesState();
      }

      return TabBarView(
        controller: _tabController,
        children: [
          filtered.isEmpty
              ? _emptyState()
              : _listView(filtered, showBuyButton: true),
          _accountType == 'BuyerCustomer'
              ? _emptyPurchasesState()
              : (filtered.isEmpty
                  ? _emptyState()
                  : _listView(filtered, showBuyButton: false)),
        ],
      );
    }

    if (state is MarketplaceError) return _errorState(state.message);

    return TabBarView(
      controller: _tabController,
      children: [_emptyState(), _emptyState()],
    );
  }

  Widget _listView(List<PublicationDto> pubs, {required bool showBuyButton}) {
    return RefreshIndicator(
      color: _green,
      onRefresh: () async => _load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: pubs.length,
        itemBuilder: (_, i) =>
            _publicationCard(pubs[i], showBuyButton: showBuyButton),
      ),
    );
  }

  // ── Card ───────────────────────────────────────────────────────────────────
  Widget _publicationCard(PublicationDto pub, {required bool showBuyButton}) {
    final isMine = pub.sellerId == _myUserId;
    final isSelected = _selectedIds.contains(pub.id);
    final statusColor = _statusColor(pub.publicationStatus);

    return GestureDetector(
      onLongPress: () => _toggleSelection(pub.id),
      onTap: () {
        if (_selectionMode) {
          _toggleSelection(pub.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? _green.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? _green : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _green.withValues(alpha: 0.15)
                  : const Color(0xFF00695C).withValues(alpha: 0.06),
              blurRadius: isSelected ? 24 : 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _lightGreen.withValues(alpha: 0.6),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: const Center(
                    child: Icon(Icons.pets_rounded, size: 52, color: _green),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(pub.publicationStatus,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor)),
                      ],
                    ),
                  ),
                ),
                // Selection indicator
                if (_selectionMode)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected ? _green : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isSelected ? _green : Colors.grey.shade300,
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6)
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pub.title,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2332))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _chip(Icons.attach_money,
                          '${pub.price.toStringAsFixed(0)} ${pub.currency}'),
                      _chip(Icons.category_outlined, pub.salePurpose),
                      if (pub.includesTransport)
                        _chip(Icons.local_shipping_outlined, 'Con transporte',
                            color: Colors.blue.shade700),
                      if (pub.negotiablePrice)
                        _chip(Icons.handshake_outlined, 'Negociable',
                            color: Colors.orange.shade700),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_selectionMode) ...[
                    if (showBuyButton &&
                        !isMine &&
                        pub.publicationStatus == 'Publicada')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _requestPurchaseDialog(pub),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Solicitar compra',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (isMine && pub.publicationStatus == 'Publicada')
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => context
                              .read<MarketplaceBloc>()
                              .add(CancelPublicationEvent(pub.id)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: Colors.red.shade200)),
                          ),
                          child: Text('Cancelar Publicación',
                              style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  Widget _chip(IconData icon, String text, {Color? color}) {
    final c = color ?? _green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 11, color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _skeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade100,
            child: Container(
                height: 150,
                width: double.infinity,
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)))),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                      height: 18,
                      width: 200,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6))),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final w in [80.0, 90.0, 70.0]) ...[
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                            height: 24,
                            width: w,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8))),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                      height: 46,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'Publicada' => Colors.green.shade700,
        'Reservada' => Colors.orange.shade700,
        'Vendida' => Colors.blue.shade700,
        'Cancelada' => Colors.red.shade700,
        'Expirada' => Colors.grey.shade600,
        _ => Colors.grey.shade600,
      };

  void _requestPurchaseDialog(PublicationDto pub) {
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Comprar: ${pub.title}',
            style: const TextStyle(fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Precio: ${pub.price.toStringAsFixed(0)} ${pub.currency}'
                '${pub.negotiablePrice ? " (negociable)" : ""}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              decoration: InputDecoration(
                labelText: 'Mensaje al vendedor (opcional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(context);
              if (_myUserId != null) {
                context.read<MarketplaceBloc>().add(RequestPurchaseEvent(
                      publicationId: pub.id,
                      buyerId: _myUserId!,
                      message: msgCtrl.text.trim().isEmpty
                          ? null
                          : msgCtrl.text.trim(),
                    ));
              }
            },
            child: const Text('Enviar solicitud',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Empty / Error states ───────────────────────────────────────────────────
  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration:
                const BoxDecoration(color: _lightGreen, shape: BoxShape.circle),
            child: const Icon(Icons.storefront_outlined,
                size: 64, color: _green),
          ),
          const SizedBox(height: 20),
          const Text('Sin publicaciones',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _green)),
          const SizedBox(height: 8),
          const Text('Aún no hay bovinos publicados en el mercado',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _green, foregroundColor: Colors.white),
          ),
        ]),
      );

  Widget _emptyPurchasesState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration:
                const BoxDecoration(color: _lightGreen, shape: BoxShape.circle),
            child: const Icon(Icons.shopping_bag_outlined,
                size: 64, color: _green),
          ),
          const SizedBox(height: 20),
          const Text('Sin compras',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _green)),
          const SizedBox(height: 8),
          const Text('Aún no tienes compras realizadas',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
        ]),
      );

  Widget _errorState(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text('¡Ups! Algo salió mal',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade600, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white),
            ),
          ]),
        ),
      );
}

// ─── Island Header Widget ─────────────────────────────────────────────────────
class _IslandHeader extends StatelessWidget {
  final bool selectionMode;
  final int selectedCount;
  final bool canPublish;
  final bool filterActive;
  final bool showFilterBar;
  final VoidCallback onPublish;
  final VoidCallback onCancelSelection;
  final VoidCallback onToggleFilter;
  final TabController tabController;
  final String accountType;

  const _IslandHeader({
    required this.selectionMode,
    required this.selectedCount,
    required this.canPublish,
    required this.filterActive,
    required this.showFilterBar,
    required this.onPublish,
    required this.onCancelSelection,
    required this.onToggleFilter,
    required this.tabController,
    required this.accountType,
  });

  static const _green = Color(0xFF00695C);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      color: const Color(0xFFF2F4F5),
      padding: EdgeInsets.only(top: topPadding + 8, bottom: 12, left: 16, right: 16),
      child: Column(
        children: [
          // ── Island pill ─────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: selectionMode
                  ? const Color(0xFF1A2332)
                  : _green,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: (selectionMode ? const Color(0xFF1A2332) : _green)
                      .withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: selectionMode
                  ? _selectionBar(context)
                  : _normalBar(context),
            ),
          ),

          const SizedBox(height: 12),

          // ── Tab bar (outside island, subtle) ────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: TabBar(
              controller: tabController,
              labelColor: _green,
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: _green,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: const Color(0xFF00695C).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: [
                const Tab(text: 'Feria'),
                Tab(
                    text: accountType == 'BuyerCustomer'
                        ? 'Mis Compras'
                        : 'Mis Publicaciones'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _normalBar(BuildContext context) {
    return Row(
      key: const ValueKey('normal'),
      children: [
        // Icon + title
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.store_mall_directory_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Feria Ganadera',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.2)),
              Text('Bovinos disponibles',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
        // Filter button
        _IslandIconBtn(
          icon: filterActive
              ? Icons.filter_alt_rounded
              : Icons.filter_alt_outlined,
          badge: filterActive,
          onTap: onToggleFilter,
          active: showFilterBar,
        ),
        const SizedBox(width: 6),
        if (canPublish)
          _IslandIconBtn(
            icon: Icons.add_rounded,
            onTap: onPublish,
          ),
      ],
    );
  }

  Widget _selectionBar(BuildContext context) {
    return Row(
      key: const ValueKey('selection'),
      children: [
        GestureDetector(
          onTap: onCancelSelection,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$selectedCount seleccionado${selectedCount != 1 ? "s" : ""}',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.share_outlined, color: Colors.white, size: 18),
              SizedBox(width: 4),
              Text('Compartir',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

// Small icon button for island
class _IslandIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  final bool active;

  const _IslandIconBtn({
    required this.icon,
    required this.onTap,
    this.badge = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          if (badge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFCC02),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────
class _FilterBar extends StatefulWidget {
  final _MarketFilter filter;
  final List<PublicationDto> publications;
  final VoidCallback onChanged;

  const _FilterBar({
    required this.filter,
    required this.publications,
    required this.onChanged,
  });

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  static const _green = Color(0xFF00695C);

  RangeValues _priceRange = const RangeValues(0, 10000);

  double get _maxDetectedPrice {
    if (widget.publications.isEmpty) return 10000;

    final max = widget.publications
        .map((e) => e.price)
        .reduce((a, b) => a > b ? a : b);

    return max <= 1000 ? 1000 : max;
  }

  @override
  void initState() {
    super.initState();

    _priceRange = RangeValues(
      widget.filter.minPrice ?? 0,
      widget.filter.maxPrice ?? _maxDetectedPrice,
    );
  }

  @override
  Widget build(BuildContext context) {
    final purposes = widget.publications
        .map((p) => p.salePurpose)
        .toSet()
        .toList()
      ..sort();

    return Container(
      color: const Color(0xFFF2F4F5),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: _green,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filtros inteligentes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2332),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Encuentra el bovino ideal',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Propósito ───────────────────────────────────────────
            _sectionTitle('Propósito de venta'),

            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: purposes.map((purpose) {
                final isSelected =
                    widget.filter.salePurpose == purpose;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.filter.salePurpose =
                          isSelected ? null : purpose;
                    });

                    widget.onChanged();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _green
                          : const Color(0xFFF4F6F7),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? _green
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      purpose,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 26),

            // ── Precio ──────────────────────────────────────────────
            _sectionTitle('Rango de precio'),

            const SizedBox(height: 12),

            Row(
              children: [
                _priceBox(
                  'Mínimo',
                  _priceRange.start.toInt(),
                ),
                const SizedBox(width: 12),
                _priceBox(
                  'Máximo',
                  _priceRange.end.toInt(),
                ),
              ],
            ),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _green,
                inactiveTrackColor: _green.withValues(alpha: 0.12),
                thumbColor: _green,
                overlayColor: _green.withValues(alpha: 0.12),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8,
                ),
              ),
              child: RangeSlider(
                values: _priceRange,
                min: 0,
                max: _maxDetectedPrice,
                divisions: 20,
                labels: RangeLabels(
                  _priceRange.start.toInt().toString(),
                  _priceRange.end.toInt().toString(),
                ),
                onChanged: (values) {
                  setState(() {
                    _priceRange = values;

                    widget.filter.minPrice = values.start;
                    widget.filter.maxPrice = values.end;
                  });

                  widget.onChanged();
                },
              ),
            ),

            const SizedBox(height: 22),

            // ── Extras ──────────────────────────────────────────────
            _sectionTitle('Características'),

            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _modernToggle(
                  label: 'Con transporte',
                  icon: Icons.local_shipping_outlined,
                  active:
                      widget.filter.includesTransport == true,
                  onTap: () {
                    setState(() {
                      widget.filter.includesTransport =
                          widget.filter.includesTransport == true
                              ? null
                              : true;
                    });

                    widget.onChanged();
                  },
                ),
                _modernToggle(
                  label: 'Negociable',
                  icon: Icons.handshake_outlined,
                  active:
                      widget.filter.negotiable == true,
                  onTap: () {
                    setState(() {
                      widget.filter.negotiable =
                          widget.filter.negotiable == true
                              ? null
                              : true;
                    });

                    widget.onChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A2332),
      ),
    );
  }

  Widget _priceBox(String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'S/ $value',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2332),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modernToggle({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: active
              ? _green
              : const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active
                ? _green
                : Colors.grey.shade200,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active
                  ? Colors.white
                  : Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active
                    ? Colors.white
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ─── Active filter chips ──────────────────────────────────────────────────────
class _ActiveFilterChips extends StatelessWidget {
  final _MarketFilter filter;
  final VoidCallback onClear;
  final VoidCallback onRemoveOne;

  const _ActiveFilterChips({
    required this.filter,
    required this.onClear,
    required this.onRemoveOne,
  });

  static const _green = Color(0xFF00695C);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F4F5),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (filter.status != null)
                    _chip(filter.status!, () {
                      filter.status = null;
                      onRemoveOne();
                    }),
                  if (filter.salePurpose != null)
                    _chip(filter.salePurpose!, () {
                      filter.salePurpose = null;
                      onRemoveOne();
                    }),
                  if (filter.includesTransport == true)
                    _chip('Con transporte', () {
                      filter.includesTransport = null;
                      onRemoveOne();
                    }),
                  if (filter.negotiable == true)
                    _chip('Negociable', () {
                      filter.negotiable = null;
                      onRemoveOne();
                    }),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Limpiar',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _green.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: _green,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 13, color: _green),
          ),
        ],
      ),
    );
  }
}