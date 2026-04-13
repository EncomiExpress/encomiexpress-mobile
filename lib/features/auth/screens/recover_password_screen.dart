import 'package:flutter/material.dart';
import '../../../core/models.dart';
import '../../../core/services/auth_service.dart';

class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  String? _message;
  bool _isError = false;

  void _recover() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    setState(() { _loading = true; _message = null; });

    final result = await _authService.recoverPassword(_emailCtrl.text.trim());

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _message = 'Correo enviado';
        _isError = false;
      } else {
        _message = result['message'] ?? 'Error al procesar la solicitud';
        _isError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: AppColors.blue, size: 30),
                ),
                const SizedBox(height: 24),
                const Text('¿Olvidaste tu contraseña?',
                    style: TextStyle(
                        color: AppColors.textMain,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                  style: TextStyle(
                      color: AppColors.textSub,
                      fontSize: 14,
                      height: 1.5),
                ),
                const SizedBox(height: 32),
                const Text('Correo electrónico',
                    style: TextStyle(
                        color: AppColors.textMain,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                  style: const TextStyle(color: AppColors.textMain, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'ejemplo@correo.com',
                    hintStyle: const TextStyle(color: AppColors.textSub, fontSize: 14),
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
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isError 
                          ? AppColors.red.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isError ? Icons.error_outline : Icons.check_circle_outline,
                          color: _isError ? AppColors.red : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_message!,
                              style: TextStyle(
                                  color: _isError ? AppColors.red : Colors.green,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _loading ? null : _recover,
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
                          : const Text('Enviar enlace',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver a iniciar sesión',
                        style: TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }
}