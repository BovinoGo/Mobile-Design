import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/animals/data/repositories/animal_repository.dart';
import 'package:vacapp/features/ranches/data/datasources/ranch_service.dart';
import 'package:vacapp/features/ranches/data/models/ranch_dto.dart';

class CreateAnimalPage extends StatefulWidget {
  final AnimalRepository repository;
  const CreateAnimalPage({super.key, required this.repository});

  @override
  State<CreateAnimalPage> createState() => _CreateAnimalPageState();
}

class _CreateAnimalPageState extends State<CreateAnimalPage> {
  static const _green = Color(0xFF00695C);

  final _earTagCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  String _sex = 'Male';
  String _category = 'Vaca';
  String _productivePurpose = 'Carne';
  DateTime? _birthDate;
  File? _photo;
  bool _loading = false;

  // Ranch selector
  List<RanchDto> _ranches = [];
  RanchDto? _selectedRanch;
  bool _loadingRanches = true;
  String? _ranchError;

  static const _sexOptions = ['Male', 'Female'];
  static const _categoryOptions = ['Ternero', 'Vaca', 'Toro', 'Novilla', 'Novillo'];
  static const _purposeOptions = [
    'Carne', 'Leche', 'DoblePropósito', 'Reproducción', 'Reemplazo'
  ];

  @override
  void initState() {
    super.initState();
    _loadRanches();
  }

  @override
  void dispose() {
    _earTagCtrl.dispose();
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRanches() async {
    try {
      final ranches = await RanchService().fetchMine();
      if (mounted) {
        setState(() {
          _ranches = ranches;
          _selectedRanch = ranches.isNotEmpty ? ranches.first : null;
          _loadingRanches = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ranchError = 'No se pudieron cargar los ranchos';
          _loadingRanches = false;
        });
      }
    }
  }

  String? _validate() {
    if (_earTagCtrl.text.trim().isEmpty) return 'El código de arete es obligatorio';
    if (_breedCtrl.text.trim().isEmpty) return 'La raza es obligatoria';
    if (_weightCtrl.text.trim().isEmpty ||
        double.tryParse(_weightCtrl.text) == null) {
      return 'Ingresa un peso válido en kg';
    }
    if (_selectedRanch == null) return 'Selecciona un rancho';
    return null;
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (_, child) => Theme(
        data: ThemeData.light()
            .copyWith(colorScheme: const ColorScheme.light(primary: _green)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      return;
    }

    final ownerId = await TokenService.instance.getUserId();
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sesión inválida. Vuelve a iniciar sesión.'),
            backgroundColor: Colors.red));
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final body = <String, dynamic>{
        'earTagCode': _earTagCtrl.text.trim(),
        if (_nameCtrl.text.trim().isNotEmpty) 'name': _nameCtrl.text.trim(),
        'breed': _breedCtrl.text.trim(),
        'sex': _sex,
        'category': _category,
        'currentWeightKg': double.parse(_weightCtrl.text.trim()),
        'productivePurpose': _productivePurpose,
        'ranchId': _selectedRanch!.id,
        'ownerId': ownerId,
        if (_birthDate != null) 'birthDate': _birthDate!.toIso8601String(),
      };
      await widget.repository.createAnimal(body, imageFile: _photo);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Registrar Bovino',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Photo picker
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _green.withValues(alpha: 0.3),
                      style: BorderStyle.solid),
                ),
                child: _photo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_photo!, fit: BoxFit.cover))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 36,
                              color: _green.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          const Text('Agregar foto (opcional)',
                              style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),

            // Identification
            _card([
              _field(_earTagCtrl, 'Código de Arete *', Icons.tag),
              const SizedBox(height: 12),
              _field(_nameCtrl, 'Nombre (opcional)', Icons.pets),
              const SizedBox(height: 12),
              _field(_breedCtrl, 'Raza *', Icons.category_outlined),
              const SizedBox(height: 12),
              _field(_weightCtrl, 'Peso actual (kg) *', Icons.scale,
                  keyboard: TextInputType.number),
            ], title: 'Identificación'),
            const SizedBox(height: 12),

            // Production data
            _card([
              _dropdown('Sexo', _sexOptions, _sex,
                  (v) => setState(() => _sex = v!)),
              const SizedBox(height: 12),
              _dropdown('Categoría', _categoryOptions, _category,
                  (v) => setState(() => _category = v!)),
              const SizedBox(height: 12),
              _dropdown('Propósito productivo', _purposeOptions,
                  _productivePurpose,
                  (v) => setState(() => _productivePurpose = v!)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: _green, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _birthDate != null
                            ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                            : 'Fecha de nacimiento (opcional)',
                        style: TextStyle(
                          color: _birthDate != null
                              ? Colors.black87
                              : Colors.grey.shade500,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ], title: 'Datos Productivos'),
            const SizedBox(height: 12),

            // Ranch selector
            _card([
              if (_loadingRanches)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: _green),
                  ),
                )
              else if (_ranchError != null)
                _ranchErrorWidget()
              else if (_ranches.isEmpty)
                _noRanchesWidget()
              else
                _ranchDropdown(),
            ], title: 'Rancho *'),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Registrar Bovino',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _ranchDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<RanchDto>(
          // ignore: deprecated_member_use
          value: _selectedRanch,
          decoration: InputDecoration(
            labelText: 'Selecciona el rancho',
            labelStyle: const TextStyle(color: _green, fontSize: 13),
            prefixIcon: const Icon(Icons.home_work_outlined,
                color: _green, size: 18),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _green),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          items: _ranches
              .map((r) => DropdownMenuItem(
                    value: r,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(r.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('${r.country} · ${r.region} · ${r.productionType}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedRanch = v),
        ),
        if (_selectedRanch != null) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: _green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ID: ${_selectedRanch!.id}',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _ranchErrorWidget() {
    return Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(_ranchError!,
              style: TextStyle(color: Colors.red.shade600, fontSize: 13)),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _loadingRanches = true;
              _ranchError = null;
            });
            _loadRanches();
          },
          child: const Text('Reintentar',
              style: TextStyle(color: _green, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _noRanchesWidget() {
    return Column(
      children: [
        const Icon(Icons.home_work_outlined, size: 36, color: Colors.grey),
        const SizedBox(height: 8),
        const Text('No tienes ranchos registrados.',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        const Text(
            'Ve a Gestión → Ranchos y crea uno primero.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _card(List<Widget> children, {required String title}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _green.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: _green)),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: _green, size: 18),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _dropdown(String label, List<String> options, String value,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _green, fontSize: 13),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: options
          .map((o) => DropdownMenuItem(
              value: o,
              child: Text(o, style: const TextStyle(fontSize: 14))))
          .toList(),
      onChanged: onChanged,
    );
  }
}
