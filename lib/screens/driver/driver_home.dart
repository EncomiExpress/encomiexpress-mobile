import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/anticipo_service.dart';
import '../../widgets/widgets.dart';
import '../admin/anticipo_detail.dart';
import '../admin/anticipo_edit.dart';
import 'driver_profile.dart';

class DriverHome extends StatefulWidget {
  final UserModel user;
  const DriverHome({super.key, required this.user});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  final _anticipoService = AnticipoService();
  int _tab = 0;
  late List<Anticipo> _anticipos;
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  bool _showFiltros = false;
  String _filtroEstado = 'Todos';
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _anticipos = [];
    _currentUser = widget.user;
    _loadAnticipos();
    _searchCtrl.addListener(() => setState(() {}));
  }

  void _onUserUpdated(UserModel updatedUser) {
    setState(() {
      _currentUser = updatedUser;
    });
  }

  Future<void> _loadAnticipos() async {
    setState(() => _loading = true);
    final conductorId = widget.user.conductorId;
    final data = await _anticipoService.getAnticipos(conductorId: conductorId);
    if (mounted) {
      setState(() {
        _anticipos = data;
        _loading = false;
      });
    }
  }

  List<Anticipo> get _filtrados {
    return _anticipos.where((a) {
      final query = _searchCtrl.text.toLowerCase();
      final matchSearch = query.isEmpty ||
          a.tipo.toLowerCase().contains(query);
      final matchEstado = _filtroEstado == 'Todos' ||
          a.estado == _filtroEstado;
      return matchSearch && matchEstado;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: IndexedStack(
        index: _tab,
        children: [
          _buildMisAnticipos(),
          DriverProfile(
            user: _currentUser, 
            anticipos: _anticipos,
            onUserUpdated: _onUserUpdated,
          ),
          _buildSolicitar(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildMisAnticipos() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.driverGradStart, AppColors.driverGradEnd],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 16, 20, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mis anticipos',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                  Text('Gestiona tus anticipos y excedentes',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ],
              ),
              GestureDetector(
                onTap: _loading ? null : _loadAnticipos,
                child: const Icon(Icons.refresh,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(
                      color: AppColors.textMain, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por tipo de anticipo...',
                    hintStyle:
                        TextStyle(color: AppColors.textSub, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.textSub, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _showFiltros = !_showFiltros),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_alt_outlined,
                            size: 16, color: AppColors.textSub),
                        SizedBox(width: 6),
                        Text('Filtros',
                            style: TextStyle(
                                color: AppColors.textMain, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showFiltros) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Text('Estado:',
                          style: TextStyle(
                              color: AppColors.textMain,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _filtroEstado,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: ['Todos', 'Activo', 'Pendiente', 'Pagado']
                              .map((e) => DropdownMenuItem(
                                  value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _filtroEstado = v!),
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtrados.isEmpty
                  ? Center(
                      child: Text('Sin anticipos',
                          style: TextStyle(
                              color: AppColors.textSub, fontSize: 14)))
                  : RefreshIndicator(
                      onRefresh: _loadAnticipos,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: _filtrados.length,
                        itemBuilder: (_, i) => AnticipoCard(
                          anticipo: _filtrados[i],
                          isAdmin: false,
                          onVer: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => AnticipoDetail(
                                      anticipo: _filtrados[i],
                                      isAdmin: false))),
                          onEditar: () async {
                            final updated =
                                await Navigator.push<Anticipo>(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AnticipoEdit(
                                            anticipo: _filtrados[i],
                                            isAdmin: false)));
                            if (updated != null) {
                              setState(() {
                                final idx = _anticipos
                                    .indexWhere((x) => x.id == updated.id);
                                if (idx != -1) _anticipos[idx] = updated;
                              });
                            }
                          },
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildSolicitar() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.driverGradStart, AppColors.driverGradEnd],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 16, 20, 20),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Solicitar anticipo',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              Text('Crea una nueva solicitud',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13)),
            ],
          ),
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
                    decoration: BoxDecoration(
                        color: AppColors.blueBg,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.add_circle_outline_rounded,
                        color: AppColors.driverPrimary, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nueva solicitud',
                      style: TextStyle(
                          color: AppColors.textMain,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                      'Registra un nuevo anticipo para tus gastos de ruta.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSub, fontSize: 14)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Solo el administrador puede crear anticipos'),
                            backgroundColor: AppColors.orange),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.driverGradStart,
                            AppColors.driverGradEnd
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('Crear solicitud',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(
              items.length,
              (i) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        color: _tab == i
                            ? AppColors.driverPrimary
                            : AppColors.textSub,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          color: _tab == i
                              ? AppColors.driverPrimary
                              : AppColors.textSub,
                          fontSize: 11,
                          fontWeight: _tab == i
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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