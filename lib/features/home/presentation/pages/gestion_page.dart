import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/ranches/data/datasources/ranch_service.dart';
import 'package:vacapp/features/ranches/data/repositories/ranch_repository.dart';
import 'package:vacapp/features/ranches/presentation/blocs/ranch_bloc.dart';
import 'package:vacapp/features/ranches/presentation/blocs/ranch_event.dart';
import 'package:vacapp/features/ranches/presentation/pages/ranch_page.dart';
import 'package:vacapp/features/workers/data/datasources/worker_service.dart';
import 'package:vacapp/features/workers/data/repositories/worker_repository.dart';
import 'package:vacapp/features/workers/presentation/blocs/worker_bloc.dart';
import 'package:vacapp/features/workers/presentation/blocs/worker_event.dart';
import 'package:vacapp/features/workers/presentation/pages/workers_page.dart';

class GestionPage extends StatefulWidget {
  const GestionPage({super.key});

  @override
  State<GestionPage> createState() => _GestionPageState();
}

class _GestionPageState extends State<GestionPage>
    with TickerProviderStateMixin {
  static const _green = Color(0xFF00695C);
  static const _lightGreen = Color(0xFFE8F5E8);

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  String? _accountType;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _slideCtrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this);
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    _slideCtrl.forward();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final accountType = await TokenService.instance.getAccountType();
    final userId = await TokenService.instance.getUserId();
    if (mounted) {
      setState(() {
        _accountType = accountType;
        _userId = userId;
      });
    }
  }

  bool get _isCompany => _accountType == 'LivestockCompany';
  bool get _isBuyer => _accountType == 'BuyerCustomer';

  List<Map<String, dynamic>> get _options => [
    {
      'title': 'Ranchos',
      'subtitle': 'Gestiona tus ranchos y propiedades ganaderas',
      'icon': Icons.home_work_outlined,
      'gradient': [const Color(0xFF00695C), const Color(0xFF004D40)],
      'action': 'ranches',
    },
    if (_isCompany)
      {
        'title': 'Trabajadores',
        'subtitle': 'Administra el personal de tu empresa ganadera',
        'icon': Icons.people_outline,
        'gradient': [const Color(0xFF00796B), const Color(0xFF004D40)],
        'action': 'workers',
      },
  ];

  void _handleTap(String action) {
    HapticFeedback.mediumImpact();
    if (action == 'ranches') _goToRanches();
    if (action == 'workers') _goToWorkers();
  }

  void _goToRanches() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) =>
              RanchBloc(RanchRepository(RanchService()))..add(LoadRanchesEvent()),
          child: const RanchPage(),
        ),
      ),
    );
  }

  void _goToWorkers() {
    if (_userId == null || _userId!.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => WorkerBloc(WorkerRepository(WorkerService()))
            ..add(LoadWorkersEvent(_userId!)),
          child: WorkersPage(companyId: _userId!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8F9FA),
              _lightGreen.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 28),
                    Expanded(child: _isBuyer ? _buildBuyerLocked() : _buildOptions()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_green, Color(0xFF004D40)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _green.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings,
                size: 30, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gestión',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(
                  'Administra recursos y personal',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    final opts = _options;
    if (opts.isEmpty) {
      return Center(
        child: Text('Cargando opciones...',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: opts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) {
        final opt = opts[i];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 500 + i * 150),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (_, v, __) => Transform.translate(
            offset: Offset(0, 24 * (1 - v)),
            child: Opacity(opacity: v, child: _optionCard(opt)),
          ),
        );
      },
    );
  }

  Widget _optionCard(Map<String, dynamic> opt) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _handleTap(opt['action'] as String),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: _green.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 7)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: (opt['gradient'] as List).cast<Color>(),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: (opt['gradient'] as List<Color>)[0]
                            .withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Icon(opt['icon'] as IconData,
                    size: 28, color: Colors.white),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt['title'] as String,
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: _green)),
                    const SizedBox(height: 4),
                    Text(opt['subtitle'] as String,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_forward_ios,
                    size: 14, color: _green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuyerLocked() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, size: 56, color: _green),
          ),
          const SizedBox(height: 20),
          const Text(
            'Acceso restringido',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: _green),
          ),
          const SizedBox(height: 8),
          Text(
            'Las cuentas de tipo Comprador no tienen\nacceso a la gestión de ranchos ni trabajadores.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
