import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

const Cubic _easeOutQuint = Cubic(0.23, 1, 0.32, 1);

/// A card whose media has notched corners: labels set into the image with
/// concave fillets, so they look cut out of it.
///
/// Put a [NotchCardMedia] (with its [NotchLabel]s) and your content in
/// [child]. The card tracks hover from the pointer (on touch, a tap toggles
/// it), and its parts react: the media zooms in, [NotchCardReveal]s appear
/// and the card's shadow deepens. Read the state anywhere below with
/// [NotchCard.hoveredOf]. The card fades in when first shown.
///
/// When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) nothing zooms, slides or fades in.
class NotchCard extends StatefulWidget {
  /// Creates a notched card.
  const NotchCard({
    super.key,
    required this.child,
    this.hovered,
    this.onHoverChanged,
    this.onTap,
    this.radius = 28,
    this.color,
    this.borderColor,
  });

  /// The card's content, usually a [Column] with a [NotchCardMedia] on top.
  final Widget child;

  /// Hover state controlled from outside; when null the card tracks it.
  final bool? hovered;

  /// Called when the hover state changes.
  final ValueChanged<bool>? onHoverChanged;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Corner radius of the card.
  final double radius;

  /// Card surface. Defaults to white, or near-black when the ambient text
  /// is light.
  final Color? color;

  /// Hairline border. Defaults to the ambient text color at 10%.
  final Color? borderColor;

  /// Whether the nearest [NotchCard] above [context] is hovered.
  static bool hoveredOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HoverScope>()?.hovered ?? false;

  /// The surface color of the nearest [NotchCard], for labels that should
  /// look cut out of it.
  static Color surfaceOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HoverScope>()?.surface ?? const Color(0xFFFFFFFF);

  @override
  State<NotchCard> createState() => _NotchCardState();
}

class _HoverScope extends InheritedWidget {
  const _HoverScope({required this.hovered, required this.surface, required super.child});

  final bool hovered;
  final Color surface;

  @override
  bool updateShouldNotify(_HoverScope old) => old.hovered != hovered || old.surface != surface;
}

class _NotchCardState extends State<NotchCard> {
  bool _hovered = false;

  bool get _effective => widget.hovered ?? _hovered;

  void _set(bool value) {
    if (value == _effective) return;
    if (widget.hovered == null) setState(() => _hovered = value);
    widget.onHoverChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final ink = DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    final dark = ink.computeLuminance() > 0.5;
    final surface = widget.color ?? (dark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF));
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final hovered = _effective;
    final shadow = dark ? const Color(0xFF000000) : const Color(0xFF09090B);
    final lift = hovered ? 2.0 : 1.0;
    return _HoverScope(
      hovered: hovered,
      surface: surface,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduce ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 360),
        curve: _easeOutQuint,
        builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => _set(true),
          onExit: (_) => _set(false),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              // Touch has no hover: a tap toggles it instead.
              _set(!_effective);
              widget.onTap?.call();
            },
            child: AnimatedContainer(
              duration: reduce ? Duration.zero : const Duration(milliseconds: 500),
              curve: _easeOutQuint,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(widget.radius),
                border: Border.all(
                  color: widget.borderColor ?? ink.withValues(alpha: hovered ? 0.14 : 0.09),
                ),
                boxShadow: [
                  for (final (blur, y, a) in const [
                    (2.0, 1.0, 0.08),
                    (8.0, 4.0, 0.06),
                    (16.0, 8.0, 0.05),
                  ])
                    BoxShadow(
                      color: shadow.withValues(alpha: a * (dark ? 3 : 1)),
                      blurRadius: blur * lift,
                      spreadRadius: -blur / 4,
                      offset: Offset(0, y * lift),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.radius - 1),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A corner of a [NotchCardMedia].
enum NotchCorner {
  /// The top left corner.
  topLeft,

  /// The top right corner.
  topRight,

  /// The bottom left corner.
  bottomLeft,

  /// The bottom right corner.
  bottomRight;

  bool get _top => this == topLeft || this == topRight;
  bool get _left => this == topLeft || this == bottomLeft;
}

/// A label set into a corner of a [NotchCardMedia], joined to the media's
/// edges by concave fillets so it looks cut out of the image.
@immutable
class NotchLabel {
  /// Creates a notched label.
  const NotchLabel({
    required this.corner,
    required this.child,
    this.color,
    this.radius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
  });

  /// Which corner the label sits in.
  final NotchCorner corner;

  /// The label's content.
  final Widget child;

  /// Label (and fillet) color. Defaults to the card's surface, which makes
  /// the label read as a notch cut out of the image.
  final Color? color;

  /// Radius of the fillets and of the label's inner corner.
  final double radius;

  /// Space around [child].
  final EdgeInsets padding;
}

/// The media of a [NotchCard]: [child] fills it and zooms in while the card
/// is hovered, with [labels] notched into its corners and an optional
/// bottom-up [wash] in the card's surface color.
class NotchCardMedia extends StatelessWidget {
  /// Creates the card media.
  const NotchCardMedia({
    super.key,
    required this.child,
    this.height = 280,
    this.labels = const [],
    this.zoom = 1.05,
    this.wash = 0.35,
  });

  /// The image or other media.
  final Widget child;

  /// Height of the media.
  final double height;

  /// Labels notched into the corners.
  final List<NotchLabel> labels;

  /// Scale of the media while the card is hovered.
  final double zoom;

  /// Opacity of the surface-colored wash rising from the bottom (0 for
  /// none).
  final double wash;

  @override
  Widget build(BuildContext context) {
    final hovered = NotchCard.hoveredOf(context);
    final surface = NotchCard.surfaceOf(context);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          ClipRect(
            child: AnimatedScale(
              scale: hovered && !reduce ? zoom : 1,
              duration: const Duration(milliseconds: 700),
              curve: _easeOutQuint,
              child: child,
            ),
          ),
          if (wash > 0)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      surface.withValues(alpha: wash),
                      surface.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.5],
                  ),
                ),
              ),
            ),
          for (final label in labels)
            Align(
              alignment: Alignment(label.corner._left ? -1 : 1, label.corner._top ? -1 : 1),
              child: _Notch(label: label, color: label.color ?? surface),
            ),
        ],
      ),
    );
  }
}

/// A label box with a fillet along each media edge it touches.
class _Notch extends StatelessWidget {
  const _Notch({required this.label, required this.color});

  final NotchLabel label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final r = label.radius;
    final top = label.corner._top;
    final left = label.corner._left;
    // Fillets overlap the label by a pixel so no seam shows.
    final out = -r + 1;
    // The corner of each fillet square that touches both the media edge and
    // the label is the one that is filled.
    final filled = Alignment(left ? -1 : 1, top ? -1 : 1);
    final inner = Radius.circular(r);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: label.padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: !top && !left ? inner : Radius.zero,
              topRight: !top && left ? inner : Radius.zero,
              bottomLeft: top && !left ? inner : Radius.zero,
              bottomRight: top && left ? inner : Radius.zero,
            ),
          ),
          child: label.child,
        ),
        // Along the side edge, past the label.
        Positioned(
          left: left ? 0 : null,
          right: left ? null : 0,
          top: top ? null : out,
          bottom: top ? out : null,
          child: _Fillet(size: r, color: color, filled: filled),
        ),
        // Along the top or bottom edge, past the label.
        Positioned(
          top: top ? 0 : null,
          bottom: top ? null : 0,
          left: left ? null : out,
          right: left ? out : null,
          child: _Fillet(size: r, color: color, filled: filled),
        ),
      ],
    );
  }
}

/// A square of [size] with a quarter circle scooped out of it, leaving the
/// [filled] corner solid: an inverted rounded corner.
class _Fillet extends StatelessWidget {
  const _Fillet({required this.size, required this.color, required this.filled});

  final double size;
  final Color color;
  final Alignment filled;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(size: Size.square(size), painter: _FilletPainter(color, filled)),
    );
  }
}

class _FilletPainter extends CustomPainter {
  const _FilletPainter(this.color, this.filled);

  final Color color;
  final Alignment filled;

  @override
  void paint(Canvas canvas, Size size) {
    final square = Offset.zero & size;
    // The scooped circle is centred on the corner opposite the filled one.
    final centre = Alignment(-filled.x, -filled.y).withinRect(square);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(square),
        Path()..addOval(Rect.fromCircle(center: centre, radius: size.width)),
      ),
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_FilletPainter old) => old.color != color || old.filled != filled;
}

/// Content that appears while the card is hovered: it fades in and rises a
/// little, and ignores taps while hidden.
class NotchCardReveal extends StatelessWidget {
  /// Creates a hover reveal.
  const NotchCardReveal({super.key, required this.child});

  /// The content to reveal, such as an action button.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visible = NotchCard.hoveredOf(context);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 240);
    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: duration,
          curve: _easeOutQuint,
          child: AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, 0.2),
            duration: duration,
            curve: _easeOutQuint,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A column whose children rise into place one after another, un-blurring
/// as they come, when first shown.
class NotchCardStagger extends StatefulWidget {
  /// Creates a staggered column.
  const NotchCardStagger({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.delay = const Duration(milliseconds: 60),
    this.step = const Duration(milliseconds: 55),
  });

  /// The items, top to bottom.
  final List<Widget> children;

  /// How the items line up across.
  final CrossAxisAlignment crossAxisAlignment;

  /// Pause before the first item.
  final Duration delay;

  /// Pause between items.
  final Duration step;

  @override
  State<NotchCardStagger> createState() => _NotchCardStaggerState();
}

class _NotchCardStaggerState extends State<NotchCardStagger> with SingleTickerProviderStateMixin {
  static const int _itemMs = 480;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds:
          widget.delay.inMilliseconds +
          widget.step.inMilliseconds * widget.children.length +
          _itemMs,
    ),
  );

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      reduce ? _entrance.value = 1 : _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _entrance.duration!.inMilliseconds;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.crossAxisAlignment,
      children: [
        for (final (i, child) in widget.children.indexed)
          _StaggerItem(
            animation: _entrance,
            start: (widget.delay.inMilliseconds + widget.step.inMilliseconds * i) / total,
            end: (widget.delay.inMilliseconds + widget.step.inMilliseconds * i + _itemMs) / total,
            child: child,
          ),
      ],
    );
  }
}

/// One item of a [NotchCardStagger]: fades in, rises 12 px and un-blurs.
class _StaggerItem extends StatelessWidget {
  const _StaggerItem({
    required this.animation,
    required this.start,
    required this.end,
    required this.child,
  });

  final Animation<double> animation;
  final double start;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final raw = ((animation.value - start) / (end - start)).clamp(0.0, 1.0);
        // Mostly a smooth ease with a touch of overshoot.
        final t =
            Curves.easeOutCubic.transform(raw) * 0.75 + Curves.easeOutBack.transform(raw) * 0.25;
        final blur = (1 - raw) * 5;
        Widget out = Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child);
        if (blur > 0.05) {
          out = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: out,
          );
        }
        return Opacity(opacity: raw, child: out);
      },
    );
  }
}
