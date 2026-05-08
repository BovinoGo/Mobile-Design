import 'package:vacapp/features/animals/data/repositories/animal_repository.dart';

class DeleteAnimal {
  final AnimalRepository repository;
  DeleteAnimal(this.repository);

  Future<void> call(String id) async {
    await repository.deactivateAnimal(id);
  }
}
