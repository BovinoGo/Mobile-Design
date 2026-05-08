import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vacapp/features/vaccines/data/models/vaccines_dto.dart';
import 'package:vacapp/features/vaccines/data/repositories/vaccines_repository.dart';
import 'package:vacapp/features/vaccines/data/datasources/vaccine_types_service.dart';
import 'package:vacapp/features/animals/data/models/animal_dto.dart';
import 'package:vacapp/features/animals/data/dataasources/animals_service.dart';
import 'package:vacapp/core/widgets/island_notification.dart';
import 'package:vacapp/features/vaccines/presentation/widgets/vaccine_dropdown.dart';
import 'package:vacapp/features/vaccines/presentation/widgets/animal_dropdown.dart';

class UpdateVaccinesPage extends StatefulWidget {
  final VaccinesRepository repository;
  final VaccinesDto vaccine;

  const UpdateVaccinesPage({
    super.key,
    required this.repository,
    required this.vaccine,
  });

  @override
  State<UpdateVaccinesPage> createState() => _UpdateVaccinesPageState();
}

class _UpdateVaccinesPageState extends State<UpdateVaccinesPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  bool _isLoading = false;
  bool _useDefaultImageUrl = false;

  // URL de imagen predeterminada
  static const String defaultImageUrl = 'https://res.cloudinary.com/dgcgdxn0u/image/upload/v1751348101/xiynxh6vlqy4ykjezhul.png';

  // Campos para los dropdowns
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
    _selectedDate = DateTime.tryParse(widget.vaccine.vaccineDate) ?? DateTime.now();
    _selectedAnimalId = widget.vaccine.bovineId.toString();
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
          
          // Buscar la vacuna seleccionada actual
          try {
            _selectedVaccineInfo = vaccineTypes.firstWhere(
              (v) => v.name == widget.vaccine.vaccineType,
            );
          } catch (e) {
            // Si no se encuentra, usar la primera disponible
            _selectedVaccineInfo = vaccineTypes.isNotEmpty ? vaccineTypes.first : null;
          }
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

  Future<void> _updateVaccine() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAnimalId == null) {
      IslandNotification.showError(context, message: 'Por favor selecciona un animal');
      return;
    }

    if (_selectedVaccineInfo == null) {
      IslandNotification.showError(context, message: 'Por favor selecciona una vacuna');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'name': widget.vaccine.name, // Mantener el nombre original o usar el de la vacuna seleccionada
        'vaccineType': _selectedVaccineInfo!.name,
        'vaccineDate': _selectedDate.toIso8601String().split('T')[0],
        'vaccineImg': _useDefaultImageUrl ? defaultImageUrl : widget.vaccine.vaccineImg, // Usar imagen predeterminada si se seleccionó
        'bovineId': int.tryParse(_selectedAnimalId!) ?? 0,
      };

      await widget.repository.updateVaccine(
        widget.vaccine.id,
        data,
        _selectedImage,
      );
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        IslandNotification.showError(context, message: 'Error al actualizar vacuna: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                        
                        // Dropdown de Animales
                        AnimalDropdown(
                          selectedAnimalId: _selectedAnimalId,
                          animals: _availableAnimals,
                          onChanged: (animalId) {
                            setState(() {
                              _selectedAnimalId = animalId;
                            });
                          },
                          validator: (animalId) {
                            if (animalId == null) {
                              return 'Por favor selecciona un animal';
                            }
                            return null;
                          },
                        ),
                        
                        // Aviso explicativo sobre bovinos
                        _buildBovineExplanationBanner(),
                        
                        const SizedBox(height: 16),
                        
                        // Dropdown de Vacunas
                        VaccineDropdown(
                          selectedVaccine: _selectedVaccineInfo,
                          vaccines: _availableVaccines,
                          onChanged: (vaccine) {
                            setState(() {
                              _selectedVaccineInfo = vaccine;
                            });
                          },
                          validator: (vaccine) {
                            if (vaccine == null) {
                              return 'Por favor selecciona una vacuna';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Fecha
                        _buildDatePicker(),
                        const SizedBox(height: 32),
                        
                        // Botón de actualizar
                        _buildUpdateButton(),
                        
                        // Banner informativo de la vacuna seleccionada
                        if (_selectedVaccineInfo != null)
                          _buildVaccineInfoBanner(),
                        
                        const SizedBox(height: 16),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editar Vacuna',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                Text(
                  widget.vaccine.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
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
          child: Stack(
            children: [
              // Imagen actual o nueva
              if (_selectedImage != null)
                Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              else if (_useDefaultImageUrl)
                Image.network(
                  defaultImageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: lightGreen,
                      child: const Icon(
                        Icons.vaccines_outlined,
                        size: 48,
                        color: primary,
                      ),
                    );
                  },
                )
              else if (widget.vaccine.vaccineImg.isNotEmpty)
                Image.network(
                  widget.vaccine.vaccineImg,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: lightGreen,
                      child: const Icon(
                        Icons.vaccines_outlined,
                        size: 48,
                        color: primary,
                      ),
                    );
                  },
                )
              else
                Container(
                  color: lightGreen,
                  child: const Icon(
                    Icons.vaccines_outlined,
                    size: 48,
                    color: primary,
                  ),
                ),
              
              // Overlay para cambiar imagen
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit,
                        size: 32,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca para cambiar imagen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                  'Fecha de Vencimiento',
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

  Widget _buildUpdateButton() {
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
          onTap: _isLoading ? null : _updateVaccine,
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Actualizar Vacuna',
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
    return GestureDetector(
      onTap: () {
        // Mostrar el diálogo de animales vacunados como ejemplo
        _showVaccinatedAnimalsDialog(widget.vaccine);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade50,
              Colors.cyan.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.1),
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
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Quieres agregar más animales?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toca aquí para ver cómo agregar más animales a esta vacuna.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.touch_app_rounded,
              color: Colors.blue,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showVaccinatedAnimalsDialog(VaccinesDto vaccine) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue, Colors.cyan],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cómo agregar animales',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Guía rápida',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 48,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Para agregar más animales a esta vacuna:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '1. Ve a la lista de vacunas\n2. Encuentra esta vacuna\n3. Presiona el botón "Ver más"\n4. Toca el botón "+" para agregar animales',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
      child: Row(
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
