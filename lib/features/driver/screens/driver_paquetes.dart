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
// paquetes en la sede del municipio de destino final.
// Legaliza de una sola vez, por sede, con un único botón "Dejar N paquetes en
// sede" — no hay marca por paquete individual. La entrega final al destinatario
// (Entregado/Devuelto) la hace el distribuidor de esa sede desde su propio app.
class DriverPaquetes extends StatefulWidget {
  final UserModel user;
  const DriverPaquetes({super.key, required this.user});

  @override
  State<DriverPaquetes> createState() => _DriverPaquetesState();
}

// Las tres vistas del tab Paquetes -- "Retorno" agregada 2026-09-13 como
// apartado propio entre Pendientes e Historial (antes era una tarjeta fija
// pegada arriba del todo, ocupando espacio de forma permanente; ahora es una
// pestaña más, igual de "a demanda" que las otras dos).
enum _VistaPaquetes { pendientes, retorno, historial }

class _DriverPaquetesState extends State<DriverPaquetes> {
  final _service = PaqueteService();
  bool _loading = true;
  List<dynamic> _paquetes = [];
  int _itemsToShow = 5;
  final _scrollController = ScrollController();

  // "Paquetes de retorno" (Parte B, plan-ventas-regreso-paquetes.md) — solo
  // trae algo cuando la ruta activa del conductor ahora mismo es un regreso
  // "En Ruta". Vacía = nada que confirmar en la pestaña "Retorno" (sin
  // fallback ni historial), tanto si no hay regreso activo como si ya no
  // queda nada por confirmar. idPaquete en _confirmandoRetorno mientras
  // espera la respuesta del backend, para no dejar tocar el botón dos veces.
  List<dynamic> _paquetesRetorno = [];
  final Set<int> _confirmandoRetorno = {};

  // Pendientes / Retorno / Historial -- ver _VistaPaquetes arriba.
  _VistaPaquetes _vista = _VistaPaquetes.pendientes;
  int _itemsToShowHistorial = 5;
  final _scrollControllerHistorial = ScrollController();

  // Clave "idSalida-idDestino" de la sede cuya legalización está en curso — bloquea
  // ese botón mientras se espera la respuesta del backend.
  final Set<String> _sedesActualizando = {};

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
    final retorno = await _service.getParaRetorno();
    if (mounted) {
      setState(() {
        _paquetes = data;
        _paquetesRetorno = retorno;
        _loading = false;
        _itemsToShow = 5;
        _itemsToShowHistorial = 5;
        // La pestaña "Retorno" (ver _mostrarRetorno) puede desaparecer justo
        // acá -- ej. se acaba de confirmar el último pendiente, o la ruta
        // activa dejó de ser un regreso. Si el conductor la estaba viendo, se
        // lo devuelve a "Pendientes" para no quedar parado en una pestaña que
        // ya no está seleccionable en el selector de arriba.
        if (_vista == _VistaPaquetes.retorno && !_mostrarRetorno) {
          _vista = _VistaPaquetes.pendientes;
        }
      });
    }
  }

  Future<void> _confirmarLlegada(int idPaquete, String numeroGuia) async {
    // Corregido 2026-09-13: antes disparaba directo al tocar el botón, sin
    // ningún "¿estás seguro?" — un toque accidental marcaba de una vez algo
    // bastante definitivo (no hay forma de deshacerlo desde acá). Mismo
    // diálogo genérico que ya usa el resto de la app para acciones
    // irreversibles.
    final confirmado = await confirmarDialog(
      context,
      titulo: '¿Confirmar llegada?',
      mensaje:
          'El paquete $numeroGuia quedará marcado como devuelto a Medellín. Esta acción no se puede deshacer.',
      textoConfirmar: 'Llegó a Medellín',
    );
    if (!confirmado || !mounted) return;

    setState(() => _confirmandoRetorno.add(idPaquete));
    final res = await _service.registrarDevolucion(idPaquete);
    if (!mounted) return;
    setState(() => _confirmandoRetorno.remove(idPaquete));

    showAppSnackBar(
      context,
      res['message'] ??
          (res['success'] == true
              ? 'Paquete confirmado de vuelta en Medellín'
              : 'No se pudo confirmar la devolución'),
      severity: res['success'] == true ? 'success' : 'error',
    );
    // Se recarga todo (no solo el paquete tocado): la ruta pudo completarse
    // entre medias, y ahí la sección entera tiene que desaparecer.
    if (res['success'] == true) _load();
  }

  static int? _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

  // "Paquetes de retorno" se divide en dos, corregido 2026-09-13 -- antes
  // `_paquetesRetorno` mezclaba pendientes y ya confirmados en la misma
  // tarjeta fija sobre el toggle Pendientes/Historial, ocupando mucho
  // espacio. Ahora la tarjeta de arriba solo muestra lo pendiente (lo
  // accionable de verdad); lo ya confirmado se ve en Historial (más abajo),
  // como un registro, no como algo que siga pidiendo atención.
  List<dynamic> get _retornoPendientes => _paquetesRetorno
      .where((p) => (p as Map)['estado'] == 'Devuelto')
      .toList();
  List<dynamic> get _retornoConfirmados => _paquetesRetorno
      .where((p) => (p as Map)['estado'] == 'Devuelto a base')
      .toList();

  // La pestaña "Retorno" solo se muestra mientras haya algo pendiente de
  // confirmar (pedido de la usuaria, 2026-09-13): oculta en una ruta de ida
  // (ahí `_paquetesRetorno` ya llega vacío del backend, ver getParaRetorno) y
  // también en un regreso donde ya se confirmó todo -- lo ya confirmado
  // (`_retornoConfirmados`) no alcanza por sí solo para mantenerla visible.
  bool get _mostrarRetorno => _retornoPendientes.isNotEmpty;

  // Pendientes: todavía "Por entregar" (el conductor no lo ha dejado en sede).
  // Historial: cualquier otro estado -- ya está en sede o más adelante, tarea
  // del conductor sobre ese paquete específico ya terminada.
  List<dynamic> get _paquetesPendientes =>
      _paquetes.where((p) => (p as Map)['estado'] == 'Por entregar').toList();
  List<dynamic> get _paquetesHistorial =>
      _paquetes.where((p) => (p as Map)['estado'] != 'Por entregar').toList();

  bool get _hayMas => _itemsToShow < _paquetesPendientes.length;
  bool get _hayMasHistorial =>
      _itemsToShowHistorial < _paquetesHistorial.length;

  void _mostrarMas() {
    if (_hayMas) {
      setState(
        () => _itemsToShow = (_itemsToShow + 5).clamp(
          0,
          _paquetesPendientes.length,
        ),
      );
    }
  }

  void _mostrarMasHistorial() {
    if (_hayMasHistorial) {
      setState(
        () => _itemsToShowHistorial = (_itemsToShowHistorial + 5).clamp(
          0,
          _paquetesHistorial.length,
        ),
      );
    }
  }

  // Agrupa primero por salida (Paquete.asignacion.salida) y, dentro de cada
  // salida, por sede/municipio real de la venta
  // (encomienda.destinatario.destino). "fuente" ya viene filtrada (pendientes
  // o historial) y recortada a lo "revelado".
  List<_GrupoRuta> _agrupar(List<dynamic> fuente) {
    final Map<int, _GrupoRuta> mapa = {};
    for (final p in fuente) {
      final paquete = p as Map<String, dynamic>;
      final asignacion = paquete['asignacion'] as Map<String, dynamic>?;
      final salida = asignacion?['salida'] as Map<String, dynamic>?;
      final idSalida = salida != null ? _toInt(salida['idSalida']) : null;
      final rutaKey = idSalida ?? -1;
      final grupoRuta = mapa.putIfAbsent(
        rutaKey,
        () => _GrupoRuta(idSalida: idSalida, salida: salida),
      );

      final destinatario =
          (paquete['encomienda'] as Map<String, dynamic>?)?['destinatario']
              as Map<String, dynamic>?;
      final destino = destinatario?['destino'] as Map<String, dynamic>?;
      final idDestino = destino != null
          ? _toInt(destino['idDestino'])
          : _toInt(destinatario?['idDestino']);
      final municipio =
          (destino?['municipio'] as String?) ??
          (destino?['departamento'] as String?) ??
          'Sede';
      final direccion = destino?['direccion'] as String?;
      final sedeKey = idDestino ?? -1;
      final grupoSede = grupoRuta.sedes.putIfAbsent(
        sedeKey,
        () => _GrupoSede(
          idDestino: idDestino,
          municipio: municipio,
          direccion: direccion,
        ),
      );
      grupoSede.paquetes.add(paquete);
    }
    return mapa.values.toList();
  }

  List<_GrupoRuta> get _gruposPendientes =>
      _agrupar(_paquetesPendientes.take(_itemsToShow).toList());
  List<_GrupoRuta> get _gruposHistorial =>
      _agrupar(_paquetesHistorial.take(_itemsToShowHistorial).toList());

  Future<void> _dejarEnSede(int? idSalida, _GrupoSede sede) async {
    if (idSalida == null || sede.idDestino == null) return;
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

    final key = '$idSalida-${sede.idDestino}';
    setState(() => _sedesActualizando.add(key));
    final res = await _service.dejarEnSede(
      idSalida: idSalida,
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

  Widget _contenidoActual() {
    switch (_vista) {
      case _VistaPaquetes.pendientes:
        return _buildPendientes();
      case _VistaPaquetes.retorno:
        return _buildRetorno();
      case _VistaPaquetes.historial:
        return _buildHistorial();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: _buildSelectorVista(),
        ),
        Expanded(child: _contenidoActual()),
      ],
    );
  }

  // Selector de 3 vías local a esta pantalla (2026-09-13) -- a propósito NO se
  // extendió el `TabPendientesHistorial` compartido (`core/widgets.dart`) a 3
  // segmentos: ese widget lo usan otras pantallas (Anticipos del conductor y
  // del admin) con solo 2 opciones, y tocarlo las habría afectado a todas.
  Widget _segmentoVista(_VistaPaquetes valor, String label) {
    final activo = _vista == valor;
    return Expanded(
      child: TapArea(
        onTap: () => setState(() => _vista = valor),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: activo ? AppColors.driverPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: activo ? Colors.white : AppColors.textSub,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorVista() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _segmentoVista(_VistaPaquetes.pendientes, 'Pendientes'),
          if (_mostrarRetorno)
            _segmentoVista(_VistaPaquetes.retorno, 'Retorno'),
          _segmentoVista(_VistaPaquetes.historial, 'Historial'),
        ],
      ),
    );
  }

  // "Retorno" -- apartado propio (2026-09-13, pedido de la usuaria): antes era
  // una tarjeta fija pegada arriba del todo, siempre ocupando espacio cuando
  // había algo pendiente. Ahora es una pestaña más, igual que
  // Pendientes/Historial -- con su propio estado vacío en vez de aparecer y
  // desaparecer de la pantalla.
  Widget _buildRetorno() {
    final pendientes = _retornoPendientes;
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : pendientes.isEmpty
          ? ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'No hay paquetes de retorno pendientes',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSub),
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: pendientes.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'No entregados que este convoy trae de vuelta a Medellín',
                      style: TextStyle(color: AppColors.textSub, fontSize: 12),
                    ),
                  );
                }
                final p = pendientes[i - 1] as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildRetornoItem(p),
                );
              },
            ),
    );
  }

  // Sección chica dentro de Historial para lo ya confirmado -- corregido
  // 2026-09-13: antes se quedaba mezclado con lo pendiente en la tarjeta de
  // arriba; ahora, una vez resuelto, se ve acá como registro, sin seguir
  // ocupando espacio en la vista principal.
  Widget _buildRetornoConfirmadosSection() {
    final confirmados = _retornoConfirmados;
    if (confirmados.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_return_outlined,
                  size: 18,
                  color: AppColors.textSub,
                ),
                const SizedBox(width: 6),
                Text(
                  'Paquetes de retorno confirmados',
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final p in confirmados) ...[
              _buildRetornoItem(p as Map<String, dynamic>),
              if (p != confirmados.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRetornoItem(Map<String, dynamic> p) {
    final idPaquete = _toInt(p['idPaquete']);
    final encomienda = p['encomienda'] as Map<String, dynamic>?;
    // numeroGuia es de la venta dueña (P12), no del paquete.
    final numeroGuia = (encomienda?['numeroGuia'] as String?) ?? '—';
    final destinatario = encomienda?['destinatario'] as Map<String, dynamic>?;
    // El paquete ya va de vuelta en Medellín -- lo que le interesa al
    // conductor es el CLIENTE (quien lo envió, a quien se le resuelve acá),
    // no el destinatario original del municipio donde no se pudo entregar.
    // Corregido 2026-09-13.
    final cliente = encomienda?['cliente'] as Map<String, dynamic>?;
    final nombreCliente =
        '${cliente?['nombre'] ?? ''} ${cliente?['apellido'] ?? ''}'.trim();
    final nombreMostrado = nombreCliente.isNotEmpty ? nombreCliente : '—';
    // Municipio donde quedó varado el paquete (destino original de la venta)
    // -- corregido 2026-09-13: antes no se mostraba.
    final destino = destinatario?['destino'] as Map<String, dynamic>?;
    final municipio = destino?['municipio'] as String?;
    final intentos = _toInt(p['intentosEntrega']) ?? 0;
    final yaConfirmado = (p['estado'] as String?) == 'Devuelto a base';
    final conductorDevolucion =
        p['conductorDevolucion'] as Map<String, dynamic>?;
    final usuarioDevolucion =
        conductorDevolucion?['usuario'] as Map<String, dynamic>?;
    final nombreConfirmo = usuarioDevolucion != null
        ? '${usuarioDevolucion['nombre'] ?? ''} ${usuarioDevolucion['apellido'] ?? ''}'
              .trim()
        : null;
    final confirmando =
        idPaquete != null && _confirmandoRetorno.contains(idPaquete);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  numeroGuia,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                if (municipio != null && municipio.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_city_outlined,
                        size: 13,
                        color: AppColors.textSub,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        municipio,
                        style: TextStyle(
                          color: AppColors.textSub,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                Text(
                  nombreMostrado,
                  style: TextStyle(color: AppColors.textSub, fontSize: 13),
                ),
                if (intentos > 0)
                  Text(
                    intentos == 1 ? '1 intento' : '$intentos intentos',
                    style: TextStyle(color: AppColors.textSub, fontSize: 11.5),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (yaConfirmado)
            Flexible(
              child: Text(
                nombreConfirmo != null && nombreConfirmo.isNotEmpty
                    ? 'Ya confirmado por $nombreConfirmo'
                    : 'Ya confirmado',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: (confirmando || idPaquete == null)
                  ? null
                  : () => _confirmarLlegada(idPaquete, numeroGuia),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.driverPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: confirmando
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.driverPrimary,
                      ),
                    )
                  : Text(
                      'Llegó a Medellín',
                      style: TextStyle(
                        color: AppColors.driverPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildPendientes() {
    final grupos = _gruposPendientes;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _paquetesPendientes.isEmpty
              ? ListView(
                  controller: _scrollController,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    Center(
                      child: Text(
                        'No hay paquetes pendientes por dejar en sede',
                        style: TextStyle(color: AppColors.textSub),
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
    // "Paquetes de retorno confirmados" (2026-09-13) va SIEMPRE arriba de
    // Historial, en su propia sección -- fuera del ListView de abajo, para no
    // mezclarse con los grupos por ruta/sede (son conceptos distintos: uno es
    // "lo que este conductor dejó en sede", el otro "lo que confirmó de
    // regreso").
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: Column(
            children: [
              _buildRetornoConfirmadosSection(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _paquetesHistorial.isEmpty
                    ? ListView(
                        controller: _scrollControllerHistorial,
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3,
                          ),
                          Center(
                            child: Text(
                              'Todavía no has dejado ningún paquete en sede',
                              style: TextStyle(color: AppColors.textSub),
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
                          return _buildGrupo(grupos[i]);
                        },
                      ),
              ),
            ],
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

  Widget _buildGrupo(_GrupoRuta grupo) {
    final salida = grupo.salida;
    final destino =
        (salida?['ruta'] as Map<String, dynamic>?)?['destino']
            as Map<String, dynamic>?;
    final destinoMunicipio = destino?['municipio'] as String?;
    final rutaLabel = salida != null
        ? ((salida['origen'] as String?)?.isNotEmpty == true
              ? '${salida['origen']}${(destinoMunicipio?.isNotEmpty ?? false) ? ' - $destinoMunicipio' : ''}'
              : 'Ruta #${grupo.idSalida ?? '—'}')
        : 'Ruta desconocida';
    // horaSalida llega como "HH:mm:ss" (24h) del backend -- se muestra en 12h con
    // AM/PM, igual que en el listado de Rutas del panel web (formatHora12()).
    final horaSalida = _formatHora12(salida?['horaSalida'] as String?) ?? '';
    final detalle = salida != null
        ? '${salida['fechaSalida'] ?? '—'} $horaSalida'.trim()
        : '';
    // El conductor solo puede legalizar mientras la salida está "En Ruta" —
    // antes de eso no ha salido de bodega (misma validación en el backend,
    // encomiendaService.dejarPaquetesEnSede).
    final rutaEnRuta = salida != null && salida['estado'] == 'En Ruta';

    // Rutas directas: esta salida entrega en un solo municipio, así que basta con
    // saber si ya se dejaron todos sus paquetes en la sede o todavía falta algo.
    final sedes = grupo.sedes.values.toList();
    final entregaCompletada = sedes.every(
      (s) =>
          s.paquetes.every((p) => (p['estado'] as String?) != 'Por entregar'),
    );

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
                        fontSize: 16,
                      ),
                    ),
                    if (detalle.isNotEmpty)
                      Text(
                        detalle,
                        style: TextStyle(
                          color: AppColors.textSub,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (!rutaEnRuta)
                Text(
                  'La ruta aún no ha salido',
                  style: TextStyle(
                    color: AppColors.textSub,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Text(
                  entregaCompletada
                      ? 'Entregado en sede'
                      : 'Pendiente de entregar',
                  style: TextStyle(
                    color: entregaCompletada
                        ? AppColors.green
                        : AppColors.textSub,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (final sede in sedes) ...[
            const SizedBox(height: 8),
            _buildSede(grupo.idSalida, sede, rutaEnRuta),
          ],
        ],
      ),
    );
  }

  Widget _buildSede(int? idSalida, _GrupoSede sede, bool rutaEnRuta) {
    final pendientes = sede.paquetes
        .where((p) => (p['estado'] as String?) == 'Por entregar')
        .toList();
    final completada = pendientes.isEmpty;
    final key = '$idSalida-${sede.idDestino}';
    final actualizando = _sedesActualizando.contains(key);
    final gruposGuia = _agruparPorGuia(sede.paquetes);

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
              Icon(
                Icons.location_city_outlined,
                size: 16,
                color: AppColors.textSub,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sede.municipio,
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                completada
                    ? '${sede.paquetes.length} en sede'
                    : '${pendientes.length} por dejar',
                style: TextStyle(
                  color: completada ? AppColors.green : AppColors.textSub,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
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
          for (final grupo in gruposGuia) ...[
            _buildGuiaGroup(grupo),
            if (grupo != gruposGuia.last) const SizedBox(height: 8),
          ],
          if (rutaEnRuta && !completada) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: actualizando
                    ? null
                    : () => _dejarEnSede(idSalida, sede),
                icon: actualizando
                    ? SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.driverPrimary,
                        ),
                      )
                    : Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: AppColors.driverPrimary,
                      ),
                label: Text(
                  pendientes.length == 1
                      ? 'Dejar 1 paquete en la sede'
                      : 'Dejar ${pendientes.length} paquetes en la sede',
                  style: TextStyle(
                    color: AppColors.driverPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.driverPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Un solo numeroGuia por venta (P12) — esta tarjeta agrupa todos los paquetes
  // de esa venta bajo su guía (identificador principal visible) y el
  // destinatario (mismo para todos, es un dato de la venta, no del paquete) se
  // muestra una sola vez. Cada paquete dentro es un ítem secundario,
  // distinguido por su contenido/estado -- ya no tiene guía propia.
  Widget _buildGuiaGroup(_GrupoVenta grupo) {
    final primero = grupo.paquetes.first;
    final destinatario =
        (primero['encomienda'] as Map<String, dynamic>?)?['destinatario']
            as Map<String, dynamic>?;
    final nombreDestinatario =
        (destinatario?['nombreDestinatario'] as String?) ?? '';
    final direccionDestinatario =
        (destinatario?['direccionDestinatario'] as String?) ?? '';
    final telefonoDestinatario =
        (destinatario?['telefonoDestinatario'] as String?) ?? '';

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
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 15,
                color: AppColors.textSub,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  grupo.numeroGuia,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              if (grupo.paquetes.length > 1)
                Text(
                  '${grupo.paquetes.length} paquetes',
                  style: TextStyle(color: AppColors.textSub, fontSize: 11.5),
                ),
            ],
          ),
          if (nombreDestinatario.isNotEmpty ||
              direccionDestinatario.isNotEmpty ||
              telefonoDestinatario.isNotEmpty) ...[
            const SizedBox(height: 6),
            if (nombreDestinatario.isNotEmpty)
              Text(
                nombreDestinatario,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                  fontSize: 13,
                ),
              ),
            if (direccionDestinatario.isNotEmpty)
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
                        direccionDestinatario,
                        style: TextStyle(
                          color: AppColors.textSub,
                          fontSize: 13,
                        ),
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
                    Icon(
                      Icons.phone_outlined,
                      size: 15,
                      color: AppColors.textSub,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      telefonoDestinatario,
                      style: TextStyle(color: AppColors.textSub, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 8),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          for (final p in grupo.paquetes) ...[
            _buildPaqueteItem(p),
            if (p != grupo.paquetes.last) ...[
              const SizedBox(height: 8),
              Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  // Ítem secundario de UN paquete dentro de su guía -- se distingue por
  // contenido/estado, ya no por un numeroGuia propio (P12).
  Widget _buildPaqueteItem(Map<String, dynamic> p) {
    final estado = (p['estado'] as String?) ?? 'Por entregar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                (p['descripcionContenido'] as String?)?.isNotEmpty == true
                    ? p['descripcionContenido'] as String
                    : 'Sin descripción',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                  fontSize: 13,
                ),
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
        // Mientras sigue "En sede de destino", el conductor puede volver a
        // consultar la novedad y la foto que él mismo dejó al legalizar la
        // sede (el backend ya no le deja cambiarlo). Una vez el distribuidor
        // hace la entrega final (Entregado/Devuelto), esos MISMOS campos
        // (observacionEstado/fotoEntrega) pasan a ser la novedad y evidencia
        // que dejó el distribuidor al entregar -- ya no son del conductor, así
        // que dejan de mostrarse acá.
        if (estado == 'En sede de destino') ...[
          if ((p['observacionEstado'] as String?)?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
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
              padding: const EdgeInsets.only(top: 4),
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
                        color: AppColors.driverPrimary,
                      ),
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
            ),
        ],
      ],
    );
  }

  Widget _estadoChip(String estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: estadoPaqueteBg(estado),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: estadoPaqueteColor(estado),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GrupoRuta {
  final int? idSalida;
  final Map<String, dynamic>? salida;
  final Map<int, _GrupoSede> sedes = {};
  _GrupoRuta({required this.idSalida, required this.salida});
}

class _GrupoSede {
  final int? idDestino;
  final String municipio;
  final String? direccion;
  final List<Map<String, dynamic>> paquetes = [];
  _GrupoSede({
    required this.idDestino,
    required this.municipio,
    this.direccion,
  });
}

// Un solo numeroGuia por venta (P12) — agrupa los paquetes de una misma sede
// por la venta (encomienda) dueña, para mostrar la guía una sola vez con sus
// paquetes como ítems secundarios debajo (ver _buildGuiaGroup).
class _GrupoVenta {
  final int? idEncomiendaVenta;
  final String numeroGuia;
  final List<Map<String, dynamic>> paquetes = [];
  _GrupoVenta({required this.idEncomiendaVenta, required this.numeroGuia});
}

List<_GrupoVenta> _agruparPorGuia(List<Map<String, dynamic>> paquetes) {
  final Map<int, _GrupoVenta> mapa = {};
  final sinVenta = <Map<String, dynamic>>[];
  for (final p in paquetes) {
    final encomienda = p['encomienda'] as Map<String, dynamic>?;
    final idEncomiendaVenta = _DriverPaquetesState._toInt(
      encomienda?['idEncomiendaVenta'],
    );
    if (idEncomiendaVenta == null) {
      sinVenta.add(p);
      continue;
    }
    final grupo = mapa.putIfAbsent(
      idEncomiendaVenta,
      () => _GrupoVenta(
        idEncomiendaVenta: idEncomiendaVenta,
        numeroGuia: (encomienda?['numeroGuia'] as String?) ?? '—',
      ),
    );
    grupo.paquetes.add(p);
  }
  final resultado = mapa.values.toList();
  if (sinVenta.isNotEmpty) {
    final suelto = _GrupoVenta(idEncomiendaVenta: null, numeroGuia: '—');
    suelto.paquetes.addAll(sinVenta);
    resultado.add(suelto);
  }
  return resultado;
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

  static Future<_DejarEnSedeResult?> show(
    BuildContext context, {
    required String municipio,
    required int cantidad,
  }) {
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

  @override
  Widget build(BuildContext context) {
    final acento = AppColors.driverPrimary;

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
              'Dejar en sede — ${widget.municipio}',
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.cantidad == 1
                  ? 'Se marcará 1 paquete como dejado en la sede'
                  : 'Se marcarán ${widget.cantidad} paquetes como dejados en la sede',
              style: TextStyle(color: AppColors.textSub, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              'Foto y novedades son opcionales',
              style: TextStyle(color: AppColors.textSub, fontSize: 11.5),
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
                  border: Border.all(color: AppColors.border, width: 1.5),
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
                          ? 'Adjuntar foto (opcional)'
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
            if (_errorPeso != null) ...[
              const SizedBox(height: 6),
              Text(
                _errorPeso!,
                style: TextStyle(color: AppColors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _obsCtrl,
              maxLines: 2,
              maxLength: _novedadMaxLength,
              style: TextStyle(color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: 'Novedades (opcional)',
                hintStyle: TextStyle(color: AppColors.textSub),
                filled: true,
                fillColor: AppColors.bgGray,
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
              onTap: () => Navigator.pop(
                context,
                _DejarEnSedeResult(_foto, _obsCtrl.text.trim()),
              ),
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
