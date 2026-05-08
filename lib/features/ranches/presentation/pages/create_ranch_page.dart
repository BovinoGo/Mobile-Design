import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/core/services/token_service.dart';
import 'package:vacapp/features/ranches/presentation/blocs/ranch_bloc.dart';
import 'package:vacapp/features/ranches/presentation/blocs/ranch_event.dart';
import 'package:vacapp/features/ranches/presentation/blocs/ranch_state.dart';

class CreateRanchPage extends StatefulWidget {
  const CreateRanchPage({super.key});

  @override
  State<CreateRanchPage> createState() => _CreateRanchPageState();
}

class _CreateRanchPageState extends State<CreateRanchPage> {
  static const _green = Color(0xFF00695C);

  final _nameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _sanitaryCtrl = TextEditingController();

  String _productionType = 'Carne';

  static const _productionTypes = ['Carne', 'Leche', 'DoblePropósito', 'Reproducción'];

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _countryCtrl, _regionCtrl, _descriptionCtrl,
      _provinceCtrl, _addressCtrl, _areaCtrl, _capacityCtrl,
      _phoneCtrl, _emailCtrl, _sanitaryCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    if (_nameCtrl.text.trim().isEmpty) return 'El nombre del rancho es obligatorio';
    if (_countryCtrl.text.trim().isEmpty) return 'El país es obligatorio';
    if (_regionCtrl.text.trim().isEmpty) return 'La región es obligatoria';
    return null;
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

    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'country': _countryCtrl.text.trim(),
      'region': _regionCtrl.text.trim(),
      'productionType': _productionType,
      'ownerId': ownerId,
      if (_descriptionCtrl.text.trim().isNotEmpty)
        'description': _descriptionCtrl.text.trim(),
      if (_provinceCtrl.text.trim().isNotEmpty)
        'province': _provinceCtrl.text.trim(),
      if (_addressCtrl.text.trim().isNotEmpty)
        'address': _addressCtrl.text.trim(),
      if (_areaCtrl.text.trim().isNotEmpty)
        'totalAreaHectares': double.tryParse(_areaCtrl.text.trim()),
      if (_capacityCtrl.text.trim().isNotEmpty)
        'capacityBovines': int.tryParse(_capacityCtrl.text.trim()),
      if (_phoneCtrl.text.trim().isNotEmpty)
        'contactPhone': _phoneCtrl.text.trim(),
      if (_emailCtrl.text.trim().isNotEmpty)
        'contactEmail': _emailCtrl.text.trim(),
      if (_sanitaryCtrl.text.trim().isNotEmpty)
        'sanitaryRegistrationCode': _sanitaryCtrl.text.trim(),
    };

    if (mounted) {
      context.read<RanchBloc>().add(CreateRanchEvent(body));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Crear Rancho',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: BlocListener<RanchBloc, RanchState>(
        listener: (context, state) {
          if (state is RanchOperationSuccess) {
            Navigator.pop(context);
          }
          if (state is RanchError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _card([
                _field(_nameCtrl, 'Nombre del rancho *', Icons.home_work_outlined),
                const SizedBox(height: 12),
                _field(_countryCtrl, 'País *', Icons.flag_outlined),
                const SizedBox(height: 12),
                _field(_regionCtrl, 'Región / Departamento *', Icons.map_outlined),
                const SizedBox(height: 12),
                _field(_provinceCtrl, 'Provincia (opcional)', Icons.location_city_outlined),
                const SizedBox(height: 12),
                _field(_addressCtrl, 'Dirección (opcional)', Icons.location_on_outlined),
              ], title: 'Ubicación'),
              const SizedBox(height: 12),
              _card([
                _dropdown('Tipo de producción', _productionTypes, _productionType,
                    (v) => setState(() => _productionType = v!)),
                const SizedBox(height: 12),
                _field(_areaCtrl, 'Área total (hectáreas)', Icons.landscape_outlined,
                    keyboard: TextInputType.number),
                const SizedBox(height: 12),
                _field(_capacityCtrl, 'Capacidad de bovinos', Icons.pets_rounded,
                    keyboard: TextInputType.number),
                const SizedBox(height: 12),
                _field(_descriptionCtrl, 'Descripción (opcional)',
                    Icons.description_outlined,
                    maxLines: 3),
              ], title: 'Producción'),
              const SizedBox(height: 12),
              _card([
                _field(_phoneCtrl, 'Teléfono de contacto', Icons.phone_outlined,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 12),
                _field(_emailCtrl, 'Email de contacto', Icons.email_outlined,
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _field(_sanitaryCtrl, 'Código sanitario (opcional)',
                    Icons.health_and_safety_outlined),
              ], title: 'Contacto'),
              const SizedBox(height: 24),
              BlocBuilder<RanchBloc, RanchState>(
                builder: (context, state) {
                  final loading = state is RanchLoading;
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
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('Crear Rancho',
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
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
