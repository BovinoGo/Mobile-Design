abstract class RanchEvent {
  const RanchEvent();
}

class LoadRanchesEvent extends RanchEvent {}

class CreateRanchEvent extends RanchEvent {
  final Map<String, dynamic> body;
  const CreateRanchEvent(this.body);
}

class DeactivateRanchEvent extends RanchEvent {
  final String id;
  const DeactivateRanchEvent(this.id);
}
