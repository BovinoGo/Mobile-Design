import 'package:vacapp/features/animals/data/repositories/animal_repository.dart';

class UpdateAnimal {
  final AnimalRepository repository;
  UpdateAnimal(this.repository);

  Future<void> call(String id, Map<String, dynamic> data) async {
    await repository.updateAnimal(id, data);
  }
}
