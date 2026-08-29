import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models.dart';
import '../../../../core/platform_utils.dart';
import '../../../../core/services/anticipo_service.dart';
import '../../../../core/widgets.dart';

// Mismo tope que el formulario web (RegistrarAnticipoExcedente.jsx / ActualizarAnticipoExcedente.jsx).
const double _maxValorMonto = 999999999;

// Tope propio para "Valor gastado" — mucho más bajo que _maxValorMonto porque
// en la práctica un anticipo no se gasta ni de cerca hasta los 999.999.999.
const double _maxValorGastado = 999999;

// Mismos topes que exige el backend (config/cloudinary.js: multer `fileSize`,
// y `upload.array('soporte', 5)` en routes/anticipos.js) — validados acá para
// avisar antes de intentar subir, no solo cuando el backend ya rechazó.
const int _maxSoporteBytes = 8 * 1024 * 1024; // 8 MB por archivo
const int _maxSoporteArchivos = 5; // por cada vez que se suben (no es un total acumulado del anticipo)

String _formatBytes(num bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb < 0.1 && bytes > 0) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${mb.toStringAsFixed(1)} MB';
}

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

  List<Map<String, dynamic>> _rutas = [];
  bool _loadingRutas = false;
  bool _rutasError = false;
  String? _idRuta;
  String? _idRutaVehiculoConductor;

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
  String? _idRutaOriginal;
  String? _idRutaVehiculoConductorOriginal;
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
  Map<String, dynamic> get _rutaSeleccionada => _rutas.firstWhere(
        (r) => r['idRuta']?.toString() == _idRuta,
        orElse: () => <String, dynamic>{},
      );

  List<Map<String, dynamic>> get _paresDeRutaSeleccionada =>
      ((_rutaSeleccionada['paresVehiculoConductor'] as List?) ?? [])
          .cast<Map<String, dynamic>>();

  Map<String, dynamic> get _parSeleccionado => _paresDeRutaSeleccionada.firstWhere(
        (p) => p['idRutaVehiculoConductor']?.toString() == _idRutaVehiculoConductor,
        orElse: () => <String, dynamic>{},
      );

  String _nombreConductorDePar(Map<String, dynamic> par) {
    final usuario = par['conductor']?['usuario'] as Map<String, dynamic>?;
    return usuario != null ? '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}'.trim() : '';
  }

  String get _conductorNombreActual {
    if (_isNew || _entregado) {
      return _nombreConductorDePar(_parSeleccionado);
    }
    return widget.anticipo?.conductorNombre ?? '';
  }

  @override
  void initState() {
    super.initState();
    final a = widget.anticipo;
    _idRuta = a?.idRuta.toString();
    _valorAnticipoCtrl = TextEditingController(text: a != null ? a.valorAnticipo.toStringAsFixed(0) : '');
    _valorGastadoCtrl = TextEditingController(text: a != null ? a.valorGastado.toStringAsFixed(0) : '');
    _fechaEntrega = _parseIso(a?.fechaEntrega);
    _soporteActual = a?.soporte ?? [];

    _valorAnticipoOriginal = a?.valorAnticipo ?? 0;
    _valorGastadoOriginal = a?.valorGastado ?? 0;
    _idRutaOriginal = a?.idRuta.toString();
    _fechaEntregaOriginal = _fechaEntrega;

    if (widget.isAdmin && (_isNew || _entregado)) {
      _loadRutas();
    }

    _valorAnticipoCtrl.addListener(() => setState(() {}));
    _valorGastadoCtrl.addListener(() => setState(() {}));
    _valorAnticipoFocus.addListener(() => setState(() {}));
    _valorGastadoFocus.addListener(() {
      // El "0" que se ve al entrar a legalizar es el valor por defecto que
      // pone el backend al crear el anticipo (nadie lo escribió) — se borra
      // solo al enfocar el campo, para no obligar al conductor a borrarlo a
      // mano antes de escribir el valor real.
      if (_valorGastadoFocus.hasFocus && _valorGastadoCtrl.text == '0') {
        _valorGastadoCtrl.clear();
      }
      setState(() {});
    });
  }

  DateTime? _parseIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadRutas() async {
    setState(() {
      _loadingRutas = true;
      _rutasError = false;
    });
    try {
      final data = await _anticipoService.getRutas();
      if (!mounted) return;
      setState(() {
        _rutas = data;
        _loadingRutas = false;
        // Al editar un anticipo "Entregado", preselecciona el par
        // vehículo/conductor que ya tenía (mismo idConductor) dentro de la
        // ruta que ya traía — igual que `parInicial` en
        // ActualizarAnticipoExcedente.jsx (web).
        if (!_isNew && _idRutaVehiculoConductor == null) {
          final par = _paresDeRutaSeleccionada.firstWhere(
            (p) => p['idConductor']?.toString() == widget.anticipo?.idConductor.toString(),
            orElse: () => <String, dynamic>{},
          );
          if (par.isNotEmpty) {
            _idRutaVehiculoConductor = par['idRutaVehiculoConductor']?.toString();
            _idRutaVehiculoConductorOriginal = _idRutaVehiculoConductor;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rutas = [];
        _loadingRutas = false;
        _rutasError = true;
      });
    }
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

  // Filtra por tamaño y por el tope de cantidad antes de agregar — avisa qué
  // quedó afuera y por qué, en vez de dejar que el backend lo rechace después
  // sin que el conductor sepa cuál de los archivos era el problema.
  void _agregarSoporte(List<PlatformFile> candidatos) {
    if (candidatos.isEmpty) return;
    final rechazadosPorPeso = <String>[];
    final aceptados = <PlatformFile>[];
    var cupoRestante = _maxSoporteArchivos - _soporteNuevo.length;

    for (final f in candidatos) {
      if (f.size > _maxSoporteBytes) {
        rechazadosPorPeso.add(f.name);
        continue;
      }
      if (cupoRestante <= 0) continue;
      aceptados.add(f);
      cupoRestante--;
    }

    if (aceptados.isNotEmpty) setState(() => _soporteNuevo.addAll(aceptados));

    if (rechazadosPorPeso.isNotEmpty) {
      showAppSnackBar(
        context,
        '${rechazadosPorPeso.length == 1 ? 'No se agregó "${rechazadosPorPeso.first}"' : 'No se agregaron ${rechazadosPorPeso.length} archivos'}: superan el máximo de ${_formatBytes(_maxSoporteBytes)} por archivo.',
        severity: 'error',
      );
    } else if (cupoRestante < 0 || (candidatos.length - rechazadosPorPeso.length) > aceptados.length) {
      showAppSnackBar(context, 'Solo se pueden agregar hasta $_maxSoporteArchivos archivos por vez.', severity: 'error');
    }
  }

  Future<void> _pickArchivos() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      _agregarSoporte(result.files);
    }
  }

  Future<void> _pickSoporte() async {
    if (_soporteNuevo.length >= _maxSoporteArchivos) {
      showAppSnackBar(context, 'Ya agregaste el máximo de $_maxSoporteArchivos archivos por vez.', severity: 'error');
      return;
    }
    // En escritorio/web, image_picker no tiene cámara/galería — directo al
    // selector de archivos de siempre (PDF + imágenes, varios a la vez).
    if (!esMovil) {
      await _pickArchivos();
      return;
    }

    final opcion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: AppColors.textMain),
              title: Text('Tomar foto', style: TextStyle(color: AppColors.textMain)),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppColors.textMain),
              title: Text('Elegir de la galería', style: TextStyle(color: AppColors.textMain)),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: Icon(Icons.insert_drive_file_outlined, color: AppColors.textMain),
              title: Text('Elegir archivo (PDF o imagen)', style: TextStyle(color: AppColors.textMain)),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
          ],
        ),
      ),
    );
    if (opcion == null || !mounted) return;

    if (opcion == 'file') {
      await _pickArchivos();
      return;
    }

    final xfile = await ImagePicker().pickImage(
      source: opcion == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (xfile == null || !mounted) return;

    final size = await xfile.length();
    _agregarSoporte([PlatformFile(path: xfile.path, name: xfile.name, size: size)]);
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
      if (_idRuta == null || _idRuta!.isEmpty) {
        setState(() {
          _saving = false;
          _error = 'Selecciona una ruta';
        });
        return;
      }
      if (_idRutaVehiculoConductor == null || _idRutaVehiculoConductor!.isEmpty) {
        setState(() {
          _saving = false;
          _error = 'Selecciona el vehículo y conductor de la ruta';
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
        idRuta: _idRuta!,
        idRutaVehiculoConductor: _idRutaVehiculoConductor!,
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
      final sinCambios = _idRuta == _idRutaOriginal &&
          _idRutaVehiculoConductor == _idRutaVehiculoConductorOriginal &&
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
        'idRuta': int.tryParse(_idRuta ?? ''),
        'idRutaVehiculoConductor': int.tryParse(_idRutaVehiculoConductor ?? ''),
        'valorAnticipo': valorAnticipo,
        if (_fechaEntrega != null) 'fechaEntrega': _isoDate(_fechaEntrega!),
      });
    }

    Anticipo? anticipo = result['success'] == true ? result['anticipo'] as Anticipo : null;

    // Si esta llamada falla (p. ej. el token venció justo entre esta petición
    // y la de arriba), _soporteNuevo se deja intacto para poder reintentar
    // sin perder los archivos ya elegidos — no se puede tratar como éxito
    // solo porque el resto del anticipo sí se guardó.
    String? soporteError;
    if (anticipo != null && _soporteNuevo.isNotEmpty) {
      final subResult = await _anticipoService.subirSoporte(anticipo.id, _soporteNuevo);
      // Se arma el anticipo actualizado con la respuesta de la propia subida
      // (ya trae el array `soporte` completo) en vez de volver a pedirlo con
      // GET /api/anticipos/:id — ese endpoint exige el permiso 'consultar_anticipo',
      // que el rol conductor no tiene, así que le daba 403 y la subida quedaba
      // "invisible" hasta la próxima vez que abrieras el detalle.
      if (subResult['success'] == true) {
        anticipo = anticipo.copyWith(soporte: subResult['soporte'] as List<String>);
      } else {
        soporteError = subResult['message'] as String? ?? 'Error al subir el soporte';
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (anticipo == null) {
      setState(() => _error = result['message'] ?? 'Error al guardar');
    } else if (soporteError != null) {
      // El anticipo sí quedó guardado, pero el comprobante no — mostrar el
      // error y quedarse en la pantalla en vez de cerrarla como si todo
      // hubiera salido bien (antes esto se mostraba como cargado en el
      // móvil aunque el backend nunca recibió el archivo).
      setState(() => _error = soporteError);
    } else {
      Navigator.pop(context, anticipo);
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
                                  _loadingRutas
                                      ? Text('Cargando rutas...',
                                          style: TextStyle(color: AppColors.textSub, fontSize: 13))
                                      : (_rutas.isEmpty
                                          ? Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                      _rutasError
                                                          ? 'No se pudieron cargar las rutas. Verifica tu conexión con el servidor.'
                                                          : 'No hay rutas disponibles.',
                                                      style: TextStyle(color: AppColors.textSub, fontSize: 13)),
                                                ),
                                                TapArea(
                                                  onTap: _loadRutas,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 8),
                                                    child: Icon(Icons.refresh_rounded, color: primary, size: 20),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : _dropdown(
                                          value: _idRuta,
                                          items: _rutas.map((r) {
                                            final destino = r['destino'] as Map<String, dynamic>?;
                                            final origen = (r['origen'] as String?) ?? 'Ruta #${r['idRuta']}';
                                            final destinoTxt = destino?['ciudad'] as String? ?? 'Sin destino';
                                            return DropdownMenuItem<String>(
                                                value: r['idRuta'].toString(),
                                                child: Text('$origen → $destinoTxt'));
                                          }).toList(),
                                          // Cambiar de ruta invalida el par vehículo/conductor
                                          // elegido — se autocompleta solo si la ruta tiene un
                                          // único par, igual que en RegistrarAnticipoExcedente.jsx
                                          // (web).
                                          onChanged: (v) => setState(() {
                                            _idRuta = v;
                                            final pares = _paresDeRutaSeleccionada;
                                            _idRutaVehiculoConductor =
                                                pares.length == 1 ? pares.first['idRutaVehiculoConductor']?.toString() : null;
                                          }),
                                        )),
                                  if (!_loadingRutas && _rutas.isNotEmpty && _idRuta != null) ...[
                                    const SizedBox(height: 14),
                                    _label('Vehículo / Conductor *'),
                                    const SizedBox(height: 8),
                                    _paresDeRutaSeleccionada.isEmpty
                                        ? Text('Esta ruta no tiene vehículo/conductor asignado.',
                                            style: TextStyle(color: AppColors.textSub, fontSize: 13))
                                        : _dropdown(
                                            value: _idRutaVehiculoConductor,
                                            items: _paresDeRutaSeleccionada.map((p) {
                                              final placa = (p['vehiculo'] as Map<String, dynamic>?)?['placa'] as String? ?? 'Sin placa';
                                              final nombre = _nombreConductorDePar(p);
                                              return DropdownMenuItem<String>(
                                                  value: p['idRutaVehiculoConductor'].toString(),
                                                  child: Text('$placa — $nombre'));
                                            }).toList(),
                                            onChanged: (v) => setState(() => _idRutaVehiculoConductor = v),
                                          ),
                                  ],
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
                                  if (widget.anticipo!.destinoTexto != null) ...[
                                    Divider(color: AppColors.border, height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Destino', style: TextStyle(color: AppColors.textMain, fontSize: 14)),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Text(
                                              widget.anticipo!.destinoTexto!,
                                              textAlign: TextAlign.right,
                                              style: TextStyle(color: AppColors.textMain, fontSize: 15)),
                                        ),
                                      ],
                                    ),
                                  ],
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
                                      // El gasto puede superar el anticipo (queda un excedente
                                      // negativo a favor del conductor) — el tope acá es solo la
                                      // cota de sanidad fija, ya no depende de "Valor del anticipo".
                                      maxValue: () => _maxValorGastado,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'El valor gastado es obligatorio';
                                        final n = double.tryParse(v);
                                        if (n == null || n < 0) return 'Ingresa un valor válido';
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
                                              .withValues(alpha: 0.3)),
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
                                              Text(_excedente < 0 ? 'Faltante a Reponer' : 'Excedente a Devolver',
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
                                                      'La empresa deberá reponer este saldo',
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
                                const SizedBox(height: 4),
                                Text(
                                  'Máx. ${_formatBytes(_maxSoporteBytes)} por archivo · hasta $_maxSoporteArchivos por vez',
                                  style: TextStyle(color: AppColors.textSub, fontSize: 11.5),
                                ),
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
                                          const SizedBox(width: 6),
                                          Text(_formatBytes(e.value.size),
                                              style: TextStyle(color: AppColors.textSub, fontSize: 12)),
                                          const SizedBox(width: 6),
                                          TapArea(
                                            onTap: () => _quitarSoporteNuevo(e.key),
                                            child: Icon(Icons.close_rounded, color: AppColors.textSub, size: 18),
                                          ),
                                        ],
                                      ),
                                    )),
                                // Contador en vivo: se actualiza al agregar/quitar un archivo
                                // (setState del propio _soporteNuevo ya dispara el rebuild).
                                if (_soporteNuevo.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      '${_soporteNuevo.length}/$_maxSoporteArchivos archivos · ${_formatBytes(_soporteNuevo.fold<int>(0, (s, f) => s + f.size))} en total',
                                      style: TextStyle(color: AppColors.textSub, fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                  ),
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
                                                : Icons.check_circle,
                                            color: (_soporteActual.isEmpty && _soporteNuevo.isEmpty)
                                                ? AppColors.textSub
                                                : AppColors.green,
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
          color: readonly ? AppColors.border.withValues(alpha: 0.25) : AppColors.bgGray,
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
