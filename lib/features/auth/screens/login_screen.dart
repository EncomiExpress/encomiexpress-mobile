import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets.dart';
import '../../admin/screens/admin_home.dart';
import '../../driver/screens/driver_home.dart';
import 'recover_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();
  final _authService = AuthService();

  bool _obscure  = true;
  bool _loading  = false;
  String? _error;
  // Como en Login.jsx (frontend web): nada se valida hasta el primer submit.
  // Después, cada error se limpia solo cuando el usuario vuelve a escribir
  // en SU campo — no en cualquier campo del formulario.
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(() {
      _clearError();
      if (_emailError != null) setState(() => _emailError = null);
    });
    _passCtrl.addListener(() {
      _clearError();
      if (_passwordError != null) setState(() => _passwordError = null);
    });
    // El halo de foco (boxShadow) depende de qué campo tiene el foco —
    // hay que reconstruir cuando eso cambia.
    _emailFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  String? _validateEmail(String v) {
    if (v.trim().isEmpty) return 'El correo es obligatorio';
    // Misma regex que validarFormulario() en Login.jsx (frontend web).
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
      return 'Ingresa un correo válido (ejemplo@dominio.com)';
    }
    return null;
  }

  String? _validatePassword(String v) {
    if (v.isEmpty) return 'La contraseña es obligatoria';
    return null;
  }

  void _login() async {
    final emailError = _validateEmail(_emailCtrl.text);
    final passwordError = _validatePassword(_passCtrl.text);
    if (emailError != null || passwordError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
      });
      return;
    }
    setState(() { _loading = true; _error = null; });

    final result = await _authService.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      // Forma real de POST /api/auth/login (authService.login en el backend):
      // { success, message, data: { token, refreshToken, usuario: {..., rol}, conductor } }
      final payload = result['data']?['data'] as Map<String, dynamic>?;
      final usuario = payload?['usuario'] as Map<String, dynamic>?;
      final conductor = payload?['conductor'] as Map<String, dynamic>?;

      if (usuario == null) {
        setState(() {
          _loading = false;
          _error = 'Respuesta inesperada del servidor';
        });
        return;
      }

      final user = UserModel(
        id: usuario['idUsuario']?.toString() ?? '',
        nombre: usuario['nombre'] ?? '',
        // El backend no devuelve el email en el login — se conserva el que se tipeó.
        email: _emailCtrl.text.trim(),
        telefono: usuario['telefono'] ?? '',
        rol: usuario['rol'] ?? '',
        conductorId: conductor?['idConductor']?.toString(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', user.toJson().toString());

      setState(() => _loading = false);

      final dest = user.rol.toLowerCase() == 'conductor'
          ? DriverHome(user: user)
          : AdminHome(user: user);

      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => dest));
    } else {
      setState(() {
        _loading = false;
        _error = result['message'] ?? 'Error al iniciar sesión';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      body: Column(
        children: [
          // Zona superior gris con los hexágonos — recortados dentro de su
          // propia caja (Clip.hardEdge) para que no se cuelen en la zona
          // blanca de abajo.
          Container(
            width: double.infinity,
            height: 320,
            color: AppColors.bgGray,
            child: SafeArea(
              bottom: false,
              child: ClipRect(
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      bottom: -40,
                      left: -40,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.12,
                          child: Transform.rotate(
                            angle: -5 * pi / 180,
                            child: HexagonCluster(
                              size: 220,
                              fillTop: const Color(0xFFE84040),
                              fillLeft: AppColors.adminPrimary,
                              fillRight: const Color(0xFF9B1010),
                              stroke: AppColors.adminPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -40,
                      right: -40,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.09,
                          child: Transform.rotate(
                            angle: 8 * pi / 180,
                            child: HexagonCluster(
                              size: 240,
                              fillTop: const Color(0xFF2A3F8F),
                              fillLeft: AppColors.secondary,
                              fillRight: const Color(0xFF0F1C45),
                              stroke: AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 130,
                              height: 80,
                              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                            ),
                            const SizedBox(height: 12),
                            Text('Bienvenido',
                                style: TextStyle(
                                    color: AppColors.textMain,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Cambria')),
                            const SizedBox(height: 4),
                            Text('Ingresa tus credenciales para acceder',
                                style: TextStyle(color: AppColors.textSub, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Zona inferior blanca — se estira hasta el fondo de la pantalla
          // sin importar cuánto contenido tenga (Expanded), igual que en
          // la captura de referencia.
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppColors.cardBg,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // Campos + botón, sin tarjeta/borde alrededor — directo
                    // sobre el fondo de la página (solo limitado en ancho
                    // para que no quede pegado de lado a lado en desktop).
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _field(
                                controller: _emailCtrl,
                                focusNode: _emailFocus,
                                label: 'Correo electrónico *',
                                hint: 'correo@ejemplo.com',
                                icon: Icons.mail_outline_rounded,
                                keyboard: TextInputType.emailAddress,
                                errorText: _emailError,
                              ),
                              const SizedBox(height: 16),
                              _field(
                                controller: _passCtrl,
                                focusNode: _passFocus,
                                label: 'Contraseña *',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscure,
                                suffix: IconButton(
                                  icon: Icon(
                                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: AppColors.textSub, size: 20),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                                errorText: _passwordError,
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.redBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(_error!, style: TextStyle(color: AppColors.red, fontSize: 13)),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => const RecoverPasswordScreen(),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text('¿Olvidaste tu contraseña?',
                                      style: TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _login,
                                  style: ButtonStyle(
                                    shape: WidgetStateProperty.all(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                    // Fondo más oscuro al pasar el mouse o al presionar —
                                    // igual que '&:hover' en el botón de Login.jsx (frontend web).
                                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(WidgetState.disabled)) {
                                        return AppColors.adminPrimary.withOpacity(0.6);
                                      }
                                      if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
                                        return AppColors.adminGradEnd;
                                      }
                                      return AppColors.adminPrimary;
                                    }),
                                    elevation: WidgetStateProperty.resolveWith((states) =>
                                        states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed) ? 6 : 3),
                                    shadowColor: WidgetStateProperty.all(AppColors.adminPrimary.withOpacity(0.4)),
                                    mouseCursor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled)
                                        ? SystemMouseCursors.basic
                                        : SystemMouseCursors.click),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20, width: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('Iniciar Sesión',
                                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                            SizedBox(width: 8),
                                            Icon(Icons.login_rounded, color: Colors.white, size: 20),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    String? errorText,
  }) {
    // formFieldStyles.js (frontend web): el borde se queda delgado (1px)
    // en todos los estados — el foco se marca con un halo suave alrededor
    // del campo (boxShadow), no con un borde más grueso.
    final hasError = errorText != null;
    final borderColor = hasError ? AppColors.red : AppColors.border;
    final glowColor = hasError ? AppColors.redBg : AppColors.activeBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // El halo (boxShadow) solo envuelve el cuadro del campo — el mensaje
        // de error se pinta aparte más abajo, fuera de este Container, para
        // que la sombra no se estire hasta el texto.
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: focusNode.hasFocus
                ? [BoxShadow(color: glowColor, blurRadius: 0, spreadRadius: 3)]
                : [],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscure,
            keyboardType: keyboard,
            style: TextStyle(color: AppColors.textMain, fontSize: 15),
            // Sin esto, Flutter tiñe el cursor del color de error mientras el campo
            // esté inválido (y del color primario cuando no) — en el web el cursor
            // es simplemente el color de texto por defecto, no cambia con el estado.
            cursorColor: AppColors.textMain,
            decoration: InputDecoration(
              labelText: label,
              // Sin esto, Flutter superpone el label con el placeholder hasta que
              // el campo tiene foco — a diferencia de MUI, que en el web muestra
              // el label chico arriba desde el inicio en cuanto hay un placeholder.
              floatingLabelBehavior: FloatingLabelBehavior.always,
              // El boxShadow del halo se dibuja detrás de todo el campo — sin un
              // fondo opaco acá, se transparenta por el interior en vez de verse
              // solo alrededor del borde.
              filled: true,
              fillColor: AppColors.cardBg,
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textSub, fontSize: 14),
              labelStyle: TextStyle(color: AppColors.textSub, fontSize: 13),
              // Gris normalmente, rojo si hay error, del color primario solo
              // cuando el campo tiene foco — igual que MUI (Mui-focused).
              floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) => TextStyle(
                  color: hasError
                      ? AppColors.red
                      : (states.contains(WidgetState.focused) ? AppColors.adminPrimary : AppColors.textSub),
                  fontSize: 13)),
              prefixIcon: Icon(icon, color: hasError ? AppColors.red : AppColors.textSub, size: 20),
              suffixIcon: suffix,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              // No se usa errorBorder/errorText de Flutter a propósito — esos
              // agregan el texto de error DENTRO del mismo widget del campo,
              // que es justo lo que hacía que el halo se estirara hasta el
              // texto. El color de borde/label/ícono se controla a mano con
              // `hasError` en vez de depender del estado de error de Flutter.
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: hasError ? AppColors.red : AppColors.adminPrimary),
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(errorText, style: TextStyle(color: AppColors.red, fontSize: 11)),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }
}
