import 'package:flutter/material.dart';
import '../../../anticipos/domain/entities/anticipo.dart';

class AnticipoEdit extends StatefulWidget {
  final Anticipo? anticipo;
  final bool isAdmin;
  final Function(Anticipo)? onSave;

  const AnticipoEdit({
    super.key,
    this.anticipo,
    this.isAdmin = false,
    this.onSave,
  });

  @override
  State<AnticipoEdit> createState() => _AnticipoEditState();
}

class _AnticipoEditState extends State<AnticipoEdit> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tipoCtrl;
  late TextEditingController _conductorCtrl;
  late TextEditingController _conductorIdCtrl;
  late TextEditingController _anticipoCtrl;
  late TextEditingController _gastadoCtrl;
  late TextEditingController _fechaEntregaCtrl;
  late TextEditingController _fechaLegalCtrl;
  late TextEditingController _fechaMaxCtrl;
  late TextEditingController _soporteCtrl;
  String _estado = 'Pendiente';

  @override
  void initState() {
    super.initState();
    final a = widget.anticipo;
    _tipoCtrl = TextEditingController(text: a?.tipo ?? '');
    _conductorCtrl = TextEditingController(text: a?.conductorNombre ?? '');
    _conductorIdCtrl = TextEditingController(text: a?.conductorId ?? '');
    _anticipoCtrl = TextEditingController(text: a?.anticipo.toString() ?? '');
    _gastadoCtrl = TextEditingController(text: a?.gastado.toString() ?? '');
    _fechaEntregaCtrl = TextEditingController(text: a?.fechaEntrega ?? '');
    _fechaLegalCtrl = TextEditingController(text: a?.fechaLegalizacion ?? '');
    _fechaMaxCtrl = TextEditingController(text: a?.fechaMaxima ?? '');
    _soporteCtrl = TextEditingController(text: a?.soporte ?? '');
    _estado = a?.estado ?? 'Pendiente';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isAdmin
                    ? [const Color(0xFF7B2FBE), const Color(0xFF9B59B6)]
                    : [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.anticipo == null ? 'Nuevo Anticipo' : 'Editar Anticipo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField('Tipo', _tipoCtrl, Icons.category_rounded),
                    if (widget.isAdmin) ...[
                      _buildTextField('Conductor', _conductorCtrl, Icons.person_rounded),
                      _buildTextField('ID Conductor', _conductorIdCtrl, Icons.badge_rounded),
                    ],
                    _buildTextField('Anticipo', _anticipoCtrl, Icons.attach_money_rounded, isNumeric: true),
                    _buildTextField('Gastado', _gastadoCtrl, Icons.receipt_long_rounded, isNumeric: true),
                    _buildTextField('Fecha Entrega', _fechaEntregaCtrl, Icons.calendar_today_rounded),
                    _buildTextField('Fecha Legalización', _fechaLegalCtrl, Icons.event_available_rounded),
                    _buildTextField('Fecha Máxima', _fechaMaxCtrl, Icons.event_rounded),
                    _buildTextField('Soporte', _soporteCtrl, Icons.attach_file_rounded, required: false),
                    if (widget.isAdmin) ...[
                      const SizedBox(height: 16),
                      _buildEstadoDropdown(),
                    ],
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _guardar,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isAdmin
                                ? [const Color(0xFF7B2FBE), const Color(0xFF9B59B6)]
                                : [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Guardar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {bool isNumeric = false, bool required = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        validator: required ? (v) => v == null || v.isEmpty ? 'Requerido' : null : null,
        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B)),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
          filled: true,
          fillColor: Colors.white,
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
            borderSide: BorderSide(
              color: widget.isAdmin ? const Color(0xFF7B2FBE) : const Color(0xFF2563EB),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButton<String>(
        value: _estado,
        isExpanded: true,
        underline: const SizedBox(),
        items: ['Pendiente', 'Activo', 'Pagado', 'Rechazado']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => setState(() => _estado = v!),
      ),
    );
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final nuevo = Anticipo(
        id: widget.anticipo?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        tipo: _tipoCtrl.text,
        conductorNombre: _conductorCtrl.text,
        conductorId: _conductorIdCtrl.text,
        anticipo: double.tryParse(_anticipoCtrl.text) ?? 0,
        gastado: double.tryParse(_gastadoCtrl.text) ?? 0,
        estado: _estado,
        fechaEntrega: _fechaEntregaCtrl.text,
        fechaLegalizacion: _fechaLegalCtrl.text,
        fechaMaxima: _fechaMaxCtrl.text,
        soporte: _soporteCtrl.text.isEmpty ? null : _soporteCtrl.text,
      );
      widget.onSave?.call(nuevo);
      Navigator.pop(context, nuevo);
    }
  }

  @override
  void dispose() {
    _tipoCtrl.dispose();
    _conductorCtrl.dispose();
    _conductorIdCtrl.dispose();
    _anticipoCtrl.dispose();
    _gastadoCtrl.dispose();
    _fechaEntregaCtrl.dispose();
    _fechaLegalCtrl.dispose();
    _fechaMaxCtrl.dispose();
    _soporteCtrl.dispose();
    super.dispose();
  }
}