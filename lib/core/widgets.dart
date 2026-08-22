import 'dart:async';
import 'package:flutter/material.dart';
import 'models.dart';
import 'theme/theme_controller.dart';

// Mismo look que los <Alert severity="..."> de MUI en el web (ToastContext.jsx):
// fondo suave del color de la severidad, ícono + texto del mismo color,
// esquinas redondeadas y flotante — no la barra sólida por defecto de Flutter.
void showAppSnackBar(
  BuildContext context,
  String message, {
  String severity = 'success',
}) {
  late final Color color;
  late final Color bg;
  late final IconData icon;
  switch (severity) {
    case 'error':
      color = AppColors.red;
      bg = AppColors.redBg;
      icon = Icons.error_outline;
      break;
    case 'warning':
      color = AppColors.orange;
      bg = AppColors.orangeBg;
      icon = Icons.warning_amber_outlined;
      break;
    case 'info':
      color = AppColors.blue;
      bg = AppColors.blueBg;
      icon = Icons.info_outline;
      break;
    default:
      color = AppColors.green;
      bg = AppColors.greenBg;
      icon = Icons.check_circle_outline;
  }

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: color,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

// Diálogo genérico de "¿estás seguro?" para acciones irreversibles — mismo
// propósito que el modal de confirmar devolución en ListarAnticipoExcedente.jsx
// (web), que hoy es la única acción de este tipo en la app.
Future<bool> confirmarDialog(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String textoConfirmar = 'Confirmar',
  Color? colorConfirmar,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        titulo,
        style: TextStyle(
          color: AppColors.textMain,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
      content: Text(
        mensaje,
        style: TextStyle(color: AppColors.textSub, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: AppColors.textSub,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: colorConfirmar ?? AppColors.purple,
          ),
          child: Text(
            textoConfirmar,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}

// Mismo estilo del buscador de los listados en el web (ej. ListarConductor.jsx):
// borderRadius bien redondeado (16) y, al enfocar, el mismo halo (boxShadow
// con activeBg) que ya usa el login — no un borde más grueso.
class SearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final double borderRadius;

  const SearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.borderRadius = 16,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _focusNode.hasFocus;
    final radius = BorderRadius.circular(widget.borderRadius);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: AppColors.activeBg,
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : [],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: radius,
          border: Border.all(
            color: hasFocus ? AppColors.adminPrimary : AppColors.border,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          cursorColor: AppColors.textMain,
          style: TextStyle(color: AppColors.textMain, fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: AppColors.textSub, fontSize: 14),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.textSub,
              size: 20,
            ),
            suffixIcon: widget.controller.text.isEmpty
                ? null
                : TapArea(
                    onTap: () => widget.controller.clear(),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSub,
                    ),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

// Mismo estilo del Select "Estado" en los listados del web (ej.
// ListarConductor.jsx): redondeado, halo al enfocar, y el placeholder
// (ej. "Estado") se muestra DENTRO del selector cuando no hay nada elegido
// — no como un label aparte arriba del campo.
class FilterSelect extends StatefulWidget {
  final String label;
  final String value; // == label -> "sin filtro", se muestra el placeholder
  final List<String> items;
  final ValueChanged<String> onChanged;
  // Por default el menú cuelga con el borde derecho pegado al del chip (se
  // "abre hacia la izquierda") — es lo correcto cuando el chip está pegado al
  // borde derecho de la pantalla, como el filtro único del conductor. Cuando
  // hay varios chips en fila (admin) y este no es el último, conviene que
  // cuelgue del borde izquierdo en vez de invadir los chips de al lado.
  final bool alignLeft;

  const FilterSelect({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.alignLeft = false,
  });

  @override
  State<FilterSelect> createState() => _FilterSelectState();
}

class _FilterSelectState extends State<FilterSelect> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _open = false;

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _open = false);
  }

  void _toggleMenu() {
    if (_overlayEntry != null) {
      _closeMenu();
      return;
    }
    final renderBox = context.findRenderObject() as RenderBox;
    final width = renderBox.size.width;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Barrera invisible: cualquier click fuera del menú lo cierra
          // al instante, sin la animación de cierre que trae el
          // DropdownButton nativo de Flutter.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeMenu,
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: widget.alignLeft
                ? Alignment.bottomLeft
                : Alignment.bottomRight,
            followerAnchor: widget.alignLeft
                ? Alignment.topLeft
                : Alignment.topRight,
            offset: const Offset(0, 6),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.cardBg,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: width),
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.items.map((e) {
                      final selected = e == widget.value;
                      final text = e == widget.label ? 'Todos' : e;
                      return InkWell(
                        onTap: () {
                          widget.onChanged(e);
                          _closeMenu();
                        },
                        hoverColor: AppColors.activeBg,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                text,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMain,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                              if (selected)
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: AppColors.adminPrimary,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _open = true);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != widget.label;
    final radius = BorderRadius.circular(16);

    return CompositedTransformTarget(
      link: _layerLink,
      child: TapArea(
        onTap: _toggleMenu,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: _open
                ? [
                    BoxShadow(
                      color: AppColors.activeBg,
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : [],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: radius,
              border: Border.all(
                color: _open ? AppColors.adminPrimary : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasValue ? widget.value : widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: hasValue ? AppColors.textMain : AppColors.textSub,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _open
                      ? Icons.keyboard_arrow_up_outlined
                      : Icons.keyboard_arrow_down_outlined,
                  color: AppColors.textSub,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Puerto de PaletaAnimada (Header.jsx, frontend web): el mismo trazo SVG del
// ícono de paleta (24x24) con 4 puntos que se "apagan" en cascada y se
// vuelven a encender — no es un ícono de librería, se dibuja a mano igual
// que en el web para poder animar los puntos por separado.
class AnimatedPaletteIcon extends StatefulWidget {
  final Color color;
  final double size;
  final VoidCallback? onTap;

  const AnimatedPaletteIcon({
    super.key,
    required this.color,
    this.size = 22,
    this.onTap,
  });

  @override
  State<AnimatedPaletteIcon> createState() => _AnimatedPaletteIconState();
}

class _AnimatedPaletteIconState extends State<AnimatedPaletteIcon> {
  static const _paso = Duration(milliseconds: 90);
  static const _trans = Duration(milliseconds: 120);

  List<bool> _ocultos = [false, false, false, false];
  bool _animando = false;
  final List<Timer> _timers = [];

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _schedule(List<bool> valores, Duration delay) {
    _timers.add(
      Timer(delay, () {
        if (mounted) setState(() => _ocultos = valores);
      }),
    );
  }

  void _animar() {
    if (_animando) return;
    _animando = true;

    _schedule([false, false, false, true], Duration.zero);
    _schedule([false, false, true, true], _paso);
    _schedule([false, true, true, true], _paso * 2);
    _schedule([true, true, true, true], _paso * 3);

    final inicio = _paso * 3 + _trans + const Duration(milliseconds: 60);
    _schedule([false, true, true, true], inicio);
    _schedule([false, false, true, true], inicio + _paso);
    _schedule([false, false, false, true], inicio + _paso * 2);
    _schedule([false, false, false, false], inicio + _paso * 3);
    _timers.add(
      Timer(inicio + _paso * 3 + _trans + const Duration(milliseconds: 80), () {
        _animando = false;
      }),
    );
  }

  // Mismas coordenadas que PUNTOS_PALETA en Header.jsx (viewBox 24x24).
  static const _puntos = [
    Offset(6.5, 10.5),
    Offset(9.5, 6.5),
    Offset(14.5, 6.5),
    Offset(17.5, 10.5),
  ];

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _animar(),
      child: TapArea(
        onTap: () {
          _animar();
          widget.onTap?.call();
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _PalettePainter(
              color: widget.color,
              ocultos: _ocultos,
              puntos: _puntos,
            ),
          ),
        ),
      ),
    );
  }
}

class _PalettePainter extends CustomPainter {
  final Color color;
  final List<bool> ocultos;
  final List<Offset> puntos;

  _PalettePainter({
    required this.color,
    required this.ocultos,
    required this.puntos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);

    // Mismo trazo `d` del <path> de PaletaAnimada — el contorno de la paleta.
    final outline = Path()
      ..moveTo(12, 3)
      ..cubicTo(7.03, 3, 3, 7.03, 3, 12)
      ..cubicTo(3, 16.97, 7.03, 21, 12, 21)
      ..cubicTo(12.83, 21, 13.5, 20.33, 13.5, 19.5)
      ..cubicTo(13.5, 19.11, 13.35, 18.76, 13.11, 18.49)
      ..cubicTo(12.88, 18.23, 12.73, 17.88, 12.73, 17.5)
      ..cubicTo(12.73, 16.67, 13.4, 16.0, 14.23, 16.0)
      ..lineTo(16, 16.0)
      ..cubicTo(18.76, 16, 21, 13.76, 21, 11)
      ..cubicTo(21, 6.58, 16.97, 3, 12, 3)
      ..close();

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(outline, strokePaint);

    final dotPaint = Paint()..color = color;
    for (var i = 0; i < puntos.length; i++) {
      if (ocultos[i]) continue;
      canvas.drawCircle(puntos[i], 1.5, dotPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PalettePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.ocultos != ocultos;
}

// Igual que el Avatar de Header.jsx (frontend web): hasta 2 iniciales del
// nombre, círculo del color primario activo, texto blanco.
class UserAvatar extends StatelessWidget {
  final String nombre;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const UserAvatar({
    super.key,
    required this.nombre,
    this.size = 33,
    this.backgroundColor,
    this.textColor,
  });

  String get _iniciales {
    final trimmed = nombre.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed
        .split(RegExp(r'\s+'))
        .take(2)
        .map((n) => n[0])
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.adminPrimary,
      ),
      alignment: Alignment.center,
      child: Text(
        _iniciales,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: size * 0.36,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// Envuelve GestureDetector con el cursor de mano en desktop/web — un
// GestureDetector normal no cambia el cursor al pasar el mouse por encima,
// a diferencia de los widgets Material (ElevatedButton, InkWell, etc).
// Reemplazo directo de GestureDetector para cualquier "botón" custom de la app.
class TapArea extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final HitTestBehavior? behavior;

  const TapArea({
    super.key,
    required this.onTap,
    required this.child,
    this.behavior,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(onTap: onTap, behavior: behavior, child: child),
    );
  }
}

// Puerto de las figuras hexagonales decorativas del fondo de Login.jsx
// (frontend web) — mismos 3 polígonos que el SVG original, sobre un
// viewBox de 300x300 que se escala al tamaño pedido.
class HexagonCluster extends StatelessWidget {
  final double size;
  final Color fillTop;
  final Color fillLeft;
  final Color fillRight;
  final Color stroke;

  const HexagonCluster({
    super.key,
    required this.size,
    required this.fillTop,
    required this.fillLeft,
    required this.fillRight,
    required this.stroke,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HexagonPainter(
        fillTop: fillTop,
        fillLeft: fillLeft,
        fillRight: fillRight,
        stroke: stroke,
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color fillTop;
  final Color fillLeft;
  final Color fillRight;
  final Color stroke;

  _HexagonPainter({
    required this.fillTop,
    required this.fillLeft,
    required this.fillRight,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 300;
    Offset p(double x, double y) => Offset(x * scale, y * scale);

    final top = Path()
      ..addPolygon([p(150, 20), p(280, 90), p(150, 160), p(20, 90)], true);
    final left = Path()
      ..addPolygon([p(20, 90), p(150, 160), p(150, 280), p(20, 210)], true);
    final right = Path()
      ..addPolygon([p(280, 90), p(150, 160), p(150, 280), p(280, 210)], true);

    canvas.drawPath(top, Paint()..color = fillTop);
    canvas.drawPath(left, Paint()..color = fillLeft);
    canvas.drawPath(right, Paint()..color = fillRight);

    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(top, strokePaint);
    canvas.drawPath(left, strokePaint);
    canvas.drawPath(right, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _HexagonPainter oldDelegate) =>
      oldDelegate.fillTop != fillTop ||
      oldDelegate.fillLeft != fillLeft ||
      oldDelegate.fillRight != fillRight ||
      oldDelegate.stroke != stroke;
}

// Equivalente al Popover "Personalizar" de Header.jsx (frontend web) — Tema
// y Color. Se omite el selector Sidebar/Top Nav: es un concepto de layout
// de escritorio que no tiene equivalente en mobile (acá ya usamos nav
// inferior, que es el patrón correcto en un celular).
class PersonalizarSheet extends StatelessWidget {
  const PersonalizarSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const PersonalizarSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController(),
      builder: (context, _) {
        final controller = ThemeController();
        return Container(
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
                'Personalizar',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Apariencia',
                style: TextStyle(color: AppColors.textSub, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _sectionLabel('TEMA'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _optionCard(
                      icon: Icons.light_mode_outlined,
                      label: 'Claro',
                      color: AppColors.textMain,
                      active: !controller.darkMode,
                      onTap: () {
                        if (controller.darkMode) controller.toggleDarkMode();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _optionCard(
                      icon: Icons.dark_mode_outlined,
                      label: 'Oscuro',
                      color: AppColors.textMain,
                      active: controller.darkMode,
                      onTap: () {
                        if (!controller.darkMode) controller.toggleDarkMode();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionLabel('COLOR'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _colorOption(
                      color: const Color(0xFFCC1818),
                      label: 'Rojo',
                      active: controller.paletteKey == 'red',
                      onTap: () => controller.setPalette('red'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _colorOption(
                      color: const Color(0xFF1A2E6E),
                      label: 'Azul',
                      active: controller.paletteKey == 'blue',
                      onTap: () => controller.setPalette('blue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      color: AppColors.textSub,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    ),
  );

  Widget _optionCard({
    required IconData icon,
    required String label,
    required Color color,
    required bool active,
    required VoidCallback onTap,
  }) {
    return TapArea(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.adminPrimary : AppColors.border,
            width: 1.5,
          ),
          color: active
              ? AppColors.adminPrimary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? AppColors.adminPrimary : AppColors.textSub,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.adminPrimary : AppColors.textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorOption({
    required Color color,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return TapArea(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? color : AppColors.border,
            width: 1.5,
          ),
          color: active ? color.withValues(alpha: 0.08) : Colors.transparent,
        ),
        child: Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: active
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? color : AppColors.textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Equivalente a useDateTime.js (frontend web) — se refresca cada minuto.
class LiveDateTime extends StatefulWidget {
  final TextStyle? style;
  const LiveDateTime({super.key, this.style});

  @override
  State<LiveDateTime> createState() => _LiveDateTimeState();
}

class _LiveDateTimeState extends State<LiveDateTime> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(formatDateTime(DateTime.now()), style: widget.style);
  }
}

// Sin gradStart/gradEnd: barra lisa color background.paper (blanca en modo
// claro), igual que el Header.jsx real del frontend web — no un degradado
// de color como tenían antes las pantallas de inicio de admin/conductor.
// Pasando gradStart/gradEnd sí arma un degradado de color (para pantallas
// tipo detalle/perfil que si lo usan).
class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Color? gradStart;
  final Color? gradEnd;
  final Widget? trailing;
  final bool showBack;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.gradStart,
    this.gradEnd,
    this.trailing,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final isFlat = gradStart == null || gradEnd == null;
    final fg = isFlat ? AppColors.textMain : Colors.white;
    final fgSub = isFlat
        ? AppColors.textSub
        : Colors.white.withValues(alpha: 0.75);

    return Container(
      width: double.infinity,
      decoration: isFlat
          ? BoxDecoration(
              color: AppColors.cardBg,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            )
          : BoxDecoration(
              gradient: LinearGradient(
                colors: [gradStart!, gradEnd!],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        20,
      ),
      child: Row(
        children: [
          if (showBack)
            TapArea(
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.arrow_back, color: fg, size: 22),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: fg,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cambria',
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(color: fgSub, fontSize: 13)),
                ],
                if (subtitleWidget != null) ...[
                  const SizedBox(height: 2),
                  subtitleWidget!,
                ],
              ],
            ),
          ),
          ?trailing,
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
      child: Text(
        estado,
        style: TextStyle(
          color: estadoColor(estado),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
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
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: AppColors.textSub, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: iconColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
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
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: AppColors.textSub, fontSize: 11),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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

// Igual al Chip de licencia en ListarConductor.jsx (web): "categoría · fecha",
// borde/relleno primario según si ya venció.
class LicenciaChip extends StatelessWidget {
  final LicenciaCategoria categoria;

  const LicenciaChip({super.key, required this.categoria});

  @override
  Widget build(BuildContext context) {
    final vencida = categoria.vencida;
    final label =
        '${categoria.categoria} · ${categoria.vencimiento != null ? formatFecha(categoria.vencimiento) : 'N/A'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: vencida ? AppColors.driverPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.driverPrimary),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: vencida ? Colors.white : AppColors.driverPrimary,
        ),
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
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Igual a ConfirmRow.jsx (web): si se pasa previousValue y difiere de value,
// la fila se marca con un punto junto a la etiqueta y el valor anterior
// tachado debajo del nuevo — usado en el paso de confirmación de los forms.
class ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final String? previousValue;

  const ConfirmRow({
    super.key,
    required this.label,
    required this.value,
    this.previousValue,
  });

  @override
  Widget build(BuildContext context) {
    final huboCambio = previousValue != null && previousValue != value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (huboCambio) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.adminPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSub,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value.isEmpty ? '—' : value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (huboCambio) ...[
                  const SizedBox(height: 2),
                  Text(
                    'antes: ${previousValue!.isEmpty ? '—' : previousValue}',
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSub,
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnticipoCard extends StatelessWidget {
  final Anticipo anticipo;
  final bool isAdmin;
  final VoidCallback onVer;
  // null => ícono deshabilitado (el estado actual no permite editar, según
  // quién esté mirando la tarjeta — ver Anticipo.esEditable y las reglas de
  // cada pantalla que arma esta card).
  final VoidCallback? onEditar;
  // Solo aplica para admin cuando estado == 'Excedente pendiente'.
  final VoidCallback? onConfirmarDevolucion;

  const AnticipoCard({
    super.key,
    required this.anticipo,
    required this.isAdmin,
    required this.onVer,
    this.onEditar,
    this.onConfirmarDevolucion,
  });

  // Por qué el conductor no puede editar todavía — el admin sigue siendo
  // dueño del anticipo mientras la ruta no arranca (estado Entregado).
  String get _editDisabledReason => 'Aún no lo puedes editar';

  @override
  Widget build(BuildContext context) {
    final mostrarConfirmarDevolucion =
        isAdmin &&
        anticipo.estado == EstadoAnticipo.excedentePendiente &&
        onConfirmarDevolucion != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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
                    Tooltip(
                      message: 'Ver detalle',
                      child: IconButton(
                        onPressed: onVer,
                        icon: Icon(
                          Icons.remove_red_eye_outlined,
                          color: AppColors.textSub,
                          size: 20,
                        ),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                    Tooltip(
                      message: onEditar != null
                          ? 'Editar'
                          : _editDisabledReason,
                      child: IconButton(
                        onPressed: onEditar,
                        icon: Icon(
                          Icons.edit_outlined,
                          color: onEditar != null
                              ? AppColors.textSub
                              : AppColors.border,
                          size: 20,
                        ),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  anticipo.nombreRuta != null
                      ? '${anticipo.nombreRuta}${anticipo.destinoTexto != null ? ' → ${anticipo.destinoTexto}' : ''}'
                      : 'Anticipo #${anticipo.id}',
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isAdmin && anticipo.conductorNombre.isNotEmpty)
                  Text(
                    'Conductor: ${anticipo.conductorNombre}',
                    style: TextStyle(color: AppColors.textSub, fontSize: 12),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _val(
                      'Anticipo',
                      formatCOP(anticipo.valorAnticipo),
                      AppColors.blue,
                    ),
                    _val(
                      'Gastado',
                      anticipo.valorGastado == 0
                          ? '—'
                          : '-${formatCOP(anticipo.valorGastado)}',
                      anticipo.valorGastado == 0
                          ? AppColors.textSub
                          : AppColors.orange,
                    ),
                    _val(
                      'Excedente',
                      anticipo.valorGastado == 0
                          ? '—'
                          : (anticipo.tieneDeficit
                                ? formatCOP(anticipo.excedente)
                                : '+${formatCOP(anticipo.excedente)}'),
                      anticipo.valorGastado == 0
                          ? AppColors.textSub
                          : (anticipo.tieneDeficit
                                ? AppColors.red
                                : AppColors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Entrega: ${formatFecha(anticipo.fechaEntrega)}',
                      style: TextStyle(color: AppColors.textSub, fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      'Legalización: ${formatFecha(anticipo.fechaLegalizacion)}',
                      style: TextStyle(color: AppColors.textSub, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (mostrarConfirmarDevolucion) ...[
            Divider(height: 1, color: AppColors.border),
            TapArea(
              onTap: onConfirmarDevolucion,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Confirmar devolución de excedente',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

  Widget _val(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSub, fontSize: 11)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
