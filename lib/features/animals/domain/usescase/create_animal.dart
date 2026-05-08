import 'dart:io';
import 'package:vacapp/features/animals/data/repositories/animal_repository.dart';

class CreateAnimal {
  final AnimalRepository repository;
  CreateAnimal(this.repository);

  Future<void> call(Map<String, dynamic> body, {File? imageFile}) async {
    await repository.createAnimal(body, imageFile: imageFile);
  }
}
