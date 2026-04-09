import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../widgets/image_viewer.dart';

class AnticipoDetail extends StatelessWidget {
  final Anticipo anticipo;
  final bool isAdmin;

  const AnticipoDetail({
    super.key,
    required this.anticipo,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final gradStart = isAdmin ? AppColors.adminGradStart : AppColors.driverGradStart;
    final gradEnd   = isAdmin ? AppColors.adminGradEnd   : AppColors.driverGradEnd;

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SingleChildScrollView(
        child: Column(
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
                  20, MediaQuery.of(context).padding.top + 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text('Detalle del anticipo',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  EstadoBadge(anticipo.estado),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (isAdmin)
                    SectionCard(
                      child: InfoRow(
                        icon: Icons.person_outline_rounded,
                        iconColor: AppColors.purple,
                        iconBg: AppColors.purpleBg,
                        label: 'Conductor',
                        value: anticipo.conductorNombre,
                      ),
                    ),
                  SectionCard(
                    child: InfoRow(
                      icon: Icons.description_outlined,
                      iconColor: AppColors.purple,
                      iconBg: AppColors.purpleBg,
                      label: 'Tipo de anticipo',
                      value: anticipo.tipo,
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
                              child: const Icon(Icons.attach_money_rounded,
                                  color: AppColors.green, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text('Valores',
                                style: TextStyle(
                                    color: AppColors.textMain,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _valorRow('Anticipo asignado',
                            formatCOP(anticipo.anticipo), AppColors.blue),
                        const Divider(color: AppColors.border, height: 20),
                        _valorRow('Total gastado',
                            formatCOP(anticipo.gastado), AppColors.textMain),
                        const Divider(color: AppColors.border, height: 20),
                        _valorRow('Excedente',
                            formatCOP(anticipo.excedente),
                            anticipo.tieneDeficit ? AppColors.red : AppColors.orange),
                        if (anticipo.excedente != 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: anticipo.tieneDeficit
                                  ? AppColors.redBg
                                  : AppColors.purpleBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              anticipo.tieneDeficit
                                  ? 'Déficit: Gasto superior al anticipo asignado'
                                  : 'Excedente pendiente de devolución',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: anticipo.tieneDeficit
                                    ? AppColors.red
                                    : AppColors.purple,
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
                                  color: isAdmin ? AppColors.purpleBg : AppColors.blueBg,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.calendar_month_outlined,
                                  color: isAdmin ? AppColors.purple : AppColors.blue,
                                  size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text('Fechas importantes',
                                style: TextStyle(
                                    color: AppColors.textMain,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _fechaRow('Fecha de entrega', anticipo.fechaEntrega),
                        const Divider(color: AppColors.border, height: 20),
                        _fechaRow('Fecha de legalización', anticipo.fechaLegalizacion),
                        const Divider(color: AppColors.border, height: 20),
                        _fechaRow('Fecha máxima de legalización', anticipo.fechaMaxima),
                      ],
                    ),
                  ),
                  if (anticipo.soporte != null)
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Soporte adjunto',
                              style: TextStyle(
                                  color: AppColors.textMain,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                          const SizedBox(height: 14),
                          _buildSoporteSection(),
                        ],
                      ),
                    ),
                  if (isAdmin)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.purpleBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.purple.withOpacity(0.2)),
                      ),
                      child: const Text(
                        'Como administrador tienes control total sobre este anticipo. Puedes editarlo usando el botón de editar en la lista.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.purple,
                            fontSize: 13),
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
            style: const TextStyle(
                color: AppColors.textMain, fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _fechaRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSub, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  bool _isImage(String? filename) {
    if (filename == null) return false;
    final ext = filename.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  Future<void> _openFile(String filename) async {
    final url = Uri.parse('http://localhost:3000/uploads/$filename');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Widget _buildSoporteSection() {
    return Container(
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
                color: isAdmin ? AppColors.purpleBg : AppColors.blueBg,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.attach_file,
                color: isAdmin ? AppColors.purple : AppColors.blue,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(anticipo.soporte ?? 'Sin archivo',
                    style: const TextStyle(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                if (anticipo.soporte != null && anticipo.soporte!.isNotEmpty)
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () {
                        if (_isImage(anticipo.soporte)) {
                          final url = 'http://localhost:3000/uploads/${anticipo.soporte}';
                          ImageViewer.show(ctx, [url]);
                        } else {
                          _openFile(anticipo.soporte!);
                        }
                      },
                      child: Text(
                        _isImage(anticipo.soporte) ? 'Tocar para ver imagen' : 'Tocar para abrir archivo',
                        style: const TextStyle(
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
    );
  }
}