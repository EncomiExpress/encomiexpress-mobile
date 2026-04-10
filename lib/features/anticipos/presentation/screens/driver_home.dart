import 'package:flutter/material.dart';
import '../../domain/entities/anticipo.dart';
import '../../presentation/providers/anticipo_provider.dart';
import '../../presentation/widgets/anticipo_card.dart';

class DriverHomeScreen extends StatefulWidget {
  final AnticipoProvider provider;
  final String userId;
  final String userName;

  const DriverHomeScreen({
    super.key,
    required this.provider,
    required this.userId,
    required this.userName,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _tab = 0;
  final _searchCtrl = TextEditingController();
  bool _showFiltros = false;
  String _filtroEstado = 'Todos';

  @override
  void initState() {
    super.initState();
    widget.provider.loadAnticipos();
    _searchCtrl.addListener(() => setState(() {}));
  }

  List<Anticipo> get _misAnticipos =>
      widget.provider.anticipos.where((a) => a.conductorId == widget.userId).toList();

  List<Anticipo> get _filtrados {
    return _misAnticipos.where((a) {
      final query = _searchCtrl.text.toLowerCase();
      final matchSearch = query.isEmpty || a.tipo.toLowerCase().contains(query);
      final matchEstado = _filtroEstado == 'Todos' || a.estado == _filtroEstado;
      return matchSearch && matchEstado;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: IndexedStack(
        index: _tab,
        children: [
          _buildMisAnticipos(),
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
              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
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
                  const Text('Gestiona tus anticipos y excedentes',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
              GestureDetector(
                onTap: widget.provider.loading ? null : () => widget.provider.loadAnticipos(),
                child: const Icon(Icons.refresh, color: Colors.white, size: 26),
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
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por tipo de anticipo...',
                    hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Color(0xFF64748B), size: 20),
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_alt_outlined, size: 16, color: Color(0xFF64748B)),
                        SizedBox(width: 6),
                        Text('Filtros',
                            style: TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
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
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Text('Estado:',
                          style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _filtroEstado,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: ['Todos', 'Activo', 'Pendiente', 'Pagado']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
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
          child: widget.provider.loading
              ? const Center(child: CircularProgressIndicator())
              : _filtrados.isEmpty
                  ? const Center(
                      child: Text('Sin anticipos',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 14)))
                  : RefreshIndicator(
                      onRefresh: () => widget.provider.loadAnticipos(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: _filtrados.length,
                        itemBuilder: (_, i) => AnticipoCard(
                          anticipo: _filtrados[i],
                          isAdmin: false,
                          onVer: () {},
                          onEditar: () {},
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
              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
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
                  style: TextStyle(color: Colors.white, fontSize: 13)),
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
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.add_circle_outline_rounded,
                        color: Color(0xFF2563EB), size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nueva solicitud',
                      style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                      'Registra un nuevo anticipo para tus gastos de ruta.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
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
      {'icon': Icons.add_circle_outline_rounded, 'label': 'Solicitar'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
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
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF64748B),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          color: _tab == i
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: _tab == i ? FontWeight.w700 : FontWeight.w400,
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