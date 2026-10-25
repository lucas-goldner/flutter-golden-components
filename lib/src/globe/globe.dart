import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'globe_data.dart';

/// A position on the globe in degrees.
@immutable
class GlobeLatLng {
  /// Creates a position; [latitude] in -90..90, [longitude] in -180..180.
  const GlobeLatLng(this.latitude, this.longitude);

  /// Degrees north of the equator (negative is south).
  final double latitude;

  /// Degrees east of Greenwich (negative is west).
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is GlobeLatLng && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GlobeLatLng($latitude, $longitude)';
}

/// The continents countries are grouped into.
enum GlobeContinent {
  /// Africa.
  africa,

  /// Antarctica.
  antarctica,

  /// Asia.
  asia,

  /// Europe.
  europe,

  /// North America, including Central America and the Caribbean.
  northAmerica,

  /// Oceania.
  oceania,

  /// South America.
  southAmerica,
}

/// A country the globe knows about.
@immutable
class GlobeCountry {
  const GlobeCountry._(this.index, this.code, this.name, this.continent, this.center);

  /// 1-based index into the globe's country table.
  final int index;

  /// ISO 3166-1 alpha-3 code, e.g. `JPN`.
  final String code;

  /// English short name, e.g. `Japan`.
  final String name;

  /// The continent it belongs to.
  final GlobeContinent continent;

  /// Centre of its largest landmass, handy for markers, arcs and focusing.
  final GlobeLatLng center;

  /// Every country, sorted by [code].
  static final List<GlobeCountry> all = [
    for (var i = 0; i < globeCountries.length; i++)
      GlobeCountry._(
        i + 1,
        globeCountries[i].$1,
        globeCountries[i].$2,
        GlobeContinent.values[globeCountries[i].$3],
        GlobeLatLng(globeCountries[i].$4, globeCountries[i].$5),
      ),
  ];

  static final Map<String, GlobeCountry> _byCode = {for (final c in all) c.code: c};

  /// The country with ISO alpha-3 [code], or null.
  static GlobeCountry? byCode(String code) => _byCode[code.toUpperCase()];

  @override
  String toString() => 'GlobeCountry($code, $name)';
}

/// Dots to tint: a single country or a whole continent.
@immutable
class GlobeHighlight {
  /// Highlights the country with ISO alpha-3 [code].
  const GlobeHighlight.country(String code, {this.color}) : countryCode = code, continent = null;

  /// Highlights every country on [continent].
  const GlobeHighlight.continent(GlobeContinent this.continent, {this.color}) : countryCode = null;

  /// ISO alpha-3 code, for a country highlight.
  final String? countryCode;

  /// Continent, for a continent highlight.
  final GlobeContinent? continent;

  /// Dot color; defaults to [Globe.highlightColor].
  final Color? color;

  @override
  bool operator ==(Object other) =>
      other is GlobeHighlight &&
      other.countryCode == countryCode &&
      other.continent == continent &&
      other.color == color;

  @override
  int get hashCode => Object.hash(countryCode, continent, color);

  /// Whether [country] is covered by this highlight.
  bool matches(GlobeCountry country) => countryCode != null
      ? country.code == countryCode!.toUpperCase()
      : country.continent == continent;
}

/// A route drawn over the globe along the great circle from [from] to [to],
/// lifted above the surface, with a plane flying along its head.
@immutable
class GlobeArc {
  /// Creates an arc.
  const GlobeArc({required this.from, required this.to, this.color, this.height = 0.35});

  /// Start of the route.
  final GlobeLatLng from;

  /// End of the route.
  final GlobeLatLng to;

  /// Line color; defaults to [Globe.arcColor].
  final Color? color;

  /// Peak height above the surface, as a fraction of the globe radius, for
  /// a route halfway round the world; shorter routes fly lower.
  final double height;

  @override
  bool operator ==(Object other) =>
      other is GlobeArc &&
      other.from == from &&
      other.to == to &&
      other.color == color &&
      other.height == height;

  @override
  int get hashCode => Object.hash(from, to, color, height);
}

/// A pin on the globe, with an optional pulse.
@immutable
class GlobeMarker {
  /// Creates a marker.
  const GlobeMarker({required this.at, this.color, this.size = 4, this.pulse = true});

  /// Where the marker sits.
  final GlobeLatLng at;

  /// Dot color; defaults to [Globe.markerColor].
  final Color? color;

  /// Dot radius in logical pixels.
  final double size;

  /// Whether a ring pulses out of the dot.
  final bool pulse;

  @override
  bool operator ==(Object other) =>
      other is GlobeMarker &&
      other.at == at &&
      other.color == color &&
      other.size == size &&
      other.pulse == pulse;

  @override
  int get hashCode => Object.hash(at, color, size, pulse);
}

/// Turns a [Globe] towards places.
class GlobeController extends ChangeNotifier {
  GlobeLatLng? _target;
  Duration _duration = const Duration(milliseconds: 900);

  /// Smoothly turns the globe so that [position] faces the viewer.
  void focus(GlobeLatLng position, {Duration duration = const Duration(milliseconds: 900)}) {
    _target = position;
    _duration = duration;
    notifyListeners();
  }

  /// Focuses the centre of [country].
  void focusCountry(
    GlobeCountry country, {
    Duration duration = const Duration(milliseconds: 900),
  }) => focus(country.center, duration: duration);
}

/// An interactive dotted globe.
///
/// Land is drawn as dots (one per ~1° of latitude, evenly spaced along each
/// ring) on a softly shaded sphere. Countries and whole continents can be
/// tinted with [highlights]; [arcs] are flight routes that draw from start
/// to end with a small plane at their head, staggered and (with
/// [loopArcs]) repeating; [markers] are pulsing pins.
///
/// Drag to spin it (with momentum), tap a country to get [onCountryTap].
/// It turns slowly by itself ([autoRotateSpeed]) and can be pointed at a
/// place through a [GlobeController]. When the platform asks to reduce
/// motion ([MediaQueryData.disableAnimations]) it holds still and draws the
/// arcs complete.
class Globe extends StatefulWidget {
  /// Creates a globe.
  const Globe({
    super.key,
    this.highlights = const [],
    this.arcs = const [],
    this.markers = const [],
    this.initialFocus = const GlobeLatLng(25, 15),
    this.controller,
    this.autoRotateSpeed = 6,
    this.interactive = true,
    this.onCountryTap,
    this.sphereColor = const Color(0xFFF8F8FA),
    this.shadeColor = const Color(0xFFDCDDE2),
    this.glowColor = const Color(0x00000000),
    this.dotColor = const Color(0xFF8E9099),
    this.highlightColor = const Color(0xFFE3A008),
    this.arcColor = const Color(0xFFE3A008),
    this.markerColor = const Color(0xFFFF3B30),
    this.dotSize = 1.6,
    this.arcWidth = 1.6,
    this.showPlanes = true,
    this.planeSize = 14,
    this.arcDuration = const Duration(milliseconds: 1800),
    this.arcStagger = const Duration(milliseconds: 500),
    this.arcHold = const Duration(milliseconds: 1500),
    this.loopArcs = true,
  }) : assert(dotSize > 0),
       assert(arcWidth > 0);

  /// Countries or continents to tint.
  final List<GlobeHighlight> highlights;

  /// Routes to draw.
  final List<GlobeArc> arcs;

  /// Pins to show.
  final List<GlobeMarker> markers;

  /// Point facing the viewer at first.
  final GlobeLatLng initialFocus;

  /// Optional controller to turn the globe towards places.
  final GlobeController? controller;

  /// Spin in degrees of longitude per second while idle; 0 to stop.
  final double autoRotateSpeed;

  /// Whether dragging spins the globe and taps report countries.
  final bool interactive;

  /// Called with the country under a tap, if any.
  final ValueChanged<GlobeCountry>? onCountryTap;

  /// Lit side of the sphere.
  final Color sphereColor;

  /// Shaded edge of the sphere.
  final Color shadeColor;

  /// Halo around the sphere; transparent for none.
  final Color glowColor;

  /// Land dots.
  final Color dotColor;

  /// Default color of highlighted dots.
  final Color highlightColor;

  /// Default arc color.
  final Color arcColor;

  /// Default marker color.
  final Color markerColor;

  /// Dot diameter, in logical pixels for a 400 px globe (scales with size).
  final double dotSize;

  /// Arc stroke width in logical pixels.
  final double arcWidth;

  /// Whether a plane flies at the head of each drawing arc.
  final bool showPlanes;

  /// Plane length in logical pixels.
  final double planeSize;

  /// Time for one arc to draw from start to end.
  final Duration arcDuration;

  /// Delay between consecutive arcs starting.
  final Duration arcStagger;

  /// How long finished arcs stay before fading (when looping).
  final Duration arcHold;

  /// Repeat the arc sequence forever; otherwise arcs stay once drawn.
  final bool loopArcs;

  @override
  State<Globe> createState() => _GlobeState();
}

class _GlobeState extends State<Globe> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);

  /// Repaints the painter without rebuilding.
  final ValueNotifier<int> _frame = ValueNotifier(0);

  /// Centre of view (degrees).
  late double _lat = widget.initialFocus.latitude;
  late double _lng = widget.initialFocus.longitude;

  /// Seconds the arc/marker clock has run.
  double _time = 0;
  Duration? _last;

  bool _dragging = false;
  Offset _velocity = Offset.zero; // degrees per second, (dLng, dLat)

  // Focus animation.
  double? _fromLat, _fromLng, _toLat, _toLng;
  double _focusT = 1;
  double _focusSeconds = 0.9;

  bool _reduceMotion = false;
  late Int32List _countryColors = _resolveHighlights();

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onFocusRequest);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncTicker();
  }

  @override
  void didUpdateWidget(Globe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onFocusRequest);
      widget.controller?.addListener(_onFocusRequest);
    }
    if (!listEquals(oldWidget.highlights, widget.highlights) ||
        oldWidget.highlightColor != widget.highlightColor) {
      _countryColors = _resolveHighlights();
    }
    if (!listEquals(oldWidget.arcs, widget.arcs)) _time = 0;
    _syncTicker();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onFocusRequest);
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  /// ARGB per country index (0 = not highlighted); later highlights win.
  Int32List _resolveHighlights() {
    final colors = Int32List(GlobeCountry.all.length + 1);
    for (final h in widget.highlights) {
      final color = (h.color ?? widget.highlightColor).toARGB32();
      for (final c in GlobeCountry.all) {
        if (h.matches(c)) colors[c.index] = color;
      }
    }
    return colors;
  }

  bool get _focusing => _focusT < 1;

  bool get _needsTicker {
    if (_dragging || _focusing || _velocity.distance > 0.5) return true;
    if (_reduceMotion) return false;
    return widget.autoRotateSpeed != 0 ||
        widget.markers.any((m) => m.pulse) ||
        (widget.arcs.isNotEmpty && (widget.loopArcs || _time < _arcTimelineSeconds));
  }

  double get _arcTimelineSeconds =>
      (widget.arcs.length - 1) * _seconds(widget.arcStagger) + _seconds(widget.arcDuration);

  static double _seconds(Duration d) => d.inMicroseconds / 1e6;

  void _syncTicker() {
    if (_needsTicker && !_ticker.isActive) {
      _last = null;
      _ticker.start();
    } else if (!_needsTicker && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final last = _last;
    final dt = last == null ? 0.0 : (elapsed - last).inMicroseconds / 1e6;
    _last = elapsed;
    if (!_reduceMotion) _time += dt;

    if (_focusing) {
      _focusT = math.min(1, _focusT + dt / _focusSeconds);
      final t = Curves.easeInOutCubic.transform(_focusT);
      _lat = _fromLat! + (_toLat! - _fromLat!) * t;
      _lng = _fromLng! + (_toLng! - _fromLng!) * t;
    } else if (!_dragging) {
      if (_velocity.distance > 0.5) {
        _lng += _velocity.dx * dt;
        _lat = (_lat + _velocity.dy * dt).clamp(-80.0, 80.0);
        _velocity *= math.pow(0.04, dt).toDouble();
      } else if (!_reduceMotion) {
        _velocity = Offset.zero;
        _lng += widget.autoRotateSpeed * dt;
      }
    }
    _lng = ((_lng + 180) % 360) - 180;
    _frame.value++;
    if (!_needsTicker) _ticker.stop();
  }

  void _onFocusRequest() {
    final target = widget.controller?._target;
    if (target == null) return;
    _fromLat = _lat;
    _fromLng = _lng;
    _toLat = target.latitude.clamp(-80.0, 80.0);
    // Shortest way round.
    var delta = (target.longitude - _lng) % 360;
    if (delta > 180) delta -= 360;
    _toLng = _lng + delta;
    _focusSeconds = math.max(0.001, _seconds(widget.controller!._duration));
    _focusT = 0;
    _velocity = Offset.zero;
    _syncTicker();
  }

  double _radius(Size size) => size.shortestSide / 2 * 0.92;

  void _onPanStart(DragStartDetails d) {
    _dragging = true;
    _focusT = 1;
    _velocity = Offset.zero;
    _syncTicker();
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    final degreesPerPixel = 180 / math.pi / _radius(size);
    _lng -= d.delta.dx * degreesPerPixel;
    _lat = (_lat + d.delta.dy * degreesPerPixel).clamp(-80.0, 80.0);
    _frame.value++;
  }

  void _onPanEnd(DragEndDetails d, Size size) {
    _dragging = false;
    final degreesPerPixel = 180 / math.pi / _radius(size);
    final v = d.velocity.pixelsPerSecond;
    _velocity = Offset(-v.dx * degreesPerPixel, v.dy * degreesPerPixel);
    _syncTicker();
  }

  void _onTapUp(TapUpDetails d, Size size) {
    final onTap = widget.onCountryTap;
    if (onTap == null) return;
    final r = _radius(size);
    final p = (d.localPosition - size.center(Offset.zero)) / r;
    final country = _GlobeView(_lat, _lng).countryAt(p.dx, -p.dy);
    if (country != null) onTap(country);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final painter = CustomPaint(
          size: size,
          painter: _GlobePainter(state: this, repaint: _frame),
        );
        if (!widget.interactive) return painter;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onPanStart,
          onPanUpdate: (d) => _onPanUpdate(d, size),
          onPanEnd: (d) => _onPanEnd(d, size),
          onTapUp: (d) => _onTapUp(d, size),
          child: MouseRegion(cursor: SystemMouseCursors.grab, child: painter),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Data

/// Land dots decoded once: unit vectors and owning country per dot, plus
/// the per-ring country grid used to look up taps.
class _Land {
  _Land._(this.xyz, this.country, this.rings);

  final Float32List xyz;
  final Uint16List country;

  /// Country index per sample, per ring (0 = ocean).
  final List<Uint8List> rings;

  static final _Land instance = _decode();

  static int ringSamples(int ring) {
    final lat = 90 - (ring + 0.5) * 180 / globeRings;
    return math.max(1, (2 * globeRings * math.cos(lat * math.pi / 180)).round());
  }

  static _Land _decode() {
    final bytes = base64.decode(globeSamples);
    final rings = <Uint8List>[];
    final xyz = <double>[];
    final country = <int>[];
    var pos = 0;
    for (var r = 0; r < globeRings; r++) {
      final n = ringSamples(r);
      final ring = Uint8List(n);
      var i = 0;
      while (i < n) {
        final c = bytes[pos];
        final run = bytes[pos + 1];
        pos += 2;
        ring.fillRange(i, i + run, c);
        i += run;
      }
      rings.add(ring);
      final lat = (90 - (r + 0.5) * 180 / globeRings) * math.pi / 180;
      for (var k = 0; k < n; k++) {
        if (ring[k] == 0) continue;
        final lng = (-180 + (k + 0.5) * 360 / n) * math.pi / 180;
        xyz
          ..add(math.cos(lat) * math.sin(lng))
          ..add(math.sin(lat))
          ..add(math.cos(lat) * math.cos(lng));
        country.add(ring[k]);
      }
    }
    return _Land._(Float32List.fromList(xyz), Uint16List.fromList(country), rings);
  }
}

/// Unit vector of a position.
(double, double, double) _toXyz(GlobeLatLng p) {
  final lat = p.latitude * math.pi / 180;
  final lng = p.longitude * math.pi / 180;
  return (math.cos(lat) * math.sin(lng), math.sin(lat), math.cos(lat) * math.cos(lng));
}

/// The rotation that brings (lat, lng) to the front of the globe.
class _GlobeView {
  _GlobeView(double lat, double lng)
    : _cy = math.cos(lng * math.pi / 180),
      _sy = math.sin(lng * math.pi / 180),
      _cx = math.cos(lat * math.pi / 180),
      _sx = math.sin(lat * math.pi / 180);

  final double _cy, _sy, _cx, _sx;

  /// View-space (x right, y up, z towards the viewer) of a world vector.
  (double, double, double) apply(double x, double y, double z) {
    final x1 = x * _cy - z * _sy;
    final z1 = x * _sy + z * _cy;
    return (x1, y * _cx - z1 * _sx, y * _sx + z1 * _cx);
  }

  /// Country under view-space point (x, y) on the front of the unit disk.
  GlobeCountry? countryAt(double x, double y) {
    final d = x * x + y * y;
    if (d > 1) return null;
    final z = math.sqrt(1 - d);
    // Undo the pitch, then the yaw.
    final wy = y * _cx + z * _sx;
    final z1 = -y * _sx + z * _cx;
    final wx = x * _cy + z1 * _sy;
    final wz = -x * _sy + z1 * _cy;
    final lat = math.asin(wy.clamp(-1.0, 1.0)) * 180 / math.pi;
    final lng = math.atan2(wx, wz) * 180 / math.pi;
    final ring = ((90 - lat) / 180 * globeRings).floor().clamp(0, globeRings - 1);
    final samples = _Land.instance.rings[ring];
    final k = ((lng + 180) / 360 * samples.length).floor().clamp(0, samples.length - 1);
    final index = samples[k];
    return index == 0 ? null : GlobeCountry.all[index - 1];
  }
}

// ---------------------------------------------------------------------------
// Painting

class _GlobePainter extends CustomPainter {
  _GlobePainter({required this.state, required super.repaint});

  final _GlobeState state;

  static const int _shades = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final w = state.widget;
    final r = state._radius(size);
    if (r <= 0) return;
    final c = size.center(Offset.zero);
    final view = _GlobeView(state._lat, state._lng);

    // Halo and sphere.
    if (w.glowColor.a > 0) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = w.glowColor
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, r * 0.12),
      );
    }
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c + Offset(-r * 0.35, -r * 0.4),
          r * 1.45,
          [w.sphereColor, Color.lerp(w.sphereColor, w.shadeColor, 0.55)!, w.shadeColor],
          [0, 0.6, 1],
        ),
    );

    _paintDots(canvas, c, r, view);
    _paintArcs(canvas, c, r, view);
    _paintMarkers(canvas, c, r, view);
  }

  void _paintDots(Canvas canvas, Offset c, double r, _GlobeView view) {
    final w = state.widget;
    final land = _Land.instance;
    final colors = state._countryColors;
    // Bucket by (color, shade) so each bucket is one drawRawPoints call.
    final buckets = <int, List<double>>{};
    final xyz = land.xyz;
    for (var i = 0, n = land.country.length; i < n; i++) {
      final (x, y, z) = view.apply(xyz[i * 3], xyz[i * 3 + 1], xyz[i * 3 + 2]);
      if (z <= 0.02) continue;
      final shade = math.min(_shades - 1, (z * _shades).floor());
      final key = colors[land.country[i]] * _shades + shade;
      (buckets[key] ??= <double>[])
        ..add(c.dx + x * r)
        ..add(c.dy - y * r);
    }
    final base = w.dotSize * r / 200;
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (final MapEntry(:key, value: points) in buckets.entries) {
      final argb = key ~/ _shades;
      final shade = key - argb * _shades;
      final highlighted = argb != 0;
      final color = highlighted ? Color(argb) : w.dotColor;
      // Brighter towards the viewer, fading at the limb. Highlights fade
      // less so they stay readable on light spheres.
      final depth = (shade + 1) / _shades;
      final alpha = highlighted ? 0.55 + 0.45 * depth : 0.3 + 0.7 * depth;
      paint
        ..color = color.withValues(alpha: color.a * alpha)
        ..strokeWidth = highlighted ? base * 1.45 : base;
      canvas.drawRawPoints(ui.PointMode.points, Float32List.fromList(points), paint);
    }
  }

  /// Screen point and visibility of a point at [height] above the surface
  /// along the great circle from [a] to [b] at fraction [t].
  static (Offset, bool) _arcPoint(
    _GlobeView view,
    Offset c,
    double r,
    (double, double, double) a,
    (double, double, double) b,
    double omega,
    double t,
    double height,
  ) {
    double x, y, z;
    if (omega < 1e-6) {
      (x, y, z) = a;
    } else {
      final s = math.sin(omega);
      final fa = math.sin((1 - t) * omega) / s;
      final fb = math.sin(t * omega) / s;
      x = a.$1 * fa + b.$1 * fb;
      y = a.$2 * fa + b.$2 * fb;
      z = a.$3 * fa + b.$3 * fb;
    }
    final lift = 1 + height * math.sin(math.pi * t);
    final (vx, vy, vz) = view.apply(x * lift, y * lift, z * lift);
    // Visible when in front, or poking out past the rim.
    final visible = vz >= 0 || vx * vx + vy * vy > 1;
    return (Offset(c.dx + vx * r, c.dy - vy * r), visible);
  }

  void _paintArcs(Canvas canvas, Offset c, double r, _GlobeView view) {
    final w = state.widget;
    if (w.arcs.isEmpty) return;
    final reduce = state._reduceMotion;
    final duration = _GlobeState._seconds(w.arcDuration);
    final stagger = _GlobeState._seconds(w.arcStagger);
    final hold = _GlobeState._seconds(w.arcHold);
    const fade = 0.5;
    final period = (w.arcs.length - 1) * stagger + duration + hold + fade;
    final time = w.loopArcs ? state._time % period : state._time;

    for (var i = 0; i < w.arcs.length; i++) {
      final arc = w.arcs[i];
      final local = time - i * stagger;
      double progress;
      var opacity = 1.0;
      if (reduce) {
        progress = 1;
      } else {
        if (local <= 0) continue;
        progress = Curves.easeInOut.transform((local / duration).clamp(0.0, 1.0));
        if (w.loopArcs && local > duration + hold) {
          opacity = (1 - (local - duration - hold) / fade).clamp(0.0, 1.0);
        }
      }
      if (opacity <= 0) continue;

      final a = _toXyz(arc.from);
      final b = _toXyz(arc.to);
      final dot = (a.$1 * b.$1 + a.$2 * b.$2 + a.$3 * b.$3).clamp(-1.0, 1.0);
      final omega = math.acos(dot);
      final height = math.max(0.03, arc.height * omega / math.pi);
      final color = arc.color ?? w.arcColor;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w.arcWidth
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: color.a * opacity);

      const steps = 64;
      final end = (progress * steps).ceil();
      Path? path;
      for (var s = 0; s <= end; s++) {
        final t = math.min(s / steps, progress);
        final (p, visible) = _arcPoint(view, c, r, a, b, omega, t, height);
        if (!visible) {
          if (path != null) canvas.drawPath(path, paint);
          path = null;
          continue;
        }
        if (path == null) {
          path = Path()..moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      if (path != null) canvas.drawPath(path, paint);

      // Endpoint dots.
      final (start, startVisible) = _arcPoint(view, c, r, a, b, omega, 0, height);
      final dotPaint = Paint()..color = paint.color;
      if (startVisible) canvas.drawCircle(start, w.arcWidth * 1.4, dotPaint);
      if (progress >= 1) {
        final (finish, finishVisible) = _arcPoint(view, c, r, a, b, omega, 1, height);
        if (finishVisible) canvas.drawCircle(finish, w.arcWidth * 1.4, dotPaint);
      } else if (w.showPlanes && !reduce) {
        final (head, headVisible) = _arcPoint(view, c, r, a, b, omega, progress, height);
        final (behind, _) = _arcPoint(
          view,
          c,
          r,
          a,
          b,
          omega,
          math.max(0, progress - 0.01),
          height,
        );
        if (headVisible) _paintPlane(canvas, head, head - behind, color, w.planeSize, opacity);
      }
    }
  }

  void _paintPlane(
    Canvas canvas,
    Offset at,
    Offset direction,
    Color color,
    double size,
    double opacity,
  ) {
    final angle = direction.distance < 1e-6 ? 0.0 : math.atan2(direction.dy, direction.dx);
    final s = size / 2;
    // Pointing along +x: fuselage, swept wings and tailplane.
    final plane = Path()
      ..moveTo(1.0 * s, 0)
      ..lineTo(0.55 * s, 0.1 * s)
      ..lineTo(0.05 * s, 0.12 * s)
      ..lineTo(-0.35 * s, 0.85 * s)
      ..lineTo(-0.5 * s, 0.85 * s)
      ..lineTo(-0.25 * s, 0.12 * s)
      ..lineTo(-0.7 * s, 0.12 * s)
      ..lineTo(-0.88 * s, 0.38 * s)
      ..lineTo(-1.0 * s, 0.38 * s)
      ..lineTo(-0.9 * s, 0)
      ..lineTo(-1.0 * s, -0.38 * s)
      ..lineTo(-0.88 * s, -0.38 * s)
      ..lineTo(-0.7 * s, -0.12 * s)
      ..lineTo(-0.25 * s, -0.12 * s)
      ..lineTo(-0.5 * s, -0.85 * s)
      ..lineTo(-0.35 * s, -0.85 * s)
      ..lineTo(0.05 * s, -0.12 * s)
      ..lineTo(0.55 * s, -0.1 * s)
      ..close();
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(angle);
    canvas.drawShadow(plane, const Color(0xFF000000), 2, false);
    canvas.drawPath(plane, Paint()..color = color.withValues(alpha: color.a * opacity));
    canvas.restore();
  }

  void _paintMarkers(Canvas canvas, Offset c, double r, _GlobeView view) {
    final w = state.widget;
    final reduce = state._reduceMotion;
    for (final m in w.markers) {
      final (x, y, z) = _toXyz(m.at);
      final (vx, vy, vz) = view.apply(x, y, z);
      if (vz <= 0) continue;
      final p = Offset(c.dx + vx * r, c.dy - vy * r);
      final color = m.color ?? w.markerColor;
      final fadeEdge = (vz * 4).clamp(0.0, 1.0);
      if (m.pulse && !reduce) {
        final t = state._time % 1.6 / 1.6;
        canvas.drawCircle(
          p,
          m.size * (1 + 2.2 * t),
          Paint()..color = color.withValues(alpha: color.a * 0.45 * (1 - t) * fadeEdge),
        );
      }
      canvas.drawCircle(p, m.size, Paint()..color = color.withValues(alpha: color.a * fadeEdge));
      canvas.drawCircle(
        p,
        m.size,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * fadeEdge),
      );
    }
  }

  @override
  bool shouldRepaint(_GlobePainter oldDelegate) => true;
}
