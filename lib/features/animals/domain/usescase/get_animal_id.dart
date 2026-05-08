import 'package:vacapp/features/animals/data/models/animal_dto.dart';
import 'package:vacapp/features/animals/data/repositories/animal_repository.dart';

class GetAnimalById {
  final AnimalRepository repository;
  GetAnimalById(this.repository);

  Future<AnimalDto> call(String id) async {
    return await repository.getAnimalById(id);
  }
}
