import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../login_screen.dart';
import 'driver_profile_edit.dart';

class DriverProfile extends StatefulWidget {
  final UserModel user;
  final List<Anticipo> anticipos;
  final Function(UserModel)? onUserUpdated;

  const DriverProfile({
    super.key, 
    required this.user, 
    required this.anticipos,
    this.onUserUpdated,
  });

  @override
  State<DriverProfile> createState() => _DriverProfileState();
}

class _DriverProfileState extends State<DriverProfile> {
  late UserModel _localUser;

  @override
  void initState() {
    super.initState();
    _localUser = widget.user;
  }

  void _onUserUpdated(UserModel updatedUser) {
    setState(() {
      _localUser = updatedUser;
    });
    widget.onUserUpdated?.call(updatedUser);
  }

  @override
  Widget build(BuildContext context) {
    final legalizados = widget.anticipos.where((a) => a.estado == 'Pagado').length;
    final pendientes  = widget.anticipos.where((a) => a.estado == 'Pendiente').length;
    final enProceso   = widget.anticipos.where((a) => a.estado == 'Activo').length;

    return SingleChildScrollView(
      child: Column(
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
                20, MediaQuery.of(context).padding.top + 12, 20, 28),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Mi perfil',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12)
                    ],
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      color: AppColors.driverPrimary, size: 34),
                ),
                const SizedBox(height: 12),
                Text(_localUser.nombre,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Conductor',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
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
                        iconColor: AppColors.blue,
                        iconBg: AppColors.blueBg,
                        label: 'Nombre completo',
                        value: _localUser.nombre,
                      ),
                      InfoRow(
                        icon: Icons.email_outlined,
                        iconColor: AppColors.green,
                        iconBg: AppColors.greenBg,
                        label: 'Correo electrónico',
                        value: _localUser.email,
                      ),
                      InfoRow(
                        icon: Icons.phone_outlined,
                        iconColor: AppColors.purple,
                        iconBg: AppColors.purpleBg,
                        label: 'Teléfono',
                        value: _localUser.telefono,
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mis estadísticas',
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
                          _miniStat('${widget.anticipos.length}', 'Anticipos totales',
                              AppColors.blue, AppColors.blueBg),
                          _miniStat('$legalizados', 'Legalizados',
                              AppColors.green, AppColors.greenBg),
                          _miniStat('$pendientes', 'Pendientes',
                              AppColors.orange, AppColors.orangeBg),
                          _miniStat('$enProceso', 'En proceso',
                              AppColors.purple, AppColors.purpleBg),
                        ],
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.edit_outlined,
                        color: AppColors.driverPrimary),
                    title: const Text('Editar perfil',
                        style: TextStyle(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textSub),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverProfileEdit(
                            user: _localUser,
                            onSave: (updatedUser) {
                              _onUserUpdated(updatedUser);
                            },
                          ),
                        ),
                      );
                    },
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
                      border: Border.all(
                          color: AppColors.red.withOpacity(0.3)),
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
    );
  }

  Widget _miniStat(String value, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
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