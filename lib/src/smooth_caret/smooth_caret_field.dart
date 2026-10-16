import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A text input whose caret glides to every new cursor position on a spring
/// instead of jumping there.
///
/// Built on [EditableText] (no Material or Cupertino), so it brings no
/// decoration of its own: wrap it in whatever padding, border or background
/// fits your design.
///
/// The caret is measured from the field's own text layout, so it follows
/// typing, deleting, arrow keys, taps, scrolling and line wraps. While it
/// travels it stretches along the direction of motion and squashes slightly;
/// at rest it blinks with a soft fade.
class SmoothCaretField extends StatefulWidget {
  /// Creates a text input with a spring-animated caret.
  const SmoothCaretField({
    super.key,
    this.controller,
    this.focusNode,
    this.style = const TextStyle(fontSize: 16, color: Color(0xFF111827)),
    this.placeholder,
    this.placeholderStyle,
    this.caretColor = const Color(0xFF3B82F6),
    this.selectionColor,
    this.caretWidth = 2,
    this.caretRadius = 2,
    this.spring = const SpringDescription(mass: 1, stiffness: 520, damping: 34),
    this.stretch = 0.012,
    this.maxStretch = 14,
    this.squash = 0.0004,
    this.maxSquash = 0.25,
    this.glowRadius = 6,
    this.glowOpacity = 0.35,
    this.blink = true,
    this.blinkPeriod = const Duration(milliseconds: 1000),
    this.blinkDelay = const Duration(milliseconds: 500),
    this.textAlign = TextAlign.start,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.readOnly = false,
    this.onChanged,
    this.onSubmitted,
  }) : assert(caretWidth > 0),
       assert(maxLines == null || maxLines > 0),
       assert(minLines == null || minLines > 0);

  /// Text controller. One is created internally if omitted.
  final TextEditingController? controller;

  /// Focus node. One is created internally if omitted.
  final FocusNode? focusNode;

  /// Style of the editable text.
  final TextStyle style;

  /// Text shown while the field is empty.
  final String? placeholder;

  /// Style of [placeholder]. Defaults to [style] at 40% opacity.
  final TextStyle? placeholderStyle;

  /// Color of the caret and its glow.
  final Color caretColor;

  /// Color of selected text's background. Defaults to [caretColor] at 25%.
  final Color? selectionColor;

  /// Width of the caret at rest, in logical pixels.
  final double caretWidth;

  /// Corner radius of the caret.
  final double caretRadius;

  /// Spring that drives the caret between positions.
  final SpringDescription spring;

  /// How much the caret widens per logical pixel / second of horizontal
  /// velocity. Set to 0 to disable stretching.
  final double stretch;

  /// Upper bound for the extra width added by [stretch].
  final double maxStretch;

  /// How much the caret shortens per logical pixel / second of speed.
  /// Set to 0 to disable squashing.
  final double squash;

  /// Upper bound for the height fraction removed by [squash] (0-1).
  final double maxSquash;

  /// Blur radius of the glow around the caret. Set to 0 to disable.
  final double glowRadius;

  /// Opacity of the glow (0-1).
  final double glowOpacity;

  /// Whether the caret blinks while idle.
  final bool blink;

  /// Duration of one blink cycle.
  final Duration blinkPeriod;

  /// How long the caret stays solid after moving before it starts blinking.
  final Duration blinkDelay;

  /// Horizontal alignment of the text.
  final TextAlign textAlign;

  /// Minimum number of visible lines. See [EditableText.minLines].
  final int? minLines;

  /// Maximum number of visible lines; `null` grows without bound.
  /// See [EditableText.maxLines].
  final int? maxLines;

  /// Keyboard type. Defaults to text, or multiline when [maxLines] != 1.
  final TextInputType? keyboardType;

  /// Action button of the soft keyboard.
  final TextInputAction? textInputAction;

  /// Whether to request focus on mount.
  final bool autofocus;

  /// Whether the text can be changed. The caret still moves when read-only.
  final bool readOnly;

  /// Called on every text change.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits.
  final ValueChanged<String>? onSubmitted;

  @override
  State<SmoothCaretField> createState() => _SmoothCaretFieldState();
}

class _SmoothCaretFieldState extends State<SmoothCaretField>
    with TickerProviderStateMixin
    implements TextSelectionGestureDetectorBuilderDelegate {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;

  late final TextSelectionGestureDetectorBuilder _gestures = TextSelectionGestureDetectorBuilder(
    delegate: this,
  );

  final GlobalKey _stackKey = GlobalKey();
  final ScrollController _scroll = ScrollController();

  late final AnimationController _x = AnimationController.unbounded(vsync: this);
  late final AnimationController _y = AnimationController.unbounded(vsync: this);
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: widget.blinkPeriod,
  );

  Timer? _idle;
  double _height = 0;
  bool _visible = false;
  Rect? _clip;
  Offset? _target;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onText);
    _focus.addListener(_onFocus);
    _scroll.addListener(_schedule);
  }

  @override
  void didUpdateWidget(covariant SmoothCaretField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_onText);
      _controller.addListener(_onText);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
    if (oldWidget.blinkPeriod != widget.blinkPeriod) {
      _blink.duration = widget.blinkPeriod;
      if (_blink.isAnimating) _blink.repeat();
    }
    if (!widget.blink) {
      _idle?.cancel();
      _blink
        ..stop()
        ..value = 0;
    } else if (!oldWidget.blink) {
      _restartBlink();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    _focus.removeListener(_onFocus);
    _idle?.cancel();
    _x.dispose();
    _y.dispose();
    _blink.dispose();
    _scroll.dispose();
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _onText() {
    // The placeholder depends on whether the text is empty.
    setState(() {});
    _schedule();
  }

  void _onFocus() {
    setState(() {
      if (!_focus.hasFocus) {
        _idle?.cancel();
        _blink.stop();
        _visible = false;
      }
    });
    _schedule();
  }

  /// Measures the caret after the next layout, once per frame at most.
  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) _measure();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _restartBlink() {
    _blink
      ..stop()
      ..value = 0;
    _idle?.cancel();
    if (!widget.blink) return;
    _idle = Timer(widget.blinkDelay, () {
      if (mounted && _focus.hasFocus) _blink.repeat();
    });
  }

  void _measure() {
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final editable = editableTextKey.currentState?.renderEditable;
    if (stack == null || editable == null || !editable.attached || !editable.hasSize) {
      return;
    }
    var sel = _controller.selection;
    // A focused field without a selection yet edits at the end of the text.
    if (!sel.isValid) sel = TextSelection.collapsed(offset: _controller.text.length);
    final show = _focus.hasFocus && sel.isCollapsed;
    if (!show) {
      if (_visible) setState(() => _visible = false);
      return;
    }
    final origin = editable.localToGlobal(Offset.zero, ancestor: stack);
    final rect = editable.getLocalRectForCaret(sel.extent).shift(origin);
    final clip = (origin & editable.size).inflate(widget.caretWidth + widget.maxStretch);
    final target = rect.topLeft;
    final moved = _target == null || (target - _target!).distance > 0.01;
    if (!moved && _visible && clip == _clip && rect.height == _height) return;

    if (!_visible || _target == null) {
      // Appear in place rather than flying in from a stale position.
      _x.value = target.dx;
      _y.value = target.dy;
    } else if (moved) {
      _x.animateWith(SpringSimulation(widget.spring, _x.value, target.dx, _x.velocity));
      _y.animateWith(SpringSimulation(widget.spring, _y.value, target.dy, _y.velocity));
    }
    _target = target;
    if (moved || !_visible) _restartBlink();
    setState(() {
      _visible = true;
      _height = rect.height;
      _clip = clip;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Re-measure after any rebuild (resizes, style or parameter changes).
    _schedule();
    final style = widget.style;
    final placeholder = widget.placeholder;
    final multiline = widget.maxLines != 1;
    final editable = EditableText(
      key: editableTextKey,
      controller: _controller,
      focusNode: _focus,
      style: style,
      textAlign: widget.textAlign,
      cursorColor: widget.caretColor,
      backgroundCursorColor: const Color(0x00000000),
      showCursor: false,
      selectionColor:
          widget.selectionColor ?? widget.caretColor.withValues(alpha: widget.caretColor.a * 0.25),
      scrollController: _scroll,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      keyboardType:
          widget.keyboardType ?? (multiline ? TextInputType.multiline : TextInputType.text),
      textInputAction: widget.textInputAction,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      rendererIgnoresPointer: true,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: _gestures.buildGestureDetector(
        behavior: HitTestBehavior.translucent,
        child: Stack(
          key: _stackKey,
          clipBehavior: Clip.none,
          children: [
            if (placeholder != null && _controller.text.isEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Text(
                    placeholder,
                    textAlign: widget.textAlign,
                    maxLines: widget.maxLines,
                    overflow: TextOverflow.ellipsis,
                    style:
                        widget.placeholderStyle ??
                        style.copyWith(
                          color: (style.color ?? const Color(0xFF111827)).withValues(alpha: 0.4),
                        ),
                  ),
                ),
              ),
            editable,
            if (_visible && _clip != null)
              Positioned.fromRect(
                rect: _clip!,
                child: _Caret(
                  field: widget,
                  x: _x,
                  y: _y,
                  blink: _blink,
                  origin: _clip!.topLeft,
                  lineHeight: _height,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The animated caret, painted inside the field's (inflated) clip rect.
class _Caret extends StatelessWidget {
  const _Caret({
    required this.field,
    required this.x,
    required this.y,
    required this.blink,
    required this.origin,
    required this.lineHeight,
  });

  /// The field whose caret this is; supplies the visual parameters.
  final SmoothCaretField field;

  /// Caret position (top left), in the field's stack coordinates.
  final AnimationController x;
  final AnimationController y;

  /// Drives one blink cycle from 0 to 1 while idle.
  final AnimationController blink;

  /// Top left of the clip rect, to convert positions into local ones.
  final Offset origin;

  /// Height of the line the caret sits on.
  final double lineHeight;

  /// Opacity over one blink cycle: hold, fade out, hold, fade in.
  double get _opacity {
    if (!blink.isAnimating) return 1;
    final t = blink.value;
    if (t < 0.45) return 1;
    if (t < 0.55) return 1 - (t - 0.45) / 0.1;
    if (t < 0.95) return 0;
    return (t - 0.95) / 0.05;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: AnimatedBuilder(
          animation: Listenable.merge([x, y, blink]),
          builder: (context, _) {
            final vx = x.velocity;
            final vy = y.velocity;
            final moving = x.isAnimating || y.isAnimating;
            final speed = math.sqrt(vx * vx + vy * vy);
            final extra = moving ? math.min(field.maxStretch, vx.abs() * field.stretch) : 0.0;
            final squash = moving ? math.min(field.maxSquash, speed * field.squash) : 0.0;
            final height = lineHeight * (1 - squash);
            final color = field.caretColor;
            return Stack(
              children: [
                Positioned(
                  // Grow the caret behind its direction of travel, like a trail.
                  left: x.value - origin.dx - (vx > 0 ? extra : 0),
                  top: y.value - origin.dy + (lineHeight - height) / 2,
                  width: field.caretWidth + extra,
                  height: height,
                  child: Opacity(
                    opacity: _opacity.clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(field.caretRadius),
                        boxShadow: [
                          if (field.glowRadius > 0 && field.glowOpacity > 0)
                            BoxShadow(
                              color: color.withValues(alpha: color.a * field.glowOpacity),
                              blurRadius: field.glowRadius,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
