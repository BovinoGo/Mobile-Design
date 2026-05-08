import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/features/animals/data/dataasources/animals_service.dart';
import 'package:vacapp/features/animals/data/models/animal_dto.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class StatisticsEvent {
  const StatisticsEvent();
}

class LoadStatistics extends StatisticsEvent {}

class RefreshStatistics extends StatisticsEvent {}

// ── States ────────────────────────────────────────────────────────────────────
abstract class StatisticsState {
  const StatisticsState();
}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {}

class StatisticsLoaded extends StatisticsState {
  final HomeStatistics statistics;
  const StatisticsLoaded(this.statistics);
}

class StatisticsError extends StatisticsState {
  final String message;
  const StatisticsError(this.message);
}

class StatisticsOffline extends StatisticsState {
  const StatisticsOffline();
}

// ── Data model ────────────────────────────────────────────────────────────────
class HomeStatistics {
  final List<AnimalDto> animals;
  final List<CriticalAlertDto> alerts;

  const HomeStatistics({required this.animals, required this.alerts});

  // Bovine counts
  int get totalBovines => animals.length;
  int get activeBovines => animals.where((a) => a.isActive).length;
  int get maleBovines =>
      animals.where((a) => a.sex.toLowerCase() == 'male').length;
  int get femaleBovines =>
      animals.where((a) => a.sex.toLowerCase() == 'female').length;

  // Health
  int get healthyBovines =>
      animals.where((a) => a.healthStatus == 'Sano').length;
  int get sickBovines =>
      animals.where((a) => a.healthStatus != 'Sano' && a.isActive).length;
  int get criticalBovines =>
      animals.where((a) => a.vitalSignsStatus == 'Critico').length;

  // Backward-compat aliases used by existing home widgets
  int get totalAnimals => totalBovines;
  int get maleAnimals => maleBovines;
  int get femaleAnimals => femaleBovines;
  int get totalStables => 0;
  int get totalCapacity => 0;
  double get occupationPercentage => 0;
  int get totalVaccines => 0;
  int get appliedVaccines => 0;
  int get pendingVaccines => 0;
  int get animalsWithVaccines => 0;
  double get vaccinationPercentage => 0;
  List<AnimalDto> get animalsInQuarantineList => [];
  List<AnimalDto> get animalsInMaternityList => [];
  List<AnimalDto> get animalsWithVetAppointmentList => [];

  // Weight
  double get avgWeightKg {
    if (animals.isEmpty) return 0;
    return animals.fold(0.0, (s, a) => s + a.currentWeightKg) / animals.length;
  }

  // Alerts
  int get unreadAlerts => alerts.where((a) => !a.isRead).length;
  int get totalAlerts => alerts.length;

  // Distributions
  Map<String, int> get breedDistribution {
    final dist = <String, int>{};
    for (final a in animals) {
      dist[a.breed] = (dist[a.breed] ?? 0) + 1;
    }
    return dist;
  }

  Map<String, int> get healthDistribution {
    final dist = <String, int>{};
    for (final a in animals) {
      dist[a.healthStatus] = (dist[a.healthStatus] ?? 0) + 1;
    }
    return dist;
  }

  // Compat for AlertStatsCard: maps critical bovines to the old "without vaccines" concept
  int get animalsWithoutVaccines => criticalBovines + unreadAlerts;
  List<AnimalDto> get animalsWithoutVaccinesList =>
      animals.where((a) => a.vitalSignsStatus == 'Critico').toList();
}

// ── Bloc ──────────────────────────────────────────────────────────────────────
class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final AnimalsService _animalsService;

  StatisticsBloc({AnimalsService? animalsService})
      : _animalsService = animalsService ?? AnimalsService(),
        super(StatisticsInitial()) {
    on<LoadStatistics>(_onLoad);
    on<RefreshStatistics>(_onLoad);
  }

  Future<void> _onLoad(
      StatisticsEvent event, Emitter<StatisticsState> emit) async {
    try {
      emit(StatisticsLoading());
      final results = await Future.wait([
        _animalsService.fetchAnimals(),
        _animalsService.fetchUnreadAlerts(),
      ]);
      final animals = results[0] as List<AnimalDto>;
      final alerts = results[1] as List<CriticalAlertDto>;
      emit(StatisticsLoaded(HomeStatistics(animals: animals, alerts: alerts)));
    } catch (e) {
      emit(StatisticsError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
