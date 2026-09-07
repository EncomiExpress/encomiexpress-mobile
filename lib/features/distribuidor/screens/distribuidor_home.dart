import 'package:flutter/material.dart';
import '../../../../core/models.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets.dart';
import '../../auth/screens/login_screen.dart';
import 'distribuidor_paquetes.dart';

/// Home del rol 'distribuidor' (encargado de sede) — versión reducida del home
/// del conductor: barra inferior Tema / Paquetes / Perfil, sin "Anticipos".
/// La pestaña "Paquetes" muestra los paquetes "En sede de destino" de la sede
/// que cubre y deja registrar la entrega final al destinatario.
class DistribuidorHome extends StatefulWidget {
  final UserModel user;
  const DistribuidorHome({super.key, required this.user});

  @override
  State<DistribuidorHome> createState() => _DistribuidorHomeState();
}

class _DistribuidorHomeState extends State<DistribuidorHome> {
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
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

  void _abrirPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _DistribuidorPerfil(user: _currentUser)),
    );
  }

  String get _resumenSedes {
    final nombres = _currentUser.sedes
        .map((s) => (s['municipio'] ?? '').toString())
        .where((n) => n.isNotEmpty)
        .toList();
    if (nombres.isEmpty) return 'Sin sede asignada';
    return nombres.join(' · ');
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
          if (_currentUser.sedes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Icon(Icons.location_city_outlined,
                      size: 15, color: AppColors.textSub),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_resumenSedes,
                        style: TextStyle(
                            color: AppColors.textSub, fontSize: 12)),
                  ),
                ],
              ),
            ),
          Expanded(child: DistribuidorPaquetes(user: _currentUser)),
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
            icon: Icons.inventory_2_outlined,
            label: 'Paquetes',
            active: true,
            onTap: () {},
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
}

/// Perfil de solo lectura para el distribuidor — el rol no tiene endpoint de
/// autogestión (GET/PUT /conductores/perfil es solo para conductores). Muestra
/// los datos que ya vinieron en el login + la sede que cubre.
class _DistribuidorPerfil extends StatelessWidget {
  final UserModel user;
  const _DistribuidorPerfil({required this.user});

  @override
  Widget build(BuildContext context) {
    final sedes = user.sedes
        .map((s) => (s['municipio'] ?? '').toString())
        .where((n) => n.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        title: const Text('Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  UserAvatar(nombre: user.nombreCompleto, size: 72),
                  const SizedBox(height: 12),
                  Text(user.nombreCompleto,
                      style: TextStyle(
                        color: AppColors.textMain,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      )),
                  Text('Encargado de sede',
                      style: TextStyle(color: AppColors.textSub, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            InfoRow(
              icon: Icons.email_outlined,
              iconColor: AppColors.blue,
              iconBg: AppColors.blueBg,
              label: 'Correo',
              value: user.email.isEmpty ? '—' : user.email,
            ),
            InfoRow(
              icon: Icons.phone_outlined,
              iconColor: AppColors.green,
              iconBg: AppColors.greenBg,
              label: 'Teléfono',
              value: user.telefono.isEmpty ? '—' : user.telefono,
            ),
            InfoRow(
              icon: Icons.location_city_outlined,
              iconColor: AppColors.orange,
              iconBg: AppColors.orangeBg,
              label: 'Sede',
              value: sedes.isEmpty ? '—' : sedes.join(', '),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await AuthService().logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
                  );
                },
                style: ButtonStyle(
                  shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  backgroundColor: WidgetStateProperty.all(AppColors.adminPrimary),
                  elevation: WidgetStateProperty.all(3),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Cerrar sesión',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
