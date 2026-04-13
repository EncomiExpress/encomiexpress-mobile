import 'package:flutter/material.dart';
import '../../../../core/models.dart';
import '../../../../core/widgets.dart';
import '../../auth/screens/login_screen.dart';

class AdminProfile extends StatelessWidget {
  final UserModel user;
  final List<Anticipo> anticipos;

  const AdminProfile({super.key, required this.user, required this.anticipos});

  @override
  Widget build(BuildContext context) {
    final pendientes = anticipos.where((a) => a.estado == 'Pendiente').length;
    final aprobados  = anticipos.where((a) => a.estado == 'Pagado').length;
    final conductores = anticipos.map((a) => a.conductorId).toSet().length;

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.adminGradStart, AppColors.adminGradEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 12, 20, 28),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text('Perfil de administrador',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15),
                            blurRadius: 12)
                      ],
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: AppColors.adminPrimary, size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(user.nombre,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Admin',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Información personal',
                            style: TextStyle(
                                color: AppColors.textMain,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 14),
                        InfoRow(
                          icon: Icons.person_outline_rounded,
                          iconColor: AppColors.purple,
                          iconBg: AppColors.purpleBg,
                          label: 'Nombre completo',
                          value: user.nombre,
                        ),
                        InfoRow(
                          icon: Icons.email_outlined,
                          iconColor: AppColors.green,
                          iconBg: AppColors.greenBg,
                          label: 'Correo electrónico',
                          value: user.email,
                        ),
                        if (user.telefono.isNotEmpty)
                          InfoRow(
                            icon: Icons.phone_outlined,
                            iconColor: AppColors.blue,
                            iconBg: AppColors.blueBg,
                            label: 'Teléfono',
                            value: user.telefono,
                          ),
                        InfoRow(
                          icon: Icons.shield_outlined,
                          iconColor: AppColors.purple,
                          iconBg: AppColors.purpleBg,
                          label: 'Rol',
                          value: 'Admin',
                        ),
                      ],
                    ),
                  ),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estadísticas del sistema',
                            style: TextStyle(
                                color: AppColors.textMain,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 14),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.8,
                          children: [
                            _miniStat('${anticipos.length}', 'Anticipos totales',
                                AppColors.purple, AppColors.purpleBg),
                            _miniStat('$conductores', 'Conductores',
                                AppColors.blue, AppColors.blueBg),
                            _miniStat('$pendientes', 'Pendientes',
                                AppColors.orange, AppColors.orangeBg),
                            _miniStat('$aprobados', 'Aprobados',
                                AppColors.green, AppColors.greenBg),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Privilegios de administrador',
                            style: TextStyle(
                                color: AppColors.textMain,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 14),
                        ...[
                          'Crear y editar anticipos',
                          'Aprobar y rechazar legalizaciones',
                          'Ver todos los conductores',
                          'Gestión completa del sistema',
                        ].map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.circle,
                                  color: AppColors.purple, size: 8),
                              const SizedBox(width: 10),
                              Text(p,
                                  style: const TextStyle(
                                      color: AppColors.textMain,
                                      fontSize: 14)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (r) => false,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.red.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: AppColors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Cerrar sesión',
                              style: TextStyle(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSub, fontSize: 11)),
        ],
      ),
    );
  }
}