import 'package:flutter/material.dart';
import '../../../core/models.dart';
import '../../../core/services/auth_service.dart';

class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _authService = AuthService();

  bool _loading = false;
  String? _emailError;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(() {
      setState(() {
        _emailError = null;
        _message = null;
      });
    });
    _emailFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'El correo es obligatorio';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
      return 'Ingresa un correo válido (ejemplo@dominio.com)';
    }
    return null;
  }

  void _recover() async {
    final error = _validateEmail(_emailCtrl.text);
    if (error != null) {
      setState(() => _emailError = error);
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    final result = await _authService.recoverPassword(_emailCtrl.text.trim());

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _message = 'Si el correo está registrado, recibirás un enlace para elegir una nueva contraseña.';
        _isError = false;
      } else {
        _message = result['message'] ?? 'Error al procesar la solicitud';
        _isError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 67,
                height: 67,
                decoration: BoxDecoration(
                  color: AppColors.activeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.lock_reset_rounded, color: AppColors.adminPrimary, size: 35),
              ),
              const SizedBox(height: 14),
              Text('Recuperar contraseña',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMain, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Ingresa tu correo registrado',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSub, fontSize: 16)),
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: _buildEmailField(),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isError ? AppColors.redBg : AppColors.greenBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _isError ? Icons.error_outline : Icons.check_circle_outline,
                        color: _isError ? AppColors.red : AppColors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_message!,
                            style: TextStyle(
                                color: _isError ? AppColors.red : AppColors.green, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textSub)
                        .copyWith(
                      mouseCursor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.disabled)
                              ? SystemMouseCursors.basic
                              : SystemMouseCursors.click),
                    ),
                    child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 24),
                  ElevatedButton(
                    onPressed:
                        (_loading || _emailCtrl.text.trim().isEmpty || (_message != null && !_isError))
                            ? null
                            : _recover,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ).copyWith(
                      mouseCursor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.disabled)
                              ? SystemMouseCursors.basic
                              : SystemMouseCursors.click),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_message != null && !_isError ? 'Correo enviado' : 'Enviar enlace',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
              Positioned(
                top: -8,
                right: -8,
                child: IconButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: AppColors.textSub, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mismo patrón que los campos del login: borde delgado + halo (boxShadow)
  // al enfocar, en vez del borde grueso por defecto de Flutter.
  Widget _buildEmailField() {
    final hasError = _emailError != null;
    final borderColor = hasError ? AppColors.red : AppColors.border;
    final glowColor = hasError ? AppColors.redBg : AppColors.activeBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow:
                _emailFocus.hasFocus ? [BoxShadow(color: glowColor, blurRadius: 0, spreadRadius: 3)] : [],
          ),
          child: TextFormField(
            controller: _emailCtrl,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: AppColors.textMain, fontSize: 15),
            cursorColor: AppColors.textMain,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              filled: true,
              fillColor: AppColors.cardBg,
              hintText: 'ejemplo@correo.com',
              hintStyle: TextStyle(color: AppColors.textSub, fontSize: 14),
              labelStyle: TextStyle(color: AppColors.textSub, fontSize: 13),
              floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) => TextStyle(
                  color: hasError
                      ? AppColors.red
                      : (states.contains(WidgetState.focused) ? AppColors.adminPrimary : AppColors.textSub),
                  fontSize: 13)),
              prefixIcon: Icon(Icons.email_outlined, color: hasError ? AppColors.red : AppColors.textSub, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: hasError ? AppColors.red : AppColors.adminPrimary)),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(_emailError!, style: TextStyle(color: AppColors.red, fontSize: 11)),
          ),
      ],
    );
  }
}
