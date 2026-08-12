import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/models.dart';
import '../../../../core/services/paquete_service.dart';
import '../../../../core/widgets.dart';

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
  int? _conductorId;

  // idRuta / idPaquete cuya acción está en curso — deshabilita el botón
  // correspondiente mientras se espera la respuesta del backend.
  final Set<int> _rutasIniciando = {};
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
    _conductorId = conductorId;
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
      });
    }
  }

  static int? _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

  // Agrupa por ruta (Paquete.asignacion.ruta) porque "Iniciar reparto" es una
  // acción masiva: rutaService.marcarReparto marca de una vez todos los
  // paquetes del conductor en esa ruta — no tiene sentido pedirla por paquete.
  List<_GrupoRuta> get _grupos {
    final Map<int, _GrupoRuta> mapa = {};
    for (final p in _paquetes) {
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

  Future<void> _iniciarReparto(_GrupoRuta grupo) async {
    if (grupo.idRuta == null || _conductorId == null) return;
    setState(() => _rutasIniciando.add(grupo.idRuta!));
    final result = await _service.marcarReparto(grupo.idRuta!, _conductorId!);
    if (!mounted) return;
    setState(() => _rutasIniciando.remove(grupo.idRuta!));
    if (result['success'] == true) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'No se pudo iniciar el reparto')),
      );
    }
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
              itemCount: grupos.length,
              itemBuilder: (_, i) => _buildGrupo(grupos[i]),
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
    final hayPendientes = grupo.paquetes.any((p) => p['estado'] == 'Por entregar');
    final iniciando = grupo.idRuta != null && _rutasIniciando.contains(grupo.idRuta);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rutaLabel,
                        style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      if (detalle.isNotEmpty)
                        Text(detalle, style: TextStyle(color: AppColors.textSub, fontSize: 12)),
                    ],
                  ),
                ),
                if (hayPendientes && grupo.idRuta != null)
                  TextButton.icon(
                    onPressed: iniciando ? null : () => _iniciarReparto(grupo),
                    icon: iniciando
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.driverPrimary),
                          )
                        : Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.driverPrimary),
                    label: Text(
                      'Iniciar reparto',
                      style: TextStyle(color: AppColors.driverPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          ...grupo.paquetes.map(_buildPaqueteCard),
        ],
      ),
    );
  }

  Widget _buildPaqueteCard(Map<String, dynamic> p) {
    final encomienda = p['encomienda'] as Map<String, dynamic>?;
    final destinatario = encomienda != null ? encomienda['destinatario'] as Map<String, dynamic>? : null;
    final nombreDestinatario = (destinatario?['nombreDestinatario'] as String?) ?? '';
    final direccionDestinatario = (destinatario?['direccionDestinatario'] as String?) ?? '';
    final telefonoDestinatario = (destinatario?['telefonoDestinatario'] as String?) ?? '';
    final estado = (p['estado'] as String?) ?? 'Por entregar';
    final idPaquete = _toInt(p['idPaquete']);
    final actualizando = idPaquete != null && _paquetesActualizando.contains(idPaquete);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
            // Solo se puede marcar entregado/devuelto una vez la ruta está
            // "En reparto" — antes de eso ('Por entregar') o después
            // (ya 'Entregado'/'Devuelto') no hay acción que tomar.
            if (estado == 'En reparto') ...[
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
          ],
        ),
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
  final _obsCtrl = TextEditingController();

  Future<void> _pickFoto() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _foto = result.files.single);
    }
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEntregado = widget.estado == 'Entregado';
    final acento = esEntregado ? AppColors.green : AppColors.red;

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
                      _foto == null ? 'Seleccionar foto' : _foto!.name,
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
