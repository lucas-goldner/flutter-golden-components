import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A slider whose track stretches like rubber when dragged past either end.
///
/// The fill eases to each new [value] on a spring and follows the pointer
/// directly while dragging. Pull past the minimum or maximum and the whole
/// track (with the [leading] or [trailing] widget on that side) stretches
/// toward the pointer, up to [maxStretch], getting thinner as it goes; let
/// go and it snaps back on [stretchSpring]. The track thickens from
/// [thickness] to [activeThickness] while hovered, dragged or focused.
///
/// Works horizontally or vertically ([axis]; vertical sliders grow upward),
/// with optional steps ([divisions], [showTicks]), a [thumb], a fill that
/// starts from an [origin] for signed values, and [leading] / [trailing]
/// widgets beside the track or [insideTrack] (like a control-center pill,
/// where they switch to [fillContentColor] as the fill passes them).
///
/// The slider is controlled: it shows [value] and reports changes through
/// [onChanged]. Arrow, Page Up/Down, Home and End keys adjust it when
/// focused. When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the fill jumps and the track snaps
/// back without bouncing.
class StretchSlider extends StatefulWidget {
  /// Creates a stretchy slider.
  const StretchSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.origin,
    this.axis = Axis.horizontal,
    this.length,
    this.thickness = 6,
    this.activeThickness = 12,
    this.radius,
    this.maxStretch = 40,
    this.stretchSpring = defaultStretchSpring,
    this.leading,
    this.trailing,
    this.insideTrack = false,
    this.showTicks = false,
    this.thumb = false,
    this.jumpOnTap = true,
    this.idleOpacity = 0.7,
    this.trackColor,
    this.fillColor,
    this.contentColor,
    this.fillContentColor,
    this.thumbColor = const Color(0xFFFFFFFF),
    this.semanticLabel,
    this.semanticFormatter,
  }) : assert(min < max),
       assert(divisions == null || divisions > 0),
       assert(thickness > 0 && activeThickness > 0),
       assert(maxStretch >= 0),
       assert(idleOpacity >= 0 && idleOpacity <= 1);

  /// A bouncy spring for the snap back.
  static const SpringDescription defaultStretchSpring = SpringDescription(
    mass: 1,
    stiffness: 400,
    damping: 14,
  );

  /// The value shown, between [min] and [max].
  final double value;

  /// Called with each new value while the user drags, taps or uses the
  /// keyboard. When null the slider is disabled.
  final ValueChanged<double>? onChanged;

  /// Called when a drag or tap starts.
  final ValueChanged<double>? onChangeStart;

  /// Called when a drag or tap ends, with the final value.
  final ValueChanged<double>? onChangeEnd;

  /// The smallest value.
  final double min;

  /// The largest value.
  final double max;

  /// Number of equal steps between [min] and [max]; values snap to them.
  final int? divisions;

  /// Where the fill starts, for signed values such as -100 to 100 with an
  /// origin of 0. Defaults to [min].
  final double? origin;

  /// Direction of the track. Vertical sliders have [min] at the bottom.
  final Axis axis;

  /// Length of the track. Defaults to the available space along [axis].
  final double? length;

  /// Track thickness at rest.
  final double thickness;

  /// Track thickness while hovered, dragged or focused.
  final double activeThickness;

  /// Corner radius of the track; defaults to fully rounded ends.
  final double? radius;

  /// How far, in logical pixels, the track can stretch past an end.
  final double maxStretch;

  /// The spring the track snaps back on after a stretch.
  final SpringDescription stretchSpring;

  /// Shown at the [min] end, usually an icon.
  final Widget? leading;

  /// Shown at the [max] end, usually an icon.
  final Widget? trailing;

  /// Whether [leading] and [trailing] sit inside the track instead of
  /// beside it. Use a thick track for this.
  final bool insideTrack;

  /// Whether to mark each of the [divisions].
  final bool showTicks;

  /// Whether to show a round thumb at the end of the fill.
  final bool thumb;

  /// Whether tapping the track jumps to that value. When false, values
  /// change only by dragging relative to where the drag started.
  final bool jumpOnTap;

  /// Opacity of the track while idle; it goes fully opaque when active.
  final double idleOpacity;

  /// Color of the empty track. Defaults to the ambient text color at 15%.
  final Color? trackColor;

  /// Color of the fill. Defaults to the ambient text color.
  final Color? fillColor;

  /// Color of [leading] and [trailing], given to them through [IconTheme]
  /// and [DefaultTextStyle]. Defaults to the ambient text color at 60%
  /// (outside) or 80% (inside).
  final Color? contentColor;

  /// Color of [leading] and [trailing] where the fill covers them, when
  /// [insideTrack]. Defaults to black or white, whichever reads on the fill.
  final Color? fillContentColor;

  /// Color of the [thumb].
  final Color thumbColor;

  /// Read out by screen readers, such as "Volume".
  final String? semanticLabel;

  /// Turns the value into text for screen readers. Defaults to a
  /// percentage of the range.
  final String Function(double value)? semanticFormatter;

  @override
  State<StretchSlider> createState() => _StretchSliderState();
}

class _StretchSliderState extends State<StretchSlider> with TickerProviderStateMixin {
  /// Fill position as a fraction of the range, eased toward the value.
  late final AnimationController _fill = AnimationController.unbounded(
    vsync: this,
    value: _fractionOf(widget.value),
  );

  /// Signed stretch in pixels: negative past [min], positive past [max].
  late final AnimationController _stretch = AnimationController.unbounded(vsync: this)
    ..addStatusListener((status) {
      // The spring stops within its tolerance; land exactly on rest.
      if (status == AnimationStatus.completed && !_dragging) _stretch.value = 0;
    });

  /// 0 at rest, 1 while hovered, dragged or focused.
  late final AnimationController _active = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );

  final FocusNode _focus = FocusNode(debugLabel: 'StretchSlider');
  final GlobalKey _trackKey = GlobalKey();

  bool _hovered = false;
  bool _focused = false;
  bool _dragging = false;

  /// For relative drags: the fraction and pointer position at drag start.
  double _dragStartFraction = 0;
  double _dragStartAlong = 0;

  bool get _enabled => widget.onChanged != null;
  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void didUpdateWidget(StretchSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _fractionOf(widget.value);
    if (_dragging || _reduceMotion) {
      _fill.value = target;
    } else if (target != _fill.value) {
      _fill.animateWith(
        SpringSimulation(
          const SpringDescription(mass: 1, stiffness: 300, damping: 30),
          _fill.value,
          target,
          _fill.velocity,
        ),
      );
    }
    if (!_enabled) _setActive(hovered: false, dragging: false);
  }

  @override
  void dispose() {
    _fill.dispose();
    _stretch.dispose();
    _active.dispose();
    _focus.dispose();
    super.dispose();
  }

  double _fractionOf(double value) =>
      ((value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  double _valueOf(double fraction) {
    var f = fraction.clamp(0.0, 1.0);
    final divisions = widget.divisions;
    if (divisions != null) f = (f * divisions).round() / divisions;
    return widget.min + f * (widget.max - widget.min);
  }

  void _setActive({bool? hovered, bool? focused, bool? dragging}) {
    _hovered = hovered ?? _hovered;
    _focused = focused ?? _focused;
    _dragging = dragging ?? _dragging;
    final on = _enabled && (_hovered || _focused || _dragging);
    if (_reduceMotion) {
      _active.value = on ? 1 : 0;
    } else if (on) {
      _active.forward();
    } else {
      _active.reverse();
    }
  }

  /// The track's length and the pointer's distance along it from the
  /// [StretchSlider.min] end.
  (double length, double along) _measure(Offset global) {
    final box = _trackKey.currentContext!.findRenderObject()! as RenderBox;
    final local = box.globalToLocal(global);
    return switch (widget.axis) {
      Axis.horizontal => (box.size.width, local.dx),
      Axis.vertical => (box.size.height, box.size.height - local.dy),
    };
  }

  /// Rubber band: the further past the end, the less each pixel stretches.
  double _rubber(double over) {
    final limit = widget.maxStretch;
    if (limit == 0) return 0;
    return limit * (1 - math.exp(-over / (limit * 2.5)));
  }

  void _emit(double value) {
    if (value != widget.value) widget.onChanged?.call(value);
  }

  void _start(Offset global) {
    final (length, along) = _measure(global);
    _setActive(dragging: true);
    _stretch.stop();
    _dragStartAlong = along;
    if (widget.jumpOnTap) {
      final value = _valueOf(along / length);
      _dragStartFraction = _fractionOf(value);
      widget.onChangeStart?.call(widget.value);
      _emit(value);
    } else {
      _dragStartFraction = _fractionOf(widget.value);
      widget.onChangeStart?.call(widget.value);
    }
  }

  void _update(Offset global) {
    final (length, along) = _measure(global);
    final raw = widget.jumpOnTap
        ? along / length
        : _dragStartFraction + (along - _dragStartAlong) / length;
    final over = raw < 0 ? raw * length : (raw > 1 ? (raw - 1) * length : 0.0);
    _stretch.value = over.sign * _rubber(over.abs());
    _emit(_valueOf(raw));
  }

  void _end() {
    _setActive(dragging: false);
    if (_reduceMotion) {
      _stretch.value = 0;
    } else if (_stretch.value != 0) {
      _stretch.animateWith(
        SpringSimulation(widget.stretchSpring, _stretch.value, 0, 0)
          ..tolerance = const Tolerance(distance: 0.1, velocity: 1),
      );
    }
    widget.onChangeEnd?.call(widget.value);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_enabled || event is KeyUpEvent) return KeyEventResult.ignored;
    final span = widget.max - widget.min;
    final step = widget.divisions != null ? span / widget.divisions! : span / 100;
    final page = math.max(step, span / 10);
    final key = event.logicalKey;
    final increase = widget.axis == Axis.horizontal
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowUp;
    final decrease = widget.axis == Axis.horizontal
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowDown;
    final double? next = switch (key) {
      _ when key == increase => widget.value + step,
      _ when key == decrease => widget.value - step,
      LogicalKeyboardKey.pageUp => widget.value + page,
      LogicalKeyboardKey.pageDown => widget.value - page,
      LogicalKeyboardKey.home => widget.min,
      LogicalKeyboardKey.end => widget.max,
      _ => null,
    };
    if (next == null) return KeyEventResult.ignored;
    _emit(_valueOf(_fractionOf(next)));
    return KeyEventResult.handled;
  }

  String _describe(double value) =>
      widget.semanticFormatter?.call(value) ?? '${(_fractionOf(value) * 100).round()}%';

  double _nudged(int direction) {
    final span = widget.max - widget.min;
    final step = widget.divisions != null ? span / widget.divisions! : span / 20;
    return _valueOf(_fractionOf(widget.value + direction * step));
  }

  @override
  Widget build(BuildContext context) {
    final ambient = DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    final fill = widget.fillColor ?? ambient;
    final colors = _Colors(
      track: widget.trackColor ?? ambient.withValues(alpha: 0.15),
      fill: fill,
      content: widget.contentColor ?? ambient.withValues(alpha: widget.insideTrack ? 0.8 : 0.6),
      fillContent: widget.fillContentColor ?? _readableOn(fill),
      thumb: widget.thumbColor,
    );
    final vertical = widget.axis == Axis.vertical;
    final crossExtent = math.max(32.0, math.max(widget.thickness, widget.activeThickness));

    Widget track = _Track(
      key: _trackKey,
      slider: widget,
      fill: _fill,
      stretch: _stretch,
      active: _active,
      colors: colors,
      crossExtent: crossExtent,
    );
    if (widget.length case final length?) {
      track = SizedBox(
        width: vertical ? null : length,
        height: vertical ? length : null,
        child: track,
      );
    }
    track = GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onTapDown: _enabled ? (d) => _start(d.globalPosition) : null,
      onTapUp: _enabled ? (_) => _end() : null,
      onHorizontalDragStart: _enabled && !vertical ? (d) => _start(d.globalPosition) : null,
      onHorizontalDragUpdate: _enabled && !vertical ? (d) => _update(d.globalPosition) : null,
      onHorizontalDragEnd: _enabled && !vertical ? (_) => _end() : null,
      onHorizontalDragCancel: _enabled && !vertical ? _end : null,
      onVerticalDragStart: _enabled && vertical ? (d) => _start(d.globalPosition) : null,
      onVerticalDragUpdate: _enabled && vertical ? (d) => _update(d.globalPosition) : null,
      onVerticalDragEnd: _enabled && vertical ? (_) => _end() : null,
      onVerticalDragCancel: _enabled && vertical ? _end : null,
      child: track,
    );

    final children = <Widget>[
      if (widget.leading case final leading? when !widget.insideTrack)
        _OutsideEnd(
          stretch: _stretch,
          axis: widget.axis,
          atMax: false,
          maxStretch: widget.maxStretch,
          color: colors.content,
          child: leading,
        ),
      Flexible(fit: widget.length == null ? FlexFit.tight : FlexFit.loose, child: track),
      if (widget.trailing case final trailing? when !widget.insideTrack)
        _OutsideEnd(
          stretch: _stretch,
          axis: widget.axis,
          atMax: true,
          maxStretch: widget.maxStretch,
          color: colors.content,
          child: trailing,
        ),
    ];
    final line = vertical
        ? Column(
            mainAxisSize: widget.length == null ? MainAxisSize.max : MainAxisSize.min,
            spacing: 10,
            children: children.reversed.toList(),
          )
        : Row(
            mainAxisSize: widget.length == null ? MainAxisSize.max : MainAxisSize.min,
            spacing: 10,
            children: children,
          );

    return Semantics(
      slider: true,
      enabled: _enabled,
      focusable: _enabled,
      label: widget.semanticLabel,
      value: _describe(widget.value),
      increasedValue: _describe(_nudged(1)),
      decreasedValue: _describe(_nudged(-1)),
      onIncrease: _enabled ? () => _emit(_nudged(1)) : null,
      onDecrease: _enabled ? () => _emit(_nudged(-1)) : null,
      child: Focus(
        focusNode: _focus,
        canRequestFocus: _enabled,
        onKeyEvent: _onKey,
        onFocusChange: (f) => _setActive(focused: f),
        child: MouseRegion(
          cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => _setActive(hovered: true),
          onExit: (_) => _setActive(hovered: false),
          child: _enabled ? line : Opacity(opacity: 0.45, child: line),
        ),
      ),
    );
  }
}

/// Black or white, whichever reads better on [background].
Color _readableOn(Color background) =>
    background.computeLuminance() > 0.45 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

@immutable
class _Colors {
  const _Colors({
    required this.track,
    required this.fill,
    required this.content,
    required this.fillContent,
    required this.thumb,
  });

  final Color track;
  final Color fill;
  final Color content;
  final Color fillContent;
  final Color thumb;
}

/// Geometry of the track at one moment, shared by its painter and the
/// widgets inside it.
@immutable
class _Geometry {
  const _Geometry({
    required this.size,
    required this.axis,
    required this.stretch,
    required this.thickness,
    required this.radius,
  });

  /// Size of the track's layout box (stretch paints beyond it).
  final Size size;
  final Axis axis;
  final double stretch;
  final double thickness;
  final double radius;

  double get length => axis == Axis.horizontal ? size.width : size.height;

  /// Where the [StretchSlider.min] and [StretchSlider.max] ends sit along the
  /// track, after stretching.
  double get start => math.min(0, stretch);
  double get end => length + math.max(0, stretch);

  /// Distance along the track of [fraction] of the range.
  double along(double fraction) => start + fraction * (end - start);

  /// The rectangle spanning [from] to [to] along the track.
  Rect span(double from, double to) {
    final lo = math.min(from, to);
    final hi = math.max(from, to);
    return switch (axis) {
      Axis.horizontal => Rect.fromLTRB(
        lo,
        (size.height - thickness) / 2,
        hi,
        (size.height + thickness) / 2,
      ),
      Axis.vertical => Rect.fromLTRB(
        (size.width - thickness) / 2,
        size.height - hi,
        (size.width + thickness) / 2,
        size.height - lo,
      ),
    };
  }

  RRect get track => RRect.fromRectAndRadius(span(start, end), Radius.circular(radius));

  /// The point at [along] on the track's centre line.
  Offset point(double along) => switch (axis) {
    Axis.horizontal => Offset(along, size.height / 2),
    Axis.vertical => Offset(size.width / 2, size.height - along),
  };
}

/// The track, fill, ticks, thumb and any inside widgets.
class _Track extends StatelessWidget {
  const _Track({
    super.key,
    required this.slider,
    required this.fill,
    required this.stretch,
    required this.active,
    required this.colors,
    required this.crossExtent,
  });

  final StretchSlider slider;
  final Animation<double> fill;
  final Animation<double> stretch;
  final Animation<double> active;
  final _Colors colors;
  final double crossExtent;

  @override
  Widget build(BuildContext context) {
    final vertical = slider.axis == Axis.vertical;
    return SizedBox(
      width: vertical ? crossExtent : null,
      height: vertical ? null : crossExtent,
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: Listenable.merge([fill, stretch, active]),
          builder: (context, _) {
            final a = Curves.easeOut.transform(active.value.clamp(0.0, 1.0));
            final base = slider.thickness + (slider.activeThickness - slider.thickness) * a;
            final pull = slider.maxStretch == 0 ? 0.0 : stretch.value.abs() / slider.maxStretch;
            // Stretching thins the track, like pulled rubber.
            final thickness = base * (1 - 0.22 * pull.clamp(0.0, 1.0));
            final geometry = _Geometry(
              size: constraints.biggest,
              axis: slider.axis,
              stretch: stretch.value,
              thickness: thickness,
              radius: math.min(slider.radius ?? thickness / 2, thickness / 2),
            );
            final originFraction = slider.origin == null
                ? 0.0
                : ((slider.origin! - slider.min) / (slider.max - slider.min)).clamp(0.0, 1.0);
            final fillRect = geometry.span(
              geometry.along(originFraction),
              geometry.along(fill.value.clamp(0.0, 1.0)),
            );
            final opacity = slider.idleOpacity + (1 - slider.idleOpacity) * a;
            return Opacity(
              opacity: opacity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TrackPainter(
                        geometry: geometry,
                        fillRect: fillRect,
                        fraction: fill.value.clamp(0.0, 1.0),
                        colors: colors,
                        divisions: slider.showTicks ? slider.divisions : null,
                        thumb: slider.thumb,
                      ),
                    ),
                  ),
                  if (slider.insideTrack) ...[
                    if (slider.leading case final leading?)
                      _InsideEnd(
                        geometry: geometry,
                        fillRect: fillRect,
                        atMax: false,
                        colors: colors,
                        child: leading,
                      ),
                    if (slider.trailing case final trailing?)
                      _InsideEnd(
                        geometry: geometry,
                        fillRect: fillRect,
                        atMax: true,
                        colors: colors,
                        child: trailing,
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({
    required this.geometry,
    required this.fillRect,
    required this.fraction,
    required this.colors,
    required this.divisions,
    required this.thumb,
  });

  final _Geometry geometry;
  final Rect fillRect;
  final double fraction;
  final _Colors colors;
  final int? divisions;
  final bool thumb;

  @override
  void paint(Canvas canvas, Size size) {
    final track = geometry.track;
    canvas.drawRRect(track, Paint()..color = colors.track);
    canvas
      ..save()
      ..clipRRect(track)
      ..drawRect(fillRect, Paint()..color = colors.fill)
      ..restore();

    if (divisions case final count?) {
      final dot = math.max(1.5, geometry.thickness * 0.14);
      for (var i = 0; i <= count; i++) {
        final center = geometry.point(geometry.along(i / count));
        final covered = fillRect.inflate(0.5).contains(center);
        canvas.drawCircle(
          center,
          dot,
          Paint()..color = (covered ? colors.fillContent : colors.fill).withValues(alpha: 0.55),
        );
      }
    }

    if (thumb) {
      final center = geometry.point(geometry.along(fraction));
      final radius = (geometry.thickness + 8).clamp(16.0, 28.0) / 2;
      canvas
        ..drawCircle(
          center + const Offset(0, 1),
          radius + 1,
          Paint()
            ..color = const Color(0x40000000)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
        )
        ..drawCircle(center, radius, Paint()..color = colors.thumb)
        ..drawCircle(
          center,
          radius,
          Paint()
            ..color = const Color(0x1F000000)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.75,
        );
    }
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.geometry != geometry ||
      old.fillRect != fillRect ||
      old.fraction != fraction ||
      old.colors != colors ||
      old.divisions != divisions ||
      old.thumb != thumb;
}

/// A [StretchSlider.leading] or [StretchSlider.trailing] widget inside the
/// track, drawn in the content color with the fill-covered part in the
/// fill content color.
class _InsideEnd extends StatelessWidget {
  const _InsideEnd({
    required this.geometry,
    required this.fillRect,
    required this.atMax,
    required this.colors,
    required this.child,
  });

  final _Geometry geometry;
  final Rect fillRect;
  final bool atMax;
  final _Colors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // A square cell the size of the track's thickness, at its end.
    final cell = geometry.thickness;
    final along = atMax ? geometry.end - cell / 2 : geometry.start + cell / 2;
    final rect = Rect.fromCenter(center: geometry.point(along), width: cell, height: cell);
    return Positioned.fromRect(
      rect: rect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Tinted(
            color: colors.content,
            child: Center(child: child),
          ),
          ClipRect(
            clipper: _RectClipper(fillRect.shift(-rect.topLeft)),
            child: _Tinted(
              color: colors.fillContent,
              child: Center(child: child),
            ),
          ),
        ],
      ),
    );
  }
}

/// A [StretchSlider.leading] or [StretchSlider.trailing] widget beside the
/// track; it follows a stretch on its side and grows a little with it.
class _OutsideEnd extends StatelessWidget {
  const _OutsideEnd({
    required this.stretch,
    required this.axis,
    required this.atMax,
    required this.maxStretch,
    required this.color,
    required this.child,
  });

  final Animation<double> stretch;
  final Axis axis;
  final bool atMax;
  final double maxStretch;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: stretch,
      builder: (context, child) {
        final s = stretch.value;
        final mine = atMax ? math.max(0.0, s) : math.min(0.0, s);
        final pull = maxStretch == 0 ? 0.0 : (mine.abs() / maxStretch).clamp(0.0, 1.0);
        final offset = axis == Axis.horizontal ? Offset(mine, 0) : Offset(0, -mine);
        return Transform.translate(
          offset: offset,
          child: Transform.scale(scale: 1 + 0.25 * pull, child: child),
        );
      },
      child: _Tinted(color: color, child: child),
    );
  }
}

/// Gives [child] a color through [IconTheme] and [DefaultTextStyle].
class _Tinted extends StatelessWidget {
  const _Tinted({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IconTheme.merge(
      data: IconThemeData(color: color),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: color),
        child: child,
      ),
    );
  }
}

class _RectClipper extends CustomClipper<Rect> {
  const _RectClipper(this.rect);

  final Rect rect;

  @override
  Rect getClip(Size size) => rect;

  @override
  bool shouldReclip(_RectClipper old) => old.rect != rect;
}
