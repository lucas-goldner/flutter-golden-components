import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Metal palettes for a [MetalButton]'s ring.
enum MetalPreset {
  /// Iridescent chrome with hints of pink, cyan and gold.
  chromatic([
    Color(0xFFD9E2FF),
    Color(0xFFFFFFFF),
    Color(0xFFFFD6F5),
    Color(0xFF8A8FA3),
    Color(0xFFF5F5FF),
    Color(0xFFB8F3FF),
    Color(0xFF5C6070),
    Color(0xFFFFE9C2),
  ]),

  /// Neutral brushed silver.
  silver([
    Color(0xFFF4F4F5),
    Color(0xFFA1A1AA),
    Color(0xFFFFFFFF),
    Color(0xFF52525B),
    Color(0xFFE4E4E7),
    Color(0xFF71717A),
    Color(0xFFFAFAFA),
    Color(0xFFA1A1AA),
  ]),

  /// Warm polished gold.
  gold([
    Color(0xFFFFF3C4),
    Color(0xFFD4A017),
    Color(0xFFFFFBE6),
    Color(0xFF8A6100),
    Color(0xFFF7D774),
    Color(0xFFB8860B),
    Color(0xFFFFF1B8),
    Color(0xFFA07408),
  ]);

  const MetalPreset(this.colors);

  /// The palette, in order around the ring.
  final List<Color> colors;
}

/// The surface inside a [MetalButton]'s ring.
enum MetalButtonStyle {
  /// A solid fill in the ambient text color, for the main action.
  filled,

  /// The page's own color, so the ring does the talking.
  outline,

  /// A soft tint.
  soft,

  /// No fill until hovered.
  ghost,
}

/// A button wrapped in a ring of slowly flowing liquid metal.
///
/// The ring's [preset] (or [colors]) sweeps around it while a specular
/// glint rolls the other way, with an optional soft [glow]; [strength]
/// scales both. Inside, [child] sits on a [style] surface that responds to
/// hover, press and keyboard focus (which also brightens the ring). Use a
/// [radius] of half the [height] with a square [width] for a round icon
/// button.
///
/// The ring holds still when [paused] or when the platform asks to reduce
/// motion ([MediaQueryData.disableAnimations]).
class MetalButton extends StatefulWidget {
  /// Creates a metal button.
  const MetalButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.style = MetalButtonStyle.filled,
    this.preset = MetalPreset.chromatic,
    this.colors,
    this.height = 40,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.radius,
    this.ringWidth = 2,
    this.strength = 0.9,
    this.glow = true,
    this.speed = 1,
    this.paused = false,
    this.dark,
    this.semanticLabel,
  }) : assert(strength >= 0 && strength <= 1),
       assert(ringWidth > 0);

  /// The label or icon.
  final Widget child;

  /// Called when the button is tapped or activated; null disables it.
  final VoidCallback? onPressed;

  /// The surface inside the ring.
  final MetalButtonStyle style;

  /// The ring's metal.
  final MetalPreset preset;

  /// A custom palette for the ring, used instead of [preset].
  final List<Color>? colors;

  /// Height of the button, ring included.
  final double height;

  /// Fixed width, ring included; defaults to fitting [child].
  final double? width;

  /// Space between the surface's edge and [child].
  final EdgeInsets padding;

  /// Corner radius; defaults to a pill.
  final double? radius;

  /// Thickness of the metal ring.
  final double ringWidth;

  /// Opacity of the metal and glow, from 0 to 1.
  final double strength;

  /// Whether a soft glow spills out of the ring.
  final bool glow;

  /// How fast the metal flows; 1 is a slow, calm drift.
  final double speed;

  /// Freezes the metal where it is.
  final bool paused;

  /// Whether to draw for a dark background; defaults to following the
  /// ambient text color (light text means a dark background).
  final bool? dark;

  /// Read out by screen readers, useful when [child] is an icon.
  final String? semanticLabel;

  @override
  State<MetalButton> createState() => _MetalButtonState();
}

class _MetalButtonState extends State<MetalButton> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<double> _time = ValueNotifier(0);
  double _offset = 0;
  bool _hover = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(MetalButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final still =
        widget.paused ||
        widget.speed == 0 ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (still && _ticker.isActive) {
      _offset = _time.value;
      _ticker.stop();
    } else if (!still && !_ticker.isActive) {
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) =>
      _time.value = _offset + elapsed.inMicroseconds / 1e6 * widget.speed;

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    final dark = widget.dark ?? ink.computeLuminance() > 0.5;
    final surface = _Surface.of(widget.style, dark, hovered: _hover && _enabled);
    final radius = widget.radius ?? widget.height / 2;
    final ring = widget.ringWidth;
    final colors = (widget.colors?.isNotEmpty ?? false) ? widget.colors! : widget.preset.colors;
    final face = Container(
      height: widget.height - ring * 2,
      width: widget.width == null ? null : widget.width! - ring * 2,
      padding: widget.width == null ? widget.padding : null,
      decoration: BoxDecoration(
        color: surface.fill,
        borderRadius: BorderRadius.circular(math.max(0, radius - ring)),
        border: Border.all(color: surface.edge),
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: surface.ink, size: 16),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: surface.ink,
            fontSize: 14,
            height: 1,
            fontWeight: FontWeight.w500,
          ),
          // Hug the label rather than stretching to the available width.
          child: Center(widthFactor: 1, child: widget.child),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed?.call()),
        },
        child: GestureDetector(
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            child: Opacity(
              opacity: _enabled ? 1 : 0.5,
              child: CustomPaint(
                painter: _RingPainter(
                  time: _time,
                  colors: colors,
                  ring: ring,
                  radius: radius,
                  // Hover and focus brighten the metal a little.
                  strength: (widget.strength + (_hover || _focused ? 0.1 : 0)).clamp(0.0, 1.0),
                  glow: widget.glow,
                  focused: _focused,
                  dark: dark,
                ),
                child: Padding(padding: EdgeInsets.all(ring), child: face),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Colors of a [MetalButtonStyle] surface.
@immutable
class _Surface {
  const _Surface(this.fill, this.ink, this.edge);

  factory _Surface.of(MetalButtonStyle style, bool dark, {required bool hovered}) {
    final edge = dark ? const Color(0xCC3F3F46) : const Color(0xB3E5E5E5);
    return switch ((style, dark)) {
      (MetalButtonStyle.filled, false) => _Surface(
        hovered ? const Color(0xFF2E2E33) : const Color(0xFF171717),
        const Color(0xFFFAFAFA),
        edge,
      ),
      (MetalButtonStyle.filled, true) => _Surface(
        hovered ? const Color(0xFFF4F4F5) : const Color(0xFFE5E5E5),
        const Color(0xFF171717),
        edge,
      ),
      (MetalButtonStyle.outline, false) => _Surface(
        hovered ? const Color(0xFFF4F4F5) : const Color(0xFFFFFFFF),
        const Color(0xFF0A0A0A),
        edge,
      ),
      (MetalButtonStyle.outline, true) => _Surface(
        hovered ? const Color(0xFF26262B) : const Color(0xFF151518),
        const Color(0xFFFAFAFA),
        edge,
      ),
      (MetalButtonStyle.soft, false) => _Surface(
        hovered ? const Color(0xFFEAEAEC) : const Color(0xFFF4F4F5),
        const Color(0xFF171717),
        edge,
      ),
      (MetalButtonStyle.soft, true) => _Surface(
        hovered ? const Color(0xFF33333A) : const Color(0xFF26262B),
        const Color(0xFFFAFAFA),
        edge,
      ),
      (MetalButtonStyle.ghost, _) => _Surface(
        hovered
            ? (dark ? const Color(0x80262626) : const Color(0x80F5F5F5))
            : const Color(0x00000000),
        dark ? const Color(0xFFFAFAFA) : const Color(0xFF0A0A0A),
        edge,
      ),
    };
  }

  final Color fill;
  final Color ink;
  final Color edge;
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.time,
    required this.colors,
    required this.ring,
    required this.radius,
    required this.strength,
    required this.glow,
    required this.focused,
    required this.dark,
  }) : super(repaint: time);

  final ValueNotifier<double> time;
  final List<Color> colors;
  final double ring;
  final double radius;
  final double strength;
  final bool glow;
  final bool focused;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final rect = Offset.zero & size;
    final r = math.min(radius, size.shortestSide / 2);
    final outer = RRect.fromRectAndRadius(rect, Radius.circular(r));
    final inner = RRect.fromRectAndRadius(
      rect.deflate(ring),
      Radius.circular(math.max(0, r - ring)),
    );

    // The palette flowing around the ring, as a slowly turning sweep that
    // loops seamlessly (first colour repeated at the end).
    final metal = SweepGradient(
      colors: [...colors, colors.first],
      transform: GradientRotation(t * 2 * math.pi * 0.12),
    ).createShader(rect);
    // Two glints rolling the other way, wobbling a little like light on
    // something liquid.
    final glint = SweepGradient(
      colors: const [
        Color(0x00FFFFFF),
        Color(0xD9FFFFFF),
        Color(0x00FFFFFF),
        Color(0x00FFFFFF),
        Color(0x99FFFFFF),
        Color(0x00FFFFFF),
      ],
      stops: const [0, 0.05, 0.13, 0.5, 0.56, 0.64],
      transform: GradientRotation(-t * 2 * math.pi * 0.21 + math.sin(t * 0.9) * 0.5),
    ).createShader(rect);

    if (glow && strength > 0) {
      canvas.drawRRect(
        outer,
        Paint()
          ..shader = metal
          ..color = Color.fromRGBO(255, 255, 255, (focused ? 0.6 : 0.35) * strength)
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, focused ? 9 : 6),
      );
    }
    final band = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(outer)
      ..addRRect(inner);
    canvas
      ..saveLayer(rect.inflate(2), Paint())
      ..drawPath(band, Paint()..color = dark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8))
      ..drawPath(
        band,
        Paint()
          ..shader = metal
          ..color = Color.fromRGBO(255, 255, 255, strength),
      )
      ..drawPath(
        band,
        Paint()
          ..shader = glint
          ..blendMode = BlendMode.plus
          ..color = Color.fromRGBO(255, 255, 255, strength),
      )
      ..restore()
      // A hairline so the ring reads on any background.
      ..drawRRect(
        outer.deflate(0.25),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = dark ? const Color(0x33FFFFFF) : const Color(0x26000000),
      );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.time != time ||
      old.colors != colors ||
      old.ring != ring ||
      old.radius != radius ||
      old.strength != strength ||
      old.glow != glow ||
      old.focused != focused ||
      old.dark != dark;
}
