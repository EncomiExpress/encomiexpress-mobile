import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models.dart';
import '../../../../core/platform_utils.dart';
import '../../../../core/services/paquete_service.dart';
import '../../../../core/widgets.dart';
import '../../../../core/image_viewer.dart';

// Mismo tope que exige el backend para cualquier archivo subido (evidencia de
// paquete o soporte de anticipo) — config/cloudinary.js, multer `fileSize`.
const int _maxFotoBytes = 8 * 1024 * 1024;

String _formatBytes(num bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb < 0.1 && bytes > 0) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${mb.toStringAsFixed(1)} MB';
}

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
  // Mismo patrón de "Mostrar más" que admin_home.dart/driver_home.dart con
  // Anticipos: se trae todo de una vez y se revela de a 5, en vez de mostrar
  // los paquetes de todas las rutas de golpe.
  int _itemsToShow = 5;

  // idPaquete cuya acción está en curso — deshabilita el botón correspondiente
  // mientras se espera la respuesta del backend.
  final Set<int> _paquetesActualizando = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final conductorIdStr = widget.user.conductorId;
    final conductorId = conductorIdStr != null
        ? int.tryParse(conductorIdStr)
        : null;
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
      setState(() => _itemsToShow = (_itemsToShow + 5).clamp(0, _paquetes.length));
    }
  }

  // Agrupa por ruta (Paquete.asignacion.ruta) — así se ve de un vistazo a qué
  // ruta pertenece cada paquete, y de ahí sale el estado de la ruta que decide
  // si ya se pueden marcar entregas (ver _buildGrupo). Se agrupa solo lo que
  // ya está "revelado" (_itemsToShow), igual que Anticipos.
  List<_GrupoRuta> get _grupos {
    final Map<int, _GrupoRuta> mapa = {};
    for (final p in _paquetes.take(_itemsToShow)) {
      final paquete = p as Map<String, dynamic>;
      final asignacion = paquete['asignacion'] as Map<String, dynamic>?;
      final ruta = asignacion != null ? asignacion['ruta'] as Map<String, dynamic>? : null;
      final idRuta = ruta != null ? _toInt(ruta['idRuta']) : null;
      final key = idRuta ?? -1;
      mapa.putIfAbsent(key, () => _GrupoRuta(idRuta: idRuta, ruta: ruta));
      mapa[key]!.paquetes.add(paquete);
    }
    return mapa.values.toList();
  }

  Future<void> _marcarPaquete(Map<String, dynamic> paquete, String estado) async {
    final idPaquete = _toInt(paquete['idPaquete']);
    if (idPaquete == null) return;
    final resultado = await _EvidenciaSheet.show(context, estado: estado);
    if (resultado == null || !mounted) return; // el conductor canceló

    setState(() => _paquetesActualizando.add(idPaquete));
    final res = await _service.subirEvidencia(
      idPaquete,
      estado: estado,
      foto: resultado.foto,
      observacion: resultado.observacion,
    );
    if (!mounted) return;
    setState(() => _paquetesActualizando.remove(idPaquete));
    if (res['success'] == true) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'No se pudo actualizar el paquete')),
      );
    }
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Mostrar 5 más', style: TextStyle(color: AppColors.textMain)),
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
    final rutaLabel = ruta != null
        ? ((ruta['origen'] as String?)?.isNotEmpty == true
            ? ruta['origen'] as String
            : 'Ruta #${grupo.idRuta ?? '—'}')
        : 'Ruta desconocida';
    final horario = ruta != null
        ? '${ruta['fechaSalida'] ?? '—'} ${ruta['horaSalida'] ?? ''}'.trim()
        : '';
    final destino = ruta != null ? ruta['destino'] as Map<String, dynamic>? : null;
    final destinoTexto = destino != null
        ? '${destino['ciudad'] ?? ''}${(destino['ciudad'] != null && destino['departamento'] != null) ? ', ' : ''}${destino['departamento'] ?? ''}'
        : '';
    final detalle = [destinoTexto, horario].where((s) => s.isNotEmpty).join(' · ');
    // El conductor solo puede marcar entregas mientras la ruta está "En Ruta" —
    // antes de eso no ha salido de bodega (ver la misma validación en el backend,
    // encomiendaService.actualizarEstadoPaquete).
    final rutaEnRuta = ruta != null && ruta['estado'] == 'En Ruta';

    // Cada ruta es su propio bloque (mismo SectionCard que usa el resto de la
    // app) para que quede claramente separada de las demás — antes eran solo
    // tarjetas de paquete sueltas, una tras otra, sin nada que agrupara cuáles
    // eran de la misma ruta.
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
                      style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    if (detalle.isNotEmpty)
                      Text(detalle, style: TextStyle(color: AppColors.textSub, fontSize: 12)),
                  ],
                ),
              ),
              if (!rutaEnRuta)
                Text(
                  'La ruta aún no ha salido',
                  style: TextStyle(color: AppColors.textSub, fontSize: 11, fontStyle: FontStyle.italic),
                ),
            ],
          ),
          const SizedBox(height: 14),
          for (final p in grupo.paquetes) ...[
            _buildPaqueteCard(p, rutaEnRuta),
            if (p != grupo.paquetes.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildPaqueteCard(Map<String, dynamic> p, bool rutaEnRuta) {
    final encomienda = p['encomienda'] as Map<String, dynamic>?;
    final destinatario = encomienda != null ? encomienda['destinatario'] as Map<String, dynamic>? : null;
    final nombreDestinatario = (destinatario?['nombreDestinatario'] as String?) ?? '';
    final direccionDestinatario = (destinatario?['direccionDestinatario'] as String?) ?? '';
    final telefonoDestinatario = (destinatario?['telefonoDestinatario'] as String?) ?? '';
    final estado = (p['estado'] as String?) ?? 'Por entregar';
    final idPaquete = _toInt(p['idPaquete']);
    final actualizando = idPaquete != null && _paquetesActualizando.contains(idPaquete);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(12),
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
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMain),
                      ),
                      if ((p['descripcionContenido'] as String?)?.isNotEmpty == true)
                        Text(
                          p['descripcionContenido'] as String,
                          style: TextStyle(color: AppColors.textSub, fontSize: 13),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _estadoChip(estado),
              ],
            ),
            if (nombreDestinatario.isNotEmpty ||
                direccionDestinatario.isNotEmpty ||
                telefonoDestinatario.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),
              if (nombreDestinatario.isNotEmpty)
                Text(
                  nombreDestinatario,
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMain, fontSize: 13),
                ),
              if (direccionDestinatario.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSub),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          direccionDestinatario,
                          style: TextStyle(color: AppColors.textSub, fontSize: 13),
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
                      Icon(Icons.phone_outlined, size: 15, color: AppColors.textSub),
                      const SizedBox(width: 4),
                      Text(telefonoDestinatario, style: TextStyle(color: AppColors.textSub, fontSize: 13)),
                    ],
                  ),
                ),
            ],
            // Solo se puede marcar entregado/devuelto mientras la ruta ya está
            // "En Ruta" y el paquete sigue "Por entregar" — antes de eso la ruta
            // no ha salido, y después ('Entregado'/'Devuelto') ya no hay acción
            // que tomar (el backend además bloquea reabrir un estado final).
            if (estado == 'Por entregar' && rutaEnRuta) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: actualizando ? null : () => _marcarPaquete(p, 'Entregado'),
                      icon: Icon(Icons.check_circle_outline, size: 16, color: AppColors.green),
                      label: Text('Entregado', style: TextStyle(color: AppColors.green)),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.green)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: actualizando ? null : () => _marcarPaquete(p, 'Devuelto'),
                      icon: Icon(Icons.undo_rounded, size: 16, color: AppColors.red),
                      label: Text('Devuelto', style: TextStyle(color: AppColors.red)),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.red)),
                    ),
                  ),
                ],
              ),
              if (actualizando)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.driverPrimary),
                    ),
                  ),
                ),
            ],
            // Una vez el paquete queda en un estado final, el conductor puede
            // volver a consultar lo que él mismo registró — la observación y la
            // foto que subió al marcarlo (el backend ya no deja modificarlo).
            if (estado == 'Entregado' || estado == 'Devuelto') ...[
              if ((p['observacionEstado'] as String?)?.isNotEmpty == true ||
                  (p['fotoEntrega'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 10),
              ],
              if ((p['observacionEstado'] as String?)?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    p['observacionEstado'] as String,
                    style: TextStyle(color: AppColors.textSub, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              if ((p['fotoEntrega'] as String?)?.isNotEmpty == true)
                Builder(
                  builder: (ctx) => TapArea(
                    onTap: () => ImageViewer.show(ctx, [p['fotoEntrega'] as String]),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.driverPrimary),
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
      decoration: BoxDecoration(color: estadoPaqueteBg(estado), borderRadius: BorderRadius.circular(20)),
      child: Text(
        estado,
        style: TextStyle(color: estadoPaqueteColor(estado), fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _GrupoRuta {
  final int? idRuta;
  final Map<String, dynamic>? ruta;
  final List<Map<String, dynamic>> paquetes = [];
  _GrupoRuta({required this.idRuta, required this.ruta});
}

class _EvidenciaResult {
  final PlatformFile foto;
  final String observacion;
  _EvidenciaResult(this.foto, this.observacion);
}

// Hoja inferior para capturar la foto de evidencia (obligatoria, la exige
// paqueteController.subirEvidencia en el backend) antes de marcar un paquete
// como Entregado o Devuelto.
class _EvidenciaSheet extends StatefulWidget {
  final String estado;
  const _EvidenciaSheet({required this.estado});

  static Future<_EvidenciaResult?> show(BuildContext context, {required String estado}) {
    return showModalBottomSheet<_EvidenciaResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EvidenciaSheet(estado: estado),
    );
  }

  @override
  State<_EvidenciaSheet> createState() => _EvidenciaSheetState();
}

class _EvidenciaSheetState extends State<_EvidenciaSheet> {
  PlatformFile? _foto;
  String? _errorPeso;
  final _obsCtrl = TextEditingController();

  // Valida el peso antes de aceptar la foto — si no, el backend la rechaza
  // recién al confirmar y el conductor pierde la evidencia que ya tomó.
  void _setFoto(PlatformFile archivo) {
    if (archivo.size > _maxFotoBytes) {
      setState(() {
        _foto = null;
        _errorPeso = '"${archivo.name}" pesa ${_formatBytes(archivo.size)}: supera el máximo de ${_formatBytes(_maxFotoBytes)}.';
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
              leading: Icon(Icons.photo_camera_outlined, color: AppColors.textMain),
              title: Text('Tomar foto', style: TextStyle(color: AppColors.textMain)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppColors.textMain),
              title: Text('Elegir de la galería', style: TextStyle(color: AppColors.textMain)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final xfile = await ImagePicker().pickImage(source: source, imageQuality: 85);
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
    final esEntregado = widget.estado == 'Entregado';
    // El acento sigue el tema activo (rojo/azul), no el estado — igual que el
    // resto de campos e inputs de la app, sin importar si es Entregado o Devuelto.
    final acento = AppColors.driverPrimary;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
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
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(
              esEntregado ? 'Marcar como entregado' : 'Marcar como devuelto',
              style: TextStyle(color: AppColors.textMain, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text('Se requiere una foto como evidencia', style: TextStyle(color: AppColors.textSub, fontSize: 13)),
            const SizedBox(height: 2),
            Text('Máx. ${_formatBytes(_maxFotoBytes)} por foto', style: TextStyle(color: AppColors.textSub, fontSize: 11.5)),
            const SizedBox(height: 16),
            TapArea(
              onTap: _pickFoto,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: _foto == null ? 24 : 14, horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(
                      _foto == null ? Icons.camera_alt_outlined : Icons.check_circle,
                      color: _foto == null ? AppColors.textSub : AppColors.green,
                      size: _foto == null ? 28 : 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _foto == null ? 'Seleccionar foto' : '${_foto!.name} · ${_formatBytes(_foto!.size)}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _foto == null ? AppColors.textSub : AppColors.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_errorPeso != null) ...[
              const SizedBox(height: 6),
              Text(_errorPeso!, style: TextStyle(color: AppColors.red, fontSize: 12)),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _obsCtrl,
              maxLines: 2,
              style: TextStyle(color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: 'Observación (opcional)',
                hintStyle: TextStyle(color: AppColors.textSub),
                filled: true,
                fillColor: AppColors.bgGray,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: acento, width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),
            TapArea(
              onTap: _foto == null ? null : () => Navigator.pop(context, _EvidenciaResult(_foto!, _obsCtrl.text.trim())),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: _foto == null ? AppColors.border : acento,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Confirmar',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
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
