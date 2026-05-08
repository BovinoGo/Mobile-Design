abstract class WorkerEvent {
  const WorkerEvent();
}

class LoadWorkersEvent extends WorkerEvent {
  final String companyId;
  const LoadWorkersEvent(this.companyId);
}

class CreateWorkerEvent extends WorkerEvent {
  final Map<String, dynamic> body;
  const CreateWorkerEvent(this.body);
}

class DeactivateWorkerEvent extends WorkerEvent {
  final String id;
  final String companyId;
  const DeactivateWorkerEvent(this.id, this.companyId);
}
