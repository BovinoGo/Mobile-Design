import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/features/workers/data/models/worker_dto.dart';
import 'package:vacapp/features/workers/presentation/blocs/worker_bloc.dart';
import 'package:vacapp/features/workers/presentation/blocs/worker_event.dart';
import 'package:vacapp/features/workers/presentation/blocs/worker_state.dart';
import 'package:vacapp/features/workers/presentation/pages/create_worker_page.dart';

class WorkersPage extends StatelessWidget {
  final String companyId;
  const WorkersPage({super.key, required this.companyId});

  static const _green = Color(0xFF00695C);
  static const _lightGreen = Color(0xFFE8F5E8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Trabajadores',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: Colors.white),
            onPressed: () => _goToCreate(context),
          ),
        ],
      ),
      body: BlocConsumer<WorkerBloc, WorkerState>(
        listener: (context, state) {
          if (state is WorkerOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: _green),
            );
          }
          if (state is WorkerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is WorkerLoading) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          if (state is WorkerLoaded) {
            if (state.workers.isEmpty) return _emptyState(context);
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.workers.length,
              itemBuilder: (_, i) => _workerCard(context, state.workers[i]),
            );
          }
          if (state is WorkerError) {
            return _errorState(context, state.message);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _goToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => BlocProvider.value(
                value: context.read<WorkerBloc>(),
                child: CreateWorkerPage(companyId: companyId),
              )),
    );
  }

  Widget _workerCard(BuildContext context, WorkerDto worker) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: _green, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker.fullName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _green)),
                Text(worker.email,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (worker.canRegisterBovines)
                      _permissionChip('Registra bovinos'),
                    if (worker.canUpdateBovineStatus)
                      _permissionChip('Actualiza estado'),
                    if (worker.canSimulateVitalSigns == true)
                      _permissionChip('Simula signos'),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.person_remove_outlined,
                color: Colors.red.shade400, size: 22),
            onPressed: () => _confirmDeactivate(context, worker),
          ),
        ],
      ),
    );
  }

  Widget _permissionChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: _green)),
    );
  }

  void _confirmDeactivate(BuildContext context, WorkerDto worker) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar Trabajador'),
        content: Text('¿Seguro que deseas desactivar a "${worker.fullName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<WorkerBloc>()
                  .add(DeactivateWorkerEvent(worker.workerId, companyId));
            },
            child: const Text('Desactivar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
                color: _lightGreen, shape: BoxShape.circle),
            child: const Icon(Icons.people_outline, size: 60, color: _green),
          ),
          const SizedBox(height: 20),
          const Text('Sin trabajadores',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: _green)),
          const SizedBox(height: 8),
          const Text('Agrega el primer trabajador de tu empresa',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _goToCreate(context),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Agregar Trabajador'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                context.read<WorkerBloc>().add(LoadWorkersEvent(companyId)),
            style: ElevatedButton.styleFrom(
                backgroundColor: _green, foregroundColor: Colors.white),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
