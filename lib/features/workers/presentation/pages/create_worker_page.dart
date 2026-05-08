import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/features/workers/presentation/blocs/worker_bloc.dart';
import 'package:vacapp/features/workers/presentation/blocs/worker_event.dart';
import 'package:vacapp/features/workers/presentation/blocs/worker_state.dart';

class CreateWorkerPage extends StatefulWidget {
  final String companyId;
  const CreateWorkerPage({super.key, required this.companyId});

  @override
  State<CreateWorkerPage> createState() => _CreateWorkerPageState();
}

class _CreateWorkerPageState extends State<CreateWorkerPage> {
  static const _green = Color(0xFF00695C);

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _canRegisterBovines = false;
  bool _canUpdateBovineStatus = false;
  bool _canSimulateVitalSigns = false;
  bool _obscure = true;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_fullNameCtrl.text.trim().isEmpty) return 'El nombre es obligatorio';
    if (_emailCtrl.text.trim().isEmpty) return 'El email es obligatorio';
    if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailCtrl.text.trim())) {
      return 'Ingresa un email válido';
    }
    if (_passwordCtrl.text.trim().length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  void _submit() {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      return;
    }

    final body = {
      'fullName': _fullNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passwordCtrl.text.trim(),
      'companyId': widget.companyId,
      'canRegisterBovines': _canRegisterBovines,
      'canUpdateBovineStatus': _canUpdateBovineStatus,
      'canSimulateVitalSigns': _canSimulateVitalSigns,
      if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
    };

    context.read<WorkerBloc>().add(CreateWorkerEvent(body));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Nuevo Trabajador',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: BlocListener<WorkerBloc, WorkerState>(
        listener: (context, state) {
          if (state is WorkerOperationSuccess) Navigator.pop(context);
          if (state is WorkerError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _card([
                _field(_fullNameCtrl, 'Nombre completo *', Icons.person_outline),
                const SizedBox(height: 12),
                _field(_emailCtrl, 'Email *', Icons.email_outlined,
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _field(_phoneCtrl, 'Teléfono (opcional)', Icons.phone_outlined,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Contraseña *',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline, color: _green, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: _green, size: 18),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _green),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                ),
              ], title: 'Datos del Trabajador'),
              const SizedBox(height: 12),
              _card([
                _permSwitch(
                  'Puede registrar bovinos',
                  'Permite crear nuevos registros de bovinos',
                  _canRegisterBovines,
                  (v) => setState(() => _canRegisterBovines = v),
                ),
                _permSwitch(
                  'Puede actualizar estado de bovinos',
                  'Permite modificar salud y producción',
                  _canUpdateBovineStatus,
                  (v) => setState(() => _canUpdateBovineStatus = v),
                ),
                _permSwitch(
                  'Puede simular signos vitales',
                  'Permite registrar mediciones de signos vitales',
                  _canSimulateVitalSigns,
                  (v) => setState(() => _canSimulateVitalSigns = v),
                ),
              ], title: 'Permisos'),
              const SizedBox(height: 24),
              BlocBuilder<WorkerBloc, WorkerState>(
                builder: (context, state) {
                  final loading = state is WorkerLoading;
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
                          : const Icon(Icons.person_add_outlined),
                      label: const Text('Registrar Trabajador',
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

  Widget _permSwitch(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: _green, activeTrackColor: _green.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
