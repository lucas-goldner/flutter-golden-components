import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';

enum _Palette { lava, neon, ocean, sunset, gold }

/// Blob colors and the liquid behind them.
@immutable
class _Scheme {
  const _Scheme(this.colors, this.top, this.bottom);

  final List<Color> colors;
  final Color top;
  final Color bottom;
}

const _schemes = {
  _Palette.lava: _Scheme(
    [Color(0xFFFF3CAC), Color(0xFFFF8A00), Color(0xFFFFD23F), Color(0xFF784BA0)],
    Color(0xFF1B0B2E),
    Color(0xFF3A0D2E),
  ),
  _Palette.neon: _Scheme(
    [Color(0xFF00F5D4), Color(0xFF00BBF9), Color(0xFF9B5DE5), Color(0xFFF15BB5)],
    Color(0xFF07071A),
    Color(0xFF0D1B3A),
  ),
  _Palette.ocean: _Scheme(
    [Color(0xFF48CAE4), Color(0xFF0077B6), Color(0xFF90E0EF), Color(0xFF00B4D8)],
    Color(0xFF03045E),
    Color(0xFF023E8A),
  ),
  _Palette.sunset: _Scheme(
    [Color(0xFFFF6B6B), Color(0xFFFFA94D), Color(0xFFFFD43B), Color(0xFFF06595)],
    Color(0xFF2B1055),
    Color(0xFF7597DE),
  ),
  _Palette.gold: _Scheme(
    [Color(0xFFFDE68A), Color(0xFFF5C451), Color(0xFFC98A12)],
    Color(0xFF0A0802),
    Color(0xFF241B08),
  ),
};

/// Playground for [GooBlobs].
class GooBlobsDemo extends StatefulWidget {
  const GooBlobsDemo({super.key});

  @override
  State<GooBlobsDemo> createState() => _GooBlobsDemoState();
}

class _GooBlobsDemoState extends State<GooBlobsDemo> {
  late _Palette _palette;
  late double _count;
  late double _minSize;
  late double _maxSize;
  late double _speed;
  late double _gooeyness;
  late double _glow;
  late bool _pool;
  late bool _follow;
  late bool _lamp;

  /// The goo's light, shared with the lamp so its glow follows the wax.
  final ValueNotifier<Color> _light = ValueNotifier(const Color(0x00000000));

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _light.dispose();
    super.dispose();
  }

  void _reset() {
    _palette = _Palette.lava;
    _count = 9;
    _minSize = 0.07;
    _maxSize = 0.15;
    _speed = 1;
    _gooeyness = 1;
    _glow = 0.6;
    _pool = true;
    _follow = true;
    _lamp = true;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final scheme = _schemes[_palette]!;
    return Playground(
      preview: _Preview(
        lamp: _lamp,
        scheme: scheme,
        light: _light,
        goo: GooBlobs(
          count: _count.round(),
          colors: scheme.colors,
          minSize: _minSize,
          maxSize: _maxSize,
          speed: _speed,
          gooeyness: _gooeyness,
          glow: _glow,
          pool: _pool,
          followPointer: _follow,
          lightColor: _light,
        ),
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Look',
          children: [
            ChipsControl<_Palette>(
              label: 'Colors',
              multiple: false,
              options: const {
                _Palette.lava: 'Lava',
                _Palette.neon: 'Neon',
                _Palette.ocean: 'Ocean',
                _Palette.sunset: 'Sunset',
                _Palette.gold: 'Gold',
              },
              selected: {_palette},
              onChanged: (v) => _set(() => _palette = v.single),
            ),
            SliderControl(
              label: 'Gooeyness',
              value: _gooeyness,
              min: 0,
              max: 2.5,
              step: 0.1,
              format: (v) => v.toStringAsFixed(1),
              onChanged: (v) => _set(() => _gooeyness = v),
            ),
            SliderControl(
              label: 'Glow',
              value: _glow,
              min: 0,
              max: 1,
              step: 0.05,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => _set(() => _glow = v),
            ),
            ToggleControl(
              label: 'Lamp shape',
              value: _lamp,
              onChanged: (v) => _set(() => _lamp = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Wax',
          children: [
            SliderControl(
              label: 'Blobs',
              value: _count,
              min: 0,
              max: 20,
              step: 1,
              onChanged: (v) => _set(() => _count = v),
            ),
            SliderControl(
              label: 'Smallest',
              value: _minSize,
              min: 0.03,
              max: 0.25,
              step: 0.01,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => _set(() {
                _minSize = v;
                if (_maxSize < v) _maxSize = v;
              }),
            ),
            SliderControl(
              label: 'Largest',
              value: _maxSize,
              min: 0.03,
              max: 0.3,
              step: 0.01,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => _set(() {
                _maxSize = v;
                if (_minSize > v) _minSize = v;
              }),
            ),
            SliderControl(
              label: 'Speed',
              value: _speed,
              min: 0,
              max: 4,
              step: 0.1,
              format: (v) => v == 0 ? 'paused' : '${v.toStringAsFixed(1)}x',
              onChanged: (v) => _set(() => _speed = v),
            ),
            ToggleControl(
              label: 'Pool at the bottom',
              value: _pool,
              onChanged: (v) => _set(() => _pool = v),
            ),
            ToggleControl(
              label: 'Blob follows pointer',
              value: _follow,
              onChanged: (v) => _set(() => _follow = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// The goo in a lava lamp, or filling the stage.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.goo,
    required this.scheme,
    required this.lamp,
    required this.light,
  });

  final GooBlobs goo;
  final _Scheme scheme;
  final bool lamp;
  final ValueNotifier<Color> light;

  @override
  Widget build(BuildContext context) {
    if (!lamp) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _Liquid(scheme: scheme, light: light, goo: goo),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 56),
      child: Center(
        child: AspectRatio(
          aspectRatio: _LampGeometry.aspectRatio,
          child: _LavaLamp(goo: goo, scheme: scheme, light: light),
        ),
      ),
    );
  }
}

/// The liquid: a gradient, the bulb's glow from below, and the goo.
class _Liquid extends StatelessWidget {
  const _Liquid({required this.scheme, required this.light, required this.goo});

  final _Scheme scheme;
  final ValueNotifier<Color> light;
  final Widget goo;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [scheme.top, scheme.bottom],
            ),
          ),
        ),
        IgnorePointer(
          child: ValueListenableBuilder<Color>(
            valueListenable: light,
            builder: (context, color, _) => CustomPaint(painter: _BulbPainter(color)),
          ),
        ),
        goo,
      ],
    );
  }
}

/// Proportions of the lamp, in fractions of its width (u) and height (v):
/// a conical chrome cap, a bottle that swells towards the bottom, a chrome
/// collar and a flared base.
abstract final class _LampGeometry {
  static const double aspectRatio = 0.36;

  static const double glassTop = 0.15;
  static const double glassBottom = 0.665;
  static const double baseTop = 0.685;

  /// Glass bounds (where the goo lives).
  static Rect glassRect(Size s) =>
      Rect.fromLTRB(0.17 * s.width, glassTop * s.height, 0.83 * s.width, glassBottom * s.height);

  static Path cap(Size s) {
    final w = s.width, h = s.height;
    return Path()
      ..moveTo(0.37 * w, 0.02 * h)
      ..quadraticBezierTo(0.5 * w, -0.006 * h, 0.63 * w, 0.02 * h)
      ..lineTo(0.70 * w, (glassTop + 0.008) * h)
      ..quadraticBezierTo(0.5 * w, (glassTop + 0.02) * h, 0.30 * w, (glassTop + 0.008) * h)
      ..close();
  }

  static Path glass(Size s) {
    final w = s.width, h = s.height;
    return Path()
      ..moveTo(0.305 * w, glassTop * h)
      ..cubicTo(0.27 * w, 0.30 * h, 0.17 * w, 0.40 * h, 0.17 * w, 0.52 * h)
      ..cubicTo(0.17 * w, 0.60 * h, 0.20 * w, 0.645 * h, 0.235 * w, glassBottom * h)
      ..lineTo(0.765 * w, glassBottom * h)
      ..cubicTo(0.80 * w, 0.645 * h, 0.83 * w, 0.60 * h, 0.83 * w, 0.52 * h)
      ..cubicTo(0.83 * w, 0.40 * h, 0.73 * w, 0.30 * h, 0.695 * w, glassTop * h)
      ..close();
  }

  static Path collar(Size s) {
    final w = s.width, h = s.height;
    return Path()..addRRect(
      RRect.fromLTRBR(
        0.215 * w,
        (glassBottom - 0.006) * h,
        0.785 * w,
        (baseTop + 0.004) * h,
        Radius.circular(0.012 * h),
      ),
    );
  }

  static Path base(Size s) {
    final w = s.width, h = s.height;
    return Path()
      ..moveTo(0.235 * w, baseTop * h)
      ..lineTo(0.765 * w, baseTop * h)
      ..cubicTo(0.80 * w, 0.80 * h, 0.90 * w, 0.90 * h, 0.94 * w, 0.965 * h)
      ..quadraticBezierTo(0.95 * w, 0.995 * h, 0.90 * w, h)
      ..lineTo(0.10 * w, h)
      ..quadraticBezierTo(0.05 * w, 0.995 * h, 0.06 * w, 0.965 * h)
      ..cubicTo(0.10 * w, 0.90 * h, 0.20 * w, 0.80 * h, 0.235 * w, baseTop * h)
      ..close();
  }
}

/// A chrome lava lamp: light spill around it, chrome cap/collar/base that
/// pick up the lava's color, and a shaded glass bottle holding the goo.
class _LavaLamp extends StatelessWidget {
  const _LavaLamp({required this.goo, required this.scheme, required this.light});

  final GooBlobs goo;
  final _Scheme scheme;
  final ValueNotifier<Color> light;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final glass = _LampGeometry.glassRect(size);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Light thrown onto the surroundings and the floor.
            Positioned.fill(
              child: IgnorePointer(
                child: ValueListenableBuilder<Color>(
                  valueListenable: light,
                  builder: (context, color, _) => CustomPaint(painter: _SpillPainter(color)),
                ),
              ),
            ),
            Positioned.fill(
              child: ClipPath(
                clipper: _GlassClipper(),
                child: Stack(
                  children: [
                    Positioned.fromRect(
                      rect: glass,
                      child: _Liquid(scheme: scheme, light: light, goo: goo),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ValueListenableBuilder<Color>(
                  valueListenable: light,
                  builder: (context, color, _) => CustomPaint(painter: _LampBodyPainter(color)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlassClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _LampGeometry.glass(size);

  @override
  bool shouldReclip(_GlassClipper oldClipper) => false;
}

/// Warm light rising from the bulb in the base, tinted by the lava.
class _BulbPainter extends CustomPainter {
  const _BulbPainter(this.light);

  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 1.05);
    final glow = Color.lerp(const Color(0xFFFFE8B0), light.withValues(alpha: 1), 0.55)!;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            glow.withValues(alpha: 0.55 * light.a),
            glow.withValues(alpha: 0.12 * light.a),
            glow.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: center, radius: size.height * 0.75)),
    );
  }

  @override
  bool shouldRepaint(_BulbPainter oldDelegate) => oldDelegate.light != light;
}

/// The lamp's halo on the surroundings and its pool of light on the floor.
class _SpillPainter extends CustomPainter {
  const _SpillPainter(this.light);

  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final color = light.withValues(alpha: 1);
    final a = light.a;
    final glassCenter = Offset(size.width / 2, size.height * 0.45);
    final haloRadius = size.height * 0.62;
    canvas.drawCircle(
      glassCenter,
      haloRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.5 * a),
            color.withValues(alpha: 0.12 * a),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: glassCenter, radius: haloRadius)),
    );
    // Floor: a wide ellipse of light under the base.
    final floor = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 1.005),
      width: size.width * 2.6,
      height: size.height * 0.16,
    );
    canvas.drawOval(
      floor,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.7 * a),
            color.withValues(alpha: 0),
          ],
        ).createShader(floor),
    );
    // Contact shadow right under the base.
    final contact = Rect.fromCenter(
      center: Offset(size.width / 2, size.height),
      width: size.width * 0.95,
      height: size.height * 0.025,
    );
    canvas.drawOval(
      contact,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x99000000), Color(0x00000000)],
        ).createShader(contact),
    );
  }

  @override
  bool shouldRepaint(_SpillPainter oldDelegate) => oldDelegate.light != light;
}

/// Chrome parts and glass shading, lit by the lava.
class _LampBodyPainter extends CustomPainter {
  const _LampBodyPainter(this.light);

  final Color light;

  static const List<Color> _chrome = [
    Color(0xFF1B1B1F),
    Color(0xFF4A4A52),
    Color(0xFFCFCFD6),
    Color(0xFF9C9CA5),
    Color(0xFF3B3B42),
    Color(0xFF2A2A30),
    Color(0xFF8A8A93),
    Color(0xFF26262B),
    Color(0xFF141417),
  ];
  static const List<double> _chromeStops = [0, 0.1, 0.24, 0.32, 0.48, 0.62, 0.8, 0.9, 1];

  @override
  void paint(Canvas canvas, Size size) {
    final color = light.withValues(alpha: 1);
    final a = light.a;

    _glassShading(canvas, size, color, a);

    final cap = _LampGeometry.cap(size);
    final base = _LampGeometry.base(size);
    final collar = _LampGeometry.collar(size);
    _chromePart(canvas, base, size, color, a, litFromTop: true);
    _chromePart(canvas, cap, size, color, a, litFromTop: false);
    _chromePart(canvas, collar, size, color, a, litFromTop: true, strength: 1.4);

    // Bright lip where each chrome part meets the glass.
    final lip = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, size.width * 0.006)
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, 0),
        [
          const Color(0x00FFFFFF),
          Color.lerp(const Color(0xFFFFFFFF), color, 0.4)!.withValues(alpha: 0.75),
          const Color(0x00FFFFFF),
        ],
        const [0, 0.5, 1],
      );
    final capBottom = (_LampGeometry.glassTop + 0.012) * size.height;
    canvas.drawLine(
      Offset(0.31 * size.width, capBottom),
      Offset(0.69 * size.width, capBottom),
      lip,
    );
    final baseTop = (_LampGeometry.baseTop + 0.006) * size.height;
    canvas.drawLine(Offset(0.24 * size.width, baseTop), Offset(0.76 * size.width, baseTop), lip);
  }

  void _chromePart(
    Canvas canvas,
    Path path,
    Size size,
    Color light,
    double a, {
    required bool litFromTop,
    double strength = 1,
  }) {
    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(bounds.centerLeft, bounds.centerRight, _chrome, _chromeStops),
    );
    // The lava's glow reflected on the chrome, strongest next to the glass.
    canvas.drawPath(
      path,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = ui.Gradient.linear(
          litFromTop ? bounds.topCenter : bounds.bottomCenter,
          litFromTop ? bounds.bottomCenter : bounds.topCenter,
          [
            light.withValues(alpha: (0.55 * a * strength).clamp(0.0, 1.0)),
            light.withValues(alpha: 0.12 * a),
            light.withValues(alpha: 0),
          ],
          const [0, 0.35, 1],
        ),
    );
    // Darker away from the glass, so the parts read as round.
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          litFromTop ? bounds.topCenter : bounds.bottomCenter,
          litFromTop ? bounds.bottomCenter : bounds.topCenter,
          const [Color(0x00000000), Color(0x00000000), Color(0x8C000000)],
          const [0, 0.3, 1],
        ),
    );
    // Soft dark outline to sit it on the backdrop.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x66000000),
    );
  }

  void _glassShading(Canvas canvas, Size size, Color light, double a) {
    final glass = _LampGeometry.glass(size);
    final r = glass.getBounds();
    canvas
      ..save()
      ..clipPath(glass);
    // Volume: darker at the sides and towards the top.
    canvas.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.linear(
          r.centerLeft,
          r.centerRight,
          const [
            Color(0x73000000),
            Color(0x0D000000),
            Color(0x00000000),
            Color(0x14000000),
            Color(0x80000000),
          ],
          const [0, 0.18, 0.5, 0.8, 1],
        ),
    );
    canvas.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.linear(
          r.topCenter,
          r.bottomCenter,
          const [Color(0x66000000), Color(0x00000000)],
          const [0, 0.35],
        ),
    );
    // Specular streaks: a broad soft one and a crisp one on the left,
    // a colored rim light on the right.
    final broad = Rect.fromLTWH(r.left + r.width * 0.14, r.top, r.width * 0.12, r.height);
    canvas.drawRect(
      broad,
      Paint()
        ..shader = ui.Gradient.linear(
          broad.centerLeft,
          broad.centerRight,
          const [Color(0x00FFFFFF), Color(0x2EFFFFFF), Color(0x00FFFFFF)],
          const [0, 0.5, 1],
        ),
    );
    final crisp = Rect.fromLTWH(
      r.left + r.width * 0.29,
      r.top + r.height * 0.06,
      r.width * 0.025,
      r.height * 0.8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(crisp, Radius.circular(crisp.width)),
      Paint()
        ..shader = ui.Gradient.linear(
          crisp.topCenter,
          crisp.bottomCenter,
          const [Color(0x00FFFFFF), Color(0x59FFFFFF), Color(0x26FFFFFF), Color(0x00FFFFFF)],
          const [0, 0.25, 0.7, 1],
        ),
    );
    final rim = Rect.fromLTWH(r.right - r.width * 0.12, r.top, r.width * 0.12, r.height);
    canvas.drawRect(
      rim,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = ui.Gradient.linear(
          rim.centerLeft,
          rim.centerRight,
          [
            light.withValues(alpha: 0),
            light.withValues(alpha: 0.35 * a),
            light.withValues(alpha: 0),
          ],
          const [0, 0.7, 1],
        ),
    );
    canvas.restore();
    // Glass edge.
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, size.width * 0.005)
        ..shader = ui.Gradient.linear(
          r.centerLeft,
          r.centerRight,
          const [Color(0x40FFFFFF), Color(0x0DFFFFFF), Color(0x33FFFFFF)],
          const [0, 0.5, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_LampBodyPainter oldDelegate) => oldDelegate.light != light;
}
