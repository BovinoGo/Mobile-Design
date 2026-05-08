import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vacapp/features/vaccines/data/models/vaccines_dto.dart';
import 'package:vacapp/features/vaccines/data/repositories/vaccines_repository.dart';
import 'package:vacapp/features/vaccines/data/datasources/vaccine_types_service.dart';
import 'package:vacapp/features/animals/data/models/animal_dto.dart';
import 'package:vacapp/features/animals/data/dataasources/animals_service.dart';
import 'package:vacapp/core/widgets/island_notification.dart';
import 'package:vacapp/features/vaccines/presentation/widgets/vaccine_dropdown.dart';
import 'package:vacapp/features/vaccines/presentation/widgets/animal_dropdown.dart';

class CreateVaccinesPage extends StatefulWidget {
  final VaccinesRepository repository;

  const CreateVaccinesPage({super.key, required this.repository});

  @override
  State<CreateVaccinesPage> createState() => _CreateVaccinesPageState();
}

class _CreateVaccinesPageState extends State<CreateVaccinesPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  bool _isLoading = false;
  bool _useDefaultImageUrl = false;

  // URL de imagen predeterminada
  static const String defaultImageUrl = 'https://res.cloudinary.com/dgcgdxn0u/image/upload/v1751348101/xiynxh6vlqy4ykjezhul.png';

  // Campos para los dropdowns
  String? _selectedVaccineName;
  String? _selectedAnimalId;
  List<VaccineTypeDto> _availableVaccines = [];
  List<AnimalDto> _availableAnimals = [];
  VaccineTypeDto? _selectedVaccineInfo;
  final VaccineTypesService _vaccineTypesService = VaccineTypesService();
  final AnimalsService _animalsService = AnimalsService();

  // Paleta institucional
  static const Color primary = Color(0xFF00695C);
  static const Color lightGreen = Color(0xFFE8F5E8);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Cargar tipos de vacunas y animales
      final vaccineTypes = await _vaccineTypesService.fetchVaccineTypes();
      final animals = await _animalsService.fetchAnimals();

      if (mounted) {
        setState(() {
          _availableVaccines = vaccineTypes;
          _availableAnimals = animals;
        });
      }
    } catch (e) {
      debugPrint('[DEBUG] Error loading initial data: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)), // 5 años en el futuro
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();
    
    // Mostrar action sheet estilo Cupertino
    final ImageSource? source = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text(
          'Seleccionar imagen',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        message: const Text('Elige cómo quieres agregar la imagen de la vacuna'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text(
              'Tomar foto',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text(
              'Elegir de galería',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _useDefaultImage();
            },
            child: const Text(
              'Usar imagen predeterminada',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: const Text(
            'Cancelar',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    }
  }

  void _useDefaultImage() {
    setState(() {
      _selectedImage = null; // Marcar que se usará imagen predeterminada
      _useDefaultImageUrl = true; // Flag para indicar uso de imagen por defecto
    });
    
    // Mostrar confirmación al usuario
    IslandNotification.showSuccess(
      context, 
      message: 'Se usará la imagen predeterminada de la vacuna'
    );
  }

  Future<void> _createVaccine() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVaccineName == null || _selectedVaccineInfo == null) {
      IslandNotification.showError(context, message: 'Por favor selecciona una vacuna');
      return;
    }

    if (_selectedAnimalId == null) {
      IslandNotification.showError(context, message: 'Por favor selecciona un animal');
      return;
    }

    if (_selectedImage == null && !_useDefaultImageUrl) {
      IslandNotification.showError(context, message: 'Por favor selecciona una imagen o usa la imagen predeterminada');
      return;
    }

    // Validar restricciones de género
    final selectedAnimal = _availableAnimals.firstWhere((a) => a.id == _selectedAnimalId);
    if (_selectedVaccineInfo!.isOnlyForFemales) {
      final isFemale = selectedAnimal.gender.toLowerCase() == 'female' || 
                      selectedAnimal.gender.toLowerCase() == 'hembra';
      if (!isFemale) {
        final genderText = _formatGender(selectedAnimal.gender);
        IslandNotification.showError(
          context,
          message: 'Esta vacuna es solo para hembras. El animal seleccionado es $genderText',
        );
        return;
      }
    }

    // Validar edad del animal
    try {
      final birthDate = DateTime.parse(selectedAnimal.birthDate);
      final isAgeValid = _vaccineTypesService.validateMinimumAge(
        _selectedVaccineInfo!.ageRecommended, 
        birthDate
      );
      
      if (!isAgeValid) {
        IslandNotification.showError(
          context, 
          message: 'El animal no cumple con la edad mínima recomendada: ${_selectedVaccineInfo!.ageRecommended}'
        );
        return;
      }
    } catch (e) {
      debugPrint('[DEBUG] Error validating age: $e');
    }

    setState(() {
      _isLoading = true;
    });

    try {      
      final vaccine = VaccinesDto(
        id: 0, // Se asignará en el backend
        name: _selectedVaccineName!,
        vaccineType: _selectedVaccineInfo!.type,
        vaccineDate: _selectedDate.toIso8601String().split('T')[0],
        vaccineImg: _useDefaultImageUrl ? defaultImageUrl : '', // Usar imagen predeterminada o asignar después
        bovineId: int.tryParse(_selectedAnimalId!) ?? 0,
      );

      if (_useDefaultImageUrl) {
        // Para la imagen predeterminada, crear la vacuna con la URL directamente
        await widget.repository.createVaccineWithUrl(vaccine);
      } else {
        // Para imagen seleccionada por el usuario
        await widget.repository.createVaccine(vaccine, _selectedImage!);
      }
      
      if (mounted) {
        // Haptic feedback para éxito
        HapticFeedback.mediumImpact();
        
        // Mostrar notificación de éxito
        IslandNotification.showSuccess(
          context, 
          message: 'Vacuna creada exitosamente para ${_getAnimalName(_selectedAnimalId!)}'
        );
        
        // Esperar un poco para que se vea la notificación antes de cerrar
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        // Haptic feedback para error
        HapticFeedback.lightImpact();
        IslandNotification.showError(context, message: 'Error al crear vacuna: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper para obtener el nombre del animal
  String _getAnimalName(String animalId) {
    try {
      final animal = _availableAnimals.firstWhere((a) => a.id == animalId);
      return animal.displayName;
    } catch (e) {
      return 'Animal #$animalId';
    }
  }

  // Helper para calcular la edad del animal
  String _calculateAge(String birthDateStr) {
    try {
      final birthDate = DateTime.parse(birthDateStr);
      final now = DateTime.now();
      final difference = now.difference(birthDate);
      
      final years = (difference.inDays / 365).floor();
      final months = ((difference.inDays % 365) / 30).floor();
      
      if (years > 0) {
        if (months > 0) {
          return '$years año${years > 1 ? 's' : ''} y $months mes${months > 1 ? 'es' : ''}';
        }
        return '$years año${years > 1 ? 's' : ''}';
      } else if (months > 0) {
        return '$months mes${months > 1 ? 'es' : ''}';
      } else {
        final days = difference.inDays;
        return '$days día${days > 1 ? 's' : ''}';
      }
    } catch (e) {
      return 'Edad no disponible';
    }
  }

  // Helper para formatear el género
  String _formatGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
      case 'macho':
        return 'Macho';
      case 'female':
      case 'hembra':
        return 'Hembra';
      default:
        return gender;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8F9FA),
              lightGreen.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Aviso informativo
              _buildInfoBanner(),
              
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Imagen
                        _buildImagePicker(),
                        const SizedBox(height: 24),
                        
                        // Nombre de vacuna (Dropdown)
                        VaccineDropdown(
                          selectedVaccine: _selectedVaccineInfo,
                          vaccines: _availableVaccines,
                          onChanged: (VaccineTypeDto? vaccine) {
                            setState(() {
                              _selectedVaccineInfo = vaccine;
                              _selectedVaccineName = vaccine?.name;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor selecciona una vacuna';
                            }
                            return null;
                          },
                        ),
                        
                        // Banner informativo de la vacuna seleccionada
                        if (_selectedVaccineInfo != null)
                          _buildVaccineInfoBanner(),
                        
                        const SizedBox(height: 16),
                        
                        // Animal (Dropdown con información)
                        AnimalDropdown(
                          selectedAnimalId: _selectedAnimalId,
                          animals: _availableAnimals,
                          onChanged: (String? animalId) {
                            setState(() {
                              _selectedAnimalId = animalId;
                            });
                          },
                          genderFilter: _selectedVaccineInfo?.isOnlyForFemales == true 
                            ? (animal) {
                                final isFemale = animal.gender.toLowerCase() == 'female' || 
                                               animal.gender.toLowerCase() == 'hembra';
                                return !isFemale ? 'Esta vacuna es solo para hembras' : null;
                              }
                            : null,
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor selecciona un animal';
                            }
                            return null;
                          },
                        ),
                        
                        // Aviso explicativo sobre bovinos
                        _buildBovineExplanationBanner(),
                        
                        const SizedBox(height: 16),
                        
                        // Fecha
                        _buildDatePicker(),
                        const SizedBox(height: 32),
                        
                        // Botón de crear
                        _buildCreateButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Nueva Vacuna',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _selectImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedImage != null ? primary : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _selectedImage != null
              ? Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              : _useDefaultImageUrl
                  ? Image.network(
                      defaultImageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: lightGreen,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.vaccines_outlined,
                                size: 48,
                                color: primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Imagen predeterminada',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(
                      color: lightGreen.withValues(alpha: 0.3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toca para agregar imagen',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                ],
              ),
      ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha de vencimiento',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(
                    color: primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _createVaccine,
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Crear Vacuna',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.teal.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tip: Vacunando múltiples animales',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Después de crear la vacuna, podrás agregar más animales usando "Ver más" en la lista.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Colors.amber.shade600,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBovineExplanationBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightGreen.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¿Por qué seleccionar un bovino? En ganadería, cada vacuna se registra por animal individual para llevar un control preciso del historial médico y cumplir con regulaciones sanitarias.',
                  style: TextStyle(
                    fontSize: 11,
                    color: primary.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          if (_selectedAnimalId != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pets,
                    color: Colors.blue.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Animal seleccionado: ${_getAnimalName(_selectedAnimalId!)} - Edad: ${_calculateAge(_availableAnimals.firstWhere((a) => a.id == _selectedAnimalId).birthDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVaccineInfoBanner() {
    if (_selectedVaccineInfo == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.indigo.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.vaccines_outlined,
                  color: Colors.blue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Información de la vacuna',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildVaccineInfoRow('Frecuencia', _selectedVaccineInfo!.frequency),
          const SizedBox(height: 8),
          _buildVaccineInfoRow('Edad recomendada', _selectedVaccineInfo!.ageRecommended),
          if (_selectedVaccineInfo!.isOnlyForFemales) ...[
            const SizedBox(height: 8),
            _buildVaccineInfoRow('Restricción', 'Solo para hembras', isWarning: true),
          ],
        ],
      ),
    );
  }

  Widget _buildVaccineInfoRow(String label, String value, {bool isWarning = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isWarning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
          size: 16,
          color: isWarning ? Colors.orange.shade600 : Colors.blue.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isWarning ? Colors.orange.shade700 : Colors.blue.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: isWarning ? Colors.orange.shade600 : Colors.blue.shade600,
            ),
          ),
        ),
      ],
    );
  }
}
