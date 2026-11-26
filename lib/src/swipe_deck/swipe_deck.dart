import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A carousel you swipe through one slide at a time.
///
/// Drag the [slides] sideways and they follow your finger; let go and the
/// deck snaps to the nearest slide, or the next one if you flicked. Slides
/// beside the current one shrink to [sideScale] and dim, so the one in
/// front stands out. Dots below show where you are and jump on tap, the
/// arrow keys move one slide, and with [autoplay] the deck advances on its
/// own, pausing while it is being dragged.
///
/// When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the deck jumps between slides
/// instead of gliding.
class SwipeDeck extends StatefulWidget {
  /// Creates a swipe deck.
  const SwipeDeck({
    super.key,
    required this.slides,
    this.initialIndex = 0,
    this.onChanged,
    this.aspectRatio = 16 / 9,
    this.viewportFraction = 0.86,
    this.gap = 12,
    this.sideScale = 0.92,
    this.radius = 20,
    this.showDots = true,
    this.autoplay,
    this.loop = true,
    this.duration = const Duration(milliseconds: 420),
  }) : assert(sideScale > 0 && sideScale <= 1),
       assert(viewportFraction > 0 && viewportFraction <= 1);

  /// The slides, in order.
  final List<Widget> slides;

  /// The slide shown first.
  final int initialIndex;

  /// Called with the index of each slide that settles in front.
  final ValueChanged<int>? onChanged;

  /// Width / height of the deck.
  final double aspectRatio;

  /// Share of the width each slide takes; below 1 the neighbours peek in
  /// at the sides.
  final double viewportFraction;

  /// Space between slides.
  final double gap;

  /// Scale of the slides beside the current one.
  final double sideScale;

  /// Corner radius of the slides.
  final double radius;

  /// Whether to show the position dots.
  final bool showDots;

  /// How long each slide stays before advancing on its own; null for no
  /// autoplay.
  final Duration? autoplay;

  /// Whether autoplay wraps from the last slide back to the first.
  final bool loop;

  /// Length of a glide to another slide.
  final Duration duration;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
    viewportFraction: widget.viewportFraction,
  );
  late int _index = widget.initialIndex;

  /// The last index reported through [SwipeDeck.onChanged].
  late int _reported = widget.initialIndex;
  Timer? _timer;
  bool _dragging = false;

  /// Room the dots take below the slides.
  static const double _dotsHeight = 30;

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(SwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoplay != widget.autoplay) _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    final every = widget.autoplay;
    if (every == null || widget.slides.length < 2) return;
    _timer = Timer.periodic(every, (_) {
      if (_dragging || !mounted) return;
      final last = widget.slides.length - 1;
      if (_index == last && !widget.loop) return;
      if (_index == last) {
        // Wrapping jumps straight back instead of rewinding past every slide.
        _jumpTo(0);
      } else {
        _goTo(_index + 1);
      }
    });
  }

  void _jumpTo(int index) {
    if (!_pages.hasClients) return;
    _pages.jumpToPage(index);
    _settled();
  }

  /// Reports the slide in front once the deck comes to rest.
  void _settled() {
    if (_index != _reported) {
      _reported = _index;
      widget.onChanged?.call(_index);
    }
  }

  void _goTo(int index) {
    final target = index.clamp(0, widget.slides.length - 1);
    if (!_pages.hasClients) return;
    if (_reduceMotion) {
      _jumpTo(target);
    } else {
      _pages.animateToPage(target, duration: widget.duration, curve: Curves.easeOutCubic);
    }
    // Moving by hand resets the autoplay countdown.
    _restartTimer();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goTo(_index + 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goTo(_index - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.slides.length;
    return Semantics(
      container: true,
      label: 'Slide ${_index + 1} of $count',
      child: Focus(
        onKeyEvent: _onKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dots = widget.showDots && count > 1 ? _dotsHeight : 0.0;
            // As tall as the aspect ratio asks, but never taller than the
            // space left for it.
            var height = constraints.maxWidth / widget.aspectRatio;
            if (constraints.hasBoundedHeight) {
              height = math.min(height, math.max(0.0, constraints.maxHeight - dots));
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: height,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollStartNotification && n.dragDetails != null) {
                        _dragging = true;
                      } else if (n is ScrollEndNotification) {
                        _dragging = false;
                        _settled();
                        _restartTimer();
                      }
                      return false;
                    },
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: count,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) => _Slide(
                        pages: _pages,
                        index: i,
                        gap: widget.gap,
                        sideScale: widget.sideScale,
                        radius: widget.radius,
                        child: widget.slides[i],
                      ),
                    ),
                  ),
                ),
                if (dots > 0) ...[
                  const SizedBox(height: 14),
                  _Dots(pages: _pages, count: count, current: _index, onTap: _goTo),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One slide, scaled and dimmed by how far it is from the front.
class _Slide extends StatelessWidget {
  const _Slide({
    required this.pages,
    required this.index,
    required this.gap,
    required this.sideScale,
    required this.radius,
    required this.child,
  });

  final PageController pages;
  final int index;
  final double gap;
  final double sideScale;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pages,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: gap / 2),
        child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: child),
      ),
      builder: (context, child) {
        final page = pages.hasClients && pages.position.hasContentDimensions
            ? pages.page ?? pages.initialPage.toDouble()
            : pages.initialPage.toDouble();
        final away = (page - index).abs().clamp(0.0, 1.0);
        return Opacity(
          opacity: 1 - 0.35 * away,
          child: Transform.scale(scale: 1 - (1 - sideScale) * away, child: child),
        );
      },
    );
  }
}

/// Position dots; the current one stretches into a pill.
class _Dots extends StatelessWidget {
  const _Dots({
    required this.pages,
    required this.count,
    required this.current,
    required this.onTap,
  });

  final PageController pages;
  final int count;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final ink = DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    return AnimatedBuilder(
      animation: pages,
      builder: (context, _) {
        final page = pages.hasClients && pages.position.hasContentDimensions
            ? pages.page ?? current.toDouble()
            : current.toDouble();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              Semantics(
                button: true,
                selected: i == current,
                label: 'Go to slide ${i + 1}',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _Dot(
                      // 1 while this dot's slide is in front, easing with the drag.
                      emphasis: 1 - math.min(1.0, (page - i).abs()),
                      ink: ink,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.emphasis, required this.ink});

  final double emphasis;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8 + 16 * emphasis,
      height: 8,
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.22 + 0.68 * emphasis),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
