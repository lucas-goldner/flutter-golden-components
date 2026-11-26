import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// One link in an [ImageHoverList].
@immutable
class ImageHoverItem {
  /// Creates a link with a [title] and the [image] shown while it is hovered.
  const ImageHoverItem({required this.title, this.subtitle, required this.image});

  /// The large link text.
  final String title;

  /// A smaller line under the title.
  final String? subtitle;

  /// Shown under the pointer while the link is hovered; usually an [Image].
  final Widget image;
}

/// A list of large text links that reveal an image under the pointer.
///
/// Hover a link and its [ImageHoverItem.image] grows in under the pointer
/// and follows it with a soft lag, leaning into the direction it moves.
/// The title's letters slide over one after another and take on the
/// [highlight] colour, and an arrow slides in at the end of the row. The
/// image sits behind the text, so the links stay readable. Moving to
/// another link swaps the image in place.
///
/// Links are focusable: with the keyboard the image shows at the right of
/// the focused link, and Enter or Space calls [onTap]. On touch screens the
/// image shows while a finger is down.
///
/// When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the image appears directly under the
/// pointer and the letters only change colour.
class ImageHoverList extends StatefulWidget {
  /// Creates an image hover list.
  const ImageHoverList({
    super.key,
    required this.items,
    this.onTap,
    this.imageSize = const Size(200, 136),
    this.imageRadius = 12,
    this.titleStyle,
    this.subtitleStyle,
    this.highlight,
    this.dividerColor,
    this.padding = const EdgeInsets.symmetric(vertical: 20),
    this.stiffness = 12,
  }) : assert(stiffness > 0);

  /// The links, top to bottom.
  final List<ImageHoverItem> items;

  /// Called with the index of a link that is tapped or activated.
  final ValueChanged<int>? onTap;

  /// Size of the floating image.
  final Size imageSize;

  /// Corner radius of the floating image.
  final double imageRadius;

  /// Style of the titles, merged over a large bold style in the ambient
  /// text colour.
  final TextStyle? titleStyle;

  /// Style of the subtitles, merged over a small muted style.
  final TextStyle? subtitleStyle;

  /// Colour the title of the hovered link turns. Defaults to the ambient
  /// text colour.
  final Color? highlight;

  /// Colour of the lines between links. Defaults to a faint ambient text
  /// colour.
  final Color? dividerColor;

  /// Padding inside each row.
  final EdgeInsets padding;

  /// How quickly the image follows the pointer; higher is snappier.
  final double stiffness;

  @override
  State<ImageHoverList> createState() => _ImageHoverListState();
}

/// Where the image is and how far it has grown in (0 hidden, 1 shown).
@immutable
class _Float {
  const _Float(this.position, this.shown, this.lean);

  final Offset position;
  final double shown;

  /// Rotation in radians, leaning into the direction of travel.
  final double lean;
}

class _ImageHoverListState extends State<ImageHoverList> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<_Float> _float = ValueNotifier(const _Float(Offset.zero, 0, 0));
  late List<GlobalKey> _rowKeys = _keys(widget.items.length);
  Duration _last = Duration.zero;

  /// The link the pointer (or focus) is on.
  int? _active;

  /// The link whose image is showing; kept while the image fades out.
  int? _shown;

  Offset _target = Offset.zero;

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static List<GlobalKey> _keys(int n) => [for (var i = 0; i < n; i++) GlobalKey()];

  @override
  void didUpdateWidget(ImageHoverList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _rowKeys = _keys(widget.items.length);
      _active = null;
      _shown = null;
      _float.value = _Float(_float.value.position, 0, 0);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _float.dispose();
    super.dispose();
  }

  void _point(int? index, Offset position) {
    final appearing = _active == null || _float.value.shown < 0.05;
    _target = position;
    if (_active != index) setState(() => _active = index);
    if (index != null) _shown = index;
    if (_reduceMotion) {
      _float.value = _Float(position, index == null ? 0 : 1, 0);
      return;
    }
    // A fresh image starts right under the pointer instead of flying in.
    if (appearing && index != null) _float.value = _Float(position, _float.value.shown, 0);
    _start();
  }

  void _leave() => _point(null, _target);

  /// Shows [index]'s image at the right of its row, for keyboard focus.
  void _focus(int index, bool focused) {
    if (!focused) {
      if (_active == index) _leave();
      return;
    }
    final row = _rowKeys[index].currentContext?.findRenderObject() as RenderBox?;
    final list = context.findRenderObject() as RenderBox?;
    if (row == null || list == null) return;
    final spot = row.localToGlobal(
      row.size.centerRight(Offset(-widget.imageSize.width * 0.75, 0)),
      ancestor: list,
    );
    _point(index, spot);
  }

  void _start() {
    if (_ticker.isActive) return;
    _last = Duration.zero;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    final dt = (_last == Duration.zero ? 1 / 60 : (elapsed - _last).inMicroseconds / 1e6).clamp(
      0.0,
      0.1,
    );
    _last = elapsed;
    final k = 1 - math.exp(-widget.stiffness * dt);
    final f = _float.value;
    final goal = _active == null ? 0.0 : 1.0;
    final position = Offset.lerp(f.position, _target, k)!;
    // Lean by how far the image trails the pointer sideways.
    final lean = ((_target.dx - position.dx) * 0.004).clamp(-0.25, 0.25);
    final shown = f.shown + (goal - f.shown) * (1 - math.exp(-16 * dt));
    final settled =
        (position - _target).distance < 0.3 && (shown - goal).abs() < 0.002 && lean.abs() < 0.001;
    _float.value = settled ? _Float(_target, goal, 0) : _Float(position, shown, lean);
    if (settled) _ticker.stop();
  }

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    final ink = base.color ?? const Color(0xFF000000);
    final titleStyle = base
        .copyWith(fontSize: 44, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -1)
        .merge(widget.titleStyle);
    final subtitleStyle = base
        .copyWith(fontSize: 14, color: ink.withValues(alpha: 0.55))
        .merge(widget.subtitleStyle);
    final highlight = widget.highlight ?? titleStyle.color ?? ink;
    final divider = widget.dividerColor ?? ink.withValues(alpha: 0.14);
    final shown = _shown;
    return Listener(
      // Touch has no hover: show the image while a finger is down.
      onPointerUp: (e) {
        if (e.kind == PointerDeviceKind.touch) _leave();
      },
      onPointerCancel: (e) {
        if (e.kind == PointerDeviceKind.touch) _leave();
      },
      child: MouseRegion(
        onExit: (_) => _leave(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Behind the rows, so the links stay readable.
            if (shown != null && shown < widget.items.length)
              Positioned.fill(
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: _FloatingImage(
                      float: _float,
                      index: shown,
                      size: widget.imageSize,
                      radius: widget.imageRadius,
                      child: widget.items[shown].image,
                    ),
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < widget.items.length; i++)
                  _Row(
                    key: _rowKeys[i],
                    item: widget.items[i],
                    active: _active == i,
                    reduceMotion: _reduceMotion,
                    titleStyle: titleStyle,
                    subtitleStyle: subtitleStyle,
                    highlight: highlight,
                    divider: divider,
                    padding: widget.padding,
                    onPoint: (local) {
                      final row = _rowKeys[i].currentContext?.findRenderObject() as RenderBox?;
                      final list = context.findRenderObject() as RenderBox?;
                      if (row == null || list == null) return;
                      _point(i, row.localToGlobal(local, ancestor: list));
                    },
                    onFocus: (focused) => _focus(i, focused),
                    onTap: widget.onTap == null ? null : () => widget.onTap!(i),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The image, placed, grown in and leaning as [float] says.
class _FloatingImage extends StatelessWidget {
  const _FloatingImage({
    required this.float,
    required this.index,
    required this.size,
    required this.radius,
    required this.child,
  });

  final ValueListenable<_Float> float;
  final int index;
  final Size size;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_Float>(
      valueListenable: float,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: SizedBox.fromSize(
          key: ValueKey(index),
          size: size,
          child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: child),
        ),
      ),
      builder: (context, f, child) {
        if (f.shown < 0.005) return const SizedBox.shrink();
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: f.position.dx - size.width / 2,
              top: f.position.dy - size.height / 2,
              width: size.width,
              height: size.height,
              child: Opacity(
                opacity: f.shown.clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: f.lean,
                  child: Transform.scale(scale: 0.3 + 0.7 * f.shown, child: child),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One link: title, subtitle, divider and the arrow that slides in.
class _Row extends StatefulWidget {
  const _Row({
    super.key,
    required this.item,
    required this.active,
    required this.reduceMotion,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.highlight,
    required this.divider,
    required this.padding,
    required this.onPoint,
    required this.onFocus,
    required this.onTap,
  });

  final ImageHoverItem item;
  final bool active;
  final bool reduceMotion;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final Color highlight;
  final Color divider;
  final EdgeInsets padding;
  final ValueChanged<Offset> onPoint;
  final ValueChanged<bool> onFocus;
  final VoidCallback? onTap;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> with SingleTickerProviderStateMixin {
  late final AnimationController _hover = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    // Letting go is quicker than taking hold.
    reverseDuration: const Duration(milliseconds: 280),
    value: widget.active ? 1 : 0,
  );

  @override
  void didUpdateWidget(_Row oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;
    if (widget.reduceMotion) {
      _hover.value = widget.active ? 1 : 0;
    } else if (widget.active) {
      _hover.forward();
    } else {
      _hover.reverse();
    }
  }

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.item.subtitle;
    final arrowSize = (widget.titleStyle.fontSize ?? 44) * 0.7;
    return FocusableActionDetector(
      onFocusChange: widget.onFocus,
      mouseCursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap?.call()),
      },
      child: Semantics(
        button: widget.onTap != null,
        label: subtitle == null ? widget.item.title : '${widget.item.title}, $subtitle',
        excludeSemantics: true,
        child: MouseRegion(
          onEnter: (e) => widget.onPoint(e.localPosition),
          onHover: (e) => widget.onPoint(e.localPosition),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onPanDown: (d) => widget.onPoint(d.localPosition),
            onPanUpdate: (d) => widget.onPoint(d.localPosition),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: widget.divider)),
              ),
              child: Padding(
                padding: widget.padding,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Title(
                            text: widget.item.title,
                            hover: _hover,
                            style: widget.titleStyle,
                            highlight: widget.highlight,
                            slide: widget.reduceMotion ? 0 : 14,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 6),
                            Text(subtitle, style: widget.subtitleStyle),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _Arrow(
                      hover: _hover,
                      size: arrowSize,
                      color: widget.highlight,
                      slide: widget.reduceMotion ? 0 : arrowSize * 0.5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The title, its letters sliding over one after another as [hover] rises.
class _Title extends StatelessWidget {
  const _Title({
    required this.text,
    required this.hover,
    required this.style,
    required this.highlight,
    required this.slide,
  });

  final String text;
  final Animation<double> hover;
  final TextStyle style;
  final Color highlight;
  final double slide;

  @override
  Widget build(BuildContext context) {
    final letters = text.characters.toList();
    final rest = style.color?.withValues(alpha: (style.color?.a ?? 1) * 0.85);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: hover,
        builder: (context, _) {
          final h = hover.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < letters.length; i++)
                _Letter(
                  letter: letters[i],
                  // Each letter starts a little after the one before it.
                  progress: Curves.easeOutCubic.transform(
                    ((h - 0.5 * i / math.max(1, letters.length)) / 0.5).clamp(0.0, 1.0),
                  ),
                  slide: slide,
                  style: style,
                  rest: rest ?? highlight,
                  highlight: highlight,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Letter extends StatelessWidget {
  const _Letter({
    required this.letter,
    required this.progress,
    required this.slide,
    required this.style,
    required this.rest,
    required this.highlight,
  });

  final String letter;
  final double progress;
  final double slide;
  final TextStyle style;
  final Color rest;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(slide * progress, 0),
      child: Text(letter, style: style.copyWith(color: Color.lerp(rest, highlight, progress))),
    );
  }
}

/// An arrow that slides in from the left and turns from pointing up-right
/// to pointing right.
class _Arrow extends StatelessWidget {
  const _Arrow({required this.hover, required this.size, required this.color, required this.slide});

  final Animation<double> hover;
  final double size;
  final Color color;
  final double slide;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: hover,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(hover.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(-slide * (1 - t), 0),
            child: Transform.rotate(
              angle: -math.pi / 4 * (1 - t),
              child: CustomPaint(size: Size.square(size), painter: _ArrowPainter(color)),
            ),
          ),
        );
      },
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawLine(Offset(s * 0.12, s / 2), Offset(s * 0.88, s / 2), paint)
      ..drawPath(
        Path()
          ..moveTo(s * 0.56, s * 0.18)
          ..lineTo(s * 0.88, s / 2)
          ..lineTo(s * 0.56, s * 0.82),
        paint,
      );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}
