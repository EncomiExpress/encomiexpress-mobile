import 'package:flutter/material.dart';
import '../../../../core/models.dart';
import '../../../../core/services/paquete_service.dart';

class DriverPaquetes extends StatefulWidget {
  final UserModel user;
  const DriverPaquetes({super.key, required this.user});

  @override
  State<DriverPaquetes> createState() => _DriverPaquetesState();
}

class _DriverPaquetesState extends State<DriverPaquetes> {
  final _service = PaqueteService();
  bool _loading = true;
  List<dynamic> _paquetes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final conductorIdStr = widget.user.conductorId;
    final conductorId = conductorIdStr != null
        ? int.tryParse(conductorIdStr)
        : null;
    if (conductorId == null) {
      if (mounted) {
        setState(() {
          _paquetes = [];
          _loading = false;
        });
      }
      return;
    }
    final data = await _service.getPaquetesPorConductor(conductorId);
    if (mounted) {
      setState(() {
        _paquetes = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _paquetes.isEmpty
          ? Center(
              child: Text(
                'No hay paquetes asignados',
                style: TextStyle(color: AppColors.textSub),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _paquetes.length,
              itemBuilder: (_, i) {
                final p = _paquetes[i];
                return Card(
                  child: ListTile(
                    title: Text(p['numeroGuia'] ?? '—'),
                    subtitle: Text(p['descripcionContenido'] ?? ''),
                    trailing: Text(p['estado'] ?? ''),
                  ),
                );
              },
            ),
    );
  }
}
