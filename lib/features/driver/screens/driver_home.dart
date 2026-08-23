import 'package:flutter/material.dart';
import '../../../../core/models.dart';
import '../../../../core/services/anticipo_service.dart';
import '../../../../core/services/conductor_service.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets.dart';
import '../../admin/screens/anticipo_detail.dart';
import '../../admin/screens/anticipo_edit.dart';
import 'driver_profile.dart';
import 'driver_paquetes.dart';

class DriverHome extends StatefulWidget {
  final UserModel user;
  const DriverHome({super.key, required this.user});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  final _anticipoService = AnticipoService();
  final _conductorService = ConductorService();
  late List<Anticipo> _anticipos;
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _filtroEstado = 'Estado';
  late UserModel _currentUser;
  int _itemsToShow = 5;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _anticipos = [];
    _currentUser = widget.user;
    _loadPerfil();
    _loadAnticipos();
    _searchCtrl.addListener(_onSearchChanged);
    ThemeController().addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() => _itemsToShow = 5);
    }
  }

  @override
  void dispose() {
    ThemeController().removeListener(_onThemeChanged);
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPerfil() async {
    final perfil = await _conductorService.getPerfil();
    if (perfil != null && mounted) {
      setState(() {
        _currentUser = perfil;
      });
    }
  }

  void _onUserUpdated(UserModel updatedUser) {
    setState(() {
      _currentUser = updatedUser;
    });
  }

  // GET /api/conductores/mis-anticipos — el idConductor sale del token, no
  // hay que mandarlo. El listado genérico /api/anticipos exige un permiso
  // que el rol conductor no tiene.
  Future<void> _loadAnticipos() async {
    setState(() => _loading = true);
    final data = await _anticipoService.getMisAnticipos();
    if (mounted) {
      setState(() {
        _anticipos = data;
        _loading = false;
        _itemsToShow = 5;
      });
    }
  }

  List<Anticipo> get _filtrados {
    return _anticipos.where((a) {
      final query = _searchCtrl.text.trim().toLowerCase();
      final matchSearch =
          query.isEmpty ||
          (a.nombreRuta ?? '').toLowerCase().contains(query) ||
          a.id.toString().contains(query);
      final matchEstado =
          _filtroEstado == 'Estado' || a.estado == _filtroEstado;
      return matchSearch && matchEstado;
    }).toList();
  }

  List<Anticipo> get _visibleAnticipos =>
      _filtrados.take(_itemsToShow).toList();

  bool get _hayMas => _itemsToShow < _filtrados.length;

  void _mostrarMas() {
    if (_hayMas) {
      setState(
        () => _itemsToShow = (_itemsToShow + 5).clamp(0, _filtrados.length),
      );
    }
  }

  void _abrirPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DriverProfile(user: _currentUser, onUserUpdated: _onUserUpdated),
      ),
    );
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
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              20,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${greeting()} ${_currentUser.nombre}',
                        style: TextStyle(
                          color: AppColors.textMain,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cambria',
                        ),
                      ),
                      LiveDateTime(
                        style: TextStyle(color: AppColors.textSub, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox.shrink(),
              ],
            ),
          ),
          Expanded(
            child: _tabIndex == 0
                ? _buildMisAnticipos()
                : DriverPaquetes(user: _currentUser),
          ),
        ],
      ),
      bottomNavigationBar: BottomMenuBar(
        items: [
          BottomMenuItem(
            icon: Icons.palette_outlined,
            label: 'Tema',
            onTap: () => PersonalizarSheet.show(context),
          ),
          BottomMenuItem(
            icon: Icons.monetization_on,
            label: 'Anticipos',
            active: _tabIndex == 0,
            onTap: () => setState(() => _tabIndex = 0),
          ),
          BottomMenuItem(
            icon: Icons.inventory_2_outlined,
            label: 'Paquetes',
            active: _tabIndex == 1,
            onTap: () => setState(() => _tabIndex = 1),
          ),
          BottomMenuItem(
            icon: Icons.person_outline,
            label: 'Perfil',
            onTap: _abrirPerfil,
          ),
        ],
      ),
    );
  }

  Widget _buildMisAnticipos() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SearchField(
                  controller: _searchCtrl,
                  hint: 'Buscar por ruta...',
                ),
              ),
              const SizedBox(width: 10),
              FilterSelect(
                label: 'Estado',
                value: _filtroEstado,
                items: ['Estado', ...EstadoAnticipo.todos],
                onChanged: (v) => setState(() => _filtroEstado = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadAnticipos,
                  // Lista vacía envuelta igual en un ListView (no un simple
                  // Center) para que arrastrar hacia abajo siga refrescando
                  // aunque no haya anticipos que mostrar.
                  child: _filtrados.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                            Center(
                              child: Text(
                                'Sin anticipos',
                                style: TextStyle(color: AppColors.textSub, fontSize: 14),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _visibleAnticipos.length + (_hayMas ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i < _visibleAnticipos.length) {
                        final a = _visibleAnticipos[i];
                        return AnticipoCard(
                          anticipo: a,
                          isAdmin: false,
                          onVer: () async {
                            final updated = await Navigator.push<Anticipo>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AnticipoDetail(anticipo: a, isAdmin: false),
                              ),
                            );
                            if (updated != null) _reemplazar(updated);
                          },
                          // El conductor solo legaliza — solo tiene sentido
                          // editar mientras el anticipo está "En Legalización".
                          onEditar: a.estado == EstadoAnticipo.enLegalizacion
                              ? () async {
                                  final updated =
                                      await Navigator.push<Anticipo>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AnticipoEdit(
                                            anticipo: a,
                                            isAdmin: false,
                                          ),
                                        ),
                                      );
                                  if (updated != null) _reemplazar(updated);
                                }
                              : null,
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: OutlinedButton(
                          onPressed: _mostrarMas,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Mostrar 5 más',
                            style: TextStyle(color: AppColors.textMain),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _reemplazar(Anticipo updated) {
    setState(() {
      final idx = _anticipos.indexWhere((x) => x.id == updated.id);
      if (idx != -1) _anticipos[idx] = updated;
    });
  }
}
