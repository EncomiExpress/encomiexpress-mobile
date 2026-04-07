import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class AnticipoEdit extends StatefulWidget {
  final Anticipo? anticipo;
  final bool isAdmin;

  const AnticipoEdit({super.key, this.anticipo, required this.isAdmin});

  @override
  State<AnticipoEdit> createState() => _AnticipoEditState();
}

class _AnticipoEditState extends State<AnticipoEdit> {
  final _formKey = GlobalKey<FormState>();

  late String _conductor;
  late String _tipo;
  late String _estado;
  late TextEditingController _anticipoCtrl;
  late TextEditingController _gastadoCtrl;
  late String _fechaEntrega;
  late String _fechaLeg;
  late String _fechaMax;
  String? _soporte;

  final _tipos    = ['Combustible', 'Peajes', 'Viáticos', 'Mantenimiento', 'Otro'];
  final _estados  = ['Activo', 'Pendiente', 'Pagado', 'Rechazado'];
  final _conductores = ['Juan Pérez', 'María García', 'Pedro Ramírez'];

  bool get _isNew => widget.anticipo == null;

  double get _excedente {
    final a = double.tryParse(_anticipoCtrl.text) ?? 0;
    final g = double.tryParse(_gastadoCtrl.text) ?? 0;
    return a - g;
  }

  @override
  void initState() {
    super.initState();
    final a = widget.anticipo;
    _conductor    = a?.conductorNombre ?? _conductores.first;
    _tipo         = a?.tipo ?? _tipos.first;
    _estado       = a?.estado ?? 'Activo';
    _anticipoCtrl = TextEditingController(text: a != null ? a.anticipo.toStringAsFixed(0) : '');
    _gastadoCtrl  = TextEditingController(text: a != null ? a.gastado.toStringAsFixed(0) : '');
    _fechaEntrega = a?.fechaEntrega ?? '';
    _fechaLeg     = a?.fechaLegalizacion ?? '';
    _fechaMax     = a?.fechaMaxima ?? '';
    _soporte      = a?.soporte;

    _anticipoCtrl.addListener(() => setState(() {}));
    _gastadoCtrl.addListener(() => setState(() {}));
  }

  Future<void> _pickDate(String field) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: widget.isAdmin
                ? AppColors.adminPrimary
                : AppColors.driverPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final str =
        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    setState(() {
      if (field == 'entrega')   _fechaEntrega = str;
      if (field == 'leg')       _fechaLeg     = str;
      if (field == 'max')       _fechaMax     = str;
    });
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final updated = Anticipo(
      id: widget.anticipo?.id ?? 'A-${DateTime.now().millisecondsSinceEpoch}',
      tipo: _tipo,
      conductorNombre: _conductor,
      conductorId: widget.anticipo?.conductorId ?? '2',
      anticipo: double.tryParse(_anticipoCtrl.text) ?? 0,
      gastado: double.tryParse(_gastadoCtrl.text) ?? 0,
      estado: _estado,
      fechaEntrega: _fechaEntrega,
      fechaLegalizacion: _fechaLeg,
      fechaMaxima: _fechaMax,
      soporte: _soporte,
    );

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final gradStart = widget.isAdmin ? AppColors.adminGradStart : AppColors.driverGradStart;
    final gradEnd   = widget.isAdmin ? AppColors.adminGradEnd   : AppColors.driverGradEnd;
    final primary   = widget.isAdmin ? AppColors.adminPrimary   : AppColors.driverPrimary;

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [gradStart, gradEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight),
            ),
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 12, 20, 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isNew ? 'Nuevo anticipo' : 'Editar anticipo',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    Text(
                        widget.isAdmin
                            ? 'Control total del anticipo'
                            : 'Registra gastos y soportes',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12)),
                  ],
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
                    if (widget.isAdmin)
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Conductor *'),
                            const SizedBox(height: 8),
                            _dropdown(
                              value: _conductor,
                              items: _conductores,
                              onChanged: (v) => setState(() => _conductor = v!),
                            ),
                          ],
                        ),
                      ),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Tipo de anticipo'),
                          const SizedBox(height: 8),
                          _dropdown(
                            value: _tipo,
                            items: _tipos,
                            onChanged: (v) => setState(() => _tipo = v!),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isAdmin)
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Estado'),
                            const SizedBox(height: 8),
                            _dropdown(
                              value: _estado,
                              items: _estados,
                              onChanged: (v) => setState(() => _estado = v!),
                            ),
                          ],
                        ),
                      ),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Anticipo'),
                          const SizedBox(height: 8),
                          _moneyField(_anticipoCtrl,
                              readonly: !widget.isAdmin),
                          const SizedBox(height: 14),
                          _label('Gastado'),
                          const SizedBox(height: 8),
                          _moneyField(_gastadoCtrl),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.purpleBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Excedente (calculado)',
                                    style: TextStyle(
                                        color: primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(formatCOP(_excedente),
                                    style: TextStyle(
                                        color: _excedente < 0
                                            ? AppColors.red
                                            : primary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800)),
                                if (_excedente < 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                        'Déficit: se gastó más del anticipo asignado',
                                        style: const TextStyle(
                                            color: AppColors.red,
                                            fontSize: 11)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Fecha de entrega'),
                          const SizedBox(height: 8),
                          _dateField(_fechaEntrega,
                              onTap: () => _pickDate('entrega'),
                              readonly: !widget.isAdmin),
                          const SizedBox(height: 14),
                          _label('Fecha de legalización'),
                          const SizedBox(height: 8),
                          _dateField(_fechaLeg,
                              onTap: () => _pickDate('leg')),
                          if (widget.isAdmin) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _label('Fecha máxima de legalización'),
                                const SizedBox(width: 4),
                                const Icon(Icons.lock_outline,
                                    size: 14, color: AppColors.textSub),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _dateField(_fechaMax,
                                onTap: () => _pickDate('max')),
                          ],
                        ],
                      ),
                    ),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Adjuntar soporte'),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => setState(
                                () => _soporte = 'documento_soporte.pdf'),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.bgGray,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.border,
                                    style: BorderStyle.solid,
                                    width: 1.5),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.upload_outlined,
                                      color: AppColors.textSub, size: 28),
                                  const SizedBox(height: 6),
                                  if (_soporte != null)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.attach_file,
                                            size: 14,
                                            color: AppColors.textSub),
                                        const SizedBox(width: 4),
                                        Text(_soporte!,
                                            style: const TextStyle(
                                                color: AppColors.textSub,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  TextButton(
                                    onPressed: () => setState(
                                        () => _soporte = 'archivo_seleccionado.pdf'),
                                    child: Text('Seleccionar archivo',
                                        style: TextStyle(color: primary)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _guardar,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [gradStart, gradEnd],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text('Actualizar anticipo',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          color: AppColors.textMain,
          fontSize: 14,
          fontWeight: FontWeight.w600));

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSub),
        style: const TextStyle(color: AppColors.textMain, fontSize: 15),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _moneyField(TextEditingController ctrl, {bool readonly = false}) {
    return TextFormField(
      controller: ctrl,
      readOnly: readonly,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: AppColors.textMain, fontSize: 15),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Campo requerido';
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12, right: 8),
          child: Text('\$',
              style: TextStyle(color: AppColors.textSub, fontSize: 16)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: readonly ? const Color(0xFFEEEEEE) : AppColors.bgGray,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.red)),
      ),
    );
  }

  Widget _dateField(String value,
      {required VoidCallback onTap, bool readonly = false}) {
    return GestureDetector(
      onTap: readonly ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: readonly ? const Color(0xFFEEEEEE) : AppColors.bgGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.textSub, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value.isEmpty ? 'Seleccionar fecha' : value,
                style: TextStyle(
                    color: value.isEmpty
                        ? AppColors.textSub
                        : AppColors.textMain,
                    fontSize: 15),
              ),
            ),
            if (!readonly)
              const Icon(Icons.calendar_month_outlined,
                  color: AppColors.textSub, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _anticipoCtrl.dispose();
    _gastadoCtrl.dispose();
    super.dispose();
  }
}