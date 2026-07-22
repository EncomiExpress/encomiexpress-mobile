import 'package:flutter/material.dart';
import '../../../../core/models.dart';
import '../../../../core/services/anticipo_service.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets.dart';
import 'admin_profile.dart';
import 'anticipo_detail.dart';
import 'anticipo_edit.dart';

class AdminHome extends StatefulWidget {
  final UserModel user;
  const AdminHome({super.key, required this.user});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

// Mismos 12 meses que usa el filtro Año/Mes en ListarAnticipoExcedente.jsx
// (web) — value es lo que se manda al backend, label es lo que se muestra.
const _meses = [
  {'value': '1', 'label': 'Enero'}, {'value': '2', 'label': 'Febrero'},
  {'value': '3', 'label': 'Marzo'}, {'value': '4', 'label': 'Abril'},
  {'value': '5', 'label': 'Mayo'}, {'value': '6', 'label': 'Junio'},
  {'value': '7', 'label': 'Julio'}, {'value': '8', 'label': 'Agosto'},
  {'value': '9', 'label': 'Septiembre'}, {'value': '10', 'label': 'Octubre'},
  {'value': '11', 'label': 'Noviembre'}, {'value': '12', 'label': 'Diciembre'},
];

class _AdminHomeState extends State<AdminHome> {
  final _anticipoService = AnticipoService();
  late List<Anticipo> _anticipos;
  bool _loading = true;
  String _filtroEstado = 'Estado';
  String _filtroAnio = 'Año';
  // Guarda el número de mes ('1'..'12') que espera el backend, no el label.
  String _filtroMes = '';
  List<String> _aniosDisponibles = [];

  @override
  void initState() {
    super.initState();
    _anticipos = [];
    _loadAnticipos();
    _loadAniosDisponibles();
    ThemeController().addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ThemeController().removeListener(_onThemeChanged);
    super.dispose();
  }

  // Filtrado server-side (estado/año/mes) — mismo mecanismo que
  // ListarAnticipoExcedente.jsx (web): cada cambio de filtro vuelve a pedirle
  // al backend, en vez de filtrar solo entre los últimos 100 ya cargados.
  // Nota: sigue sin paginación real — se trae un límite alto en cada consulta.
  Future<void> _loadAnticipos() async {
    setState(() => _loading = true);
    final result = await _anticipoService.getAnticipos(
      limit: 100,
      estado: _filtroEstado == 'Estado' ? null : _filtroEstado,
      anio: _filtroAnio == 'Año' ? null : _filtroAnio,
      mes: _filtroMes.isEmpty ? null : _filtroMes,
    );
    if (mounted) {
      setState(() {
        _anticipos = result['data'] as List<Anticipo>;
        _loading = false;
      });
    }
  }

  Future<void> _loadAniosDisponibles() async {
    final anios = await _anticipoService.getAniosDisponibles();
    if (mounted) setState(() => _aniosDisponibles = anios);
  }

  double get _totalAnticipos =>
      _anticipos.fold(0, (s, a) => s + a.valorAnticipo);
  double get _totalGastado =>
      _anticipos.fold(0, (s, a) => s + a.valorGastado);
  double get _totalExcedentes => _anticipos
      .where((a) => a.estado == EstadoAnticipo.excedentePendiente)
      .fold(0, (s, a) => s + a.excedente);
  int get _porConfirmar =>
      _anticipos.where((a) => a.estado == EstadoAnticipo.excedentePendiente).length;

  Future<void> _confirmarDevolucion(Anticipo a) async {
    final confirmado = await confirmarDialog(
      context,
      titulo: 'Confirmar devolución',
      mensaje: '¿El conductor devolvió el excedente? El anticipo pasará a Completado '
          'y la fecha de entrega del excedente quedará registrada a la de hoy.',
      textoConfirmar: 'Confirmar',
    );
    if (!confirmado || !mounted) return;

    final result = await _anticipoService.entregarExcedente(a.id);
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        final idx = _anticipos.indexWhere((x) => x.id == a.id);
        if (idx != -1) _anticipos[idx] = result['anticipo'] as Anticipo;
      });
      showAppSnackBar(context, 'Devolución confirmada');
    } else {
      showAppSnackBar(context, result['message'] ?? 'Error al confirmar la devolución', severity: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.gradientNavbar,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          GradientHeader(
            title: '${greeting()} ${widget.user.nombre}',
            subtitleWidget: LiveDateTime(
              style: TextStyle(color: AppColors.textSub, fontSize: 13),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // El toggle de claro/oscuro ya vive dentro de PersonalizarSheet
                // (ícono de paleta) — igual que en driver_home.dart, sin ícono
                // de luna suelto aparte.
                AnimatedPaletteIcon(
                  color: AppColors.textSub,
                  size: 24,
                  onTap: () => PersonalizarSheet.show(context),
                ),
                const SizedBox(width: 14),
                TapArea(
                  onTap: _loadAnticipos,
                  child: Icon(Icons.refresh_outlined,
                      color: AppColors.textSub, size: 26),
                ),
                const SizedBox(width: 12),
                TapArea(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => AdminProfile(user: widget.user,
                              anticipos: _anticipos))),
                  child: UserAvatar(nombre: widget.user.nombreCompleto),
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
                                label: 'Excedentes pendientes',
                                value: formatCOP(_totalExcedentes),
                                icon: Icons.access_time_rounded,
                                iconColor: AppColors.orange,
                                iconBg: AppColors.orangeBg,
                              ),
                              StatCard(
                                label: 'Por confirmar',
                                value: '$_porConfirmar',
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
                                Row(
                                  children: [
                                    Icon(Icons.filter_alt_outlined,
                                        size: 18, color: AppColors.textSub),
                                    const SizedBox(width: 6),
                                    Text('Filtros',
                                        style: TextStyle(
                                            color: AppColors.textMain,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // Mismo componente y estilo (con "chulito" de
                                // seleccionado) que el filtro de Estado del
                                // conductor (driver_home.dart) — Año/Mes con el
                                // mismo funcionamiento que ListarAnticipoExcedente.jsx
                                // (web): elegir Año resetea Mes, y Mes queda
                                // deshabilitado hasta que haya un Año elegido.
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    FilterSelect(
                                      label: 'Estado',
                                      value: _filtroEstado,
                                      items: ['Estado', ...EstadoAnticipo.todos],
                                      alignLeft: true,
                                      onChanged: (v) {
                                        setState(() => _filtroEstado = v);
                                        _loadAnticipos();
                                      },
                                    ),
                                    FilterSelect(
                                      label: 'Año',
                                      value: _filtroAnio,
                                      items: ['Año', ..._aniosDisponibles],
                                      alignLeft: true,
                                      onChanged: (v) {
                                        setState(() {
                                          _filtroAnio = v;
                                          _filtroMes = '';
                                        });
                                        _loadAnticipos();
                                      },
                                    ),
                                    Builder(builder: (_) {
                                      final mesSentinel = _filtroAnio == 'Año' ? 'Mes' : 'Todos';
                                      final mesValue = _filtroMes.isEmpty
                                          ? mesSentinel
                                          : _meses.firstWhere((m) => m['value'] == _filtroMes)['label']!;
                                      return IgnorePointer(
                                        ignoring: _filtroAnio == 'Año',
                                        child: Opacity(
                                          opacity: _filtroAnio == 'Año' ? 0.5 : 1,
                                          child: FilterSelect(
                                            label: mesSentinel,
                                            value: mesValue,
                                            items: [mesSentinel, ..._meses.map((m) => m['label']!)],
                                            onChanged: (v) {
                                              setState(() {
                                                _filtroMes = v == mesSentinel
                                                    ? ''
                                                    : _meses.firstWhere((m) => m['label'] == v)['value']!;
                                              });
                                              _loadAnticipos();
                                            },
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (_anticipos.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Text('Sin anticipos',
                                  style: TextStyle(color: AppColors.textSub, fontSize: 14)),
                            )
                          else
                            ..._anticipos.map((a) => AnticipoCard(
                              anticipo: a,
                              isAdmin: true,
                              onVer: () async {
                                final updated = await Navigator.push<Anticipo>(context,
                                    MaterialPageRoute(
                                        builder: (_) => AnticipoDetail(
                                            anticipo: a, isAdmin: true)));
                                if (updated != null) _reemplazar(updated);
                              },
                              onEditar: a.esEditable
                                  ? () async {
                                      final updated = await Navigator.push<Anticipo>(context,
                                          MaterialPageRoute(
                                              builder: (_) => AnticipoEdit(
                                                  anticipo: a, isAdmin: true)));
                                      if (updated != null) _reemplazar(updated);
                                    }
                                  : null,
                              onConfirmarDevolucion: () => _confirmarDevolucion(a),
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
                  builder: (_) => const AnticipoEdit(isAdmin: true)));
          if (nuevo != null) setState(() => _anticipos.insert(0, nuevo));
        },
        backgroundColor: AppColors.adminPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _reemplazar(Anticipo updated) {
    setState(() {
      final idx = _anticipos.indexWhere((x) => x.id == updated.id);
      if (idx != -1) _anticipos[idx] = updated;
    });
  }
}
