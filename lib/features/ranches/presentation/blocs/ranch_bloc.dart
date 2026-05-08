import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/features/ranches/data/repositories/ranch_repository.dart';
import 'package:vacapp/features/ranches/presentation/blocs/ranch_event.dart';
import 'package:vacapp/features/ranches/presentation/blocs/ranch_state.dart';

class RanchBloc extends Bloc<RanchEvent, RanchState> {
  final RanchRepository _repository;

  RanchBloc(this._repository) : super(RanchInitial()) {
    on<LoadRanchesEvent>(_onLoad);
    on<CreateRanchEvent>(_onCreate);
    on<DeactivateRanchEvent>(_onDeactivate);
  }

  Future<void> _onLoad(LoadRanchesEvent event, Emitter<RanchState> emit) async {
    emit(RanchLoading());
    try {
      final ranches = await _repository.getMine();
      emit(RanchLoaded(ranches));
    } catch (e) {
      emit(RanchError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreate(CreateRanchEvent event, Emitter<RanchState> emit) async {
    emit(RanchLoading());
    try {
      await _repository.create(event.body);
      emit(const RanchOperationSuccess('Rancho creado exitosamente'));
      add(LoadRanchesEvent());
    } catch (e) {
      emit(RanchError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeactivate(
      DeactivateRanchEvent event, Emitter<RanchState> emit) async {
    emit(RanchLoading());
    try {
      await _repository.deactivate(event.id);
      emit(const RanchOperationSuccess('Rancho desactivado'));
      add(LoadRanchesEvent());
    } catch (e) {
      emit(RanchError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
