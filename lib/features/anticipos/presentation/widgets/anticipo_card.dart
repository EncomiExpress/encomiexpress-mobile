import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/anticipo.dart';

class AnticipoCard extends StatelessWidget {
  final Anticipo anticipo;
  final bool isAdmin;
  final VoidCallback? onVer;
  final VoidCallback? onEditar;
  final VoidCallback? onAprobar;
  final VoidCallback? onRechazar;

  const AnticipoCard({
    super.key,
    required this.anticipo,
    this.isAdmin = false,
    this.onVer,
    this.onEditar,
    this.onAprobar,
    this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onVer,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    anticipo.tipo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildEstadoBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Conductor: ${anticipo.conductorNombre}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn('Anticipo', formatCOP(anticipo.anticipo)),
                  _buildInfoColumn('Gastado', formatCOP(anticipo.gastado)),
                  _buildInfoColumn('Excedente', formatCOP(anticipo.excedente),
                      isNegative: anticipo.tieneDeficit),
                ],
              ),
              if (isAdmin) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    if (onVer != null)
                      _buildActionButton(
                          context, 'Ver', Icons.visibility, onVer!),
                    if (onEditar != null)
                      _buildActionButton(
                          context, 'Editar', Icons.edit, onEditar!),
                    if (anticipo.estado == 'Pendiente') ...[
                      if (onAprobar != null)
                        _buildActionButton(
                            context, 'Aprobar', Icons.check_circle, onAprobar!,
                            color: Colors.green),
                      if (onRechazar != null)
                        _buildActionButton(
                            context, 'Rechazar', Icons.cancel, onRechazar!,
                            color: Colors.red),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge() {
    Color bgColor;
    Color textColor;
    switch (anticipo.estado) {
      case 'Activo':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF22C55E);
        break;
      case 'Pendiente':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFF59E0B);
        break;
      case 'Pagado':
        bgColor = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF3B82F6);
        break;
      case 'Rechazado':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFEF4444);
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        anticipo.estado,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {bool isNegative = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isNegative ? Colors.red : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, String label, IconData icon, VoidCallback onTap,
      {Color? color}) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(label,
            style: TextStyle(fontSize: 12, color: color ?? Colors.grey[700])),
      ),
    );
  }
}