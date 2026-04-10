import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/anticipo.dart';
import '../../presentation/providers/anticipo_provider.dart';
import '../../presentation/widgets/anticipo_card.dart';

class AdminHomeScreen extends StatefulWidget {
  final AnticipoProvider provider;
  final String userId;
  final String userName;

  const AdminHomeScreen({
    super.key,
    required this.provider,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String _filtroEstado = 'Todos';
  String _filtroConductor = 'Todos';

  @override
  void initState() {
    super.initState();
    widget.provider.loadAnticipos();
  }

  List<Anticipo> get _filtrados {
    return widget.provider.anticipos.where((a) {
      final okEstado = _filtroEstado == 'Todos' || a.estado == _filtroEstado;
      final okCond = _filtroConductor == 'Todos' ||
          a.conductorNombre == _filtroConductor;
      return okEstado && okCond;
    }).toList();
  }

  double get _totalAnticipos =>
      widget.provider.anticipos.fold(0, (s, a) => s + a.anticipo);
  double get _totalGastado =>
      widget.provider.anticipos.fold(0, (s, a) => s + a.gastado);
  double get _totalExcedentes =>
      widget.provider.anticipos.where((a) => a.excedente > 0).fold(0, (s, a) => s + a.excedente);
  int get _pendientes => widget.provider.pendientes;

  List<String> get _conductores {
    final names = widget.provider.anticipos.map((a) => a.conductorNombre).toSet().toList();
    return ['Todos', ...names];
  }

  void _aprobar(Anticipo a) async {
    final success = await widget.provider.aprobarAnticipo(a.id);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anticipo ${a.id} aprobado'),
            backgroundColor: Colors.green));
    }
  }

  void _rechazar(Anticipo a) async {
    final success = await widget.provider.rechazarAnticipo(a.id);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anticipo ${a.id} rechazado'),
            backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B2FBE), Color(0xFF9B59B6)],
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
                    const Text('Panel Administrador',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const Text('Gestión completa de anticipos',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
                GestureDetector(
                  onTap: () => widget.provider.loadAnticipos(),
                  child: const Icon(Icons.refresh,
                      color: Colors.white, size: 26),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.provider.loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => widget.provider.loadAnticipos(),
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
                              _buildStatCard('Total anticipos', formatCOP(_totalAnticipos),
                                  Icons.trending_up_rounded, const Color(0xFF3B82F6)),
                              _buildStatCard('Total gastado', formatCOP(_totalGastado),
                                  Icons.attach_money_rounded, const Color(0xFF22C55E)),
                              _buildStatCard('Excedentes', formatCOP(_totalExcedentes),
                                  Icons.access_time_rounded, const Color(0xFFF59E0B)),
                              _buildStatCard('Pendientes', '$_pendientes',
                                  Icons.filter_alt_outlined, const Color(0xFFF59E0B)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildFiltros(),
                          ..._filtrados.map((a) => AnticipoCard(
                            anticipo: a,
                            isAdmin: true,
                            onVer: () {},
                            onEditar: () {},
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
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.filter_alt_outlined,
                  size: 18, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text('Filtros',
                  style: TextStyle(
                      color: Color(0xFF1E293B),
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
                            color: Color(0xFF64748B), fontSize: 12)),
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
                            color: Color(0xFF64748B), fontSize: 12)),
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
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF64748B)),
        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}