import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../anticipos/domain/entities/anticipo.dart';
import '../../../usuarios/domain/entities/usuario.dart';
import '../providers/anticipo_provider.dart';
import 'anticipo_detail.dart';
import 'anticipo_edit.dart';
import 'driver_profile.dart';

class DriverHome extends StatefulWidget {
  final Usuario user;
  const DriverHome({super.key, required this.user});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  int _tab = 0;
  final _searchCtrl = TextEditingController();
  bool _showFiltros = false;
  String _filtroEstado = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnticipoProvider>().loadAnticipos();
    });
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnticipoProvider>();
    final todosAnticipos = provider.anticipos;
    final misAnticipos = todosAnticipos.where((a) => a.conductorId == widget.user.id).toList();

    final filtrados = misAnticipos.where((a) {
      final query = _searchCtrl.text.toLowerCase();
      final matchSearch = query.isEmpty || a.tipo.toLowerCase().contains(query);
      final matchEstado = _filtroEstado == 'Todos' || a.estado == _filtroEstado;
      return matchSearch && matchEstado;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: IndexedStack(
        index: _tab,
        children: [
          _buildMisAnticipos(provider, filtrados),
          DriverProfile(user: widget.user, anticipos: misAnticipos),
          _buildSolicitar(provider),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildMisAnticipos(AnticipoProvider provider, List<Anticipo> filtrados) {
    return Column(
      children: [
        GradientHeader(
          title: 'Mis anticipos',
          subtitle: 'Gestiona tus anticipos y excedentes',
          gradStart: AppColors.driverGradStart,
          gradEnd: AppColors.driverGradEnd,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppColors.textMain, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por tipo de anticipo...',
                    hintStyle: TextStyle(color: AppColors.textSub, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSub, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => setState(() => _showFiltros = !_showFiltros),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_alt_outlined, size: 16, color: AppColors.textSub),
                        SizedBox(width: 6),
                        Text('Filtros', style: TextStyle(color: AppColors.textMain, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showFiltros) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: [
                      const Text('Estado:', style: TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _filtroEstado,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: ['Todos', 'Activo', 'Pendiente', 'Pagado'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _filtroEstado = v!),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : filtrados.isEmpty
                  ? const Center(child: Text('Sin anticipos', style: TextStyle(color: AppColors.textSub, fontSize: 14)))
                  : RefreshIndicator(
                      onRefresh: () => provider.loadAnticipos(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: filtrados.length,
                        itemBuilder: (_, i) => AnticipoCard(
                          anticipo: filtrados[i],
                          isAdmin: false,
                          onVer: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnticipoDetail(anticipo: filtrados[i], isAdmin: false))),
                          onEditar: () async {
                            final updated = await Navigator.push<Anticipo>(context, MaterialPageRoute(builder: (_) => AnticipoEdit(anticipo: filtrados[i], isAdmin: false)));
                            if (updated != null) await provider.loadAnticipos();
                          },
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildSolicitar(AnticipoProvider provider) {
    return Column(
      children: [
        GradientHeader(
          title: 'Solicitar anticipo',
          subtitle: 'Crea una nueva solicitud',
          gradStart: AppColors.driverGradStart,
          gradEnd: AppColors.driverGradEnd,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: AppColors.blueBg, borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.add_circle_outline_rounded, color: AppColors.driverPrimary, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nueva solicitud', style: TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Registra un nuevo anticipo para tus gastos de ruta.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSub, fontSize: 14)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () async {
                      final nuevo = await Navigator.push<Anticipo>(context, MaterialPageRoute(builder: (_) => const AnticipoEdit(isAdmin: false)));
                      if (nuevo != null) {
                        await provider.crearAnticipo(nuevo);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anticipo solicitado'), backgroundColor: AppColors.green));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.driverGradStart, AppColors.driverGradEnd]), borderRadius: BorderRadius.circular(14)),
                      child: const Text('Crear solicitud', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.grid_view_rounded, 'label': 'Inicio'},
      {'icon': Icons.person_outline_rounded, 'label': 'Perfil'},
      {'icon': Icons.add_circle_outline_rounded, 'label': 'Solicitar'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(items[i]['icon'] as IconData, color: _tab == i ? AppColors.driverPrimary : AppColors.textSub, size: 24),
                    const SizedBox(height: 4),
                    Text(items[i]['label'] as String, style: TextStyle(color: _tab == i ? AppColors.driverPrimary : AppColors.textSub, fontSize: 11, fontWeight: _tab == i ? FontWeight.w700 : FontWeight.w400)),
                  ],
                ),
              ),
            )),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
