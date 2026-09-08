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
  int _tabIndex = 0;

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

  String get _resumenSedes {
    final nombres = _currentUser.sedes
        .map((s) => (s['municipio'] ?? '').toString())
        .where((n) => n.isNotEmpty)
        .toList();
    if (nombres.isEmpty) return 'Sin sede asignada';
    return nombres.join(' · ');
  }

  // La dirección solo se muestra cuando hay una única sede (lo normal — un
  // distribuidor cubre un solo municipio, ver ../../../LOGICA.md) y esa sede
  // tiene dirección cargada; con varias sedes sería ambiguo a cuál pertenece.
  String? get _direccionSede {
    if (_currentUser.sedes.length != 1) return null;
    final direccion = (_currentUser.sedes.first['direccion'] as String?)
        ?.trim();
    return (direccion != null && direccion.isNotEmpty) ? direccion : null;
  }

  @override
  Widget build(BuildContext context) {
    // Igual que en DriverHome: Perfil es una pestaña más, no una pantalla
    // apilada encima -- se llega y se sale por la misma barra inferior, sin
    // flecha "volver". El saludo/sede de arriba solo aplica a "Paquetes";
    // _DistribuidorPerfil ya trae su propio encabezado con avatar/nombre.
    final enPerfil = _tabIndex == 1;
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
          if (!enPerfil) ...[
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
                    Icon(
                      Icons.location_city_outlined,
                      size: 15,
                      color: AppColors.textSub,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      // Municipio y dirección en la misma fila (antes cada uno
                      // tenía su propia fila con su propio ícono) -- se ahorra
                      // una fila completa, y la dirección solo aplica de todos
                      // modos cuando hay una única sede (ver _direccionSede).
                      child: Text(
                        _direccionSede != null
                            ? '$_resumenSedes · $_direccionSede'
                            : _resumenSedes,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSub,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          Expanded(
            child: _tabIndex == 0
                ? DistribuidorPaquetes(user: _currentUser)
                : _DistribuidorPerfil(user: _currentUser),
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
            icon: Icons.inventory_2_outlined,
            label: 'Paquetes',
            active: _tabIndex == 0,
            onTap: () => setState(() => _tabIndex = 0),
          ),
          BottomMenuItem(
            icon: Icons.person_outline,
            label: 'Perfil',
            active: _tabIndex == 1,
            onTap: () => setState(() => _tabIndex = 1),
          ),
        ],
      ),
    );
  }
}

/// Perfil de solo lectura para el distribuidor — el rol no tiene endpoint de
/// autogestión (GET/PUT /conductores/perfil es solo para conductores). Muestra
/// los datos que ya vinieron en el login + la sede que cubre. Mismo diseño que
/// DriverProfile (header con avatar sobre la barra de color, SectionCard
/// "Información personal", botón de cerrar sesión) — sin el botón de editar,
/// que no aplica a este rol.
class _DistribuidorPerfil extends StatelessWidget {
  final UserModel user;
  const _DistribuidorPerfil({required this.user});

  @override
  Widget build(BuildContext context) {
    final sedes = user.sedes
        .map((s) => (s['municipio'] ?? '').toString())
        .where((n) => n.isNotEmpty)
        .toList();

    // Se embebe como pestaña de DistribuidorHome -- sin Scaffold ni flecha
    // "volver" propios, mismo criterio que DriverProfile.
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: UserAvatar(nombre: user.nombreCompleto, size: 64),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.nombreCompleto,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMain,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Encargado de sede',
                            style: TextStyle(
                              color: AppColors.textSub,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                      Text(
                        'Información personal',
                        style: TextStyle(
                          color: AppColors.textMain,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      InfoRow(
                        icon: Icons.person_outline_rounded,
                        iconColor: AppColors.blue,
                        iconBg: AppColors.blueBg,
                        label: 'Nombre completo',
                        value: user.nombreCompleto,
                      ),
                      if (user.documento != null && user.documento!.isNotEmpty)
                        InfoRow(
                          icon: Icons.badge_outlined,
                          iconColor: AppColors.orange,
                          iconBg: AppColors.orangeBg,
                          label: 'Identificación',
                          value:
                              user.tipoDocumento != null &&
                                  user.tipoDocumento!.isNotEmpty
                              ? '${user.tipoDocumento} ${user.documento}'
                              : user.documento!,
                        ),
                      InfoRow(
                        icon: Icons.phone_outlined,
                        iconColor: AppColors.purple,
                        iconBg: AppColors.purpleBg,
                        label: 'Teléfono',
                        value: user.telefono.isNotEmpty
                            ? user.telefono
                            : 'No registrado',
                      ),
                      InfoRow(
                        icon: Icons.email_outlined,
                        iconColor: AppColors.green,
                        iconBg: AppColors.greenBg,
                        label: 'Correo electrónico',
                        value: user.email.isEmpty ? '—' : user.email,
                      ),
                      InfoRow(
                        icon: Icons.location_city_outlined,
                        iconColor: AppColors.blue,
                        iconBg: AppColors.blueBg,
                        label: 'Sede que cubre',
                        value: sedes.isEmpty ? '—' : sedes.join(', '),
                      ),
                    ],
                  ),
                ),
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
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      backgroundColor: WidgetStateProperty.all(
                        AppColors.adminPrimary,
                      ),
                      elevation: WidgetStateProperty.all(3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Cerrar sesión',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
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
}
