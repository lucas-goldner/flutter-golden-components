import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Cards on the faces of a 3D cylinder that you spin by dragging.
///
/// The [cards] sit side by side around a cylinder whose circumference is
/// [circumference], seen in perspective, so the front card faces you and
/// the others turn away toward the back. Drag sideways and the front card
/// follows your finger; let go and the cylinder coasts with the fling and,
/// with [snap], settles on the nearest card. Arrow keys turn it one card at
/// a time. Tapping a card calls [onCardTap] and, with [lightbox], opens it
/// large in an overlay that a second tap closes.
///
/// When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) turns and the lightbox happen
/// without animation.
class CylinderCarousel extends StatefulWidget {
  /// Creates a cylinder carousel.
  const CylinderCarousel({
    super.key,
    required this.cards,
    this.height = 420,
    this.circumference,
    this.perspective = 0.001,
    this.gap = 8,
    this.radius = 12,
    this.snap = true,
    this.lightbox = true,
    this.lightboxAspectRatio = 2 / 3,
    this.background = const Color(0xFF161618),
    this.onCardTap,
    this.onFrontChanged,
  });

  /// The card faces, around the cylinder. Each is shown square.
  final List<Widget> cards;

  /// Height of the stage.
  final double height;

  /// Distance around the cylinder; each card gets an equal share of it.
  /// Defaults to 1100 on narrow stages (640 or less) and 1800 otherwise.
  final double? circumference;

  /// Strength of the perspective: larger values look closer and more
  /// distorted.
  final double perspective;

  /// Space around each card on its face.
  final double gap;

  /// Corner radius of the cards.
  final double radius;

  /// Whether the cylinder settles with a card facing the front.
  final bool snap;

  /// Whether tapping a card opens it large in an overlay.
  final bool lightbox;

  /// Width / height of a card in the lightbox.
  final double lightboxAspectRatio;

  /// Stage color, also used behind each card.
  final Color background;

  /// Called with the index of a tapped card.
  final ValueChanged<int>? onCardTap;

  /// Called with the index of the card that settles at the front.
  final ValueChanged<int>? onFrontChanged;

  @override
  State<CylinderCarousel> createState() => _CylinderCarouselState();
}

class _CylinderCarouselState extends State<CylinderCarousel> with TickerProviderStateMixin {
  /// Rotation in degrees; card i faces front at -i * (360 / n).
  late final AnimationController _turn = AnimationController.unbounded(vsync: this);

  /// The lightbox, 0 closed to 1 open.
  late final AnimationController _box = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  int? _open;
  int _front = 0;

  /// Where the current spin is heading, so quick key presses add up.
  double _target = 0;

  /// Degrees per pixel of drag, so the front card tracks the finger.
  double _degreesPerPixel = 0.2;

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  double get _step => widget.cards.isEmpty ? 360 : 360 / widget.cards.length;

  @override
  void initState() {
    super.initState();
    _turn.addStatusListener((status) {
      if (status == AnimationStatus.completed) _settled();
    });
    _box.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) setState(() => _open = null);
    });
  }

  @override
  void dispose() {
    _turn.dispose();
    _box.dispose();
    super.dispose();
  }

  void _settled() {
    final n = widget.cards.length;
    if (n == 0) return;
    final front = (-_turn.value / _step).round() % n;
    if (front != _front) {
      _front = front;
      widget.onFrontChanged?.call(front);
    }
  }

  /// Spins to [target] degrees with an initial [velocity] (degrees/s).
  void _spinTo(double target, [double velocity = 0]) {
    _target = target;
    if (_reduceMotion) {
      _turn.value = target;
      _settled();
      return;
    }
    _turn.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 120, damping: 22),
        _turn.value,
        target,
        velocity,
      ),
    );
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _turn.value += d.delta.dx * _degreesPerPixel;
  }

  void _onDragEnd(DragEndDetails d) {
    final velocity = d.velocity.pixelsPerSecond.dx * _degreesPerPixel;
    // Where a friction-damped coast would stop.
    var target = _turn.value + velocity * 0.35;
    if (widget.snap) target = (target / _step).roundToDouble() * _step;
    _spinTo(target, velocity);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _open != null) return KeyEventResult.ignored;
    final dir = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => 1,
      LogicalKeyboardKey.arrowRight => -1,
      _ => 0,
    };
    if (dir == 0) return KeyEventResult.ignored;
    final from = _turn.isAnimating ? _target : _turn.value;
    final base = (from / _step).roundToDouble() * _step;
    _spinTo(base + dir * _step);
    return KeyEventResult.handled;
  }

  void _tapCard(int i) {
    widget.onCardTap?.call(i);
    if (!widget.lightbox) return;
    _turn.stop();
    setState(() => _open = i);
    _reduceMotion ? _box.value = 1 : _box.forward(from: 0);
  }

  void _closeBox() => _reduceMotion ? _box.value = 0 : _box.reverse();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final circumference =
              widget.circumference ?? (constraints.maxWidth <= 640 ? 1100.0 : 1800.0);
          _degreesPerPixel = 360 / circumference;
          return ClipRect(
            child: ColoredBox(
              color: widget.background,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Focus(
                    onKeyEvent: _onKey,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: _open == null ? (_) => _turn.stop() : null,
                      onHorizontalDragUpdate: _open == null ? _onDragUpdate : null,
                      onHorizontalDragEnd: _open == null ? _onDragEnd : null,
                      child: MouseRegion(
                        cursor: _open == null ? SystemMouseCursors.grab : MouseCursor.defer,
                        child: AnimatedBuilder(
                          animation: _turn,
                          builder: (context, _) => _Cylinder(
                            cards: widget.cards,
                            rotation: _turn.value,
                            circumference: circumference,
                            perspective: widget.perspective,
                            gap: widget.gap,
                            radius: widget.radius,
                            background: widget.background,
                            onTap: _open == null ? _tapCard : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_open case final open?)
                    _Lightbox(
                      animation: _box,
                      aspectRatio: widget.lightboxAspectRatio,
                      narrow: constraints.maxWidth <= 640,
                      onClose: _closeBox,
                      child: widget.cards[open],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The cards placed around the cylinder, back to front.
class _Cylinder extends StatelessWidget {
  const _Cylinder({
    required this.cards,
    required this.rotation,
    required this.circumference,
    required this.perspective,
    required this.gap,
    required this.radius,
    required this.background,
    required this.onTap,
  });

  final List<Widget> cards;
  final double rotation;
  final double circumference;
  final double perspective;
  final double gap;
  final double radius;
  final Color background;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final n = cards.length;
    if (n == 0) return const SizedBox.shrink();
    final faceWidth = circumference / n;
    final r = circumference / (2 * math.pi);
    final faces = <(double, Widget)>[];
    for (var i = 0; i < n; i++) {
      final angle = (rotation + i * 360 / n) * math.pi / 180;
      final depth = math.cos(angle);
      // Faces turned away are hidden: only the front half is drawn.
      if (depth < -0.1) continue;
      faces.add((
        depth,
        Center(
          child: Transform(
            alignment: Alignment.center,
            // Turn about the cylinder's axis, r behind the front card, so
            // the front card keeps its natural size and the rest recede.
            transform: Matrix4.identity()
              ..setEntry(3, 2, perspective)
              ..translateByDouble(0, 0, r, 1)
              ..rotateY(-angle)
              ..translateByDouble(0, 0, -r, 1),
            child: SizedBox(
              width: faceWidth,
              child: Semantics(
                button: onTap != null,
                label: 'Card ${i + 1} of $n',
                child: GestureDetector(
                  onTap: onTap == null ? null : () => onTap!(i),
                  child: Container(
                    padding: EdgeInsets.all(gap),
                    color: background,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: AspectRatio(aspectRatio: 1, child: cards[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
    }
    // Farthest first, so nearer cards paint over them.
    faces.sort((a, b) => a.$1.compareTo(b.$1));
    return Stack(fit: StackFit.expand, children: [for (final f in faces) f.$2]);
  }
}

/// A tapped card, large, over a dimmed stage.
class _Lightbox extends StatelessWidget {
  const _Lightbox({
    required this.animation,
    required this.aspectRatio,
    required this.narrow,
    required this.onClose,
    required this.child,
  });

  final Animation<double> animation;
  final double aspectRatio;
  final bool narrow;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = const Cubic(0.32, 0.72, 0, 1).transform(animation.value);
            // The card grows in the second half of the opening.
            final grow = Curves.easeOut.transform(((animation.value - 0.4) / 0.6).clamp(0.0, 1.0));
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.85 + 0.15 * t,
                child: Container(
                  margin: narrow
                      ? const EdgeInsets.all(20)
                      : const EdgeInsets.symmetric(horizontal: 72, vertical: 36),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xF0000000),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: 0.5 + 0.5 * grow,
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000),
                              blurRadius: 16,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(borderRadius: BorderRadius.circular(10), child: child),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
