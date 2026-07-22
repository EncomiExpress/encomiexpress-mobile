import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/models.dart';
import '../../../../core/services/anticipo_service.dart';
import '../../../../core/widgets.dart';

// Mismo tope que el formulario web (RegistrarAnticipoExcedente.jsx / ActualizarAnticipoExcedente.jsx).
const double _maxValorMonto = 999999999;

// Bloquea la escritura en vez de solo marcar error después — mismo efecto que
// el `if (num > NUMERIC_LIMITS[name]) return` del formulario web, adaptado a
// TextInputFormatter porque en Flutter un TextField no es "controlado" como
// en React. `maxValue` es una función (no un valor fijo) porque el tope del
// campo "Valor gastado" depende de lo que haya en "Valor del anticipo" en
// cada momento.
class _MaxValueFormatter extends TextInputFormatter {
  final double Function() maxValue;
  _MaxValueFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final value = double.tryParse(newValue.text);
    if (value != null && value > maxValue()) return oldValue;
    return newValue;
  }
}

class AnticipoEdit extends StatefulWidget {
  final Anticipo? anticipo;
  final bool isAdmin;

  const AnticipoEdit({super.key, this.anticipo, required this.isAdmin});

  @override
  State<AnticipoEdit> createState() => _AnticipoEditState();
}

class _AnticipoEditState extends State<AnticipoEdit> {
  final _formKey = GlobalKey<FormState>();
  final _anticipoService = AnticipoService();
  bool _saving = false;
  String? _error;

  String _conductorId = '';

  List<Map<String, dynamic>> _rutasList = [];
  String? _rutaId;

  late TextEditingController _valorAnticipoCtrl;
  late TextEditingController _valorGastadoCtrl;
  final _valorAnticipoFocus = FocusNode();
  final _valorGastadoFocus = FocusNode();
  DateTime? _fechaEntrega;
  List<String> _soporteActual = [];
  final List<PlatformFile> _soporteNuevo = [];

  // Valores tal como llegaron, para poder detectar si el admin realmente
  // cambió algo antes de dejarlo guardar — mismo criterio que `formOriginal`
  // en ActualizarAnticipoExcedente.jsx (web).
  double _valorAnticipoOriginal = 0;
  double _valorGastadoOriginal = 0;
  String? _rutaIdOriginal;
  DateTime? _fechaEntregaOriginal;

  bool get _isNew => widget.anticipo == null;

  // Qué se puede tocar depende de quién mira la tarjeta y en qué estado está
  // el anticipo — ver anticipoService.update() en el backend.
  bool get _enLegalizacion => widget.anticipo?.estado == EstadoAnticipo.enLegalizacion;
  bool get _entregado => widget.anticipo?.estado == EstadoAnticipo.entregado;

  // El admin solo gestiona el anticipo mientras sigue "Entregado" (la ruta no
  // ha arrancado); una vez "En Legalización" es tarea exclusiva del conductor
  // desde su propia sesión — mismo criterio que el ícono "Editar" deshabilitado
  // en ListarAnticipoExcedente.jsx (web) para ese estado.
  bool get _puedeEditar {
    if (_isNew) return widget.isAdmin;
    if (widget.isAdmin) return _entregado;
    return _enLegalizacion;
  }

  // Mientras la ruta se puede elegir/reelegir (crear, o editar en "Entregado"),
  // el conductor mostrado sigue en vivo a la ruta seleccionada — igual que
  // `getNombreConductor()` en ActualizarAnticipoExcedente.jsx (web). En los
  // demás casos (solo consulta) se muestra el conductor que ya traía el
  // anticipo.
  String get _conductorNombreActual {
    if (_isNew || _entregado) {
      final ruta = _rutasList.firstWhere(
        (r) => r['idRuta'] == _rutaId,
        orElse: () => const {},
      );
      return ruta['conductorNombre'] as String? ?? '';
    }
    return widget.anticipo?.conductorNombre ?? '';
  }

  @override
  void initState() {
    super.initState();
    final a = widget.anticipo;
    _conductorId = a?.idConductor.toString() ?? '';
    _rutaId = a?.idRuta.toString();
    _valorAnticipoCtrl = TextEditingController(text: a != null ? a.valorAnticipo.toStringAsFixed(0) : '');
    _valorGastadoCtrl = TextEditingController(text: a != null ? a.valorGastado.toStringAsFixed(0) : '');
    _fechaEntrega = _parseIso(a?.fechaEntrega);
    _soporteActual = a?.soporte ?? [];

    _valorAnticipoOriginal = a?.valorAnticipo ?? 0;
    _valorGastadoOriginal = a?.valorGastado ?? 0;
    _rutaIdOriginal = a?.idRuta.toString();
    _fechaEntregaOriginal = _fechaEntrega;

    if (widget.isAdmin && (_isNew || _entregado)) {
      _loadRutas();
    }

    _valorAnticipoCtrl.addListener(() => setState(() {}));
    _valorGastadoCtrl.addListener(() => setState(() {}));
    _valorAnticipoFocus.addListener(() => setState(() {}));
    _valorGastadoFocus.addListener(() => setState(() {}));
  }

  DateTime? _parseIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadRutas() async {
    final data = await _anticipoService.getRutas();
    if (!mounted) return;
    setState(() => _rutasList = data);
  }

  double get _excedente {
    final anticipo = double.tryParse(_valorAnticipoCtrl.text) ?? 0;
    final gastado = double.tryParse(_valorGastadoCtrl.text) ?? 0;
    return anticipo - gastado;
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: widget.isAdmin ? AppColors.adminPrimary : AppColors.driverPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaEntrega = picked);
  }

  Future<void> _pickSoporte() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _soporteNuevo.addAll(result.files));
    }
  }

  void _quitarSoporteNuevo(int index) {
    setState(() => _soporteNuevo.removeAt(index));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    Map<String, dynamic> result;
    if (_isNew) {
      if (_rutaId == null || _rutaId!.isEmpty) {
        setState(() {
          _saving = false;
          _error = 'Selecciona una ruta';
        });
        return;
      }
      if (_fechaEntrega == null) {
        setState(() {
          _saving = false;
          _error = 'La fecha de entrega es obligatoria';
        });
        return;
      }
      result = await _anticipoService.crearAnticipo(
        idConductor: _conductorId,
        idRuta: _rutaId!,
        valorAnticipo: double.tryParse(_valorAnticipoCtrl.text) ?? 0,
        fechaEntrega: _isoDate(_fechaEntrega!),
      );
    } else if (_enLegalizacion) {
      final valorGastado = double.tryParse(_valorGastadoCtrl.text) ?? 0;
      if (valorGastado == _valorGastadoOriginal && _soporteNuevo.isEmpty) {
        setState(() {
          _saving = false;
          _error = 'No has realizado ningún cambio.';
        });
        return;
      }
      result = await _anticipoService.actualizarAnticipo(widget.anticipo!.id, {
        'valorGastado': valorGastado,
      });
    } else {
      // Entregado — solo admin llega aquí (ver _puedeEditar).
      final valorAnticipo = double.tryParse(_valorAnticipoCtrl.text) ?? 0;
      final sinCambios = _rutaId == _rutaIdOriginal &&
          valorAnticipo == _valorAnticipoOriginal &&
          _fechaEntrega == _fechaEntregaOriginal;
      if (sinCambios && _soporteNuevo.isEmpty) {
        setState(() {
          _saving = false;
          _error = 'No has realizado ningún cambio.';
        });
        return;
      }
      result = await _anticipoService.actualizarAnticipo(widget.anticipo!.id, {
        'idRuta': int.tryParse(_rutaId ?? ''),
        'valorAnticipo': valorAnticipo,
        if (_fechaEntrega != null) 'fechaEntrega': _isoDate(_fechaEntrega!),
      });
    }

    Anticipo? anticipo = result['success'] == true ? result['anticipo'] as Anticipo : null;

    if (anticipo != null && _soporteNuevo.isNotEmpty) {
      final subResult = await _anticipoService.subirSoporte(anticipo.id, _soporteNuevo);
      // Se arma el anticipo actualizado con la respuesta de la propia subida
      // (ya trae el array `soporte` completo) en vez de volver a pedirlo con
      // GET /api/anticipos/:id — ese endpoint exige el permiso 'consultar_anticipo',
      // que el rol conductor no tiene, así que le daba 403 y la subida quedaba
      // "invisible" hasta la próxima vez que abrieras el detalle.
      if (subResult['success'] == true) {
        anticipo = anticipo.copyWith(soporte: subResult['soporte'] as List<String>);
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (anticipo != null) {
      Navigator.pop(context, anticipo);
    } else {
      setState(() => _error = result['message'] ?? 'Error al guardar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradStart = widget.isAdmin ? AppColors.adminGradStart : AppColors.driverGradStart;
    final gradEnd = widget.isAdmin ? AppColors.adminGradEnd : AppColors.driverGradEnd;
    final primary = widget.isAdmin ? AppColors.adminPrimary : AppColors.driverPrimary;

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 20),
            child: Row(
              children: [
                TapArea(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back, color: AppColors.textMain, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isNew ? 'Nuevo anticipo' : 'Editar anticipo',
                        style: TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(
                        _isNew
                            ? 'Entrega un anticipo a un conductor'
                            : (!_puedeEditar
                                ? 'Solo lectura'
                                : (_enLegalizacion ? 'Registra el gasto para legalizar' : 'Ajusta los datos de entrega')),
                        style: TextStyle(color: AppColors.textSub, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: !_puedeEditar
                ? _buildNoEditable()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (widget.isAdmin && (_isNew || _entregado)) ...[
                            SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Ruta *'),
                                  const SizedBox(height: 8),
                                  _rutasList.isEmpty
                                      ? Text('Cargando rutas...',
                                          style: TextStyle(color: AppColors.textSub, fontSize: 13))
                                      : _dropdown(
                                          value: _rutaId,
                                          items: _rutasList
                                              .map((r) => DropdownMenuItem<String>(
                                                  value: r['idRuta'] as String, child: Text(r['nombre'] ?? '')))
                                              .toList(),
                                          // El conductor nunca se elige aparte — siempre sale de
                                          // la ruta escogida, igual que en la web (Autocomplete de
                                          // Ruta autocompleta el conductor) y que anticipoService
                                          // .update() en el backend, para que nunca queden
                                          // desincronizados.
                                          onChanged: (v) => setState(() {
                                            _rutaId = v;
                                            final ruta = _rutasList.firstWhere(
                                              (r) => r['idRuta'] == v,
                                              orElse: () => const {},
                                            );
                                            _conductorId = ruta['idConductor'] as String? ?? '';
                                          }),
                                        ),
                                ],
                              ),
                            ),
                          ] else if (!_isNew) ...[
                            SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 34, height: 34,
                                        decoration: BoxDecoration(
                                            color: AppColors.activeBg,
                                            borderRadius: BorderRadius.circular(10)),
                                        child: Icon(Icons.payments_outlined, color: primary, size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Text('Información',
                                          style: TextStyle(
                                              color: AppColors.textMain,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Ruta', style: TextStyle(color: AppColors.textMain, fontSize: 14)),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                            widget.anticipo!.nombreRuta ?? 'Anticipo #${widget.anticipo!.id}',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(color: AppColors.textMain, fontSize: 15)),
                                      ),
                                    ],
                                  ),
                                  Divider(color: AppColors.border, height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Estado', style: TextStyle(color: AppColors.textMain, fontSize: 14)),
                                      EstadoBadge(widget.anticipo!.estado),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (widget.isAdmin && _conductorNombreActual.isNotEmpty)
                            SectionCard(
                              child: InfoRow(
                                icon: Icons.person_outline_rounded,
                                iconColor: primary,
                                iconBg: widget.isAdmin ? AppColors.purpleBg : AppColors.blueBg,
                                label: 'Conductor',
                                value: _conductorNombreActual,
                              ),
                            ),

                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Valor del anticipo'),
                                const SizedBox(height: 8),
                                _moneyField(_valorAnticipoCtrl, _valorAnticipoFocus,
                                    readonly: !_isNew && !_entregado,
                                    maxValue: () => _maxValorMonto,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'El valor del anticipo es obligatorio';
                                      final n = double.tryParse(v);
                                      if (n == null || n <= 0) return 'Ingresa un valor válido mayor a 0';
                                      return null;
                                    }),
                                if (!_isNew && _enLegalizacion) ...[
                                  const SizedBox(height: 14),
                                  _label('Valor gastado *'),
                                  const SizedBox(height: 8),
                                  _moneyField(_valorGastadoCtrl, _valorGastadoFocus,
                                      requerido: true,
                                      maxValue: () => double.tryParse(_valorAnticipoCtrl.text) ?? _maxValorMonto,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'El valor gastado es obligatorio';
                                        final n = double.tryParse(v);
                                        if (n == null || n < 0) return 'Ingresa un valor válido';
                                        final anticipoVal = double.tryParse(_valorAnticipoCtrl.text) ?? 0;
                                        if (n > anticipoVal) return 'No puede ser mayor al valor del anticipo';
                                        return null;
                                      }),
                                  Container(
                                    margin: const EdgeInsets.only(top: 14),
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: _excedente < 0 ? AppColors.redBg : AppColors.greenBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: (_excedente < 0 ? AppColors.red : AppColors.green)
                                              .withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.attach_money_rounded,
                                            color: _excedente < 0 ? AppColors.red : AppColors.green, size: 30),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Excedente a Devolver',
                                                  style: TextStyle(
                                                      color: _excedente < 0 ? AppColors.red : AppColors.green,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 11,
                                                      letterSpacing: 0.3)),
                                              const SizedBox(height: 2),
                                              Text(formatCOP(_excedente),
                                                  style: TextStyle(
                                                      color: _excedente < 0 ? AppColors.red : AppColors.green,
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.w800)),
                                              if (_excedente < 0)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(
                                                      'El valor gastado no puede superar el anticipo entregado',
                                                      style: TextStyle(color: AppColors.red, fontSize: 11)),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Fecha de entrega'),
                                const SizedBox(height: 8),
                                _dateField(readonly: !_isNew && !_entregado),
                                if (!_isNew && _enLegalizacion) ...[
                                  const SizedBox(height: 14),
                                  _label('Fecha de legalización'),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgGray,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.event_available_outlined, color: AppColors.textSub, size: 18),
                                        const SizedBox(width: 10),
                                        Text(formatFecha(_isoDate(DateTime.now())),
                                            style: TextStyle(color: AppColors.textMain, fontSize: 15)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Se registra automáticamente con la fecha de hoy al guardar el valor gastado.',
                                      style: TextStyle(color: AppColors.textSub, fontSize: 11)),
                                ],
                              ],
                            ),
                          ),

                          // El soporte es el comprobante del GASTO (recibos de peajes,
                          // combustible, etc.) — solo tiene sentido que lo suba el
                          // conductor al legalizar, nunca el admin al entregar el
                          // anticipo (todavía no se gastó nada en ese momento).
                          if (!widget.isAdmin)
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Soporte'),
                                const SizedBox(height: 12),
                                // Comprobantes ya subidos (quedan tal cual — esta pantalla
                                // solo agrega, nunca reemplaza ni borra los anteriores).
                                ..._soporteActual.asMap().entries.map((e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Icon(Icons.insert_drive_file_outlined, color: AppColors.textSub, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text('Comprobante ${e.key + 1} (ya subido)',
                                                style: TextStyle(color: AppColors.textSub, fontSize: 13)),
                                          ),
                                        ],
                                      ),
                                    )),
                                // Archivos recién elegidos, todavía sin subir — se suben
                                // junto con el resto del formulario al pulsar "Guardar".
                                ..._soporteNuevo.asMap().entries.map((e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Icon(Icons.attach_file, color: primary, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(e.value.name,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: AppColors.textMain, fontSize: 13)),
                                          ),
                                          TapArea(
                                            onTap: () => _quitarSoporteNuevo(e.key),
                                            child: Icon(Icons.close_rounded, color: AppColors.textSub, size: 18),
                                          ),
                                        ],
                                      ),
                                    )),
                                TapArea(
                                  onTap: _pickSoporte,
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                        vertical: (_soporteActual.isEmpty && _soporteNuevo.isEmpty) ? 20 : 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgGray,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border, width: 1.5),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                            (_soporteActual.isEmpty && _soporteNuevo.isEmpty)
                                                ? Icons.upload_outlined
                                                : Icons.add_circle_outline,
                                            color: AppColors.textSub,
                                            size: (_soporteActual.isEmpty && _soporteNuevo.isEmpty) ? 28 : 20),
                                        const SizedBox(height: 6),
                                        Text(
                                            (_soporteActual.isEmpty && _soporteNuevo.isEmpty)
                                                ? 'Seleccionar archivo(s)'
                                                : 'Agregar otro archivo',
                                            style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.redBg, borderRadius: BorderRadius.circular(10)),
                              child: Text(_error!, style: TextStyle(color: AppColors.red, fontSize: 13)),
                            ),
                          ],
                          const SizedBox(height: 16),

                          TapArea(
                            onTap: _saving ? null : _guardar,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [gradStart, gradEnd], begin: Alignment.centerLeft, end: Alignment.centerRight),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: _saving
                                    ? const SizedBox(
                                        height: 22, width: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : Text(_isNew ? 'Crear anticipo' : 'Guardar',
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _buildNoEditable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, color: AppColors.textSub, size: 40),
            const SizedBox(height: 12),
            Text(
              widget.anticipo!.estado == EstadoAnticipo.enLegalizacion
                  ? 'Solo el conductor puede legalizar este anticipo.'
                  : 'Este anticipo ya no se puede editar en estado "${widget.anticipo!.estado}".',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSub, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w600));

  Widget _dropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
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
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSub),
        style: TextStyle(color: AppColors.textMain, fontSize: 15),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  // Mismo patrón que los campos del login: borde delgado + halo (boxShadow)
  // al enfocar. Cuando es de solo lectura, canRequestFocus se apaga para que
  // ni siquiera se pueda "entrar" al campo con el click — antes se podía
  // enfocar un campo bloqueado sin que eso sirviera para nada.
  Widget _moneyField(TextEditingController ctrl, FocusNode focusNode,
      {bool readonly = false,
      bool requerido = false,
      double Function()? maxValue,
      String? Function(String?)? validator}) {
    focusNode.canRequestFocus = !readonly;
    final hasFocus = focusNode.hasFocus;
    final primary = widget.isAdmin ? AppColors.adminPrimary : AppColors.driverPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: hasFocus ? [BoxShadow(color: AppColors.activeBg, blurRadius: 0, spreadRadius: 3)] : [],
      ),
      child: TextFormField(
        controller: ctrl,
        focusNode: focusNode,
        readOnly: readonly,
        showCursor: !readonly,
        enableInteractiveSelection: !readonly,
        mouseCursor: readonly ? SystemMouseCursors.basic : SystemMouseCursors.text,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          if (maxValue != null) _MaxValueFormatter(maxValue),
        ],
        style: TextStyle(color: AppColors.textMain, fontSize: 15),
        cursorColor: AppColors.textMain,
        validator: validator ??
            (v) {
              if (requerido && (v == null || v.isEmpty)) return 'Campo requerido';
              return null;
            },
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Text('\$', style: TextStyle(color: AppColors.textSub, fontSize: 16)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: readonly ? AppColors.bgGray : AppColors.cardBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.red)),
        ),
      ),
    );
  }

  Widget _dateField({bool readonly = false}) {
    return TapArea(
      onTap: readonly ? null : _pickFecha,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: readonly ? AppColors.border.withOpacity(0.25) : AppColors.bgGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: AppColors.textSub, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _fechaEntrega != null ? formatFecha(_isoDate(_fechaEntrega!)) : 'Seleccionar fecha',
                style: TextStyle(color: _fechaEntrega != null ? AppColors.textMain : AppColors.textSub, fontSize: 15),
              ),
            ),
            if (!readonly) Icon(Icons.calendar_month_outlined, color: AppColors.textSub, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _valorAnticipoCtrl.dispose();
    _valorGastadoCtrl.dispose();
    _valorAnticipoFocus.dispose();
    _valorGastadoFocus.dispose();
    super.dispose();
  }
}
