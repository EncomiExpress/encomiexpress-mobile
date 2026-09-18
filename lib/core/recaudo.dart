import 'models.dart';

// Recaudo (modalidad de pago de la venta) -- lógica pura, sin widgets.
//
// EncomiendaVenta.modalidadRecaudo ∈ {'Pago Inmediato', 'Contraentrega'} viaja en
// GET /paquetes/sede y /paquetes/sede/historial (paquete.encomienda). Solo
// 'Contraentrega' le pide dinero al distribuidor; 'Pago Inmediato' ya se pagó al
// registrar la venta. El cobro se registra solo, en el backend, cuando el
// distribuidor marca 'Entregado' (registrarEntregaFinal deja Paquete.estadoPago =
// 'Pagado'; ver LOGICA.md, "Recaudo por paquete") -- por eso no hay un botón aparte
// de "cobrado".
//
// Montos: la venta guarda un solo total (encomienda.total, el mismo que la guía
// impresa rotula "Valor a cobrar"), pero el distribuidor entrega y cobra por
// paquete -- por eso cada paquete trae su parte (paquete.valorCobro, calculada por
// el backend al registrar la venta; las partes de una guía suman su total). Lo que
// se muestra como "por cobrar" de una guía es la suma de las partes de sus
// paquetes todavía pendientes: baja a medida que se van entregando. Ventas
// anteriores a esa columna no traen valorCobro: ahí se cae al total de la venta.
const String modalidadContraentrega = 'Contraentrega';
const String modalidadPagoInmediato = 'Pago Inmediato';

bool esContraentrega(Map<String, dynamic>? encomienda) =>
    encomienda?['modalidadRecaudo'] == modalidadContraentrega;

// total y valorCobro son DECIMAL(12,2): Sequelize los serializa como String
// ("45000.00"), no como número -- de ahí el parseo tolerante. Nulo o 0 -> sin
// monto que mostrar.
double? aMonto(dynamic valor) {
  final monto = valor is num ? valor.toDouble() : double.tryParse('$valor');
  return monto == null || monto <= 0 ? null : monto;
}

// Total de la venta (guía) completa.
double? totalDeLaGuia(Map<String, dynamic>? encomienda) =>
    aMonto(encomienda?['total']);

// Parte del total que le toca a UN paquete (null si la venta es anterior a
// Paquete.valorCobro).
double? valorDelPaquete(Map<String, dynamic> paquete) =>
    aMonto(paquete['valorCobro']);

// Lo que falta por cobrar de una guía: suma de la parte de cada uno de sus
// paquetes que siguen pendientes. Si alguno no trae su parte, no se puede sumar
// con certeza -> total de la venta, como antes.
double? montoPorCobrar(List<Map<String, dynamic>> paquetes) {
  if (paquetes.isEmpty) return null;
  var suma = 0.0;
  for (final paquete in paquetes) {
    final valor = valorDelPaquete(paquete);
    if (valor == null) {
      return totalDeLaGuia(
        paquetes.first['encomienda'] as Map<String, dynamic>?,
      );
    }
    suma += valor;
  }
  return suma > 0 ? suma : null;
}

String conMonto(String etiqueta, double? monto) =>
    monto == null ? etiqueta : '$etiqueta · ${formatCOP(monto)}';

// Mensaje de cobro de la hoja de confirmación de la entrega final. Solo existe en
// Contraentrega y solo para las acciones que cierran el paquete:
//   - Entregado -> se cobra, y confirmar es lo que deja el cobro registrado.
//   - Devuelto  -> no se cobra nada (el paquete queda cerrado sin cobro).
//   - Intento   -> no toca el estado de pago, no hay nada que avisar.
class AvisoCobro {
  final String texto;
  // true = hay dinero por cobrar; false = solo informa.
  final bool destacado;
  const AvisoCobro(this.texto, {this.destacado = false});
}

// `valorPaquete`: la parte del total que le toca a ESTE paquete -- lo que se cobra
// al entregarlo. Sin ella (venta anterior a Paquete.valorCobro) se cae al total de
// la guía.
AvisoCobro? avisoCobro(
  Map<String, dynamic>? encomienda,
  String accion,
  double? valorPaquete,
) {
  if (!esContraentrega(encomienda)) return null;
  switch (accion) {
    case 'Entregado':
      final total = totalDeLaGuia(encomienda);
      final cobro = valorPaquete != null
          ? 'cobra ${formatCOP(valorPaquete)} por este paquete'
          : total != null
          ? 'cobra ${formatCOP(total)} (total de la guía)'
          : 'cobra al destinatario';
      return AvisoCobro(
        'Contraentrega: $cobro. Al confirmar queda registrado el cobro de este paquete.',
        destacado: true,
      );
    case 'Devuelto':
      return const AvisoCobro(
        'Contraentrega: no se registra ningún cobro para este paquete.',
      );
    default:
      return null;
  }
}
