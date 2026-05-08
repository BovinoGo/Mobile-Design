import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/features/workers/data/repositories/worker_repository.dart';
import 'package:vacapp/features/workers/presentation/blocs/worker_event.dart';
import 'package:vacapp/features/workers/presentation/blocs/worker_state.dart';

class WorkerBloc extends Bloc<WorkerEvent, WorkerState> {
  final WorkerRepository _repository;

  WorkerBloc(this._repository) : super(WorkerInitial()) {
    on<LoadWorkersEvent>(_onLoad);
    on<CreateWorkerEvent>(_onCreate);
    on<DeactivateWorkerEvent>(_onDeactivate);
  }

  Future<void> _onLoad(
      LoadWorkersEvent event, Emitter<WorkerState> emit) async {
    emit(WorkerLoading());
    try {
      final workers = await _repository.getByCompany(event.companyId);
      emit(WorkerLoaded(workers));
    } catch (e) {
      emit(WorkerError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreate(
      CreateWorkerEvent event, Emitter<WorkerState> emit) async {
    emit(WorkerLoading());
    try {
      await _repository.create(event.body);
      emit(const WorkerOperationSuccess('Trabajador registrado exitosamente'));
      final companyId = event.body['companyId'] as String?;
      if (companyId != null) add(LoadWorkersEvent(companyId));
    } catch (e) {
      emit(WorkerError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeactivate(
      DeactivateWorkerEvent event, Emitter<WorkerState> emit) async {
    emit(WorkerLoading());
    try {
      await _repository.deactivate(event.id);
      emit(const WorkerOperationSuccess('Trabajador desactivado'));
      add(LoadWorkersEvent(event.companyId));
    } catch (e) {
      emit(WorkerError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
