import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/conductor_service.dart';
import '../../../../core/widgets.dart';

// Mismas validaciones y flujo que ActualizarConductor.jsx/ActualizarUsuario.jsx
// (frontend web), adaptado al alcance real de PUT /conductores/perfil: el
// conductor solo puede autoeditar nombre/apellido/documento/teléfono/correo.
// Tipo de identificación y licencia son datos de verificación que solo el
// admin gestiona desde el módulo de Conductores — no aparecen aquí.
const _steps = ['Datos personales', 'Contraseña', 'Confirmación'];

final _soloLetras = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9\s]).{8,64}$');
const _passwordHelp = '8-64 caracteres, con mayúsculas, minúsculas, números y un carácter especial';

class DriverProfileEdit extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onSave;

  const DriverProfileEdit({super.key, required this.user, required this.onSave});

  @override
  State<DriverProfileEdit> createState() => _DriverProfileEditState();
}

class _DriverProfileEditState extends State<DriverProfileEdit> {
  final _conductorService = ConductorService();
  final _authService = AuthService();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _documentoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _emailCtrl;
  final _passwordActualCtrl = TextEditingController();
  final _passwordNuevaCtrl = TextEditingController();
  final _confirmarPasswordCtrl = TextEditingController();

  final _nombreFocus = FocusNode();
  final _apellidoFocus = FocusNode();
  final _documentoFocus = FocusNode();
  final _telefonoFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordActualFocus = FocusNode();
  final _passwordNuevaFocus = FocusNode();
  final _confirmarPasswordFocus = FocusNode();

  late final Map<String, String> _original;

  int _activeStep = 0;
  Map<String, String> _errores = {};
  String? _apiError;
  bool _sinCambios = false;
  bool _submitting = false;
  bool _showPasswordActual = false;
  bool _showPasswordNueva = false;
  bool _showConfirmarPassword = false;

  bool get _esDocAlfanumerico => const ['CE', 'PAS'].contains(widget.user.tipoDocumento);

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.user.nombre);
    _apellidoCtrl = TextEditingController(text: widget.user.apellido ?? '');
    _documentoCtrl = TextEditingController(text: widget.user.documento ?? '');
    _telefonoCtrl = TextEditingController(text: widget.user.telefono);
    _emailCtrl = TextEditingController(text: widget.user.email);

    _original = {
      'nombre': _nombreCtrl.text.trim(),
      'apellido': _apellidoCtrl.text.trim(),
      'documento': _documentoCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
    };

    for (final c in [_nombreCtrl, _apellidoCtrl, _documentoCtrl, _telefonoCtrl, _emailCtrl,
        _passwordActualCtrl, _passwordNuevaCtrl, _confirmarPasswordCtrl]) {
      c.addListener(_onAnyChange);
    }
    for (final f in [_nombreFocus, _apellidoFocus, _documentoFocus, _telefonoFocus, _emailFocus,
        _passwordActualFocus, _passwordNuevaFocus, _confirmarPasswordFocus]) {
      f.addListener(() => setState(() {}));
    }
  }

  void _onAnyChange() {
    if (_apiError != null || _sinCambios) {
      setState(() {
        _apiError = null;
        _sinCambios = false;
      });
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _documentoCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordActualCtrl.dispose();
    _passwordNuevaCtrl.dispose();
    _confirmarPasswordCtrl.dispose();
    _nombreFocus.dispose();
    _apellidoFocus.dispose();
    _documentoFocus.dispose();
    _telefonoFocus.dispose();
    _emailFocus.dispose();
    _passwordActualFocus.dispose();
    _passwordNuevaFocus.dispose();
    _confirmarPasswordFocus.dispose();
    super.dispose();
  }

  String get _docHelper => _esDocAlfanumerico
      ? 'Alfanumérico, hasta 12 caracteres'
      : 'Solo dígitos, entre 3 y 10';

  Map<String, String> _validarPaso(int step) {
    final e = <String, String>{};

    if (step == 0) {
      if (_nombreCtrl.text.trim().isEmpty) {
        e['nombre'] = 'El nombre es obligatorio';
      } else if (!_soloLetras.hasMatch(_nombreCtrl.text.trim())) {
        e['nombre'] = 'El nombre solo puede contener letras';
      }
      if (_apellidoCtrl.text.trim().isEmpty) {
        e['apellido'] = 'El apellido es obligatorio';
      } else if (!_soloLetras.hasMatch(_apellidoCtrl.text.trim())) {
        e['apellido'] = 'El apellido solo puede contener letras';
      }
      final doc = _documentoCtrl.text.trim();
      if (doc.isEmpty) {
        e['documento'] = 'El número de documento es obligatorio';
      } else if (_esDocAlfanumerico) {
        if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(doc)) {
          e['documento'] = 'Solo letras y números, sin caracteres especiales';
        }
      } else if (!RegExp(r'^\d+$').hasMatch(doc)) {
        e['documento'] = 'Solo se permiten dígitos';
      } else if (doc.length < 3 || doc.length > 10) {
        e['documento'] = 'Debe tener entre 3 y 10 dígitos';
      }
      final tel = _telefonoCtrl.text.trim();
      if (tel.isEmpty) {
        e['telefono'] = 'El teléfono es obligatorio';
      } else if (!RegExp(r'^\d{10}$').hasMatch(tel)) {
        e['telefono'] = 'El teléfono debe tener 10 dígitos';
      }
      final email = _emailCtrl.text.trim();
      if (email.isEmpty) {
        e['email'] = 'El correo es obligatorio';
      } else if (!_emailRegex.hasMatch(email)) {
        e['email'] = 'Ingresa un correo válido';
      }
    }

    if (step == 1) {
      final actual = _passwordActualCtrl.text;
      final nueva = _passwordNuevaCtrl.text;
      final confirmar = _confirmarPasswordCtrl.text;
      final algunaLlena = actual.isNotEmpty || nueva.isNotEmpty || confirmar.isNotEmpty;
      if (algunaLlena) {
        if (actual.isEmpty) e['passwordActual'] = 'Ingresa tu contraseña actual';
        if (nueva.isEmpty) {
          e['passwordNueva'] = 'La nueva contraseña es obligatoria';
        } else if (!_passwordRegex.hasMatch(nueva)) {
          e['passwordNueva'] = _passwordHelp;
        }
        if (confirmar.isEmpty) {
          e['confirmarPassword'] = 'Confirma la nueva contraseña';
        } else if (confirmar != nueva) {
          e['confirmarPassword'] = 'Las contraseñas no coinciden';
        }
      }
    }

    return e;
  }

  bool get _hayCambios {
    final cambiosSimples = _nombreCtrl.text.trim() != _original['nombre'] ||
        _apellidoCtrl.text.trim() != _original['apellido'] ||
        _documentoCtrl.text.trim() != _original['documento'] ||
        _telefonoCtrl.text.trim() != _original['telefono'] ||
        _emailCtrl.text.trim() != _original['email'];
    return cambiosSimples || _passwordNuevaCtrl.text.isNotEmpty;
  }

  int get _totalModificados {
    var n = 0;
    if (_nombreCtrl.text.trim() != _original['nombre']) n++;
    if (_apellidoCtrl.text.trim() != _original['apellido']) n++;
    if (_documentoCtrl.text.trim() != _original['documento']) n++;
    if (_telefonoCtrl.text.trim() != _original['telefono']) n++;
    if (_emailCtrl.text.trim() != _original['email']) n++;
    if (_passwordNuevaCtrl.text.isNotEmpty) n++;
    return n;
  }

  void _handleNext() {
    final errores = _validarPaso(_activeStep);
    if (errores.isNotEmpty) {
      setState(() => _errores = errores);
      return;
    }
    setState(() {
      _errores = {};
      _activeStep++;
    });
  }

  void _handleBack() => setState(() => _activeStep--);

  Future<void> _handleSubmit() async {
    if (!_hayCambios) {
      setState(() => _sinCambios = true);
      return;
    }

    setState(() {
      _submitting = true;
      _apiError = null;
      _sinCambios = false;
    });

    final result = await _conductorService.updatePerfil(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      documento: _documentoCtrl.text.trim(),
    );

    if (result['success'] != true) {
      setState(() {
        _submitting = false;
        _apiError = result['message'] ?? 'Error al actualizar el perfil';
      });
      return;
    }

    if (_passwordNuevaCtrl.text.isNotEmpty) {
      final passResult = await _authService.cambiarPassword(
        _passwordActualCtrl.text,
        _passwordNuevaCtrl.text,
      );
      if (passResult['success'] != true) {
        setState(() {
          _submitting = false;
          _apiError = passResult['message'] ?? 'El perfil se actualizó, pero no se pudo cambiar la contraseña';
        });
        return;
      }
    }

    setState(() => _submitting = false);

    final updatedUser = widget.user.copyWith(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      documento: _documentoCtrl.text.trim(),
    );
    widget.onSave(updatedUser);

    if (mounted) {
      Navigator.pop(context);
      showAppSnackBar(context, 'Perfil actualizado correctamente');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  TapArea(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: AppColors.textMain, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('Editar perfil',
                      style: TextStyle(
                          color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(color: AppColors.activeBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(Icons.manage_accounts_outlined, color: AppColors.driverPrimary, size: 40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
              child: _buildStepper(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildStepContent(),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (_activeStep > 0)
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _handleBack,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Anterior'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMain,
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ).copyWith(
                        mouseCursor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled)
                            ? SystemMouseCursors.basic
                            : SystemMouseCursors.click),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom().copyWith(
                        mouseCursor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled)
                            ? SystemMouseCursors.basic
                            : SystemMouseCursors.click),
                      ),
                      child: Text('Cancelar', style: TextStyle(color: AppColors.textSub)),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : (_activeStep < _steps.length - 1 ? _handleNext : _handleSubmit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.driverPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ).copyWith(
                      mouseCursor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled)
                          ? SystemMouseCursors.basic
                          : SystemMouseCursors.click),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_activeStep < _steps.length - 1
                            ? 'Siguiente'
                            : (_sinCambios ? 'Sin cambios' : 'Guardar cambios')),
                        const SizedBox(width: 8),
                        _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(
                                _activeStep < _steps.length - 1 ? Icons.arrow_forward : Icons.save_outlined,
                                size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftDone = (i - 1) ~/ 2 < _activeStep;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(height: 2, color: leftDone ? AppColors.driverPrimary : AppColors.border),
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isActive = stepIndex == _activeStep;
        final isDone = stepIndex < _activeStep;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isActive || isDone) ? AppColors.driverPrimary : Colors.transparent,
                border: Border.all(
                    color: (isActive || isDone) ? AppColors.driverPrimary : AppColors.border, width: 1.5),
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text('${stepIndex + 1}',
                      style: TextStyle(
                          color: isActive ? Colors.white : AppColors.textSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 68,
              child: Text(_steps[stepIndex],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      color: isActive ? AppColors.textMain : AppColors.textSub,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400)),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_activeStep) {
      case 0:
        return _buildPasoDatosPersonales();
      case 1:
        return _buildPasoContrasena();
      default:
        return _buildPasoConfirmacion();
    }
  }

  Widget _buildPasoDatosPersonales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField(
          controller: _nombreCtrl,
          focusNode: _nombreFocus,
          label: 'Nombres',
          icon: Icons.person_outline_rounded,
          errorText: _errores['nombre'],
          maxLength: 50,
          inputFormatters: [FilteringTextInputFormatter.allow(_soloLetras)],
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _apellidoCtrl,
          focusNode: _apellidoFocus,
          label: 'Apellidos',
          icon: Icons.person_outline_rounded,
          errorText: _errores['apellido'],
          maxLength: 50,
          inputFormatters: [FilteringTextInputFormatter.allow(_soloLetras)],
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _documentoCtrl,
          focusNode: _documentoFocus,
          label: 'Número de documento',
          icon: Icons.badge_outlined,
          errorText: _errores['documento'],
          helperText: _docHelper,
          maxLength: _esDocAlfanumerico ? 12 : 10,
          keyboardType:
              _esDocAlfanumerico ? TextInputType.text : TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                _esDocAlfanumerico ? RegExp(r'[a-zA-Z0-9]') : RegExp(r'[0-9]')),
          ],
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _telefonoCtrl,
          focusNode: _telefonoFocus,
          label: 'Teléfono',
          icon: Icons.phone_outlined,
          errorText: _errores['telefono'],
          helperText: _errores['telefono'] == null ? 'Número de 10 dígitos' : null,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _emailCtrl,
          focusNode: _emailFocus,
          label: 'Correo electrónico',
          icon: Icons.email_outlined,
          errorText: _errores['email'],
          keyboardType: TextInputType.emailAddress,
          maxLength: 80,
        ),
      ],
    );
  }

  Widget _buildPasoContrasena() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.activeBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.driverPrimary.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppColors.driverPrimary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Deja estos campos vacíos si no quieres cambiar tu contraseña.',
                    style: TextStyle(color: AppColors.driverPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _passwordActualCtrl,
          focusNode: _passwordActualFocus,
          label: 'Contraseña actual',
          icon: Icons.lock_outline_rounded,
          errorText: _errores['passwordActual'],
          obscureText: !_showPasswordActual,
          maxLength: 64,
          suffixIcon: TapArea(
            onTap: () => setState(() => _showPasswordActual = !_showPasswordActual),
            child: Icon(
                _showPasswordActual ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSub, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _passwordNuevaCtrl,
          focusNode: _passwordNuevaFocus,
          label: 'Nueva contraseña',
          icon: Icons.lock_outline_rounded,
          errorText: _errores['passwordNueva'],
          helperText: _errores['passwordNueva'] == null ? _passwordHelp : null,
          obscureText: !_showPasswordNueva,
          maxLength: 64,
          suffixIcon: TapArea(
            onTap: () => setState(() => _showPasswordNueva = !_showPasswordNueva),
            child: Icon(
                _showPasswordNueva ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSub, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _confirmarPasswordCtrl,
          focusNode: _confirmarPasswordFocus,
          label: 'Confirmar nueva contraseña',
          icon: Icons.lock_outline_rounded,
          errorText: _errores['confirmarPassword'],
          obscureText: !_showConfirmarPassword,
          maxLength: 64,
          suffixIcon: TapArea(
            onTap: () => setState(() => _showConfirmarPassword = !_showConfirmarPassword),
            child: Icon(
                _showConfirmarPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSub, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildPasoConfirmacion() {
    final totalModificados = _totalModificados;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totalModificados > 0)
          _buildAlert(
            icon: Icons.edit_outlined,
            color: AppColors.blue,
            bg: AppColors.blueBg,
            text: 'Se ${totalModificados == 1 ? 'modificó' : 'modificaron'} $totalModificados '
                '${totalModificados == 1 ? 'campo' : 'campos'}: revísalo${totalModificados == 1 ? '' : 's'} antes de guardar.',
          ),
        if (_sinCambios)
          _buildAlert(
            icon: Icons.warning_amber_outlined,
            color: AppColors.orange,
            bg: AppColors.orangeBg,
            text: 'No has realizado ningún cambio. Los datos ya están actualizados.',
          ),
        if (_apiError != null)
          _buildAlert(
            icon: Icons.error_outline,
            color: AppColors.red,
            bg: AppColors.redBg,
            text: _apiError!,
          ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textMain),
                  const SizedBox(width: 6),
                  Text('Datos personales',
                      style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              ConfirmRow(label: 'Nombres', value: _nombreCtrl.text.trim(), previousValue: _original['nombre']),
              const Divider(height: 1),
              ConfirmRow(label: 'Apellidos', value: _apellidoCtrl.text.trim(), previousValue: _original['apellido']),
              const Divider(height: 1),
              ConfirmRow(
                  label: 'N° de documento', value: _documentoCtrl.text.trim(), previousValue: _original['documento']),
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 18, color: AppColors.textMain),
                  const SizedBox(width: 6),
                  Text('Contacto',
                      style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              ConfirmRow(label: 'Teléfono', value: _telefonoCtrl.text.trim(), previousValue: _original['telefono']),
              const Divider(height: 1),
              ConfirmRow(label: 'Correo', value: _emailCtrl.text.trim(), previousValue: _original['email']),
              const Divider(height: 1),
              ConfirmRow(
                label: 'Contraseña',
                value: _passwordNuevaCtrl.text.isNotEmpty ? '••••••••' : 'Sin cambiar',
                previousValue: 'Sin cambiar',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlert({
    required IconData icon,
    required Color color,
    required Color bg,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }

  // Mismo patrón que los campos del login: borde delgado siempre + halo
  // (boxShadow) al enfocar, en vez del borde grueso por defecto de Flutter.
  // El texto de error va FUERA del contenedor con sombra para que el halo no
  // se extienda hasta el texto.
  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    String? errorText,
    String? helperText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool obscureText = false,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final hasError = errorText != null;
    final hasFocus = focusNode.hasFocus;
    final borderColor = hasError ? AppColors.red : (hasFocus ? AppColors.driverPrimary : AppColors.border);
    final radius = BorderRadius.circular(12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: hasFocus
                ? [BoxShadow(color: hasError ? AppColors.redBg : AppColors.activeBg, blurRadius: 0, spreadRadius: 3)]
                : [],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: radius,
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              maxLength: maxLength,
              obscureText: obscureText,
              textCapitalization: textCapitalization,
              style: TextStyle(color: AppColors.textMain, fontSize: 14),
              decoration: InputDecoration(
                labelText: label,
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                counterText: '',
                prefixIcon: Icon(icon, color: hasError ? AppColors.red : AppColors.textSub, size: 20),
                suffixIcon: suffixIcon,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(errorText, style: TextStyle(color: AppColors.red, fontSize: 11)),
          )
        else if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(helperText, style: TextStyle(color: AppColors.textSub, fontSize: 11)),
          ),
      ],
    );
  }
}
