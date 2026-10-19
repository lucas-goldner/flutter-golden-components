import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// An endlessly scrolling strip of widgets.
///
/// [children] are laid out in a row (or a column when [axis] is vertical),
/// separated by [gap], and that group is repeated as often as needed to fill
/// the viewport, so the strip loops seamlessly at any width.
///
/// It moves at a constant [speed] regardless of how long the content is.
/// With [pauseOnHover] it eases to a stop while hovered or touched, and it
/// stays still when the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]). Only the first copy is exposed to
/// accessibility.
class Marquee extends StatefulWidget {
  /// Creates a marquee.
  const Marquee({
    super.key,
    required this.children,
    this.axis = Axis.horizontal,
    this.reverse = false,
    this.speed = 40,
    this.gap = 16,
    this.pauseOnHover = false,
    this.fadeExtent = 0,
  }) : assert(speed >= 0),
       assert(gap >= 0),
       assert(fadeExtent >= 0);

  /// Content of one copy of the strip.
  final List<Widget> children;

  /// Direction the strip is laid out and scrolls in.
  final Axis axis;

  /// Scroll right (or down) instead of left (or up).
  final bool reverse;

  /// Scroll speed in logical pixels per second.
  final double speed;

  /// Spacing between items, and between copies.
  final double gap;

  /// Ease to a stop while the pointer hovers, or a finger rests on, the strip.
  final bool pauseOnHover;

  /// Length of the fade to transparent at both ends; 0 disables it.
  final double fadeExtent;

  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);

  /// Total distance scrolled; the track wraps it by the copy length.
  final ValueNotifier<double> _distance = ValueNotifier(0);

  /// Current speed, easing towards [widget.speed] or 0 while paused.
  double _velocity = 0;

  /// Timestamp of the previous tick; null right after (re)starting.
  Duration? _last;
  bool _hovered = false;
  bool _reduceMotion = false;

  /// Copies of [Marquee.children] currently laid out; grows to fill the
  /// viewport once the track has measured one copy.
  int _copies = 2;

  double get _targetSpeed => (_hovered && widget.pauseOnHover) || _reduceMotion ? 0 : widget.speed;

  @override
  void initState() {
    super.initState();
    _velocity = widget.speed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduceMotion) _velocity = 0;
    _syncTicker();
  }

  @override
  void didUpdateWidget(Marquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _distance.dispose();
    super.dispose();
  }

  /// Runs the ticker only while there is motion to show.
  void _syncTicker() {
    final moving = _targetSpeed > 0 || _velocity > 0.5;
    if (moving && !_ticker.isActive) {
      _last = null;
      _ticker.start();
    } else if (!moving && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final last = _last;
    final dt = last == null ? 0.0 : (elapsed - last).inMicroseconds / 1e6;
    _last = elapsed;
    // Ease the speed with a ~0.15 s time constant so pausing feels soft.
    _velocity += (_targetSpeed - _velocity) * (1 - math.exp(-dt / 0.15));
    if (_targetSpeed == 0 && _velocity < 0.5) _velocity = 0;
    _distance.value += _velocity * dt;
    if (_velocity == 0 && _targetSpeed == 0) _ticker.stop();
  }

  void _setHovered(bool hovered) {
    if (_hovered == hovered) return;
    _hovered = hovered;
    _syncTicker();
  }

  void _onMeasured(double period, double viewport) {
    if (period <= 0) return;
    final needed = math.max(2, (viewport / period).ceil() + 1);
    if (needed == _copies) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _copies = needed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.axis == Axis.horizontal;
    Widget track = _MarqueeTrack(
      axis: widget.axis,
      gap: widget.gap,
      reverse: widget.reverse,
      distance: _distance,
      onMeasured: _onMeasured,
      children: [
        for (var i = 0; i < _copies; i++)
          _MarqueeCopy(
            axis: widget.axis,
            gap: widget.gap,
            hidden: i > 0,
            children: widget.children,
          ),
      ],
    );
    if (widget.fadeExtent > 0) {
      track = _EdgeFade(horizontal: horizontal, extent: widget.fadeExtent, child: track);
    }
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Listener(
        onPointerDown: (e) {
          if (e.kind != PointerDeviceKind.mouse) _setHovered(true);
        },
        onPointerUp: (e) {
          if (e.kind != PointerDeviceKind.mouse) _setHovered(false);
        },
        onPointerCancel: (e) {
          if (e.kind != PointerDeviceKind.mouse) _setHovered(false);
        },
        child: ClipRect(child: track),
      ),
    );
  }
}

/// One copy of the content: items in a row or column, separated by gaps.
class _MarqueeCopy extends StatelessWidget {
  const _MarqueeCopy({
    required this.axis,
    required this.gap,
    required this.hidden,
    required this.children,
  });

  final Axis axis;
  final double gap;

  /// Hide from accessibility (repeated copies).
  final bool hidden;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: hidden,
      child: Flex(
        direction: axis,
        mainAxisSize: MainAxisSize.min,
        spacing: gap,
        children: children,
      ),
    );
  }
}

/// Fades both ends of [child] to transparent.
class _EdgeFade extends StatelessWidget {
  const _EdgeFade({required this.horizontal, required this.extent, required this.child});

  final bool horizontal;
  final double extent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final length = horizontal ? bounds.width : bounds.height;
        final f = length <= 0 ? 0.0 : (extent / length).clamp(0.0, 0.5);
        return LinearGradient(
          begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
          end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
          colors: const [
            Color(0x00000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0x00000000),
          ],
          stops: [0, f, 1 - f, 1],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}

/// Lays out copies end to end and shifts them by the scrolled distance,
/// wrapped by one copy's length, without relayout.
class _MarqueeTrack extends MultiChildRenderObjectWidget {
  const _MarqueeTrack({
    required this.axis,
    required this.gap,
    required this.reverse,
    required this.distance,
    required this.onMeasured,
    required super.children,
  });

  final Axis axis;
  final double gap;
  final bool reverse;
  final ValueListenable<double> distance;
  final void Function(double period, double viewport) onMeasured;

  @override
  _RenderMarqueeTrack createRenderObject(BuildContext context) => _RenderMarqueeTrack(
    axis: axis,
    gap: gap,
    reverse: reverse,
    distance: distance,
    onMeasured: onMeasured,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderMarqueeTrack renderObject) {
    renderObject
      ..axis = axis
      ..gap = gap
      ..reverse = reverse
      ..distance = distance
      ..onMeasured = onMeasured;
  }
}

class _MarqueeParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderMarqueeTrack extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _MarqueeParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _MarqueeParentData> {
  _RenderMarqueeTrack({
    required Axis axis,
    required double gap,
    required bool reverse,
    required ValueListenable<double> distance,
    required this.onMeasured,
  }) : _axis = axis,
       _gap = gap,
       _reverse = reverse,
       _distance = distance;

  void Function(double period, double viewport) onMeasured;

  Axis _axis;
  set axis(Axis value) {
    if (value == _axis) return;
    _axis = value;
    markNeedsLayout();
  }

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  bool _reverse;
  set reverse(bool value) {
    if (value == _reverse) return;
    _reverse = value;
    _onScroll();
  }

  ValueListenable<double> _distance;
  set distance(ValueListenable<double> value) {
    if (value == _distance) return;
    if (attached) _distance.removeListener(_onScroll);
    _distance = value;
    if (attached) _distance.addListener(_onScroll);
    _onScroll();
  }

  bool get _horizontal => _axis == Axis.horizontal;
  double _main(Size s) => _horizontal ? s.width : s.height;
  double _cross(Size s) => _horizontal ? s.height : s.width;

  void _onScroll() {
    _positionChildren();
    markNeedsPaint();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _MarqueeParentData) child.parentData = _MarqueeParentData();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _distance.addListener(_onScroll);
  }

  @override
  void detach() {
    _distance.removeListener(_onScroll);
    super.detach();
  }

  @override
  void performLayout() {
    final childConstraints = _horizontal
        ? BoxConstraints(maxHeight: constraints.maxHeight)
        : BoxConstraints(maxWidth: constraints.maxWidth);
    var cross = 0.0;
    var total = 0.0;
    var period = 0.0;
    var child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      cross = math.max(cross, _cross(child.size));
      period = _main(child.size) + _gap;
      total += period;
      child = childAfter(child);
    }
    final mainMax = _horizontal ? constraints.maxWidth : constraints.maxHeight;
    final main = mainMax.isFinite ? mainMax : math.max(0.0, total - _gap);
    size = constraints.constrain(_horizontal ? Size(main, cross) : Size(cross, main));
    _positionChildren();
    onMeasured(period, _main(size));
  }

  void _positionChildren() {
    final first = firstChild;
    if (!hasSize || first == null) return;
    final period = _main(first.size) + _gap;
    if (period <= 0) return;
    final wrapped = _distance.value % period;
    // Forward: slide towards the start. Reverse: start one copy early and
    // slide towards the end.
    var pos = _reverse ? wrapped - period : -wrapped;
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _MarqueeParentData;
      final crossOffset = (_cross(size) - _cross(child.size)) / 2;
      data.offset = _horizontal ? Offset(pos, crossOffset) : Offset(crossOffset, pos);
      pos += _main(child.size) + _gap;
      child = childAfter(child);
    }
  }

  double _maxCross() {
    var extent = 0.0;
    var child = firstChild;
    while (child != null) {
      extent = math.max(
        extent,
        _horizontal
            ? child.getMaxIntrinsicHeight(double.infinity)
            : child.getMaxIntrinsicWidth(double.infinity),
      );
      child = childAfter(child);
    }
    return extent;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _horizontal ? _maxCross() : 0;

  @override
  double computeMaxIntrinsicHeight(double width) => _horizontal ? _maxCross() : 0;

  @override
  double computeMinIntrinsicWidth(double height) => _horizontal ? 0 : _maxCross();

  @override
  double computeMaxIntrinsicWidth(double height) => _horizontal ? 0 : _maxCross();

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);
}
