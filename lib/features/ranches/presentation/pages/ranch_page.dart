import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/features/ranches/data/models/ranch_dto.dart';
import 'package:vacapp/features/ranches/presentation/blocs/ranch_bloc.dart';
import 'package:vacapp/features/ranches/presentation/blocs/ranch_event.dart';
import 'package:vacapp/features/ranches/presentation/blocs/ranch_state.dart';
import 'package:vacapp/features/ranches/presentation/pages/create_ranch_page.dart';

class RanchPage extends StatelessWidget {
  const RanchPage({super.key});

  static const _green = Color(0xFF00695C);
  static const _lightGreen = Color(0xFFE8F5E8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Mis Ranchos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _goToCreate(context),
          ),
        ],
      ),
      body: BlocConsumer<RanchBloc, RanchState>(
        listener: (context, state) {
          if (state is RanchOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: _green),
            );
          }
          if (state is RanchError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is RanchLoading) {
            return const Center(
                child: CircularProgressIndicator(color: _green));
          }
          if (state is RanchLoaded) {
            if (state.ranches.isEmpty) return _emptyState(context);
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.ranches.length,
              itemBuilder: (_, i) => _ranchCard(context, state.ranches[i]),
            );
          }
          if (state is RanchError) {
            return _errorState(context, state.message);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _goToCreate(BuildContext context) async {
    final bloc = context.read<RanchBloc>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const CreateRanchPage(),
        ),
      ),
    );
    if (context.mounted) bloc.add(LoadRanchesEvent());
  }

  Widget _ranchCard(BuildContext context, RanchDto ranch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _green.withValues(alpha: 0.1),
              blurRadius: 14,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home_work_outlined,
                    color: _green, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ranch.name,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _green)),
                    Text('${ranch.country} · ${ranch.region}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              _badge(ranch.productionType),
            ],
          ),
          if (ranch.description != null && ranch.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(ranch.description!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (ranch.capacityBovines != null)
                _infoChip(
                    Icons.pets_rounded, '${ranch.capacityBovines} bovinos'),
              if (ranch.totalAreaHectares != null) ...[
                const SizedBox(width: 8),
                _infoChip(Icons.landscape_outlined,
                    '${ranch.totalAreaHectares!.toStringAsFixed(1)} ha'),
              ],
              const Spacer(),
              // Copy ID button
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: SelectableText('ID: ${ranch.id}'),
                    backgroundColor: _green,
                    duration: const Duration(seconds: 5),
                  ));
                },
                icon: const Icon(Icons.copy, size: 14, color: _green),
                label: const Text('Copiar ID',
                    style: TextStyle(color: _green, fontSize: 12)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Colors.red.shade400, size: 20),
                onPressed: () => _confirmDeactivate(context, ranch),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _green)),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, RanchDto ranch) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar Rancho'),
        content: Text(
            '¿Seguro que deseas desactivar "${ranch.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              context.read<RanchBloc>().add(DeactivateRanchEvent(ranch.id));
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
            decoration:
                const BoxDecoration(color: _lightGreen, shape: BoxShape.circle),
            child: const Icon(Icons.home_work_outlined,
                size: 60, color: _green),
          ),
          const SizedBox(height: 20),
          const Text('Sin ranchos registrados',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: _green)),
          const SizedBox(height: 8),
          const Text('Crea tu primer rancho',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _goToCreate(context),
            icon: const Icon(Icons.add),
            label: const Text('Crear Rancho'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(error, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                context.read<RanchBloc>().add(LoadRanchesEvent()),
            style: ElevatedButton.styleFrom(
                backgroundColor: _green, foregroundColor: Colors.white),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
