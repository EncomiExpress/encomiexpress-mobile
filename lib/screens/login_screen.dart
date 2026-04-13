import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import 'admin/admin_home.dart';
import 'driver/driver_home.dart';
import 'recover_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _authService = AuthService();

  bool _obscure  = true;
  bool _loading  = false;
  String? _error;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await _authService.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final responseData = result['data'];
      
      print('DEBUG - responseData: $responseData');
      
      String rol = '';
      String nombre = '';
      String email = '';
      String id = '';
      String telefono = '';
      
// Buscar en responseData.data (como viene del backend)
      if (responseData['data'] != null && responseData['data']['rol'] != null) {
        rol = responseData['data']['rol'].toString();
        print('DEBUG - rol encontrado en data.rol: $rol');
      }
      else if (responseData['data'] != null && responseData['data']['role'] != null) {
        rol = responseData['data']['role'].toString();
        print('DEBUG - rol encontrado en data.role: $rol');
      }
      // Buscar en responseData directamente
      else if (responseData['rol'] != null) {
        rol = responseData['rol'].toString();
        print('DEBUG - rol encontrado en responseData.rol: $rol');
      }
      else if (responseData['role'] != null) {
        rol = responseData['role'].toString();
        print('DEBUG - rol encontrado en responseData.role: $rol');
      }
      // Por email como fallback (si el backend no devuelve el rol directamente)
      else {
        final emailInput = _emailCtrl.text.trim().toLowerCase();
        print('DEBUG - email para fallback: $emailInput');
        if (emailInput.contains('admin')) {
          rol = 'admin';
          print('DEBUG - rol asignado por email: $rol');
        }
      }
      
      print('DEBUG - rol extraido: $rol');
      
      // Extraer datos del usuario - buscar en múltiples ubicaciones
      Map<String, dynamic>? usuario;
      if (responseData['data']?['usuario'] != null) {
        usuario = Map<String, dynamic>.from(responseData['data']['usuario']);
      } else if (responseData['usuario'] != null) {
        usuario = Map<String, dynamic>.from(responseData['usuario']);
      }
      
      String? conductorId;
      if (responseData['data']?['conductor'] != null) {
        conductorId = responseData['data']['conductor']['idConductor']?.toString();
      }
      
      if (usuario != null) {
        nombre = usuario['nombre'] ?? usuario['name'] ?? '';
        email = usuario['email'] ?? _emailCtrl.text.trim();
        id = usuario['idUsuario']?.toString() ?? usuario['id']?.toString() ?? '';
        telefono = usuario['telefono'] ?? '';
      } else {
        email = _emailCtrl.text.trim();
      }
      
      final user = UserModel(
        id: id,
        nombre: nombre,
        email: email,
        telefono: telefono,
        rol: rol,
        conductorId: conductorId,
      );

      print('DEBUG - Usuario creado - rol final: ${user.rol}');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', user.toJson().toString());

      setState(() => _loading = false);

      final rolLower = user.rol.toLowerCase();
      Widget dest = rolLower == 'admin' || rolLower == 'administrador'
          ? AdminHome(user: user)
          : DriverHome(user: user);

      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => dest));
    } else {
      setState(() {
        _loading = false;
        _error = result['message'] ?? 'Error al iniciar sesión';
      });
    }
  }

  void _fillDemo(String email) {
    _emailCtrl.text = email;
    if (email == 'admin@encomiexpress.com') {
      _passCtrl.text = 'admin123';
    } else if (email == 'conductor@encomiexpress.com') {
      _passCtrl.text = 'conductor123';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.loginGradStart, AppColors.loginGradEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.login_rounded,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 16),
                    const Text('Bienvenido',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Inicia sesión para continuar',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Correo electrónico',
                          style: TextStyle(
                              color: AppColors.textMain,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: _emailCtrl,
                        hint: 'ejemplo@correo.com',
                        keyboard: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                          if (!v.contains('@')) return 'Correo inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Contraseña',
                          style: TextStyle(
                              color: AppColors.textMain,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: _passCtrl,
                        hint: '••••••••',
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.textSub, size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!,
                            style: const TextStyle(
                                color: AppColors.red, fontSize: 13)),
                      ],
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _loading ? null : _login,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.driverPrimary, AppColors.adminPrimary],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                                : const Text('Ingresar',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RecoverPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text('¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                  color: AppColors.blue,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 10),
                      Center(
                        child: Text('Usuarios de prueba:',
                            style: TextStyle(
                                color: AppColors.textSub, fontSize: 12)),
                      ),
                      const SizedBox(height: 10),
                      _demoTile('Admin:', 'admin@encomiexpress.com',
                          () => _fillDemo('admin@encomiexpress.com')),
                      const SizedBox(height: 6),
                      _demoTile('Conductor:', 'conductor@encomiexpress.com',
                          () => _fillDemo('conductor@encomiexpress.com')),
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

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      validator: validator,
      style: const TextStyle(color: AppColors.textMain, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSub, fontSize: 14),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.bgGray,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.red, fontSize: 11),
      ),
    );
  }

  Widget _demoTile(String role, String email, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgGray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(role,
                style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(width: 6),
            Text(email,
                style: const TextStyle(
                    color: AppColors.blue, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}