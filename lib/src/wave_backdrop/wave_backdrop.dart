import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Thick, soft waves of colour flowing slowly behind [child].
///
/// One wave is drawn for each of [colors]: a broad stroke [waveWidth]
/// pixels thick that undulates across the backdrop around [center]. Each
/// wave mixes a few slow ripples of its own, so the waves cross, part and
/// braid as they flow. [blur] softens them into ribbons of light, and
/// [opacity] lets them blend where they overlap.
///
/// When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the waves hold still.
class WaveBackdrop extends StatefulWidget {
  /// Creates a wave backdrop.
  const WaveBackdrop({
    super.key,
    this.child,
    this.colors = defaultColors,
    this.background,
    this.dark = true,
    this.waveWidth = 50,
    this.blur = 10,
    this.opacity = 0.5,
    this.speed = 1,
    this.amplitude = 0.35,
    this.center = 0.5,
  }) : assert(waveWidth > 0),
       assert(blur >= 0),
       assert(opacity >= 0 && opacity <= 1),
       assert(speed >= 0),
       assert(amplitude >= 0);

  /// Sky blue, indigo, violet, fuchsia and cyan.
  static const List<Color> defaultColors = [
    Color(0xFF38BDF8),
    Color(0xFF818CF8),
    Color(0xFFC084FC),
    Color(0xFFE879F9),
    Color(0xFF22D3EE),
  ];

  /// Shown in front of the waves.
  final Widget? child;

  /// One wave per colour, drawn in order.
  final List<Color> colors;

  /// The colour behind the waves. Defaults to near-black, or near-white
  /// when not [dark].
  final Color? background;

  /// Whether the default [background] is dark.
  final bool dark;

  /// Thickness of each wave, in logical pixels.
  final double waveWidth;

  /// Blur radius softening the waves, in logical pixels.
  final double blur;

  /// Opacity of each wave, so overlaps blend.
  final double opacity;

  /// How fast the waves flow; 0 holds still.
  final double speed;

  /// How far the waves swing up and down, as a fraction of the height.
  final double amplitude;

  /// Where the waves run, from 0 (top) to 1 (bottom).
  final double center;

  @override
  State<WaveBackdrop> createState() => _WaveBackdropState();
}

class _WaveBackdropState extends State<WaveBackdrop> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<double> _time = ValueNotifier(0);
  double _offset = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(WaveBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed && _ticker.isActive) {
      // Keep the waves where they are when the speed changes.
      _offset = _time.value;
      _ticker
        ..stop()
        ..start();
    }
    _sync();
  }

  /// Runs the ticker only while there is motion to show.
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
    final background =
        widget.background ?? (widget.dark ? const Color(0xFF09090B) : const Color(0xFFFAFAFA));
    Widget waves = CustomPaint(
      painter: _WavePainter(
        time: _time,
        colors: widget.colors.isEmpty ? WaveBackdrop.defaultColors : widget.colors,
        waveWidth: widget.waveWidth,
        opacity: widget.opacity,
        amplitude: widget.amplitude,
        center: widget.center,
      ),
    );
    if (widget.blur > 0) {
      waves = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: widget.blur,
          sigmaY: widget.blur,
          tileMode: TileMode.decal,
        ),
        child: waves,
      );
    }
    return ColoredBox(
      color: background,
      child: ClipRect(
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(child: RepaintBoundary(child: waves)),
              ),
            ),
            if (widget.child case final child?) child else const SizedBox.expand(),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.time,
    required this.colors,
    required this.waveWidth,
    required this.opacity,
    required this.amplitude,
    required this.center,
  }) : super(repaint: time);

  final ValueNotifier<double> time;
  final List<Color> colors;
  final double waveWidth;
  final double opacity;
  final double amplitude;
  final double center;

  /// Horizontal distance between the points of a wave.
  static const double _step = 6;

  /// A smooth value in -1..1 for wave [i] at [u] (the x position in
  /// multiples of the height) and time [t]: three ripples of different
  /// lengths and speeds, with a phase of their own per wave.
  static double _swing(int i, double u, double t) {
    final seed = i * 1.7 + 0.4;
    final a = math.sin(u * 1.3 + t * 0.45 + seed);
    final b = math.sin(u * 2.9 - t * 0.31 + seed * 2.3);
    final c = math.sin(u * 0.7 + t * 0.19 + seed * 0.6);
    return (a * 0.5 + b * 0.25 + c * 0.25).clamp(-1.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = time.value;
    final mid = size.height * center;
    final swing = size.height * amplitude / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = waveWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < colors.length; i++) {
      final path = Path();
      for (var x = -waveWidth; x <= size.width + waveWidth; x += _step) {
        final y = mid + swing * _swing(i, x / size.height * math.pi, t);
        if (x == -waveWidth) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      paint.color = colors[i].withValues(alpha: colors[i].a * opacity);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.time != time ||
      old.colors != colors ||
      old.waveWidth != waveWidth ||
      old.opacity != opacity ||
      old.amplitude != amplitude ||
      old.center != center;
}
