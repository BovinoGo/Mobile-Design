import 'package:vacapp/features/animals/data/models/animal_dto.dart';
import 'package:vacapp/features/animals/data/repositories/animal_repository.dart';

class GetAnimalsByRanchId {
  final AnimalRepository repository;
  GetAnimalsByRanchId(this.repository);

  Future<List<AnimalDto>> call(String ranchId) async {
    // Fetches all user's bovines — filter by ranchId client-side if needed
    final all = await repository.getAnimals();
    return all.where((a) => a.ranchId == ranchId).toList();
  }
}
