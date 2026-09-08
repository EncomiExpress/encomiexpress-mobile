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
// Mismo tope que ya usa "Observaciones" en Ruta/Venta (rutasValidator.js) — ver
// encomiendaService.NOVEDAD_MAX_LENGTH.
const int _novedadMaxLength = 500;
// Mismo tope que exige el backend (encomiendaService.MAX_INTENTOS_ENTREGA) —
// "No entregado" sigue disponible siempre; esto solo limita cuántas veces se
// puede seguir registrando 'Intento'. Ver LOGICA.md, "Tope de intentos de
// entrega".
const int _maxIntentosEntrega = 5;

String _formatBytes(num bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb < 0.1 && bytes > 0) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${mb.toStringAsFixed(1)} MB';
}

// "2026-09-05T20:15:00.000Z" (o similar) -> "05/09/2026" -- clave de agrupación
// y también lo que se muestra. Solo interesa el día, no la hora exacta.
String _fechaCorta(String? iso) {
  if (iso == null || iso.length < 10) return 'Sin fecha';
  final fecha = DateTime.tryParse(iso);
  if (fecha == null) return 'Sin fecha';
  return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
}

// Igual que _fechaCorta pero con hora -- para el historial de entrega
// (paquete_entrega_final.fecha), donde varios registros del mismo paquete
// pueden caer el mismo día y solo la hora los distingue. Equivalente a
// formatFechaHora() del panel web (ModalHistorialEntrega.jsx).
String _fechaHora(String? iso) {
  final fecha = iso == null ? null : DateTime.tryParse(iso);
  if (fecha == null) return 'Sin fecha';
  final local = fecha.toLocal();
  final horas12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final ampm = local.hour < 12 ? 'a. m.' : 'p. m.';
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
      '$horas12:${local.minute.toString().padLeft(2, '0')} $ampm';
}

// Pantalla "Paquetes" del distribuidor de sede — segunda fase de la entrega (ver
// ../../../LOGICA.md, "Entrega en dos fases"): el conductor ya dejó los paquetes
// "En sede de destino"; acá el distribuidor registra la entrega final al
// destinatario. Tres acciones por paquete:
//   - Entregado  -> terminal
//   - No entregado -> terminal (valor interno 'Devuelto'), novedad obligatoria
//   - Registrar intento -> no terminal, suma al contador de insistidera
class DistribuidorPaquetes extends StatefulWidget {
  final UserModel user;
  const DistribuidorPaquetes({super.key, required this.user});

  @override
  State<DistribuidorPaquetes> createState() => _DistribuidorPaquetesState();
}

class _DistribuidorPaquetesState extends State<DistribuidorPaquetes> {
  final _service = PaqueteService();
  bool _loading = true;
  List<dynamic> _paquetes = [];
  int _itemsToShow = 5;
  final _scrollController = ScrollController();

  // "Pendientes" (En sede de destino, getPaquetesEnSede) vs "Historial" (ya
  // cerrados por este distribuidor, getHistorialSede) — ver LOGICA.md,
  // "Historial de entrega final — tab del distribuidor". El historial se carga
  // recién la primera vez que se entra a esa pestaña (_historialCargado), no de
  // entrada -- lo más probable es que el distribuidor abra la pantalla a mirar
  // pendientes, no a revisar lo viejo.
  bool _verHistorial = false;
  bool _historialCargado = false;
  bool _loadingHistorial = true;
  List<dynamic> _historial = [];
  int _itemsToShowHistorial = 5;
  final _scrollControllerHistorial = ScrollController();

  // idPaquete cuya acción está en curso — deshabilita sus botones.
  final Set<int> _actualizando = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollControllerHistorial.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getPaquetesEnSede();
    if (mounted) {
      setState(() {
        _paquetes = data;
        _loading = false;
        _itemsToShow = 5;
      });
    }
  }

  Future<void> _loadHistorial() async {
    setState(() => _loadingHistorial = true);
    final data = await _service.getHistorialSede();
    if (mounted) {
      setState(() {
        _historial = data;
        _loadingHistorial = false;
        _historialCargado = true;
        _itemsToShowHistorial = 5;
      });
    }
  }

  void _cambiarTab(bool historial) {
    setState(() => _verHistorial = historial);
    if (historial && !_historialCargado) _loadHistorial();
  }

  static int? _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

  bool get _hayMas => _itemsToShow < _paquetes.length;

  void _mostrarMas() {
    if (_hayMas) {
      setState(
        () => _itemsToShow = (_itemsToShow + 5).clamp(0, _paquetes.length),
      );
    }
  }

  bool get _hayMasHistorial => _itemsToShowHistorial < _historial.length;

  void _mostrarMasHistorial() {
    if (_hayMasHistorial) {
      setState(
        () => _itemsToShowHistorial = (_itemsToShowHistorial + 5).clamp(
          0,
          _historial.length,
        ),
      );
    }
  }

  // Agrupa por fecha de llegada a la sede (Paquete.fechaUltimoEstado -- el
  // conductor deja los paquetes en sede de una sola vez por sede/ruta, así que
  // esa fecha ya es un buen indicador de "tanda"). No se agrupa por municipio:
  // un distribuidor cubre una sola sede (ver ../../../LOGICA.md), así que ese
  // dato nunca varía entre paquetes propios y mostrarlo como grupo era
  // redundante -- el municipio/dirección de la sede ya se ven una sola vez
  // arriba, en distribuidor_home.dart. Tampoco se agrupa por ruta (origen -
  // destino): esa es información de logística/flota que no le corresponde ver
  // al distribuidor, solo al conductor/admin.
  //
  // El backend ya ordena por fechaUltimoEstado DESC, así que el orden de
  // inserción en el Map ya deja primero la fecha más reciente sin resortear acá.
  List<_GrupoFecha> get _grupos {
    final Map<String, _GrupoFecha> mapa = {};
    for (final p in _paquetes.take(_itemsToShow)) {
      final paquete = p as Map<String, dynamic>;
      final etiqueta = _fechaCorta(paquete['fechaUltimoEstado'] as String?);
      final grupo = mapa.putIfAbsent(etiqueta, () => _GrupoFecha(etiqueta));
      grupo.paquetes.add(paquete);
    }
    return mapa.values.toList();
  }

  // Mismo agrupador que arriba, sobre _historial en vez de _paquetes -- acá
  // fechaUltimoEstado es cuándo ESTE distribuidor cerró el paquete (Entregado/
  // Devuelto), no cuándo llegó a la sede.
  List<_GrupoFecha> get _gruposHistorial {
    final Map<String, _GrupoFecha> mapa = {};
    for (final p in _historial.take(_itemsToShowHistorial)) {
      final paquete = p as Map<String, dynamic>;
      final etiqueta = _fechaCorta(paquete['fechaUltimoEstado'] as String?);
      final grupo = mapa.putIfAbsent(etiqueta, () => _GrupoFecha(etiqueta));
      grupo.paquetes.add(paquete);
    }
    return mapa.values.toList();
  }

  Future<void> _accion(Map<String, dynamic> p, String accion) async {
    final idPaquete = _toInt(p['idPaquete']);
    if (idPaquete == null) return;

    final titulo = accion == 'Entregado'
        ? 'Marcar como entregado'
        : accion == 'Devuelto'
        ? 'Marcar como no entregado'
        : 'Registrar intento fallido';

    final resultado = await _EntregaFinalSheet.show(context, titulo: titulo);
    if (resultado == null || !mounted) return;

    setState(() => _actualizando.add(idPaquete));
    final res = await _service.registrarEntregaFinal(
      idPaquete,
      accion: accion,
      novedad: resultado.novedad,
      foto: resultado.foto,
    );
    if (!mounted) return;
    setState(() => _actualizando.remove(idPaquete));

    showAppSnackBar(
      context,
      res['message'] ??
          (res['success'] == true
              ? 'Entrega registrada'
              : 'No se pudo registrar la entrega'),
      severity: res['success'] == true ? 'success' : 'error',
    );
    if (res['success'] == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: TabPendientesHistorial(
            verHistorial: _verHistorial,
            onChanged: _cambiarTab,
          ),
        ),
        Expanded(child: _verHistorial ? _buildHistorial() : _buildPendientes()),
      ],
    );
  }

  Widget _buildPendientes() {
    final grupos = _grupos;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _paquetes.isEmpty
              ? ListView(
                  controller: _scrollController,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.28),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'No hay paquetes en tu sede por entregar al destinatario.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSub),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  controller: _scrollController,
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Mostrar 5 más',
                            style: TextStyle(color: AppColors.textMain),
                          ),
                        ),
                      );
                    }
                    return _buildGrupo(grupos[i]);
                  },
                ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: ScrollToTopButton(controller: _scrollController),
        ),
      ],
    );
  }

  Widget _buildHistorial() {
    final grupos = _gruposHistorial;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadHistorial,
          child: _loadingHistorial
              ? const Center(child: CircularProgressIndicator())
              : _historial.isEmpty
              ? ListView(
                  controller: _scrollControllerHistorial,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.28),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Todavía no has registrado ninguna entrega.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSub),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  controller: _scrollControllerHistorial,
                  padding: const EdgeInsets.all(12),
                  itemCount: grupos.length + (_hayMasHistorial ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == grupos.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: OutlinedButton(
                          onPressed: _mostrarMasHistorial,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Mostrar 5 más',
                            style: TextStyle(color: AppColors.textMain),
                          ),
                        ),
                      );
                    }
                    return _buildGrupoHistorial(grupos[i]);
                  },
                ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: ScrollToTopButton(controller: _scrollControllerHistorial),
        ),
      ],
    );
  }

  Widget _buildGrupo(_GrupoFecha grupo) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 18,
                color: AppColors.adminPrimary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Llegaron el ${grupo.etiqueta}',
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                grupo.paquetes.length == 1
                    ? '1 paquete'
                    : '${grupo.paquetes.length} paquetes',
                style: TextStyle(color: AppColors.textSub, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final p in grupo.paquetes) ...[
            _buildPaqueteCard(p),
            if (p != grupo.paquetes.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildPaqueteCard(Map<String, dynamic> p) {
    final encomienda = p['encomienda'] as Map<String, dynamic>?;
    final destinatario = encomienda?['destinatario'] as Map<String, dynamic>?;
    final nombre = (destinatario?['nombreDestinatario'] as String?) ?? '';
    final direccion = (destinatario?['direccionDestinatario'] as String?) ?? '';
    final telefono = (destinatario?['telefonoDestinatario'] as String?) ?? '';
    final intentos = _toInt(p['intentosEntrega']) ?? 0;
    final idPaquete = _toInt(p['idPaquete']);
    final actualizando = idPaquete != null && _actualizando.contains(idPaquete);

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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    if ((p['descripcionContenido'] as String?)?.isNotEmpty ==
                        true)
                      Text(
                        p['descripcionContenido'] as String,
                        style: TextStyle(
                          color: AppColors.textSub,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _estadoChip('En sede de destino'),
            ],
          ),
          if (nombre.isNotEmpty ||
              direccion.isNotEmpty ||
              telefono.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            if (nombre.isNotEmpty)
              Text(
                nombre,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                  fontSize: 13,
                ),
              ),
            if (direccion.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: AppColors.textSub,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        direccion,
                        style: TextStyle(
                          color: AppColors.textSub,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (telefono.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 15,
                      color: AppColors.textSub,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      telefono,
                      style: TextStyle(color: AppColors.textSub, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
          if (intentos > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.replay_rounded, size: 14, color: AppColors.orange),
                const SizedBox(width: 4),
                Text(
                  intentos == 1
                      ? 'Intentado 1 de $_maxIntentosEntrega veces'
                      : 'Intentado $intentos de $_maxIntentosEntrega veces',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (idPaquete != null) ...[
                  const Spacer(),
                  TapArea(
                    onTap: () => _HistorialEntregaSheet.show(
                      context,
                      service: _service,
                      idPaquete: idPaquete,
                    ),
                    child: Text(
                      'Ver historial',
                      style: TextStyle(
                        color: AppColors.adminPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if ((p['observacionEstado'] as String?)?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                p['observacionEstado'] as String,
                style: TextStyle(
                  color: AppColors.textSub,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if ((p['fotoEntrega'] as String?)?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Builder(
                builder: (ctx) => TapArea(
                  onTap: () =>
                      ImageViewer.show(ctx, [p['fotoEntrega'] as String]),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_camera_outlined,
                        size: 16,
                        color: AppColors.adminPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ver evidencia',
                        style: TextStyle(
                          color: AppColors.adminPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: actualizando
                      ? null
                      : () => _accion(p, 'Entregado'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.green),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: Text(
                    'Entregado',
                    style: TextStyle(color: AppColors.green, fontSize: 12.5),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: actualizando ? null : () => _accion(p, 'Devuelto'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: Text(
                    'No entregado',
                    style: TextStyle(color: AppColors.red, fontSize: 12.5),
                  ),
                ),
              ),
              // El tope de intentos (encomiendaService.MAX_INTENTOS_ENTREGA)
              // solo limita seguir sumando 'Intento' -- "No entregado" (arriba)
              // sigue disponible siempre, decisión explícita de la usuaria para
              // no obligar a fingir intentos cuando ya se sabe que es
              // imposible entregar (ej. dirección inexistente). Ver LOGICA.md,
              // "Tope de intentos de entrega".
              if (intentos < _maxIntentosEntrega) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: actualizando
                        ? null
                        : () => _accion(p, 'Intento'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.orange),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: Text(
                      'Intento (${intentos + 1})',
                      style: TextStyle(color: AppColors.orange, fontSize: 12.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (actualizando)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.adminPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _estadoChip(String estado, {String? label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: estadoPaqueteBg(estado),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label ?? estado,
        style: TextStyle(
          color: estadoPaqueteColor(estado),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGrupoHistorial(_GrupoFecha grupo) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 18,
                color: AppColors.adminPrimary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Cerrados el ${grupo.etiqueta}',
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                grupo.paquetes.length == 1
                    ? '1 paquete'
                    : '${grupo.paquetes.length} paquetes',
                style: TextStyle(color: AppColors.textSub, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final p in grupo.paquetes) ...[
            _buildPaqueteHistorialCard(p),
            if (p != grupo.paquetes.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  // Card de solo lectura -- ya se cerró, no hay acciones que tomar. Muestra el
  // estado final (Entregado/No entregado), la novedad y foto que quedaron
  // guardadas en el paquete (la del cierre, ver LOGICA.md "Evidencia de entrega
  // final obligatoria") y, si tuvo intentos antes de cerrarse, cuántos.
  Widget _buildPaqueteHistorialCard(Map<String, dynamic> p) {
    final encomienda = p['encomienda'] as Map<String, dynamic>?;
    final destinatario = encomienda?['destinatario'] as Map<String, dynamic>?;
    final nombre = (destinatario?['nombreDestinatario'] as String?) ?? '';
    final direccion = (destinatario?['direccionDestinatario'] as String?) ?? '';
    final estado = (p['estado'] as String?) ?? 'Entregado';
    final intentos = _toInt(p['intentosEntrega']) ?? 0;
    final idPaquete = _toInt(p['idPaquete']);

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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    if (nombre.isNotEmpty)
                      Text(
                        nombre,
                        style: TextStyle(
                          color: AppColors.textSub,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _estadoChip(
                estado,
                label: estado == 'Devuelto' ? 'No entregado' : estado,
              ),
            ],
          ),
          if (direccion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: AppColors.textSub,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      direccion,
                      style: TextStyle(color: AppColors.textSub, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          if (intentos > 0 || idPaquete != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (intentos > 0) ...[
                  Icon(Icons.replay_rounded, size: 14, color: AppColors.orange),
                  const SizedBox(width: 4),
                  Text(
                    intentos == 1
                        ? 'Intentado 1 vez antes'
                        : 'Intentado $intentos veces antes',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (idPaquete != null) ...[
                  const Spacer(),
                  TapArea(
                    onTap: () => _HistorialEntregaSheet.show(
                      context,
                      service: _service,
                      idPaquete: idPaquete,
                    ),
                    child: Text(
                      'Ver historial',
                      style: TextStyle(
                        color: AppColors.adminPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if ((p['observacionEstado'] as String?)?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                p['observacionEstado'] as String,
                style: TextStyle(
                  color: AppColors.textSub,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if ((p['fotoEntrega'] as String?)?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Builder(
                builder: (ctx) => TapArea(
                  onTap: () =>
                      ImageViewer.show(ctx, [p['fotoEntrega'] as String]),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_camera_outlined,
                        size: 16,
                        color: AppColors.adminPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ver evidencia',
                        style: TextStyle(
                          color: AppColors.adminPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
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
}

class _GrupoFecha {
  final String etiqueta;
  final List<Map<String, dynamic>> paquetes = [];
  _GrupoFecha(this.etiqueta);
}

// Chip por acción -- mismo criterio de color que la web (ModalHistorialEntrega.jsx,
// CHIP_POR_ACCION): verde Entregado, rojo No entregado, naranja Intento (esta
// última no es un `estado` de Paquete, es solo una acción del distribuidor que
// no lo cambia, por eso no usa estadoPaqueteColor/Bg).
const Map<String, ({String label, Color Function() color, Color Function() bg})>
_chipPorAccion = {
  'Entregado': (label: 'Entregado', color: _colorGreen, bg: _bgGreen),
  'Devuelto': (label: 'No entregado', color: _colorRed, bg: _bgRed),
  'Intento': (label: 'Intento', color: _colorOrange, bg: _bgOrange),
};
Color _colorGreen() => AppColors.green;
Color _bgGreen() => AppColors.greenBg;
Color _colorRed() => AppColors.red;
Color _bgRed() => AppColors.redBg;
Color _colorOrange() => AppColors.orange;
Color _bgOrange() => AppColors.orangeBg;

// Hoja inferior con el historial completo de la entrega final de UN paquete --
// una fila por cada vez que el distribuidor registró algo (Intento/Entregado/
// Devuelto), con su propia novedad/foto/fecha. Mismo endpoint y contenido que
// el modal "Ver historial de entrega" del panel web (ModalHistorialEntrega.jsx)
// -- ver ../../../LOGICA.md, "Historial de entrega final — también en el móvil".
class _HistorialEntregaSheet extends StatefulWidget {
  final PaqueteService service;
  final int idPaquete;
  const _HistorialEntregaSheet({
    required this.service,
    required this.idPaquete,
  });

  static Future<void> show(
    BuildContext context, {
    required PaqueteService service,
    required int idPaquete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _HistorialEntregaSheet(service: service, idPaquete: idPaquete),
    );
  }

  @override
  State<_HistorialEntregaSheet> createState() => _HistorialEntregaSheetState();
}

class _HistorialEntregaSheetState extends State<_HistorialEntregaSheet> {
  bool _loading = true;
  List<dynamic> _historial = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final data = await widget.service.getHistorialEntrega(widget.idPaquete);
    if (mounted) {
      setState(() {
        _historial = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 20,
                    color: AppColors.adminPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Historial de entrega',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _historial.isEmpty
                    ? Center(
                        child: Text(
                          'Todavía no hay ningún registro de entrega para este paquete.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSub),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: _historial.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (_, i) =>
                            _buildFila(_historial[i] as Map<String, dynamic>),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFila(Map<String, dynamic> r) {
    final accion = (r['accion'] as String?) ?? 'Intento';
    final chip = _chipPorAccion[accion];
    final label = chip?.label ?? accion;
    final color = chip?.color() ?? AppColors.textSub;
    final bg = chip?.bg() ?? AppColors.bgGray;
    final distribuidorMap = r['distribuidor'] as Map<String, dynamic>?;
    final distribuidor = distribuidorMap != null
        ? '${distribuidorMap['nombre'] ?? ''} ${distribuidorMap['apellido'] ?? ''}'
              .trim()
        : '—';
    final novedad = (r['novedad'] as String?) ?? '';
    final foto = r['foto'] as String?;

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _fechaHora(r['fecha'] as String?),
                style: TextStyle(color: AppColors.textSub, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            distribuidor,
            style: TextStyle(color: AppColors.textSub, fontSize: 12.5),
          ),
          if (novedad.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                novedad,
                style: TextStyle(color: AppColors.textMain, fontSize: 13.5),
              ),
            ),
          if (foto != null && foto.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Builder(
                builder: (ctx) => TapArea(
                  onTap: () => ImageViewer.show(ctx, [foto]),
                  child: Text(
                    'Ver foto',
                    style: TextStyle(
                      color: AppColors.adminPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EntregaFinalResult {
  final PlatformFile foto;
  final String novedad;
  _EntregaFinalResult(this.foto, this.novedad);
}

// Hoja inferior para la entrega final — foto Y novedad OBLIGATORIAS en las 3
// acciones (Entregado/No entregado/Intento). Antes solo la novedad, y solo para
// No entregado/Intento — ver LOGICA.md, "Evidencia de entrega final obligatoria":
// sin evidencia propia, un "Entregado" se guardaba heredando en silencio la nota/
// foto que el conductor dejó al llegar a la sede (dos pasos del proceso
// mezclados bajo el mismo campo). Exigir siempre evidencia acá elimina ese caso.
class _EntregaFinalSheet extends StatefulWidget {
  final String titulo;
  const _EntregaFinalSheet({required this.titulo});

  static Future<_EntregaFinalResult?> show(
    BuildContext context, {
    required String titulo,
  }) {
    return showModalBottomSheet<_EntregaFinalResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EntregaFinalSheet(titulo: titulo),
    );
  }

  @override
  State<_EntregaFinalSheet> createState() => _EntregaFinalSheetState();
}

class _EntregaFinalSheetState extends State<_EntregaFinalSheet> {
  PlatformFile? _foto;
  String? _errorPeso;
  bool _intentoConfirmar = false;
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
              leading: Icon(
                Icons.photo_camera_outlined,
                color: AppColors.textMain,
              ),
              title: Text(
                'Tomar foto',
                style: TextStyle(color: AppColors.textMain),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library_outlined,
                color: AppColors.textMain,
              ),
              title: Text(
                'Elegir de la galería',
                style: TextStyle(color: AppColors.textMain),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final xfile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (xfile == null || !mounted) return;

    final size = await xfile.length();
    _setFoto(PlatformFile(path: xfile.path, name: xfile.name, size: size));
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    final novedad = _obsCtrl.text.trim();
    final foto = _foto;
    if (novedad.isEmpty || foto == null) {
      setState(() => _intentoConfirmar = true);
      return;
    }
    Navigator.pop(context, _EntregaFinalResult(foto, novedad));
  }

  @override
  Widget build(BuildContext context) {
    final acento = AppColors.adminPrimary;
    final novedadFaltante = _intentoConfirmar && _obsCtrl.text.trim().isEmpty;
    final fotoFaltante = _intentoConfirmar && _foto == null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.titulo,
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Foto y novedad obligatorias.',
              style: TextStyle(color: AppColors.textSub, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TapArea(
              onTap: _pickFoto,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: _foto == null ? 20 : 14,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: fotoFaltante ? AppColors.red : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _foto == null
                          ? Icons.camera_alt_outlined
                          : Icons.check_circle,
                      color: _foto == null
                          ? AppColors.textSub
                          : AppColors.green,
                      size: _foto == null ? 26 : 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _foto == null
                          ? 'Adjuntar foto'
                          : '${_foto!.name} · ${_formatBytes(_foto!.size)}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _foto == null
                            ? AppColors.textSub
                            : AppColors.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_errorPeso != null || fotoFaltante) ...[
              const SizedBox(height: 6),
              Text(
                _errorPeso ?? 'Adjunta una foto de evidencia',
                style: TextStyle(color: AppColors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _obsCtrl,
              maxLines: 2,
              maxLength: _novedadMaxLength,
              onChanged: (_) {
                if (_intentoConfirmar) setState(() {});
              },
              style: TextStyle(color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: 'Novedad',
                hintStyle: TextStyle(color: AppColors.textSub),
                filled: true,
                fillColor: AppColors.bgGray,
                errorText: novedadFaltante ? 'Escribe una novedad' : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: acento, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TapArea(
              onTap: _confirmar,
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
                      fontSize: 16,
                    ),
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
