import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models.dart';
import '../../../../core/platform_utils.dart';
import '../../../../core/services/paquete_service.dart';
import '../../../../core/widgets.dart';
import '../../../../core/image_viewer.dart';

// Mismo tope que exige el backend para cualquier archivo subido (config/cloudinary.js).
const int _maxFotoBytes = 8 * 1024 * 1024;

String _formatBytes(num bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb < 0.1 && bytes > 0) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${mb.toStringAsFixed(1)} MB';
}

// Misma conversión que formatHora12() del frontend web (shared/utils/formatters.js)
// -- la hora de una ruta se guarda en 24h ("08:00") pero en cualquier pantalla que
// no sea el propio formulario de edición se muestra en 12h con AM/PM.
String? _formatHora12(String? hora) {
  if (hora == null || hora.isEmpty) return null;
  final partes = hora.split(':');
  if (partes.length < 2) return null;
  final h = int.tryParse(partes[0]);
  final m = int.tryParse(partes[1]);
  if (h == null || m == null) return null;
  final periodo = h >= 12 ? 'PM' : 'AM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $periodo';
}

// Pantalla "Paquetes" del conductor — entrega en dos fases (ver ../../../LOGICA.md):
// el conductor del tramo troncal NO entrega puerta a puerta, solo deja los
// paquetes en la sede de cada municipio (parada intermedia o destino final).
// Legaliza de una sola vez, por sede, con un único botón "Dejar N paquetes en
// sede" — no hay marca por paquete individual. La entrega final al destinatario
// (Entregado/Devuelto) la hace el distribuidor de esa sede desde su propio app.
class DriverPaquetes extends StatefulWidget {
  final UserModel user;
  const DriverPaquetes({super.key, required this.user});

  @override
  State<DriverPaquetes> createState() => _DriverPaquetesState();
}

class _DriverPaquetesState extends State<DriverPaquetes> {
  final _service = PaqueteService();
  bool _loading = true;
  List<dynamic> _paquetes = [];
  int _itemsToShow = 5;

  // Clave "idRuta-idDestino" de la sede cuya legalización está en curso — bloquea
  // ese botón mientras se espera la respuesta del backend.
  final Set<String> _sedesActualizando = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final conductorIdStr = widget.user.conductorId;
    final conductorId =
        conductorIdStr != null ? int.tryParse(conductorIdStr) : null;
    if (conductorId == null) {
      if (mounted) {
        setState(() {
          _paquetes = [];
          _loading = false;
        });
      }
      return;
    }
    final data = await _service.getPaquetesPorConductor(conductorId);
    if (mounted) {
      setState(() {
        _paquetes = data;
        _loading = false;
        _itemsToShow = 5;
      });
    }
  }

  static int? _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

  bool get _hayMas => _itemsToShow < _paquetes.length;

  void _mostrarMas() {
    if (_hayMas) {
      setState(
          () => _itemsToShow = (_itemsToShow + 5).clamp(0, _paquetes.length));
    }
  }

  // Agrupa primero por ruta (Paquete.asignacion.ruta) y, dentro de cada ruta, por
  // sede/municipio real de la venta (encomienda.destinatario.destino). Solo lo
  // ya "revelado" (_itemsToShow), mismo patrón que Anticipos.
  List<_GrupoRuta> get _grupos {
    final Map<int, _GrupoRuta> mapa = {};
    for (final p in _paquetes.take(_itemsToShow)) {
      final paquete = p as Map<String, dynamic>;
      final asignacion = paquete['asignacion'] as Map<String, dynamic>?;
      final ruta = asignacion?['ruta'] as Map<String, dynamic>?;
      final idRuta = ruta != null ? _toInt(ruta['idRuta']) : null;
      final rutaKey = idRuta ?? -1;
      final grupoRuta = mapa.putIfAbsent(
          rutaKey, () => _GrupoRuta(idRuta: idRuta, ruta: ruta));

      final destinatario =
          (paquete['encomienda'] as Map<String, dynamic>?)?['destinatario']
              as Map<String, dynamic>?;
      final destino = destinatario?['destino'] as Map<String, dynamic>?;
      final idDestino = destino != null
          ? _toInt(destino['idDestino'])
          : _toInt(destinatario?['idDestino']);
      final municipio = (destino?['municipio'] as String?) ??
          (destino?['departamento'] as String?) ??
          'Sede';
      final direccion = destino?['direccion'] as String?;
      final sedeKey = idDestino ?? -1;
      final grupoSede = grupoRuta.sedes.putIfAbsent(
          sedeKey,
          () => _GrupoSede(
              idDestino: idDestino, municipio: municipio, direccion: direccion));
      grupoSede.paquetes.add(paquete);
    }
    return mapa.values.toList();
  }

  Future<void> _dejarEnSede(int? idRuta, _GrupoSede sede) async {
    if (idRuta == null || sede.idDestino == null) return;
    final pendientes = sede.paquetes
        .where((p) => (p['estado'] as String?) == 'Por entregar')
        .length;
    if (pendientes == 0) return;

    final resultado = await _DejarEnSedeSheet.show(
      context,
      municipio: sede.municipio,
      cantidad: pendientes,
    );
    if (resultado == null || !mounted) return; // el conductor canceló

    final key = '$idRuta-${sede.idDestino}';
    setState(() => _sedesActualizando.add(key));
    final res = await _service.dejarEnSede(
      idRuta: idRuta,
      idDestino: sede.idDestino!,
      novedades: resultado.novedades,
      foto: resultado.foto,
    );
    if (!mounted) return;
    setState(() => _sedesActualizando.remove(key));

    showAppSnackBar(
      context,
      res['message'] ??
          (res['success'] == true
              ? 'Paquetes dejados en sede'
              : 'No se pudo legalizar la entrega en sede'),
      severity: res['success'] == true ? 'success' : 'error',
    );
    if (res['success'] == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _grupos;
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _paquetes.isEmpty
              ? ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    Center(
                      child: Text(
                        'No hay paquetes asignados',
                        style: TextStyle(color: AppColors.textSub),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: grupos.length + (_hayMas ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == grupos.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: OutlinedButton(
                          onPressed: _mostrarMas,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Mostrar 5 más',
                              style: TextStyle(color: AppColors.textMain)),
                        ),
                      );
                    }
                    return _buildGrupo(grupos[i]);
                  },
                ),
    );
  }

  Widget _buildGrupo(_GrupoRuta grupo) {
    final ruta = grupo.ruta;
    final destino = ruta?['destino'] as Map<String, dynamic>?;
    final destinoMunicipio = destino?['municipio'] as String?;
    final rutaLabel = ruta != null
        ? ((ruta['origen'] as String?)?.isNotEmpty == true
            ? '${ruta['origen']}${(destinoMunicipio?.isNotEmpty ?? false) ? ' - $destinoMunicipio' : ''}'
            : 'Ruta #${grupo.idRuta ?? '—'}')
        : 'Ruta desconocida';
    // horaSalida llega como "HH:mm:ss" (24h) del backend -- se muestra en 12h con
    // AM/PM, igual que en el listado de Rutas del panel web (formatHora12()).
    final horaSalida = _formatHora12(ruta?['horaSalida'] as String?) ?? '';
    final detalle = ruta != null
        ? '${ruta['fechaSalida'] ?? '—'} $horaSalida'.trim()
        : '';
    // El conductor solo puede legalizar mientras la ruta está "En Ruta" — antes
    // de eso no ha salido de bodega (misma validación en el backend,
    // encomiendaService.dejarPaquetesEnSede).
    final rutaEnRuta = ruta != null && ruta['estado'] == 'En Ruta';

    final sedes = grupo.sedes.values.toList();
    final sedesCompletadas =
        sedes.where((s) => s.paquetes.every((p) => (p['estado'] as String?) != 'Por entregar')).length;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rutaLabel,
                      style: TextStyle(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                    if (detalle.isNotEmpty)
                      Text(detalle,
                          style: TextStyle(
                              color: AppColors.textSub, fontSize: 12)),
                  ],
                ),
              ),
              if (!rutaEnRuta)
                Text(
                  'La ruta aún no ha salido',
                  style: TextStyle(
                      color: AppColors.textSub,
                      fontSize: 11,
                      fontStyle: FontStyle.italic),
                )
              else
                Text(
                  'Sedes: $sedesCompletadas de ${sedes.length}',
                  style: TextStyle(
                      color: AppColors.textSub,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (final sede in sedes) ...[
            const SizedBox(height: 8),
            _buildSede(grupo.idRuta, sede, rutaEnRuta),
          ],
        ],
      ),
    );
  }

  Widget _buildSede(int? idRuta, _GrupoSede sede, bool rutaEnRuta) {
    final pendientes = sede.paquetes
        .where((p) => (p['estado'] as String?) == 'Por entregar')
        .toList();
    final completada = pendientes.isEmpty;
    final key = '$idRuta-${sede.idDestino}';
    final actualizando = _sedesActualizando.contains(key);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_city_outlined,
                  size: 16, color: AppColors.textSub),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sede.municipio,
                  style: TextStyle(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ),
              Text(
                completada
                    ? '${sede.paquetes.length} en sede'
                    : '${pendientes.length} por dejar',
                style: TextStyle(
                    color: completada ? AppColors.green : AppColors.textSub,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (sede.direccion != null && sede.direccion!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                sede.direccion!,
                style: TextStyle(color: AppColors.textSub, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 10),
          for (final p in sede.paquetes) ...[
            _buildPaqueteCard(p),
            if (p != sede.paquetes.last) const SizedBox(height: 8),
          ],
          if (rutaEnRuta && !completada) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: actualizando
                    ? null
                    : () => _dejarEnSede(idRuta, sede),
                icon: actualizando
                    ? SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.driverPrimary),
                      )
                    : Icon(Icons.inventory_2_outlined,
                        size: 16, color: AppColors.driverPrimary),
                label: Text(
                  pendientes.length == 1
                      ? 'Dejar 1 paquete en la sede'
                      : 'Dejar ${pendientes.length} paquetes en la sede',
                  style: TextStyle(
                      color: AppColors.driverPrimary,
                      fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.driverPrimary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaqueteCard(Map<String, dynamic> p) {
    final encomienda = p['encomienda'] as Map<String, dynamic>?;
    final destinatario = encomienda?['destinatario'] as Map<String, dynamic>?;
    final nombreDestinatario =
        (destinatario?['nombreDestinatario'] as String?) ?? '';
    final direccionDestinatario =
        (destinatario?['direccionDestinatario'] as String?) ?? '';
    final telefonoDestinatario =
        (destinatario?['telefonoDestinatario'] as String?) ?? '';
    final estado = (p['estado'] as String?) ?? 'Por entregar';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['numeroGuia'] ?? '—',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain),
                    ),
                    if ((p['descripcionContenido'] as String?)?.isNotEmpty ==
                        true)
                      Text(
                        p['descripcionContenido'] as String,
                        style: TextStyle(
                            color: AppColors.textSub, fontSize: 13),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // "Entregado"/"Devuelto" son el resultado de la entrega FINAL al
              // destinatario, que hace el distribuidor de la sede -- no el
              // conductor del tramo troncal (ver ../../../LOGICA.md, "Entrega en
              // dos fases"). Para el conductor, un paquete solo tiene dos estados
              // relevantes: falta dejarlo en la sede, o ya lo dejó -- lo que pase
              // después ya no es asunto suyo, mostrárselo solo generaría ruido
              // (o incluso confusión, ya que el backend reutiliza los mismos
              // campos observacionEstado/fotoEntrega para la novedad y evidencia
              // que deja el distribuidor al entregar, ver el condicional de más
              // abajo).
              if (estado == 'Por entregar' || estado == 'En sede de destino')
                _estadoChip(estado),
            ],
          ),
          if (nombreDestinatario.isNotEmpty ||
              direccionDestinatario.isNotEmpty ||
              telefonoDestinatario.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),
            if (nombreDestinatario.isNotEmpty)
              Text(
                nombreDestinatario,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                    fontSize: 13),
              ),
            if (direccionDestinatario.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 15, color: AppColors.textSub),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        direccionDestinatario,
                        style: TextStyle(
                            color: AppColors.textSub, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            if (telefonoDestinatario.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 15, color: AppColors.textSub),
                    const SizedBox(width: 4),
                    Text(telefonoDestinatario,
                        style: TextStyle(
                            color: AppColors.textSub, fontSize: 13)),
                  ],
                ),
              ),
          ],
          // Mientras sigue "En sede de destino", el conductor puede volver a
          // consultar la novedad y la foto que él mismo dejó al legalizar la
          // sede (el backend ya no le deja cambiarlo). Una vez el distribuidor
          // hace la entrega final (Entregado/Devuelto), esos MISMOS campos
          // (observacionEstado/fotoEntrega) pasan a ser la novedad y evidencia
          // que dejó el distribuidor al entregar -- ya no son del conductor, así
          // que dejan de mostrarse acá.
          if (estado == 'En sede de destino') ...[
            if ((p['observacionEstado'] as String?)?.isNotEmpty == true ||
                (p['fotoEntrega'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 8),
            ],
            if ((p['observacionEstado'] as String?)?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  p['observacionEstado'] as String,
                  style: TextStyle(
                      color: AppColors.textSub,
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
              ),
            if ((p['fotoEntrega'] as String?)?.isNotEmpty == true)
              Builder(
                builder: (ctx) => TapArea(
                  onTap: () =>
                      ImageViewer.show(ctx, [p['fotoEntrega'] as String]),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_camera_outlined,
                          size: 16, color: AppColors.driverPrimary),
                      const SizedBox(width: 6),
                      Text(
                        'Ver evidencia',
                        style: TextStyle(
                          color: AppColors.driverPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _estadoChip(String estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: estadoPaqueteBg(estado),
          borderRadius: BorderRadius.circular(20)),
      child: Text(
        estado,
        style: TextStyle(
            color: estadoPaqueteColor(estado),
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _GrupoRuta {
  final int? idRuta;
  final Map<String, dynamic>? ruta;
  final Map<int, _GrupoSede> sedes = {};
  _GrupoRuta({required this.idRuta, required this.ruta});
}

class _GrupoSede {
  final int? idDestino;
  final String municipio;
  final String? direccion;
  final List<Map<String, dynamic>> paquetes = [];
  _GrupoSede({required this.idDestino, required this.municipio, this.direccion});
}

class _DejarEnSedeResult {
  final PlatformFile? foto; // opcional
  final String novedades; // opcional
  _DejarEnSedeResult(this.foto, this.novedades);
}

// Hoja inferior para legalizar la entrega en sede: foto y novedades OPCIONALES —
// el conductor puede confirmar sin subir nada (ver dejarPaquetesEnSede en el
// backend). Distinto de la evidencia de entrega final (esa sí obligatoria) que
// hace el distribuidor desde su propio app.
class _DejarEnSedeSheet extends StatefulWidget {
  final String municipio;
  final int cantidad;
  const _DejarEnSedeSheet({required this.municipio, required this.cantidad});

  static Future<_DejarEnSedeResult?> show(BuildContext context,
      {required String municipio, required int cantidad}) {
    return showModalBottomSheet<_DejarEnSedeResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _DejarEnSedeSheet(municipio: municipio, cantidad: cantidad),
    );
  }

  @override
  State<_DejarEnSedeSheet> createState() => _DejarEnSedeSheetState();
}

class _DejarEnSedeSheetState extends State<_DejarEnSedeSheet> {
  PlatformFile? _foto;
  String? _errorPeso;
  final _obsCtrl = TextEditingController();

  void _setFoto(PlatformFile archivo) {
    if (archivo.size > _maxFotoBytes) {
      setState(() {
        _foto = null;
        _errorPeso =
            '"${archivo.name}" pesa ${_formatBytes(archivo.size)}: supera el máximo de ${_formatBytes(_maxFotoBytes)}.';
      });
      return;
    }
    setState(() {
      _foto = archivo;
      _errorPeso = null;
    });
  }

  Future<void> _pickFoto() async {
    if (!esMovil) {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result != null && result.files.isNotEmpty) {
        _setFoto(result.files.single);
      }
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
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
              leading:
                  Icon(Icons.photo_camera_outlined, color: AppColors.textMain),
              title: Text('Tomar foto',
                  style: TextStyle(color: AppColors.textMain)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading:
                  Icon(Icons.photo_library_outlined, color: AppColors.textMain),
              title: Text('Elegir de la galería',
                  style: TextStyle(color: AppColors.textMain)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final xfile =
        await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (xfile == null || !mounted) return;

    final size = await xfile.length();
    _setFoto(PlatformFile(path: xfile.path, name: xfile.name, size: size));
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acento = AppColors.driverPrimary;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(
              'Dejar en sede — ${widget.municipio}',
              style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              widget.cantidad == 1
                  ? 'Se marcará 1 paquete como dejado en la sede'
                  : 'Se marcarán ${widget.cantidad} paquetes como dejados en la sede',
              style: TextStyle(color: AppColors.textSub, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text('Foto y novedades son opcionales',
                style: TextStyle(color: AppColors.textSub, fontSize: 11.5)),
            const SizedBox(height: 16),
            TapArea(
              onTap: _pickFoto,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                    vertical: _foto == null ? 20 : 14, horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(
                      _foto == null
                          ? Icons.camera_alt_outlined
                          : Icons.check_circle,
                      color:
                          _foto == null ? AppColors.textSub : AppColors.green,
                      size: _foto == null ? 26 : 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _foto == null
                          ? 'Adjuntar foto (opcional)'
                          : '${_foto!.name} · ${_formatBytes(_foto!.size)}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            _foto == null ? AppColors.textSub : AppColors.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_errorPeso != null) ...[
              const SizedBox(height: 6),
              Text(_errorPeso!,
                  style: TextStyle(color: AppColors.red, fontSize: 12)),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _obsCtrl,
              maxLines: 2,
              style: TextStyle(color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: 'Novedades (opcional)',
                hintStyle: TextStyle(color: AppColors.textSub),
                filled: true,
                fillColor: AppColors.bgGray,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: acento, width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),
            TapArea(
              onTap: () => Navigator.pop(
                  context, _DejarEnSedeResult(_foto, _obsCtrl.text.trim())),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: acento,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'Confirmar',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
