import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Soft curtains of aurora light drifting behind [child].
///
/// Two layers of slanted, repeating bands slide past each other in
/// opposite directions: a layer of [colors] and a layer of pale (or, when
/// [dark], deep) veils. Where they overlap the light thickens and thins
/// like curtains of an aurora. The whole sky is blurred by [blur] and fades
/// out away from [focus], so the glow gathers in one part of the backdrop.
///
/// When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the aurora holds still.
class AuroraBackdrop extends StatefulWidget {
  /// Creates an aurora backdrop.
  const AuroraBackdrop({
    super.key,
    this.child,
    this.colors = defaultColors,
    this.dark = false,
    this.background,
    this.speed = 1,
    this.intensity = 0.7,
    this.blur = 22,
    this.angle = 10,
    this.focus = const Alignment(0.9, -1.1),
    this.reach = 1.0,
  }) : assert(speed >= 0),
       assert(intensity >= 0 && intensity <= 1),
       assert(blur >= 0);

  /// Cool blues and violets.
  static const List<Color> defaultColors = [
    Color(0xFF3B82F6),
    Color(0xFFA5B4FC),
    Color(0xFF93C5FD),
    Color(0xFFDDD6FE),
    Color(0xFF60A5FA),
  ];

  /// Shown in front of the aurora.
  final Widget? child;

  /// The aurora's colors, repeated across each band.
  final List<Color> colors;

  /// Whether the aurora glows on a dark sky instead of a light one.
  final bool dark;

  /// The sky behind the aurora. Defaults to near-white, or near-black when
  /// [dark].
  final Color? background;

  /// How fast the curtains drift; 1 takes about a minute per cycle, 0
  /// holds still.
  final double speed;

  /// How strong the aurora is, from 0 (invisible) to 1.
  final double intensity;

  /// Blur radius softening the bands, in logical pixels.
  final double blur;

  /// Tilt of the bands from vertical, in degrees.
  final double angle;

  /// Where the glow gathers; it fades out with distance from here.
  final Alignment focus;

  /// How far the glow reaches from [focus], as a fraction of the larger
  /// side of the backdrop.
  final double reach;

  @override
  State<AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<AuroraBackdrop> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<double> _time = ValueNotifier(0);
  double _offset = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(AuroraBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  /// Runs the ticker only while there is drift to show.
  void _sync() {
    final still = (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || widget.speed == 0;
    if (still && _ticker.isActive) {
      _offset = _time.value;
      _ticker.stop();
    } else if (!still && !_ticker.isActive) {
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    _time.value = _offset + elapsed.inMicroseconds / 1e6 * widget.speed;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sky =
        widget.background ?? (widget.dark ? const Color(0xFF09090B) : const Color(0xFFFAFAFA));
    Widget aurora = CustomPaint(
      painter: _AuroraPainter(
        time: _time,
        colors: widget.colors.isEmpty ? AuroraBackdrop.defaultColors : widget.colors,
        veil: widget.dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
        angle: widget.angle,
      ),
    );
    if (widget.blur > 0) {
      aurora = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: widget.blur,
          sigmaY: widget.blur,
          tileMode: TileMode.mirror,
        ),
        child: aurora,
      );
    }
    aurora = ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => RadialGradient(
        center: widget.focus,
        radius: widget.reach * math.max(rect.width, rect.height) / rect.shortestSide,
        colors: const [Color(0xFF000000), Color(0x8C000000), Color(0x00000000)],
        stops: const [0, 0.4, 1],
      ).createShader(rect),
      child: aurora,
    );
    return ColoredBox(
      color: sky,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Opacity(
                  opacity: widget.intensity,
                  child: RepaintBoundary(child: aurora),
                ),
              ),
            ),
          ),
          if (widget.child case final child?) child else const SizedBox.expand(),
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.time,
    required this.colors,
    required this.veil,
    required this.angle,
  }) : super(repaint: time);

  final ValueNotifier<double> time;
  final List<Color> colors;
  final Color veil;
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final diagonal = size.longestSide * 1.6;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..rotate(angle * math.pi / 180);
    final sky = Rect.fromCenter(center: Offset.zero, width: diagonal, height: diagonal);

    // The colored curtains: one wide repeat of the palette, sliding right.
    final colorPeriod = size.longestSide * 1.2;
    final colorShift = (t / 60 * colorPeriod) % colorPeriod;
    canvas.drawRect(
      sky,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(colorShift, 0),
          Offset(colorShift + colorPeriod, 0),
          [...colors, colors.first],
          [for (var i = 0; i <= colors.length; i++) i / colors.length],
          TileMode.repeated,
        ),
    );

    // The veils: narrower stripes sliding left, thinning the curtains where
    // they pass and letting the colour through between them.
    final veilPeriod = size.longestSide * 0.42;
    final veilShift = -(t / 45 * veilPeriod) % veilPeriod;
    final clear = veil.withValues(alpha: 0);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(veilShift, 0),
          Offset(veilShift + veilPeriod, 0),
          [veil, clear, clear, veil, clear, clear, veil],
          const [0, 0.12, 0.36, 0.5, 0.6, 0.88, 1],
          TileMode.repeated,
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.time != time || old.colors != colors || old.veil != veil || old.angle != angle;
}
