import 'package:vacapp/features/ranches/data/models/ranch_dto.dart';

abstract class RanchState {
  const RanchState();
}

class RanchInitial extends RanchState {}

class RanchLoading extends RanchState {}

class RanchLoaded extends RanchState {
  final List<RanchDto> ranches;
  const RanchLoaded(this.ranches);
}

class RanchOperationSuccess extends RanchState {
  final String message;
  const RanchOperationSuccess(this.message);
}

class RanchError extends RanchState {
  final String message;
  const RanchError(this.message);
}
