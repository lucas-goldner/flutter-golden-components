import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Glowing blobs of goo that drift like wax in a lava lamp, melting into
/// each other when they meet and pulling apart again.
///
/// Each blob warms up near the bottom, rises, cools near the top and sinks
/// back down, wobbling sideways on the way. Touching blobs merge into one
/// smooth shape (a blur followed by an alpha threshold, the classic "goo"
/// effect) and their [colors] blend where they meet; a softer blurred copy
/// underneath adds the [glow].
///
/// With [pool] a pool of wax lies along the bottom for blobs to drip out of
/// and fall back into. With [followPointer] an extra blob trails the pointer
/// (or finger) and merges with whatever it touches.
///
/// The widget fills its constraints and paints on a transparent background,
/// so put whatever backdrop you like behind it. When the platform asks to
/// reduce motion ([MediaQueryData.disableAnimations]) the blobs hold still.
class GooBlobs extends StatefulWidget {
  /// Creates a lava-lamp of goo.
  const GooBlobs({
    super.key,
    this.count = 9,
    this.colors = defaultColors,
    this.minSize = 0.07,
    this.maxSize = 0.15,
    this.speed = 1,
    this.gooeyness = 1,
    this.glow = 0.6,
    this.pool = true,
    this.followPointer = true,
    this.lightColor,
    this.seed = 7,
  }) : assert(count >= 0),
       assert(minSize > 0 && maxSize >= minSize),
       assert(speed >= 0),
       assert(gooeyness >= 0),
       assert(glow >= 0 && glow <= 1);

  /// Number of floating blobs.
  final int count;

  /// Blob colors, assigned in turn; blobs that merge blend theirs. An empty
  /// list falls back to [defaultColors].
  final List<Color> colors;

  /// Warm lava colors used by default.
  static const List<Color> defaultColors = [
    Color(0xFFFF3CAC),
    Color(0xFFFF8A00),
    Color(0xFFFFD23F),
    Color(0xFF784BA0),
  ];

  List<Color> get _palette => colors.isEmpty ? defaultColors : colors;

  /// Smallest blob radius, as a fraction of the shorter side.
  final double minSize;

  /// Largest blob radius, as a fraction of the shorter side.
  final double maxSize;

  /// How fast the wax moves; 1 is a calm lamp.
  final double speed;

  /// How readily blobs reach for each other and merge; 0 keeps them crisp
  /// and separate.
  final double gooeyness;

  /// Strength of the soft halo around the goo (0-1).
  final double glow;

  /// Whether a pool of wax lies along the bottom.
  final bool pool;

  /// Whether an extra blob follows the pointer.
  final bool followPointer;

  /// Seed for the blobs' sizes, colors and starting positions.
  final int seed;

  /// Receives the light the goo gives off, updated as it moves: the blobs'
  /// colors blended by size and heat (hot wax glows more), with an alpha
  /// that rises and falls with how hot the wax is overall.
  ///
  /// Use it to light the surroundings, e.g. a halo, reflections or a
  /// backdrop that follows the lamp.
  final ValueNotifier<Color>? lightColor;

  @override
  State<GooBlobs> createState() => _GooBlobsState();
}

/// One blob, in normalized coordinates (0-1 across the widget).
class _Blob {
  _Blob({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.heat,
    required this.phase,
  });

  double x;
  double y;
  double vy = 0;

  /// Radius as a fraction of the shorter side.
  final double radius;
  final Color color;

  /// 0 (cold, sinks) to 1 (hot, rises).
  double heat;

  /// Offsets this blob's sideways wobble.
  final double phase;
}

class _GooBlobsState extends State<GooBlobs> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<int> _frame = ValueNotifier(0);
  late List<_Blob> _blobs = _spawn();
  double _time = 0;
  Duration? _last;
  bool _reduceMotion = false;

  /// Pointer blob position (normalized), shown while the pointer is inside.
  Offset? _pointerTarget;
  Offset? _pointer;

  @override
  void initState() {
    super.initState();
    _publishLightLater();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncTicker();
  }

  @override
  void didUpdateWidget(GooBlobs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count ||
        oldWidget.seed != widget.seed ||
        oldWidget.minSize != widget.minSize ||
        oldWidget.maxSize != widget.maxSize ||
        !_sameColors(oldWidget._palette, widget._palette)) {
      _blobs = _spawn();
    }
    if (!widget.followPointer) _pointer = _pointerTarget = null;
    _syncTicker();
    _frame.value++;
    _publishLightLater();
  }

  /// Publishes [GooBlobs.lightColor] after this frame (listeners may
  /// rebuild, which isn't allowed mid-build).
  void _publishLightLater() {
    if (widget.lightColor == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publishLight();
    });
  }

  /// Blend of the blob colors by area and glow (hotter wax glows more).
  void _publishLight() {
    final notifier = widget.lightColor;
    if (notifier == null) return;
    var r = 0.0, g = 0.0, b = 0.0, total = 0.0, heat = 0.0, area = 0.0;
    void add(Color c, double radius, double h) {
      final a = radius * radius;
      // Hot wax dominates, so the light follows whichever blobs are hottest.
      final w = a * (0.03 + h * h * h * h);
      r += c.r * w;
      g += c.g * w;
      b += c.b * w;
      total += w;
      heat += h * a;
      area += a;
    }

    for (final blob in _blobs) {
      add(blob.color, blob.radius, blob.heat);
    }
    if (_pointer != null) {
      add(widget._palette[widget.count % widget._palette.length], widget.maxSize * 0.85, 1);
    }
    // The pool adds a little warmth without drowning out the blobs.
    if (widget.pool) add(widget._palette.first, widget.maxSize * 0.8, 0.5);
    if (total == 0) return;
    final warmth = area == 0 ? 0.0 : heat / area;
    // Averaging muddies colors; give the blend back some saturation.
    final mix = HSLColor.fromColor(
      Color.from(alpha: 1, red: r / total, green: g / total, blue: b / total),
    );
    notifier.value = mix
        .withSaturation(math.max(mix.saturation, math.min(1, mix.saturation * 1.4)))
        .withLightness(mix.lightness.clamp(0.35, 0.65))
        .toColor()
        .withValues(alpha: (0.45 + 0.55 * warmth).clamp(0.0, 1.0));
  }

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  List<_Blob> _spawn() {
    final random = math.Random(widget.seed);
    return [
      for (var i = 0; i < widget.count; i++)
        _Blob(
          x: 0.15 + random.nextDouble() * 0.7,
          y: 0.1 + random.nextDouble() * 0.8,
          radius: widget.minSize + random.nextDouble() * (widget.maxSize - widget.minSize),
          color: widget._palette[i % widget._palette.length],
          heat: random.nextDouble(),
          phase: random.nextDouble() * math.pi * 2,
        ),
    ];
  }

  bool get _animating => !_reduceMotion && widget.speed > 0;

  void _syncTicker() {
    final run = _animating || (_pointer != null && _pointer != _pointerTarget);
    if (run && !_ticker.isActive) {
      _last = null;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final last = _last;
    // Clamp long frames (tab switches) so the wax doesn't jump.
    final dt = last == null ? 0.0 : math.min(0.05, (elapsed - last).inMicroseconds / 1e6);
    _last = elapsed;
    if (_animating) _step(dt * widget.speed);
    final target = _pointerTarget;
    if (target != null) {
      final from = _pointer ?? target;
      _pointer = Offset.lerp(from, target, 1 - math.exp(-dt * 10));
    }
    _frame.value++;
    _publishLight();
    _syncTicker();
  }

  /// Lava-lamp physics: wax only heats up near the bottom and only cools
  /// near the top, keeping its temperature in between, so every blob makes
  /// the full trip up and back down. Buoyancy and drag set the pace.
  void _step(double dt) {
    _time += dt;
    for (final b in _blobs) {
      if (b.y > 0.75) {
        b.heat = math.min(1, b.heat + dt * 0.45 * (b.y - 0.75) * 4);
      } else if (b.y < 0.3) {
        b.heat = math.max(0, b.heat - dt * 0.45 * (0.3 - b.y) / 0.3);
      }
      // Hot wax rises (negative y), cold wax sinks; bigger blobs are a
      // little lazier.
      final lift = (b.heat - 0.5) * 0.3 / (0.6 + b.radius * 4);
      b.vy += -lift * dt;
      b.vy *= math.exp(-dt * 0.9);
      b.y += b.vy * dt;
      // Soft floor and ceiling.
      final top = b.radius * 0.6;
      final bottom = 1 - b.radius * 0.6;
      if (b.y < top) {
        b.y = top;
        b.vy = b.vy.abs() * 0.2;
      } else if (b.y > bottom) {
        b.y = bottom;
        b.vy = -b.vy.abs() * 0.2;
      }
      b.x += math.sin(_time * 0.45 + b.phase) * 0.012 * dt;
      b.x = b.x.clamp(b.radius * 0.5, 1 - b.radius * 0.5);
    }
  }

  void _onPointer(Offset local, Size size) {
    if (!widget.followPointer || size.isEmpty) return;
    _pointerTarget = Offset(local.dx / size.width, local.dy / size.height);
    _syncTicker();
    if (!_ticker.isActive) {
      _pointer = _pointerTarget;
      _frame.value++;
      _publishLight();
    }
  }

  void _onPointerExit() {
    _pointer = _pointerTarget = null;
    _frame.value++;
    _publishLight();
    _syncTicker();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final shortest = size.shortestSide.isFinite ? size.shortestSide : 0.0;
        // Blur scales with the blobs so the goo looks the same at any size.
        final sigma = math.max(0.0, shortest * 0.03 * widget.gooeyness);
        final painter = _GooPainter(state: this, repaint: _frame);
        final glowPainter = _GooPainter(state: this, repaint: _frame, glowPass: true);
        return MouseRegion(
          onHover: (e) => _onPointer(e.localPosition, size),
          onExit: (_) => _onPointerExit(),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _onPointer(e.localPosition, size),
            onPointerMove: (e) => _onPointer(e.localPosition, size),
            onPointerUp: (e) {
              if (e.kind != ui.PointerDeviceKind.mouse) _onPointerExit();
            },
            child: RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.glow > 0)
                    _Glow(
                      sigma: math.max(1, sigma * 2.4 + shortest * 0.02),
                      opacity: widget.glow,
                      painter: glowPainter,
                    ),
                  _Goo(sigma: sigma, painter: painter),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Matrix that keeps colors and turns alpha into a hard edge around 50%.
const List<double> _threshold = [
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 18, -18 * 0.45 * 255,
];

/// The goo itself: blobs blurred, then thresholded into smooth shapes.
class _Goo extends StatelessWidget {
  const _Goo({required this.sigma, required this.painter});

  final double sigma;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(painter: painter, size: Size.infinite);
    if (sigma < 0.5) return paint;
    return ImageFiltered(
      imageFilter: ui.ImageFilter.compose(
        outer: const ui.ColorFilter.matrix(_threshold),
        inner: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
      ),
      child: paint,
    );
  }
}

/// A soft, wide halo of the same blobs behind the goo.
class _Glow extends StatelessWidget {
  const _Glow({required this.sigma, required this.opacity, required this.painter});

  final double sigma;
  final double opacity;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
        child: CustomPaint(painter: painter, size: Size.infinite),
      ),
    );
  }
}

class _GooPainter extends CustomPainter {
  _GooPainter({required this.state, required super.repaint, this.glowPass = false});

  final _GooBlobsState state;

  /// Painting the halo: hot blobs shine, cold ones barely do.
  final bool glowPass;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = state.widget;
    final s = size.shortestSide;

    if (w.pool) {
      // A wide, shallow pool of wax along the bottom, in the first color
      // blending into the second.
      final rect = Rect.fromLTRB(
        -s * 0.1,
        size.height - s * 0.11,
        size.width + s * 0.1,
        size.height + s * 0.3,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            rect.centerLeft,
            rect.centerRight,
            [w._palette.first, w._palette[1 % w._palette.length], w._palette.first],
            [0, 0.5, 1],
          ),
      );
    }

    for (final b in state._blobs) {
      _blob(canvas, Offset(b.x * size.width, b.y * size.height), b.radius * s, b.color, b.heat);
    }
    final pointer = state._pointer;
    if (pointer != null) {
      _blob(
        canvas,
        Offset(pointer.dx * size.width, pointer.dy * size.height),
        w.maxSize * s * 0.85,
        w._palette[w.count % w._palette.length],
        1,
      );
    }
  }

  /// A blob with a brighter core (brighter still when hot), so merged goo
  /// keeps some depth; in the glow pass, hot blobs shine and cold ones fade.
  void _blob(Canvas canvas, Offset c, double r, Color color, double heat) {
    if (glowPass) {
      canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.25 + 0.75 * heat));
      return;
    }
    final core = Color.lerp(color, const Color(0xFFFFFFFF), 0.2 + 0.25 * heat)!;
    canvas.drawCircle(
      c,
      r,
      Paint()..shader = ui.Gradient.radial(c - Offset(r * 0.25, r * 0.3), r * 1.2, [core, color]),
    );
  }

  @override
  bool shouldRepaint(_GooPainter oldDelegate) => true;
}
