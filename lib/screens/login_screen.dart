import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/usuarios/presentation/providers/usuario_provider.dart';
import '../features/anticipos/presentation/providers/anticipo_provider.dart';
import '../features/anticipos/presentation/screens/admin_home.dart';
import '../features/anticipos/presentation/screens/driver_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    final usuarioProvider = context.read<UsuarioProvider>();
    final success = await usuarioProvider.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      final user = usuarioProvider.currentUser;
      if (user != null) {
        Widget dest = user.isAdmin
            ? AdminHomeScreen(
                provider: context.read<AnticipoProvider>(),
                userId: user.id,
                userName: user.nombre,
              )
            : DriverHomeScreen(
                provider: context.read<AnticipoProvider>(),
                userId: user.id,
                userName: user.nombre,
              );

        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => dest));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(usuarioProvider.error ?? 'Error al iniciar sesión'),
          backgroundColor: Colors.red,
        ),
      );
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
    final usuarioProvider = context.watch<UsuarioProvider>();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B5BDB), Color(0xFF9B59B6)],
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
                        color: Colors.white.withValues(alpha: 0.25),
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
                    const Text('Inicia sesión para continuar',
                        style: TextStyle(
                            color: Colors.white70,
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
                              color: Color(0xFF1E293B),
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
                              color: Color(0xFF1E293B),
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
                            color: const Color(0xFF64748B), size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: usuarioProvider.loading ? null : _login,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF7B2FBE)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: usuarioProvider.loading
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                                : const Text('Ingresar',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                      const Divider(color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text('Usuarios de prueba:',
                            style: TextStyle(
                                color: Color(0xFF64748B), fontSize: 12)),
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
      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
      ),
    );
  }

  Widget _demoTile(String role, String email, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(role,
                style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(width: 6),
            Text(email,
                style: const TextStyle(
                    color: Color(0xFF3B82F6), fontSize: 13)),
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