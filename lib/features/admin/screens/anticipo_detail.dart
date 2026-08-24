import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models.dart';
import '../../../../core/services/anticipo_service.dart';
import '../../../../core/widgets.dart';
import '../../../../core/image_viewer.dart';

class AnticipoDetail extends StatefulWidget {
  final Anticipo anticipo;
  final bool isAdmin;

  const AnticipoDetail({
    super.key,
    required this.anticipo,
    required this.isAdmin,
  });

  @override
  State<AnticipoDetail> createState() => _AnticipoDetailState();
}

class _AnticipoDetailState extends State<AnticipoDetail> {
  final _anticipoService = AnticipoService();
  late Anticipo _anticipo;
  bool _confirmando = false;

  @override
  void initState() {
    super.initState();
    _anticipo = widget.anticipo;
  }

  Future<void> _confirmarDevolucion() async {
    final esFaltante = _anticipo.tieneDeficit;
    final confirmado = await confirmarDialog(
      context,
      titulo: esFaltante ? 'Confirmar reposición' : 'Confirmar devolución',
      mensaje: esFaltante
          ? '¿Ya le repusiste el faltante al conductor? El anticipo pasará a Completado '
              'y quedará registrada la fecha de hoy.'
          : '¿El conductor devolvió el excedente? El anticipo pasará a Completado '
              'y la fecha de entrega del excedente quedará registrada a la de hoy.',
      textoConfirmar: 'Confirmar',
    );
    if (!confirmado || !mounted) return;

    setState(() => _confirmando = true);
    final result = await _anticipoService.entregarExcedente(_anticipo.id);
    if (!mounted) return;
    setState(() => _confirmando = false);

    if (result['success'] == true) {
      setState(() => _anticipo = result['anticipo'] as Anticipo);
      showAppSnackBar(context, esFaltante ? 'Reposición confirmada' : 'Devolución confirmada');
    } else {
      showAppSnackBar(context, result['message'] ?? (esFaltante ? 'Error al confirmar la reposición' : 'Error al confirmar la devolución'), severity: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.isAdmin ? AppColors.adminPrimary : AppColors.driverPrimary;

    return Scaffold(
        backgroundColor: AppColors.bgGray,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 12, 20, 20),
                child: Row(
                  children: [
                    TapArea(
                      onTap: () => Navigator.pop(context, _anticipo),
                      child: Icon(Icons.arrow_back, color: AppColors.textMain, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text('Detalle del anticipo',
                        style: TextStyle(
                            color: AppColors.textMain,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
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
                              Text('Ruta',
                                  style: TextStyle(color: AppColors.textMain, fontSize: 14)),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(_anticipo.nombreRuta ?? 'Anticipo #${_anticipo.id}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(color: AppColors.textMain, fontSize: 15)),
                              ),
                            ],
                          ),
                          if (_anticipo.destinoTexto != null) ...[
                            Divider(color: AppColors.border, height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Destino',
                                    style: TextStyle(color: AppColors.textMain, fontSize: 14)),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(_anticipo.destinoTexto!,
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
                              Text('Estado',
                                  style: TextStyle(color: AppColors.textMain, fontSize: 14)),
                              EstadoBadge(_anticipo.estado),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.isAdmin && _anticipo.conductorNombre.isNotEmpty)
                      SectionCard(
                        child: InfoRow(
                          icon: Icons.person_outline_rounded,
                          iconColor: AppColors.purple,
                          iconBg: AppColors.purpleBg,
                          label: 'Conductor',
                          value: _anticipo.conductorNombre,
                        ),
                      ),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                    color: AppColors.greenBg,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.attach_money_rounded,
                                    color: AppColors.green, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text('Valores',
                                  style: TextStyle(
                                      color: AppColors.textMain,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _valorRow('Anticipo entregado',
                              formatCOP(_anticipo.valorAnticipo), AppColors.blue),
                          Divider(color: AppColors.border, height: 20),
                          _valorRow(
                              'Total gastado',
                              _anticipo.valorGastado == 0
                                  ? '—'
                                  : '-${formatCOP(_anticipo.valorGastado)}',
                              _anticipo.valorGastado == 0 ? AppColors.textSub : AppColors.orange),
                          Divider(color: AppColors.border, height: 20),
                          _valorRow(
                              'Excedente',
                              _anticipo.valorGastado == 0
                                  ? '—'
                                  : (_anticipo.tieneDeficit
                                      ? formatCOP(_anticipo.excedente)
                                      : '+${formatCOP(_anticipo.excedente)}'),
                              _anticipo.valorGastado == 0
                                  ? AppColors.textSub
                                  : (_anticipo.tieneDeficit ? AppColors.red : AppColors.green)),
                          if (_anticipo.estado == EstadoAnticipo.excedentePendiente) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 14),
                              decoration: BoxDecoration(
                                color: AppColors.purpleBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _anticipo.tieneDeficit
                                    ? 'Saldo pendiente de reponer'
                                    : 'Excedente pendiente de devolución',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.purple,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
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
                          Row(
                            children: [
                              Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                    color: widget.isAdmin ? AppColors.purpleBg : AppColors.blueBg,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.calendar_month_outlined,
                                    color: widget.isAdmin ? AppColors.purple : AppColors.blue,
                                    size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text('Fechas',
                                  style: TextStyle(
                                      color: AppColors.textMain,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _fechaRow('Fecha de entrega', _anticipo.fechaEntrega),
                          Divider(color: AppColors.border, height: 20),
                          _fechaRow('Fecha de legalización', _anticipo.fechaLegalizacion),
                          Divider(color: AppColors.border, height: 20),
                          _fechaRow('Fecha de entrega del excedente', _anticipo.fechaEntregaExcedente),
                        ],
                      ),
                    ),
                    if (_anticipo.soporte.isNotEmpty)
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Soporte adjunto',
                                style: TextStyle(
                                    color: AppColors.textMain,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                            const SizedBox(height: 14),
                            _buildSoporteSection(primary),
                          ],
                        ),
                      ),
                    if (widget.isAdmin && _anticipo.estado == EstadoAnticipo.excedentePendiente)
                      TapArea(
                        onTap: _confirmando ? null : _confirmarDevolucion,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _anticipo.tieneDeficit ? AppColors.red : AppColors.purple,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: _confirmando
                                ? const SizedBox(
                                    height: 20, width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text(
                                    _anticipo.tieneDeficit ? 'Confirmar reposición al conductor' : 'Confirmar devolución de excedente',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _valorRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.textMain, fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _fechaRow(String label, String? iso) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.textSub, fontSize: 12)),
        const SizedBox(height: 4),
        Text(formatFecha(iso),
            style: TextStyle(
                color: AppColors.textMain,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  bool _isImage(String url) {
    final ext = url.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // Las imágenes se agrupan en un solo visor con navegación entre ellas
  // (ImageViewer ya soporta una lista); los archivos no-imagen se abren
  // cada uno aparte con url_launcher.
  Widget _buildSoporteSection(Color primary) {
    final imagenes = _anticipo.soporte.where(_isImage).toList();
    return Column(
      children: _anticipo.soporte.asMap().entries.map((e) {
        final url = e.value;
        final esImagen = _isImage(url);
        return Padding(
          padding: EdgeInsets.only(bottom: e.key == _anticipo.soporte.length - 1 ? 0 : 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: widget.isAdmin ? AppColors.purpleBg : AppColors.blueBg,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.attach_file, color: primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Soporte ${e.key + 1}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: AppColors.textMain,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      Builder(
                        builder: (ctx) => TapArea(
                          onTap: () {
                            if (esImagen) {
                              ImageViewer.show(ctx, imagenes, initialIndex: imagenes.indexOf(url));
                            } else {
                              _openFile(url);
                            }
                          },
                          child: Text(
                              esImagen ? 'Tocar para ver imagen' : 'Tocar para abrir archivo',
                              style: TextStyle(
                                  color: AppColors.blue,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
