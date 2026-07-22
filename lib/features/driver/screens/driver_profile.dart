import 'package:flutter/material.dart';
import '../../../../core/models.dart';
import '../../../../core/widgets.dart';
import '../../auth/screens/login_screen.dart';
import 'driver_profile_edit.dart';

class DriverProfile extends StatefulWidget {
  final UserModel user;
  final Function(UserModel)? onUserUpdated;

  const DriverProfile({
    super.key,
    required this.user,
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
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 12, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    TapArea(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, color: AppColors.textMain, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text('Mi perfil',
                        style: TextStyle(
                            color: AppColors.textMain,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12)
                        ],
                      ),
                      child: UserAvatar(nombre: _localUser.nombreCompleto, size: 64),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_localUser.nombreCompleto,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: AppColors.textMain,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('Conductor',
                              style: TextStyle(
                                  color: AppColors.textSub,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    TapArea(
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
                      child: Tooltip(
                        message: 'Editar datos y contraseña',
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.activeBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.edit_outlined, color: AppColors.driverPrimary, size: 18),
                        ),
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
                      Text('Información personal',
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
                        value: _localUser.nombreCompleto,
                      ),
                      if (_localUser.documento != null && _localUser.documento!.isNotEmpty)
                        InfoRow(
                          icon: Icons.badge_outlined,
                          iconColor: AppColors.orange,
                          iconBg: AppColors.orangeBg,
                          label: 'Identificación',
                          value: _localUser.tipoDocumento != null && _localUser.tipoDocumento!.isNotEmpty
                              ? '${_localUser.tipoDocumento} ${_localUser.documento}'
                              : _localUser.documento!,
                        ),
                      InfoRow(
                        icon: Icons.phone_outlined,
                        iconColor: AppColors.purple,
                        iconBg: AppColors.purpleBg,
                        label: 'Teléfono',
                        value: _localUser.telefono.isNotEmpty ? _localUser.telefono : 'No registrado',
                      ),
                      InfoRow(
                        icon: Icons.email_outlined,
                        iconColor: AppColors.green,
                        iconBg: AppColors.greenBg,
                        label: 'Correo electrónico',
                        value: _localUser.email,
                      ),
                      if (_localUser.numeroLicencia != null && _localUser.numeroLicencia!.isNotEmpty)
                        Opacity(
                          opacity: 0.7,
                          child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgGray,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                    color: AppColors.blueBg, borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.card_membership_outlined, color: AppColors.blue, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Licencia',
                                            style: TextStyle(color: AppColors.textSub, fontSize: 11)),
                                        const SizedBox(width: 6),
                                        Icon(Icons.lock_outline_rounded, size: 11, color: AppColors.textSub),
                                        const SizedBox(width: 2),
                                        Text('No editable',
                                            style: TextStyle(
                                                color: AppColors.textSub,
                                                fontSize: 10,
                                                fontStyle: FontStyle.italic)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (_localUser.categoriasLicencia.isEmpty)
                                      Text('—',
                                          style: TextStyle(
                                              color: AppColors.textMain,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500))
                                    else
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: _localUser.categoriasLicencia
                                            .map((cat) => LicenciaChip(categoria: cat))
                                            .toList(),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(_localUser.numeroLicencia!,
                                        style: TextStyle(color: AppColors.textSub, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (r) => false,
                    ),
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
                          return AppColors.driverGradEnd;
                        }
                        return AppColors.driverPrimary;
                      }),
                      elevation: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed) ? 6 : 3),
                      shadowColor: WidgetStateProperty.all(AppColors.driverPrimary.withOpacity(0.4)),
                      mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}