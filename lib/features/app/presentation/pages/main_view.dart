import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/animals/presentation/pages/animal_page.dart';
import 'package:vacapp/features/home/presentation/pages/home_page.dart';
import 'package:vacapp/features/home/presentation/pages/gestion_page.dart';
import 'package:vacapp/features/marketplace/data/datasources/marketplace_service.dart';
import 'package:vacapp/features/marketplace/data/repositories/marketplace_repository.dart';
import 'package:vacapp/features/marketplace/presentation/blocs/marketplace_bloc.dart';
import 'package:vacapp/features/marketplace/presentation/blocs/marketplace_event.dart';
import 'package:vacapp/features/marketplace/presentation/pages/marketplace_page.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int _selectedIndex = 0;
  String _accountType = '';

  static const Color _accent = Color(0xFF00695C);
  static const Color _lightAccent = Color(0xFF4DB6AC);
  static const Color _background = Color(0xFF0F0F0F);
  static const Color _surface = Color(0xFF2D2D2D);
  static const Color _textSecondary = Color(0xFFB0B0B0);

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final accountType = await TokenService.instance.getAccountType();
    if (mounted) setState(() => _accountType = accountType);
  }

  bool get _isBuyer => _accountType == 'BuyerCustomer';

  List<Map<String, dynamic>> get _menuItems {
    if (_isBuyer) {
      return const [
        {'icon': Icons.home_rounded, 'label': 'Inicio'},
        {'icon': Icons.storefront_rounded, 'label': 'Mercado'},
      ];
    }
    return const [
      {'icon': Icons.home_rounded, 'label': 'Inicio'},
      {'icon': Icons.pets_rounded, 'label': 'Bovinos'},
      {'icon': Icons.storefront_rounded, 'label': 'Mercado'},
      {'icon': Icons.admin_panel_settings_rounded, 'label': 'Gestión'},
    ];
  }

  Widget _buildBody() {
    if (_isBuyer) {
      return switch (_selectedIndex) {
        0 => HomePage(onNavigateToTab: (i) {
            // Buyer has 2 tabs: 0=Inicio, 1=Mercado
            // Map marketplace (tab 2 in full nav) to tab 1 for buyer
            if (i == 2) setState(() => _selectedIndex = 1);
          }),
        1 => BlocProvider(
            create: (_) => MarketplaceBloc(
                    MarketplaceRepository(MarketplaceService()))
                ..add(LoadPublicationsEvent()),
            child: const MarketplacePage(),
          ),
        _ => const SizedBox.shrink(),
      };
    }

    return switch (_selectedIndex) {
      0 => HomePage(onNavigateToTab: (i) => setState(() => _selectedIndex = i)),
      1 => const AnimalPage(),
      2 => BlocProvider(
          create: (_) => MarketplaceBloc(
                  MarketplaceRepository(MarketplaceService()))
              ..add(LoadPublicationsEvent()),
          child: const MarketplacePage(),
        ),
      3 => const GestionPage(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Show loading shimmer until role is known
    if (_accountType.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00695C))),
      );
    }

    final items = _menuItems;

    return Scaffold(
      backgroundColor: _background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_background, Color(0xFF1A1A1A), Color(0xFF242424)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeInOutCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0.04, 0), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: animation, curve: Curves.easeOutQuart)),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_selectedIndex),
                child: _buildBody(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _surface.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: _accent.withValues(alpha: 0.2), width: 1),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8)),
                        BoxShadow(
                            color: _accent.withValues(alpha: 0.08),
                            blurRadius: 30),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(items.length, (i) {
                        final selected = _selectedIndex == i;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedIndex = i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: EdgeInsets.symmetric(
                                horizontal: selected ? 14 : 10, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? const LinearGradient(
                                      colors: [_accent, _lightAccent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                          color: _accent.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4))
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  items[i]['icon'] as IconData,
                                  color: selected ? Colors.white : _textSecondary,
                                  size: selected ? 22 : 20,
                                ),
                                if (selected) ...[
                                  const SizedBox(width: 7),
                                  Text(
                                    items[i]['label'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
