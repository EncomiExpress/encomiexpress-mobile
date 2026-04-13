import 'package:flutter/material.dart';
import 'models.dart';

class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color gradStart;
  final Color gradEnd;
  final Widget? trailing;
  final bool showBack;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.gradStart,
    required this.gradEnd,
    this.trailing,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradStart, gradEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 20),
      child: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EstadoBadge extends StatelessWidget {
  final String estado;
  const EstadoBadge(this.estado, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: estadoBg(estado),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(estado,
          style: TextStyle(
              color: estadoColor(estado),
              fontSize: 12,
              fontWeight: FontWeight.w600))
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.textSub,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  color: iconColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSub, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const SectionCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}

class AnticipoCard extends StatelessWidget {
  final Anticipo anticipo;
  final bool isAdmin;
  final VoidCallback onVer;
  final VoidCallback onEditar;
  final VoidCallback? onAprobar;
  final VoidCallback? onRechazar;

  const AnticipoCard({
    super.key,
    required this.anticipo,
    required this.isAdmin,
    required this.onVer,
    required this.onEditar,
    this.onAprobar,
    this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final isPendiente = anticipo.estado == 'Pendiente';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EstadoBadge(anticipo.estado),
                    const Spacer(),
                    IconButton(
                      onPressed: onVer,
                      icon: const Icon(Icons.remove_red_eye_outlined,
                          color: AppColors.blue, size: 20),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                    IconButton(
                      onPressed: onEditar,
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.textSub, size: 20),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(anticipo.tipo,
                    style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                Text('Conductor: ${anticipo.conductorNombre}',
                    style: const TextStyle(
                        color: AppColors.textSub, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _val('Anticipo', formatCOP(anticipo.anticipo),
                        AppColors.blue),
                    _val('Gastado', formatCOP(anticipo.gastado),
                        AppColors.textMain),
                    _val('Excedente', formatCOP(anticipo.excedente),
                        anticipo.tieneDeficit
                            ? AppColors.red
                            : AppColors.orange),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Entrega: ${anticipo.fechaEntrega}',
                        style: const TextStyle(
                            color: AppColors.textSub, fontSize: 11)),
                    const Spacer(),
                    Text('Legalización: ${anticipo.fechaLegalizacion}',
                        style: const TextStyle(
                            color: AppColors.textSub, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          if (isAdmin && isPendiente) ...[
            const Divider(height: 1, color: AppColors.border),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onAprobar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Aprobar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: onRechazar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Rechazar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _val(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSub, fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}