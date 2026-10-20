import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// The direction a [BlurFade] child travels while it appears.
enum BlurFadeDirection {
  /// Moves up into place.
  up,

  /// Moves down into place.
  down,

  /// Moves left into place.
  left,

  /// Moves right into place.
  right,
}

/// Reveals its [child] by fading it in from a soft blur while it slides
/// [offset] pixels into place.
///
/// The reveal starts after [delay] and runs for [duration]. With [inView] it
/// waits until the child scrolls into the viewport of the nearest
/// [Scrollable] (inset by [inViewMargin]); with [once] set to false it hides
/// again when scrolled out and replays on the way back in.
///
/// Stagger a group by giving each item a slightly longer [delay]. When the
/// platform asks to reduce motion ([MediaQueryData.disableAnimations]) the
/// child is shown immediately.
class BlurFade extends StatefulWidget {
  /// Creates a blur-fade reveal.
  const BlurFade({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.offset = 6,
    this.direction = BlurFadeDirection.down,
    this.blur = 6,
    this.scale = 1,
    this.curve = Curves.easeOut,
    this.inView = false,
    this.inViewMargin = 50,
    this.once = true,
  }) : assert(offset >= 0),
       assert(blur >= 0),
       assert(scale > 0);

  /// The content to reveal.
  final Widget child;

  /// Length of the reveal.
  final Duration duration;

  /// Wait before the reveal starts (once in view, with [inView]).
  final Duration delay;

  /// Travel distance in logical pixels.
  final double offset;

  /// Direction of travel.
  final BlurFadeDirection direction;

  /// Starting blur radius (Gaussian sigma) in logical pixels.
  final double blur;

  /// Starting scale; 1 means no scaling.
  final double scale;

  /// Easing of the reveal.
  final Curve curve;

  /// Wait until the child is visible in its scrollable before revealing.
  final bool inView;

  /// How far (logical pixels) the child must be inside the viewport, along
  /// the scroll axis, before it counts as in view. Negative values trigger
  /// before it arrives.
  final double inViewMargin;

  /// Reveal only the first time. When false (and [inView] is set) the child
  /// hides again after leaving the viewport and replays when it returns.
  final bool once;

  @override
  State<BlurFade> createState() => _BlurFadeState();
}

class _BlurFadeState extends State<BlurFade> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _timer;
  ScrollPosition? _position;

  /// Whether the child is (or is about to be) revealed.
  bool _shown = false;
  bool _checkScheduled = false;

  @override
  void initState() {
    super.initState();
    if (!widget.inView) _show();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _timer?.cancel();
      _shown = true;
      _controller.value = 1;
    }
    final position = widget.inView ? Scrollable.maybeOf(context)?.position : null;
    if (position != _position) {
      _position?.removeListener(_scheduleCheck);
      _position = position?..addListener(_scheduleCheck);
    }
    if (widget.inView) _scheduleCheck();
  }

  @override
  void didUpdateWidget(BlurFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.inView && !widget.inView) _show();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _position?.removeListener(_scheduleCheck);
    _controller.dispose();
    super.dispose();
  }

  /// Checks visibility after the current frame's layout.
  void _scheduleCheck() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (mounted) _check();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _check() {
    if (_shown && widget.once) return;
    final visible = _isInView();
    if (visible == null) return;
    if (visible) {
      _show();
    } else if (_shown && !widget.once) {
      _hide();
    }
  }

  /// Whether the child overlaps its scrollable's viewport inset by the
  /// margin, or null when it can't be measured yet.
  bool? _isInView() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final scrollable = Scrollable.maybeOf(context);
    final viewportBox = scrollable?.context.findRenderObject();
    final Rect viewport;
    if (viewportBox is RenderBox && viewportBox.hasSize) {
      viewport = viewportBox.localToGlobal(Offset.zero) & viewportBox.size;
    } else {
      viewport = Offset.zero & MediaQuery.sizeOf(context);
    }
    final vertical =
        scrollable == null || axisDirectionToAxis(scrollable.axisDirection) == Axis.vertical;
    final m = widget.inViewMargin;
    final inset = vertical
        ? Rect.fromLTRB(viewport.left, viewport.top + m, viewport.right, viewport.bottom - m)
        : Rect.fromLTRB(viewport.left + m, viewport.top, viewport.right - m, viewport.bottom);
    if (inset.width <= 0 || inset.height <= 0) return false;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    return rect.overlaps(inset);
  }

  void _show() {
    if (_shown) return;
    _shown = true;
    _timer?.cancel();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  void _hide() {
    _shown = false;
    _timer?.cancel();
    _controller.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offset;
    final hidden = switch (widget.direction) {
      BlurFadeDirection.down => Offset(0, -o),
      BlurFadeDirection.up => Offset(0, o),
      BlurFadeDirection.right => Offset(-o, 0),
      BlurFadeDirection.left => Offset(o, 0),
    };
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = widget.curve.transform(_controller.value);
        final sigma = widget.blur * (1 - t);
        final scale = widget.scale + (1 - widget.scale) * t;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: hidden * (1 - t),
            child: Transform.scale(
              scale: scale,
              child: ImageFiltered(
                enabled: sigma > 0.01,
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: sigma,
                  sigmaY: sigma,
                  tileMode: TileMode.decal,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
