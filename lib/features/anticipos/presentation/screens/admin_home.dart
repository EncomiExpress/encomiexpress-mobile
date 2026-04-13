import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../anticipos/domain/entities/anticipo.dart';
import '../../../usuarios/domain/entities/usuario.dart';
import '../providers/anticipo_provider.dart';
import 'admin_profile.dart';
import 'anticipo_detail.dart';
import 'anticipo_edit.dart';

class AdminHome extends StatefulWidget {
  final Usuario user;
  const AdminHome({super.key, required this.user});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String _filtroEstado = 'Todos';
  String _filtroConductor = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnticipoProvider>().loadAnticipos();
    });
  }

  void _aprobar(Anticipo a) async {
    final provider = context.read<AnticipoProvider>();
    final success = await provider.aprobarAnticipo(a.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anticipo ${a.id} aprobado'), backgroundColor: AppColors.green));
    }
  }

  void _rechazar(Anticipo a) async {
    final provider = context.read<AnticipoProvider>();
    final success = await provider.rechazarAnticipo(a.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anticipo ${a.id} rechazado'), backgroundColor: AppColors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnticipoProvider>();
    final anticipos = provider.anticipos;
    final loading = provider.loading;

    final filtrados = anticipos.where((a) {
      final okEstado = _filtroEstado == 'Todos' || a.estado == _filtroEstado;
      final okCond = _filtroConductor == 'Todos' || a.conductorNombre == _filtroConductor;
      return okEstado && okCond;
    }).toList();

    final totalAnticipos = anticipos.fold(0.0, (s, a) => s + a.anticipo);
    final totalGastado = anticipos.fold(0.0, (s, a) => s + a.gastado);
    final pendientes = anticipos.where((a) => a.estado == 'Pendiente').length;

    final nombresConductores = anticipos.map((a) => a.conductorNombre).toSet().toList();

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: Column(
        children: [
          GradientHeader(
            title: 'Panel Administrador',
            subtitle: 'Gestión completa de anticipos',
            gradStart: AppColors.adminGradStart,
            gradEnd: AppColors.adminGradEnd,
            trailing: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AdminProfile(user: widget.user, anticipos: anticipos))),
              child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 26),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => provider.loadAnticipos(),
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
                              StatCard(label: 'Total anticipos', value: formatCOP(totalAnticipos), icon: Icons.trending_up_rounded, iconColor: AppColors.blue, iconBg: AppColors.blueBg),
                              StatCard(label: 'Total gastado', value: formatCOP(totalGastado), icon: Icons.attach_money_rounded, iconColor: AppColors.green, iconBg: AppColors.greenBg),
                              StatCard(label: 'Pendientes', value: '$pendientes', icon: Icons.filter_alt_outlined, iconColor: AppColors.orange, iconBg: AppColors.orangeBg),
                              StatCard(label: 'Total anticipos', value: '${anticipos.length}', icon: Icons.list_alt_rounded, iconColor: AppColors.purple, iconBg: AppColors.purpleBg),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(children: [
                                  Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.textSub),
                                  SizedBox(width: 6),
                                  Text('Filtros', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w700, fontSize: 15)),
                                ]),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Text('Estado', style: TextStyle(color: AppColors.textSub, fontSize: 12)),
                                      const SizedBox(height: 6),
                                      _dropdownField(value: _filtroEstado, items: const ['Todos', 'Activo', 'Pendiente', 'Pagado', 'Rechazado'], onChanged: (v) => setState(() => _filtroEstado = v!)),
                                    ])),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Text('Conductor', style: TextStyle(color: AppColors.textSub, fontSize: 12)),
                                      const SizedBox(height: 6),
                                      _dropdownField(value: _filtroConductor, items: ['Todos', ...nombresConductores], onChanged: (v) => setState(() => _filtroConductor = v!)),
                                    ])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ...filtrados.map((a) => AnticipoCard(
                            anticipo: a,
                            isAdmin: true,
                            onVer: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnticipoDetail(anticipo: a, isAdmin: true))),
                            onEditar: () async {
                              final updated = await Navigator.push<Anticipo>(context, MaterialPageRoute(builder: (_) => AnticipoEdit(anticipo: a, isAdmin: true)));
                              if (updated != null) await provider.loadAnticipos();
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
          final nuevo = await Navigator.push<Anticipo>(context, MaterialPageRoute(builder: (_) => const AnticipoEdit(isAdmin: true)));
          if (nuevo != null) await provider.crearAnticipo(nuevo);
        },
        backgroundColor: AppColors.adminPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _dropdownField({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.bgGray, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: DropdownButton<String>(
        value: value, isExpanded: true, underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSub),
        style: const TextStyle(color: AppColors.textMain, fontSize: 14),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
