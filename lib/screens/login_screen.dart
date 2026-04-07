import 'package:flutter/material.dart';
import '../models/models.dart';
import 'admin/admin_home.dart';
import 'driver/driver_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  bool _obscure  = true;
  bool _loading  = false;
  String? _error;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 400));

    final found = usuariosDemo.firstWhere(
      (u) => u['email'] == _emailCtrl.text.trim() &&
             u['password'] == _passCtrl.text,
      orElse: () => {},
    );

    if (!mounted) return;
    if (found.isEmpty) {
      setState(() { _loading = false; _error = 'Correo o contraseña incorrectos'; });
      return;
    }

    final user = UserModel(
      id: found['id']!,
      nombre: found['nombre']!,
      email: found['email']!,
      telefono: found['telefono']!,
      rol: found['rol']!,
    );

    setState(() => _loading = false);

    Widget dest = user.rol == 'admin'
        ? AdminHome(user: user)
        : DriverHome(user: user);

    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => dest));
  }

  void _fillDemo(String email) {
    _emailCtrl.text = email;
    _passCtrl.text  = '123456';
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
                          onPressed: () {},
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
                      _demoTile('Admin:', 'admin@test.com',
                          () => _fillDemo('admin@test.com')),
                      const SizedBox(height: 6),
                      _demoTile('Conductor:', 'conductor@test.com',
                          () => _fillDemo('conductor@test.com')),
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