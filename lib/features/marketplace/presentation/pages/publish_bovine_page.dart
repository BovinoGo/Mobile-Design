import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/animals/data/dataasources/animals_service.dart';
import 'package:vacapp/features/animals/data/models/animal_dto.dart';
import 'package:vacapp/features/marketplace/presentation/blocs/marketplace_bloc.dart';
import 'package:vacapp/features/marketplace/presentation/blocs/marketplace_event.dart';
import 'package:vacapp/features/marketplace/presentation/blocs/marketplace_state.dart';
import 'package:vacapp/features/ranches/data/datasources/ranch_service.dart';
import 'package:vacapp/features/ranches/data/models/ranch_dto.dart';

class PublishBovinePage extends StatefulWidget {
  const PublishBovinePage({super.key});

  @override
  State<PublishBovinePage> createState() => _PublishBovinePageState();
}

class _PublishBovinePageState extends State<PublishBovinePage> {
  static const _green = Color(0xFF00695C);

  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String _currency = 'USD';
  String _salePurpose = 'Engorde';
  String _contactPreference = 'Email';
  bool _negotiablePrice = false;
  bool _includesTransport = false;
  bool _requiresSanitary = false;
  bool _healthSummaryVisible = true;
  bool _vaccinationHistoryVisible = false;

  // Dropdowns
  List<AnimalDto> _bovines = [];
  List<RanchDto> _ranches = [];
  AnimalDto? _selectedBovine;
  RanchDto? _selectedRanch;
  bool _loadingData = true;
  String? _loadError;

  static const _currencies = ['USD', 'PEN', 'COP', 'MXN', 'ARS'];
  static const _salePurposes = [
    'Engorde', 'Leche', 'Reproduccion', 'Sacrificio', 'Exportacion'
  ];
  static const _contactPreferences = ['Email', 'Phone', 'WhatsApp'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        AnimalsService().fetchAnimals(),
        RanchService().fetchMine(),
      ]);
      if (mounted) {
        setState(() {
          _bovines = results[0] as List<AnimalDto>;
          _ranches = results[1] as List<RanchDto>;
          _selectedBovine = _bovines.isNotEmpty ? _bovines.first : null;
          _selectedRanch = _ranches.isNotEmpty ? _ranches.first : null;
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString().replaceAll('Exception: ', '');
          _loadingData = false;
        });
      }
    }
  }

  String? _validate() {
    if (_selectedBovine == null) return 'Selecciona un bovino';
    if (_selectedRanch == null) return 'Selecciona un rancho';
    if (_titleCtrl.text.trim().isEmpty) return 'El título es obligatorio';
    if (_priceCtrl.text.trim().isEmpty ||
        double.tryParse(_priceCtrl.text.trim()) == null) {
      return 'Ingresa un precio válido';
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      return;
    }

    final sellerId = await TokenService.instance.getUserId();
    if (sellerId == null || sellerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sesión inválida'), backgroundColor: Colors.red));
      }
      return;
    }

    final body = {
      'bovineId': _selectedBovine!.id,
      'ranchId': _selectedRanch!.id,
      'sellerId': sellerId,
      'title': _titleCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'price': double.parse(_priceCtrl.text.trim()),
      'currency': _currency,
      'salePurpose': _salePurpose,
      'contactPreference': _contactPreference,
      'negotiablePrice': _negotiablePrice,
      'includesTransport': _includesTransport,
      'requiresSanitaryDocumentation': _requiresSanitary,
      'healthSummaryVisible': _healthSummaryVisible,
      'vaccinationHistoryVisible': _vaccinationHistoryVisible,
    };

    if (mounted) context.read<MarketplaceBloc>().add(PublishBovineEvent(body));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Publicar Bovino',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: BlocListener<MarketplaceBloc, MarketplaceState>(
        listener: (context, state) {
          if (state is MarketplaceOperationSuccess) {
            Navigator.pop(context);
          }
          if (state is MarketplaceError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: _loadingData
            ? const Center(child: CircularProgressIndicator(color: _green))
            : _loadError != null
                ? _errorView()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _card([
                          _field(_titleCtrl, 'Título de la publicación *', Icons.title),
                          const SizedBox(height: 12),
                          _field(_descriptionCtrl, 'Descripción (opcional)',
                              Icons.description_outlined,
                              maxLines: 3),
                        ], title: 'Información'),
                        const SizedBox(height: 12),
                        _card([
                          _bovineDropdown(),
                          const SizedBox(height: 12),
                          _ranchDropdown(),
                        ], title: 'Bovino y Rancho'),
                        const SizedBox(height: 12),
                        _card([
                          Row(children: [
                            Expanded(
                                child: _field(_priceCtrl, 'Precio *', Icons.attach_money,
                                    keyboard: TextInputType.number)),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 110,
                              child: _dropdown('Moneda', _currencies, _currency,
                                  (v) => setState(() => _currency = v!)),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          _dropdown('Propósito de venta', _salePurposes, _salePurpose,
                              (v) => setState(() => _salePurpose = v!)),
                          const SizedBox(height: 12),
                          _dropdown('Contacto preferido', _contactPreferences,
                              _contactPreference,
                              (v) => setState(() => _contactPreference = v!)),
                        ], title: 'Precio y Venta'),
                        const SizedBox(height: 12),
                        _card([
                          _switch('Precio negociable', _negotiablePrice,
                              (v) => setState(() => _negotiablePrice = v)),
                          _switch('Incluye transporte', _includesTransport,
                              (v) => setState(() => _includesTransport = v)),
                          _switch('Requiere docs. sanitaria', _requiresSanitary,
                              (v) => setState(() => _requiresSanitary = v)),
                          _switch('Mostrar resumen de salud', _healthSummaryVisible,
                              (v) => setState(() => _healthSummaryVisible = v)),
                          _switch('Mostrar historial vacunas',
                              _vaccinationHistoryVisible,
                              (v) => setState(() => _vaccinationHistoryVisible = v)),
                        ], title: 'Opciones'),
                        const SizedBox(height: 24),
                        BlocBuilder<MarketplaceBloc, MarketplaceState>(
                          builder: (context, state) {
                            final loading = state is MarketplaceLoading;
                            return SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: loading ? null : _submit,
                                icon: loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.storefront_outlined),
                                label: const Text('Publicar en el Mercado',
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _bovineDropdown() {
    if (_bovines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('No tienes bovinos registrados. Registra uno primero.',
                  style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
    }
    return DropdownButtonFormField<AnimalDto>(
      // ignore: deprecated_member_use
      value: _selectedBovine,
      decoration: _inputDecoration('Seleccionar bovino *', Icons.pets_rounded),
      items: _bovines
          .map((a) => DropdownMenuItem(
                value: a,
                child: Text(
                  '${a.displayName} · ${a.breed} · ${a.sex}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedBovine = v),
    );
  }

  Widget _ranchDropdown() {
    if (_ranches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('No tienes ranchos registrados. Crea uno primero.',
                  style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
    }
    return DropdownButtonFormField<RanchDto>(
      // ignore: deprecated_member_use
      value: _selectedRanch,
      decoration: _inputDecoration('Seleccionar rancho *', Icons.home_work_outlined),
      items: _ranches
          .map((r) => DropdownMenuItem(
                value: r,
                child: Text(
                  '${r.name} · ${r.region}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedRanch = v),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: Icon(icon, color: _green, size: 18),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _green),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(_loadError!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() { _loadingData = true; _loadError = null; });
                _loadData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
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
      {TextInputType? keyboard, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: maxLines == 1 ? Icon(icon, color: _green, size: 18) : null,
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
              value: o, child: Text(o, style: const TextStyle(fontSize: 14))))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      thumbColor: MaterialStateProperty.resolveWith<Color?>((states) => _green),
      trackColor: MaterialStateProperty.resolveWith<Color?>((states) => _green.withOpacity(0.5)),
      onChanged: onChanged,
    );
  }
}
