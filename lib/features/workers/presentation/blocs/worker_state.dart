import 'package:vacapp/features/workers/data/models/worker_dto.dart';

abstract class WorkerState {
  const WorkerState();
}

class WorkerInitial extends WorkerState {}

class WorkerLoading extends WorkerState {}

class WorkerLoaded extends WorkerState {
  final List<WorkerDto> workers;
  const WorkerLoaded(this.workers);
}

class WorkerOperationSuccess extends WorkerState {
  final String message;
  const WorkerOperationSuccess(this.message);
}

class WorkerError extends WorkerState {
  final String message;
  const WorkerError(this.message);
}
