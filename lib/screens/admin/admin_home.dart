import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/anticipo_service.dart';
import '../../widgets/widgets.dart';
import 'admin_profile.dart';
import 'anticipo_detail.dart';
import 'anticipo_edit.dart';

class AdminHome extends StatefulWidget {
  final UserModel user;
  const AdminHome({super.key, required this.user});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final _anticipoService = AnticipoService();
  late List<Anticipo> _anticipos;
  bool _loading = true;
  String _filtroEstado = 'Todos';
  String _filtroConductor = 'Todos';

  @override
  void initState() {
    super.initState();
    _anticipos = [];
    _loadAnticipos();
  }

  Future<void> _loadAnticipos() async {
    setState(() => _loading = true);
    final data = await _anticipoService.getAnticipos();
    if (mounted) {
      setState(() {
        _anticipos = data;
        _loading = false;
      });
    }
  }

  List<Anticipo> get _filtrados {
    return _anticipos.where((a) {
      final okEstado = _filtroEstado == 'Todos' || a.estado == _filtroEstado;
      final okCond = _filtroConductor == 'Todos' ||
          a.conductorNombre == _filtroConductor;
      return okEstado && okCond;
    }).toList();
  }

  double get _totalAnticipos =>
      _anticipos.fold(0, (s, a) => s + a.anticipo);
  double get _totalGastado =>
      _anticipos.fold(0, (s, a) => s + a.gastado);
  double get _totalExcedentes =>
      _anticipos.where((a) => a.excedente > 0).fold(0, (s, a) => s + a.excedente);
  int get _pendientes =>
      _anticipos.where((a) => a.estado == 'Pendiente').length;

  List<String> get _conductores {
    final names = _anticipos.map((a) => a.conductorNombre).toSet().toList();
    return ['Todos', ...names];
  }

  void _aprobar(Anticipo a) async {
    final result = await _anticipoService.liquidarAnticipo(a.id, {
      'estado': 'Pagado',
    });
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      setState(() {
        final idx = _anticipos.indexWhere((x) => x.id == a.id);
        if (idx != -1) {
          _anticipos[idx] = Anticipo(
            id: a.id, tipo: a.tipo,
            conductorNombre: a.conductorNombre, conductorId: a.conductorId,
            anticipo: a.anticipo, gastado: a.gastado,
            estado: 'Pagado',
            fechaEntrega: a.fechaEntrega, fechaLegalizacion: a.fechaLegalizacion,
            fechaMaxima: a.fechaMaxima, soporte: a.soporte,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anticipo ${a.id} aprobado'),
            backgroundColor: AppColors.green));
    }
  }

  void _rechazar(Anticipo a) async {
    final result = await _anticipoService.liquidarAnticipo(a.id, {
      'estado': 'Rechazado',
    });
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      setState(() {
        final idx = _anticipos.indexWhere((x) => x.id == a.id);
        if (idx != -1) {
          _anticipos[idx] = Anticipo(
            id: a.id, tipo: a.tipo,
            conductorNombre: a.conductorNombre, conductorId: a.conductorId,
            anticipo: a.anticipo, gastado: a.gastado,
            estado: 'Rechazado',
            fechaEntrega: a.fechaEntrega, fechaLegalizacion: a.fechaLegalizacion,
            fechaMaxima: a.fechaMaxima, soporte: a.soporte,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anticipo ${a.id} rechazado'),
            backgroundColor: AppColors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: Column(
        children: [
          GradientHeader(
            title: 'Panel Administrador',
            subtitle: 'Gestión completa de anticipos',
            gradStart: AppColors.adminGradStart,
            gradEnd: AppColors.adminGradEnd,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _loadAnticipos,
                  child: const Icon(Icons.refresh,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => AdminProfile(user: widget.user,
                              anticipos: _anticipos))),
                  child: const Icon(Icons.person_outline_rounded,
                      color: Colors.white, size: 26),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadAnticipos,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.55,
                            children: [
                              StatCard(
                                label: 'Total anticipos',
                                value: formatCOP(_totalAnticipos),
                                icon: Icons.trending_up_rounded,
                                iconColor: AppColors.blue,
                                iconBg: AppColors.blueBg,
                              ),
                              StatCard(
                                label: 'Total gastado',
                                value: formatCOP(_totalGastado),
                                icon: Icons.attach_money_rounded,
                                iconColor: AppColors.green,
                                iconBg: AppColors.greenBg,
                              ),
                              StatCard(
                                label: 'Excedentes',
                                value: formatCOP(_totalExcedentes),
                                icon: Icons.access_time_rounded,
                                iconColor: AppColors.orange,
                                iconBg: AppColors.orangeBg,
                              ),
                              StatCard(
                                label: 'Pendientes',
                                value: '$_pendientes',
                                icon: Icons.filter_alt_outlined,
                                iconColor: AppColors.orange,
                                iconBg: AppColors.orangeBg,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.filter_alt_outlined,
                                        size: 18, color: AppColors.textSub),
                                    SizedBox(width: 6),
                                    Text('Filtros',
                                        style: TextStyle(
                                            color: AppColors.textMain,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Estado',
                                              style: TextStyle(
                                                  color: AppColors.textSub,
                                                  fontSize: 12)),
                                          const SizedBox(height: 6),
                                          _dropdownField(
                                            value: _filtroEstado,
                                            items: const ['Todos', 'Activo', 'Pendiente', 'Pagado', 'Rechazado'],
                                            onChanged: (v) => setState(() => _filtroEstado = v!),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Conductor',
                                              style: TextStyle(
                                                  color: AppColors.textSub,
                                                  fontSize: 12)),
                                          const SizedBox(height: 6),
                                          _dropdownField(
                                            value: _filtroConductor,
                                            items: _conductores,
                                            onChanged: (v) => setState(() => _filtroConductor = v!),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ..._filtrados.map((a) => AnticipoCard(
                            anticipo: a,
                            isAdmin: true,
                            onVer: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => AnticipoDetail(
                                        anticipo: a, isAdmin: true))),
                            onEditar: () async {
                              final updated = await Navigator.push<Anticipo>(context,
                                  MaterialPageRoute(
                                      builder: (_) => AnticipoEdit(
                                          anticipo: a, isAdmin: true)));
                              if (updated != null) {
                                setState(() {
                                  final idx = _anticipos.indexWhere((x) => x.id == updated.id);
                                  if (idx != -1) _anticipos[idx] = updated;
                                });
                              }
                            },
                            onAprobar: () => _aprobar(a),
                            onRechazar: () => _rechazar(a),
                          )),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nuevo = await Navigator.push<Anticipo>(context,
              MaterialPageRoute(
                  builder: (_) => AnticipoEdit(isAdmin: true)));
          if (nuevo != null) setState(() => _anticipos.add(nuevo));
        },
        backgroundColor: AppColors.adminPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _dropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSub),
        style: const TextStyle(
            color: AppColors.textMain, fontSize: 14),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
