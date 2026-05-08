import 'package:flutter/material.dart';
import 'package:vacapp/features/animals/data/repositories/animal_repository.dart';

Future<void> showDeleteAnimalDialog({
  required BuildContext context,
  required String animalId,
  required AnimalRepository repository,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Desactivar Bovino'),
      content: const Text('¿Seguro que deseas desactivar este bovino?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child:
              const Text('Desactivar', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await repository.deactivateAnimal(animalId);
  }
}
