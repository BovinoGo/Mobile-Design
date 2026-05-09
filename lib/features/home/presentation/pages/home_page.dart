import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/home/presentation/blocs/statistics_bloc.dart';
import 'package:vacapp/features/home/presentation/widgets/welcome_header.dart';
import 'package:vacapp/features/home/presentation/widgets/animals_overview_widget.dart';
import 'package:vacapp/features/home/presentation/widgets/alert_stats_card.dart';
import 'package:vacapp/features/home/presentation/widgets/ranches_overview_widget.dart';
import 'package:vacapp/features/home/presentation/widgets/marketplace_overview_widget.dart';

class HomePage extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  const HomePage({super.key, this.onNavigateToTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color backgroundColor = Color(0xFFF8F9FA);
  final ScrollController _scrollController = ScrollController();
  String _accountType = '';

  @override
  void initState() {
    super.initState();
    TokenService.instance.getAccountType().then((v) {
      if (mounted) setState(() => _accountType = v);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isBuyer => _accountType == 'BuyerCustomer';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _isBuyer
          ? (StatisticsBloc()) // don't load stats for buyer
          : (StatisticsBloc()..add(LoadStatistics())),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 130),

                    // Stats panel — oculto para BuyerCustomer
                    if (!_isBuyer)
                      BlocBuilder<StatisticsBloc, StatisticsState>(
                        builder: (context, state) {
                          if (state is StatisticsLoading) {
                            return Container(
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(
                                        color: Color(0xFF00695C)),
                                    SizedBox(height: 16),
                                    Text('Cargando estadísticas...'),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (state is StatisticsError) {
                            return Container(
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red.shade400),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(state.message,
                                        style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 13)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh,
                                        color: Color(0xFF00695C)),
                                    onPressed: () => context
                                        .read<StatisticsBloc>()
                                        .add(RefreshStatistics()),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (state is StatisticsLoaded) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  AlertStatsCard(statistics: state.statistics),
                                  const AnimalsOverviewWidget(),
                                ],
                              ),
                            );
                          }

                          return const SizedBox(height: 20);
                        },
                      ),

                    // Ranchos — oculto para BuyerCustomer
                    if (!_isBuyer)
                      RanchesOverviewWidget(
                          onNavigateToTab: widget.onNavigateToTab),

                    // Mercado — visible para todos
                    MarketplaceOverviewWidget(
                        onNavigateToTab: widget.onNavigateToTab,
                        isBuyer: _isBuyer),

                    const SizedBox(height: 120),
                  ],
                ),
              ),

              WelcomeHeader(scrollController: _scrollController),
            ],
          ),
        ),
      ),
    );
  }
}
