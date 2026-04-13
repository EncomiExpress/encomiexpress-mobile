import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../usuarios/domain/entities/usuario.dart';

class DriverProfileScreen extends StatelessWidget {
  final Usuario user;
  final List<dynamic> anticipos;
  final VoidCallback onLogout;

  const DriverProfileScreen({
    super.key,
    required this.user,
    required this.anticipos,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final misAnticipos = anticipos.where((a) => a.conductorId == user.id).toList();
    final totalAnticipos = misAnticipos.fold(0.0, (s, a) => s + (a.anticipo as num).toDouble());
    final totalGastado = misAnticipos.fold(0.0, (s, a) => s + (a.gastado as num).toDouble());
    final pendientes = misAnticipos.where((a) => a.estado == 'Pendiente').length;
    final activos = misAnticipos.where((a) => a.estado == 'Activo').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
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
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 40),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: onLogout,
                      child: const Icon(Icons.logout, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  user.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                if (user.telefono.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.telefono,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Conductor',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatCard('Total anticipos', formatCOP(totalAnticipos), Icons.trending_up_rounded, const Color(0xFF3B82F6)),
                  const SizedBox(height: 12),
                  _buildStatCard('Total gastado', formatCOP(totalGastado), Icons.attach_money_rounded, const Color(0xFF22C55E)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMiniStat('Pendientes', '$pendientes', const Color(0xFFF59E0B))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMiniStat('Activos', '$activos', const Color(0xFF22C55E))),
                    ],
                  ),
                ],
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
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
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}