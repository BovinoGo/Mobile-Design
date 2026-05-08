import 'package:flutter/material.dart';
import 'package:vacapp/features/animals/data/models/animal_dto.dart';

class AnimalDropdown extends StatefulWidget {
  final String? selectedAnimalId;
  final List<AnimalDto> animals;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;
  final String? Function(AnimalDto)? genderFilter;

  const AnimalDropdown({
    super.key,
    required this.selectedAnimalId,
    required this.animals,
    required this.onChanged,
    this.validator,
    this.genderFilter,
  });

  @override
  State<AnimalDropdown> createState() => _AnimalDropdownState();
}

class _AnimalDropdownState extends State<AnimalDropdown> with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF00695C);
  static const Color lightGreen = Color(0xFFE8F5E8);
  static const Color accent = Color(0xFF26A69A);
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper method to calculate age from birth date
  String _calculateAge(String birthDate) {
    try {
      final birth = DateTime.parse(birthDate);
      final now = DateTime.now();
      final age = now.difference(birth);
      
      if (age.inDays < 30) {
        return '${age.inDays}d';
      } else if (age.inDays < 365) {
        final months = (age.inDays / 30).round();
        return '$months${months == 1 ? 'm' : 'm'}';
      } else {
        final years = (age.inDays / 365).floor();
        final remainingMonths = ((age.inDays % 365) / 30).round();
        if (remainingMonths == 0) {
          return '$years${years == 1 ? 'a' : 'a'}';
        } else {
          return '$years${years == 1 ? 'a' : 'a'} $remainingMonths${remainingMonths == 1 ? 'm' : 'm'}';
        }
      }
    } catch (e) {
      return 'N/A';
    }
  }

  // Helper method to translate gender
  String _translateGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Macho';
      case 'female':
        return 'Hembra';
      case 'macho':
        return 'Macho';
      case 'hembra':
        return 'Hembra';
      default:
        return gender;
    }
  }

  // Helper method to check if animal is male
  bool _isMale(String gender) {
    return gender.toLowerCase() == 'male' || gender.toLowerCase() == 'macho';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Dropdown Container - Simplified for dropdown only
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      lightGreen.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.selectedAnimalId != null 
                      ? accent.withValues(alpha: 0.5)
                      : Colors.grey.shade200,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: widget.selectedAnimalId,
                  decoration: InputDecoration(
                    labelText: 'Seleccionar animal',
                    labelStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, primary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.pets,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, 
                      vertical: 18,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  items: widget.animals.map((AnimalDto animal) {
                    final genderError = widget.genderFilter?.call(animal);
                    final isDisabled = genderError != null;
                    
                    return DropdownMenuItem<String>(
                      value: animal.id,
                      enabled: !isDisabled,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Row(
                          children: [
                            // Simple Animal avatar - smaller for dropdown
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDisabled 
                                    ? [Colors.grey.shade200, Colors.grey.shade100]
                                    : _isMale(animal.gender)
                                      ? [Colors.blue.withValues(alpha: 0.2), accent.withValues(alpha: 0.1)]
                                      : [Colors.pink.withValues(alpha: 0.2), accent.withValues(alpha: 0.1)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDisabled 
                                    ? Colors.grey.shade300 
                                    : _isMale(animal.gender)
                                      ? Colors.blue.withValues(alpha: 0.3)
                                      : Colors.pink.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                _isMale(animal.gender)
                                  ? Icons.male 
                                  : Icons.female,
                                color: isDisabled 
                                  ? Colors.grey.shade400 
                                  : _isMale(animal.gender)
                                    ? Colors.blue
                                    : Colors.pink,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Animal info with name only
                            Expanded(
                              child: Text(
                                animal.displayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDisabled 
                                    ? Colors.grey.shade500 
                                    : primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isDisabled)
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.block,
                                  size: 12,
                                  color: Colors.red.shade400,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? animalId) {
                    widget.onChanged(animalId);
                    if (animalId != null) {
                      _animationController.forward().then((_) {
                        _animationController.reverse();
                      });
                    }
                  },
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  validator: widget.validator,
                  icon: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: primary,
                        size: 20,
                      ),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: primary),
                  isExpanded: true,
                  menuMaxHeight: 250,
                ),
              ),
            );
          },
        ),
        
        // Separate card for selected animal details - appears in new row
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          height: widget.selectedAnimalId != null ? null : 0,
          child: widget.selectedAnimalId != null
              ? Container(
                  margin: const EdgeInsets.only(top: 16),
                  child: _buildSelectedAnimalCard(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSelectedAnimalCard() {
    final selectedAnimal = widget.animals.firstWhere(
      (animal) => animal.id == widget.selectedAnimalId,
      orElse: () => AnimalDto(
        id: '',
        earTagCode: '',
        breed: '',
        sex: '',
        ageInMonths: 0,
        healthStatus: '',
        lifeStatus: '',
        ranchId: '',
        ownerId: '',
        isActive: false,
        currentWeightKg: 0,
      ),
    );

    if (selectedAnimal.id.isEmpty) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lightGreen.withValues(alpha: 0.3),
            accent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with animal avatar and name
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isMale(selectedAnimal.gender)
                      ? [Colors.blue, accent]
                      : [Colors.pink, accent],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: (_isMale(selectedAnimal.gender)
                        ? Colors.blue
                        : Colors.pink).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _isMale(selectedAnimal.gender)
                    ? Icons.male 
                    : Icons.female,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Animal seleccionado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedAnimal.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _calculateAge(selectedAnimal.birthDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Animal details in organized rows
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Gender and Age row
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Género',
                        _translateGender(selectedAnimal.gender),
                        _isMale(selectedAnimal.gender) ? Icons.male : Icons.female,
                        _isMale(selectedAnimal.gender) ? Colors.blue : Colors.pink,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailItem(
                        'Edad',
                        _calculateAge(selectedAnimal.birthDate),
                        Icons.cake,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                if (selectedAnimal.breed.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Raza',
                    selectedAnimal.breed,
                    Icons.pets,
                    accent,
                  ),
                ],
                
                if (selectedAnimal.location.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Ubicación',
                    selectedAnimal.location,
                    Icons.location_on,
                    Colors.green,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
