import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class _MarketplacePageState extends State<MarketplacePage>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF00695C);
  static const _lightGreen = Color(0xFFE8F5E8);

  late TabController _tabController;
  String? _myUserId;
  String _accountType = '';
  String _role = '';

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
    if (_tabController.index == 0) {
      context.read<MarketplaceBloc>().add(LoadPublicationsEvent());
    } else {
      context.read<MarketplaceBloc>().add(LoadMyPublicationsEvent());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Mercado Bovino',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (_canPublish)
            IconButton(
              icon: const Icon(Icons.add_box_outlined, color: Colors.white),
              tooltip: 'Publicar bovino',
              onPressed: _goToPublish,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Mercado'),
            Tab(text: 'Mis Publicaciones'),
          ],
        ),
      ),
      body: BlocConsumer<MarketplaceBloc, MarketplaceState>(
        listener: (context, state) {
          if (state is MarketplaceOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: _green),
            );
          }
          if (state is MarketplaceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is MarketplaceLoading) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          if (state is PublicationsLoaded) {
            if (state.publications.isEmpty) {
              return _emptyState();
            }
            return TabBarView(
              controller: _tabController,
              children: [
                _listView(state.publications, showBuyButton: true),
                _listView(state.publications, showBuyButton: false),
              ],
            );
          }
          if (state is MarketplaceError) {
            return _errorState(state.message);
          }
          // Initial state — show empty tabs
          return TabBarView(
            controller: _tabController,
            children: [_emptyState(), _emptyState()],
          );
        },
      ),
    );
  }

  Widget _listView(List<PublicationDto> pubs, {required bool showBuyButton}) {
    if (pubs.isEmpty) return _emptyState();
    return RefreshIndicator(
      color: _green,
      onRefresh: () async => _load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pubs.length,
        itemBuilder: (_, i) =>
            _publicationCard(pubs[i], showBuyButton: showBuyButton),
      ),
    );
  }

  Widget _publicationCard(PublicationDto pub,
      {required bool showBuyButton}) {
    final isMine = pub.sellerId == _myUserId;
    final statusColor = _statusColor(pub.publicationStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _green.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: _lightGreen,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.storefront_outlined,
                    color: _green, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pub.title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _green)),
                    if (pub.description != null)
                      Text(pub.description!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(pub.publicationStatus,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _chip(Icons.attach_money,
                  '${pub.price.toStringAsFixed(0)} ${pub.currency}'),
              const SizedBox(width: 8),
              _chip(Icons.category_outlined, pub.salePurpose),
              if (pub.negotiablePrice) ...[
                const SizedBox(width: 8),
                _chip(Icons.handshake_outlined, 'Negociable',
                    color: Colors.orange.shade700),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (pub.includesTransport)
                _chip(Icons.local_shipping_outlined, 'Con transporte',
                    color: Colors.blue.shade700),
              const Spacer(),
              if (showBuyButton && !isMine &&
                  pub.publicationStatus == 'Publicada')
                ElevatedButton(
                  onPressed: () => _requestPurchaseDialog(pub),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Solicitar compra',
                      style: TextStyle(fontSize: 12)),
                ),
              if (isMine && pub.publicationStatus == 'Publicada')
                TextButton(
                  onPressed: () => context
                      .read<MarketplaceBloc>()
                      .add(CancelPublicationEvent(pub.id)),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Publicada':
        return Colors.green.shade700;
      case 'Reservada':
        return Colors.orange.shade700;
      case 'Vendida':
        return Colors.blue.shade700;
      case 'Cancelada':
        return Colors.red.shade700;
      case 'Expirada':
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _chip(IconData icon, String text, {Color? color}) {
    final c = color ?? _green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _requestPurchaseDialog(PublicationDto pub) {
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Comprar: ${pub.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Precio: ${pub.price.toStringAsFixed(0)} ${pub.currency}${pub.negotiablePrice ? " (negociable)" : ""}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              decoration: const InputDecoration(
                  labelText: 'Mensaje al vendedor (opcional)',
                  border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _green),
            onPressed: () {
              Navigator.pop(context);
              _myUserId != null
                  ? context.read<MarketplaceBloc>().add(RequestPurchaseEvent(
                        publicationId: pub.id,
                        buyerId: _myUserId!,
                        message: msgCtrl.text.trim().isEmpty
                            ? null
                            : msgCtrl.text.trim(),
                      ))
                  : null;
            },
            child: const Text('Enviar solicitud',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
                color: _lightGreen, shape: BoxShape.circle),
            child: const Icon(Icons.storefront_outlined,
                size: 60, color: _green),
          ),
          const SizedBox(height: 20),
          const Text('Sin publicaciones',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: _green)),
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
        ],
      ),
    );
  }

  Widget _errorState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
                backgroundColor: _green, foregroundColor: Colors.white),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
