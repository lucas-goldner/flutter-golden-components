import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A card that tilts in 3D toward the pointer.
///
/// While the pointer (or a finger) moves over the card it turns toward it,
/// up to [maxTilt] degrees on each axis, rising slightly to [hoverScale];
/// when the pointer leaves it eases back flat. The motion follows the
/// pointer through a soft spring, so quick movements are smoothed out.
///
/// Wrap parts of [child] in [TiltLayer] to give them depth: a layer with a
/// larger [TiltLayer.depth] shifts further as the card tilts, so it seems
/// to float above the card. With [glare] a soft highlight slides across the
/// card opposite the pointer, like light on glossy paper.
///
/// When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the card stays flat.
class TiltCard extends StatefulWidget {
  /// Creates a tilting card.
  const TiltCard({
    super.key,
    required this.child,
    this.maxTilt = 12,
    this.hoverScale = 1.03,
    this.perspective = 0.0012,
    this.glare = true,
    this.glareOpacity = 0.25,
    this.radius = 20,
    this.stiffness = 14,
    this.onTap,
  }) : assert(maxTilt >= 0),
       assert(stiffness > 0);

  /// The card's content; parts wrapped in [TiltLayer] float above it.
  final Widget child;

  /// Largest rotation on each axis, in degrees.
  final double maxTilt;

  /// Scale of the card while the pointer is over it.
  final double hoverScale;

  /// Strength of the 3D perspective.
  final double perspective;

  /// Whether a highlight slides across the card opposite the pointer.
  final bool glare;

  /// Opacity of the highlight at its brightest.
  final double glareOpacity;

  /// Corner radius the glare is clipped to; match your card's.
  final double radius;

  /// How quickly the card follows the pointer; higher is snappier.
  final double stiffness;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

/// The pointer's place over the card, -1..1 on each axis, and how much the
/// card is engaged (0 at rest, 1 while hovered).
@immutable
class _Pose {
  const _Pose(this.x, this.y, this.engaged);

  static const _Pose rest = _Pose(0, 0, 0);

  final double x;
  final double y;
  final double engaged;
}

class _TiltCardState extends State<TiltCard> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<_Pose> _pose = ValueNotifier(_Pose.rest);
  Duration _last = Duration.zero;

  /// Where the pose is heading.
  _Pose _target = _Pose.rest;

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void dispose() {
    _ticker.dispose();
    _pose.dispose();
    super.dispose();
  }

  void _aim(Offset local, Size size) {
    if (_reduceMotion || size.isEmpty) return;
    _target = _Pose(
      (local.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
      (local.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
      1,
    );
    _start();
  }

  void _release() {
    _target = _Pose.rest;
    _start();
  }

  void _start() {
    if (_ticker.isActive) return;
    _last = Duration.zero;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    // Exponential smoothing: frame-rate independent and never overshoots.
    final k = 1 - math.exp(-widget.stiffness * dt.clamp(0.0, 0.1));
    final p = _pose.value;
    final next = _Pose(
      p.x + (_target.x - p.x) * k,
      p.y + (_target.y - p.y) * k,
      p.engaged + (_target.engaged - p.engaged) * k,
    );
    final settled =
        (next.x - _target.x).abs() < 0.001 &&
        (next.y - _target.y).abs() < 0.001 &&
        (next.engaged - _target.engaged).abs() < 0.001;
    _pose.value = settled ? _target : next;
    if (settled) _ticker.stop();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (e) => _aim(e.localPosition, context.size ?? Size.zero),
          onExit: (_) => _release(),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onTap,
            onPanStart: (d) => _aim(d.localPosition, context.size ?? Size.zero),
            onPanUpdate: (d) => _aim(d.localPosition, context.size ?? Size.zero),
            onPanEnd: (_) => _release(),
            onPanCancel: _release,
            child: _TiltScope(
              pose: _pose,
              maxTilt: widget.maxTilt,
              child: AnimatedBuilder(
                animation: _pose,
                child: widget.child,
                builder: (context, child) {
                  final pose = _pose.value;
                  final rad = widget.maxTilt * math.pi / 180;
                  final scale = 1 + (widget.hoverScale - 1) * pose.engaged;
                  // Pointer to the right turns the right edge away; pointer
                  // below tips the bottom edge away.
                  final transform = Matrix4.identity()
                    ..setEntry(3, 2, widget.perspective)
                    ..rotateX(pose.y * rad)
                    ..rotateY(-pose.x * rad)
                    ..scaleByDouble(scale, scale, 1, 1);
                  return Transform(
                    alignment: Alignment.center,
                    transform: transform,
                    child: widget.glare
                        ? Stack(
                            children: [
                              child!,
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: _Glare(
                                    pose: pose,
                                    opacity: widget.glareOpacity,
                                    radius: widget.radius,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : child,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A soft white highlight, opposite the pointer, brighter when engaged.
class _Glare extends StatelessWidget {
  const _Glare({required this.pose, required this.opacity, required this.radius});

  final _Pose pose;
  final double opacity;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (pose.engaged < 0.01) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-pose.x, -pose.y),
            radius: 1.1,
            colors: [
              const Color(0xFFFFFFFF).withValues(alpha: opacity * pose.engaged),
              const Color(0x00FFFFFF),
            ],
          ),
        ),
      ),
    );
  }
}

class _TiltScope extends InheritedWidget {
  const _TiltScope({required this.pose, required this.maxTilt, required super.child});

  final ValueListenable<_Pose> pose;
  final double maxTilt;

  @override
  bool updateShouldNotify(_TiltScope old) => old.pose != pose || old.maxTilt != maxTilt;
}

/// Part of a [TiltCard] that floats above it.
///
/// As the card tilts, the layer shifts away from the pointer by [depth]
/// logical pixels at full tilt, so deeper layers seem to hover higher over the
/// card. Outside a [TiltCard] it shows [child] unchanged.
class TiltLayer extends StatelessWidget {
  /// Creates a floating layer.
  const TiltLayer({super.key, required this.child, this.depth = 20});

  /// The floating content.
  final Widget child;

  /// How far the layer shifts at full tilt; larger looks higher.
  final double depth;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_TiltScope>();
    if (scope == null) return child;
    return ValueListenableBuilder<_Pose>(
      valueListenable: scope.pose,
      child: child,
      builder: (context, pose, child) => Transform.translate(
        // Away from the pointer, toward the edge that lifts: a raised layer
        // stays over the card instead of sliding off it.
        offset: Offset(-pose.x * depth, -pose.y * depth),
        child: child,
      ),
    );
  }
}
