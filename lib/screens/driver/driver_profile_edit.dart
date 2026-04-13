import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/models.dart';
import '../../services/conductor_service.dart';
import '../../widgets/widgets.dart';

class DriverProfileEdit extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onSave;

  const DriverProfileEdit({super.key, required this.user, required this.onSave});

  @override
  State<DriverProfileEdit> createState() => _DriverProfileEditState();
}

class _DriverProfileEditState extends State<DriverProfileEdit> {
  final _formKey = GlobalKey<FormState>();
  final _conductorService = ConductorService();
  
  late TextEditingController _nombreCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _documentoCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _placaCtrl;
  late TextEditingController _marcaVehiculoCtrl;
  late TextEditingController _modeloVehiculoCtrl;
  late TextEditingController _anioVehiculoCtrl;
  late TextEditingController _colorVehiculoCtrl;
  
  String? _fechaNacimiento;
  PlatformFile? _nuevaFoto;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.user.nombre);
    _telefonoCtrl = TextEditingController(text: widget.user.telefono);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _documentoCtrl = TextEditingController(text: widget.user.documento ?? '');
    _direccionCtrl = TextEditingController(text: widget.user.direccion ?? '');
    _placaCtrl = TextEditingController(text: widget.user.placa ?? '');
    _marcaVehiculoCtrl = TextEditingController(text: widget.user.marcaVehiculo ?? '');
    _modeloVehiculoCtrl = TextEditingController(text: widget.user.modeloVehiculo ?? '');
    _anioVehiculoCtrl = TextEditingController(text: widget.user.anioVehiculo ?? '');
    _colorVehiculoCtrl = TextEditingController(text: widget.user.colorVehiculo ?? '');
    _fechaNacimiento = widget.user.fechaNacimiento;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _documentoCtrl.dispose();
    _direccionCtrl.dispose();
    _placaCtrl.dispose();
    _marcaVehiculoCtrl.dispose();
    _modeloVehiculoCtrl.dispose();
    _anioVehiculoCtrl.dispose();
    _colorVehiculoCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es requerido';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  String? _validateTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }
    if (value.length < 10) {
      return 'El teléfono debe tener al menos 10 dígitos';
    }
    return null;
  }

  String? _validateAnio(String? value) {
    if (value == null || value.isEmpty) return null;
    final anio = int.tryParse(value);
    if (anio == null) {
      return 'Ingresa un año válido';
    }
    if (anio < 1900 || anio > DateTime.now().year + 1) {
      return 'El año debe estar entre 1900 y ${DateTime.now().year + 1}';
    }
    return null;
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Elegir de galería'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _nuevaFoto = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  Future<void> _selectFechaNacimiento() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento != null 
          ? DateTime.tryParse(_fechaNacimiento!) ?? now.subtract(const Duration(days: 365 * 25))
          : now.subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: now.subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null) {
      setState(() {
        _fechaNacimiento = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    String? fotoUrl;
    if (_nuevaFoto != null) {
      final fotoResult = await _conductorService.uploadFotoPerfil(_nuevaFoto!);
      if (fotoResult['success'] == true) {
        fotoUrl = fotoResult['data']?['url'] ?? fotoResult['data']?['fotoPerfil'];
      }
    }

    final result = await _conductorService.updatePerfil(
      nombre: _nombreCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      documento: _documentoCtrl.text.trim().isNotEmpty ? _documentoCtrl.text.trim() : null,
      fechaNacimiento: _fechaNacimiento,
      direccion: _direccionCtrl.text.trim().isNotEmpty ? _direccionCtrl.text.trim() : null,
      fotoPerfil: fotoUrl,
      placa: _placaCtrl.text.trim().isNotEmpty ? _placaCtrl.text.trim().toUpperCase() : null,
      marcaVehiculo: _marcaVehiculoCtrl.text.trim().isNotEmpty ? _marcaVehiculoCtrl.text.trim() : null,
      modeloVehiculo: _modeloVehiculoCtrl.text.trim().isNotEmpty ? _modeloVehiculoCtrl.text.trim() : null,
      anioVehiculo: _anioVehiculoCtrl.text.trim().isNotEmpty ? _anioVehiculoCtrl.text.trim() : null,
      colorVehiculo: _colorVehiculoCtrl.text.trim().isNotEmpty ? _colorVehiculoCtrl.text.trim() : null,
    );

    setState(() => _saving = false);

    if (result['success'] == true) {
      final updatedUser = widget.user.copyWith(
        nombre: _nombreCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        documento: _documentoCtrl.text.trim().isNotEmpty ? _documentoCtrl.text.trim() : null,
        fechaNacimiento: _fechaNacimiento,
        direccion: _direccionCtrl.text.trim().isNotEmpty ? _direccionCtrl.text.trim() : null,
        fotoPerfil: fotoUrl ?? widget.user.fotoPerfil,
        placa: _placaCtrl.text.trim().isNotEmpty ? _placaCtrl.text.trim().toUpperCase() : null,
        marcaVehiculo: _marcaVehiculoCtrl.text.trim().isNotEmpty ? _marcaVehiculoCtrl.text.trim() : null,
        modeloVehiculo: _modeloVehiculoCtrl.text.trim().isNotEmpty ? _modeloVehiculoCtrl.text.trim() : null,
        anioVehiculo: _anioVehiculoCtrl.text.trim().isNotEmpty ? _anioVehiculoCtrl.text.trim() : null,
        colorVehiculo: _colorVehiculoCtrl.text.trim().isNotEmpty ? _colorVehiculoCtrl.text.trim() : null,
      );
      widget.onSave(updatedUser);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Error al guardar cambios';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(
        backgroundColor: AppColors.driverPrimary,
        foregroundColor: Colors.white,
        title: const Text('Editar perfil', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFotoPerfil(),
            const SizedBox(height: 16),
            _buildSection('Información personal', [
              _buildTextField(
                controller: _nombreCtrl,
                label: 'Nombre completo',
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.blue,
                validator: (v) => _validateRequired(v, 'El nombre'),
                textCapitalization: TextCapitalization.words,
              ),
              _buildTextField(
                controller: _emailCtrl,
                label: 'Correo electrónico',
                icon: Icons.email_outlined,
                iconColor: AppColors.green,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              _buildTextField(
                controller: _telefonoCtrl,
                label: 'Teléfono',
                icon: Icons.phone_outlined,
                iconColor: AppColors.purple,
                keyboardType: TextInputType.phone,
                validator: _validateTelefono,
              ),
              _buildTextField(
                controller: _documentoCtrl,
                label: 'Número de documento',
                icon: Icons.badge_outlined,
                iconColor: AppColors.orange,
                keyboardType: TextInputType.number,
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('Vehículo', [
              _buildTextField(
                controller: _placaCtrl,
                label: 'Placa',
                icon: Icons.directions_car_outlined,
                iconColor: AppColors.blue,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [UpperCaseTextFormatter()],
              ),
              _buildTextField(
                controller: _marcaVehiculoCtrl,
                label: 'Marca del vehículo',
                icon: Icons.car_rental_outlined,
                iconColor: AppColors.green,
                textCapitalization: TextCapitalization.words,
              ),
              _buildTextField(
                controller: _modeloVehiculoCtrl,
                label: 'Modelo del vehículo',
                icon: Icons.car_repair_outlined,
                iconColor: AppColors.purple,
                textCapitalization: TextCapitalization.words,
              ),
              _buildTextField(
                controller: _anioVehiculoCtrl,
                label: 'Año del vehículo',
                icon: Icons.calendar_today_outlined,
                iconColor: AppColors.orange,
                keyboardType: TextInputType.number,
                validator: _validateAnio,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              ),
              _buildTextField(
                controller: _colorVehiculoCtrl,
                label: 'Color del vehículo',
                icon: Icons.palette_outlined,
                iconColor: AppColors.red,
                textCapitalization: TextCapitalization.words,
              ),
            ]),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.redBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(color: AppColors.red, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar',
                        style: TextStyle(color: AppColors.textSub)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.driverPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Guardar cambios',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoPerfil() {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.bgGray,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 2),
                image: _nuevaFoto != null
                    ? DecorationImage(
                        image: FileImage(File(_nuevaFoto!.path!)),
                        fit: BoxFit.cover,
                      )
                    : widget.user.fotoPerfil != null
                        ? DecorationImage(
                            image: NetworkImage(widget.user.fotoPerfil!),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: _nuevaFoto == null && widget.user.fotoPerfil == null
                  ? const Icon(Icons.person, size: 60, color: AppColors.textSub)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.driverPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
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
            borderSide: const BorderSide(color: AppColors.driverPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.red),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String? value,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          child: Text(
            value ?? 'Seleccionar fecha',
            style: TextStyle(
              color: value != null ? AppColors.textMain : AppColors.textSub,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}