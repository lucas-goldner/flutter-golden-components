import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A search pill that melts into a field and a separate search button.
///
/// Collapsed it is a small pill with a magnifier and [label]. Tap it and
/// the pill springs out into a text field while a round button holding the
/// magnifier melts off its left end: the two stay joined by a gooey neck
/// that stretches and snaps as they part. Tapping the button submits the
/// text (or collapses the field when it is empty); losing focus with
/// nothing typed, or pressing Escape, melts it back together.
///
/// When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) it opens and closes instantly.
class MeltSearch extends StatefulWidget {
  /// Creates a melting search field.
  const MeltSearch({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onExpandedChanged,
    this.label = 'Search',
    this.hint = 'Type to search…',
    this.width = 260,
    this.collapsedWidth = 120,
    this.height = 44,
    this.gap = 16,
    this.color,
    this.foreground,
    this.goo = 7,
    this.bounce = 0.5,
    this.initiallyExpanded = false,
  }) : assert(width > 0),
       assert(collapsedWidth >= height),
       assert(height > 0),
       assert(gap >= 0),
       assert(goo >= 0),
       assert(bounce >= 0 && bounce <= 1);

  /// Holds the typed text; one is made if null.
  final TextEditingController? controller;

  /// Focus of the text field; one is made if null.
  final FocusNode? focusNode;

  /// Called as the text changes.
  final ValueChanged<String>? onChanged;

  /// Called with the text when Enter is pressed or the button is tapped.
  final ValueChanged<String>? onSubmitted;

  /// Called when the field opens or closes.
  final ValueChanged<bool>? onExpandedChanged;

  /// Text on the collapsed pill.
  final String label;

  /// Placeholder in the empty field.
  final String hint;

  /// Width of the open field, not counting the button.
  final double width;

  /// Width of the collapsed pill.
  final double collapsedWidth;

  /// Height of the pill and diameter of the button.
  final double height;

  /// Space between the button and the open field.
  final double gap;

  /// Fill of the pill and button. Defaults to the ambient text colour.
  final Color? color;

  /// Text and icon colour. Defaults to white or black, whichever stands
  /// out on [color].
  final Color? foreground;

  /// How gooey the shapes are: the blur, in logical pixels, that melts them
  /// together. 0 keeps them crisp and apart.
  final double goo;

  /// How much the opening springs past its rest and back, from 0 (none)
  /// to 1 (a lot).
  final double bounce;

  /// Whether it starts open.
  final bool initiallyExpanded;

  @override
  State<MeltSearch> createState() => _MeltSearchState();
}

class _MeltSearchState extends State<MeltSearch> with SingleTickerProviderStateMixin {
  late final AnimationController _open = AnimationController.unbounded(
    vsync: this,
    value: widget.initiallyExpanded ? 1 : 0,
  );
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  late bool _expanded = widget.initiallyExpanded;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(MeltSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownController?.dispose();
    _ownFocus?.dispose();
    _open.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!_focus.hasFocus && _controller.text.isEmpty) _setExpanded(false);
  }

  void _setExpanded(bool expanded) {
    if (_expanded == expanded) return;
    setState(() => _expanded = expanded);
    final target = expanded ? 1.0 : 0.0;
    if (_reduceMotion) {
      _open.value = target;
    } else {
      // A spring: with some bounce it overshoots and settles, which is
      // what stretches the neck between the shapes before it snaps.
      final damping = 2 * math.sqrt(200.0) * (1 - 0.75 * widget.bounce);
      _open.animateWith(
        SpringSimulation(
          SpringDescription(mass: 1, stiffness: 200, damping: damping),
          _open.value,
          target,
          _open.velocity,
          tolerance: const Tolerance(distance: 0.001, velocity: 0.01),
        ),
      );
    }
    if (expanded) {
      // Once the field is on stage, so the web text input attaches to it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _expanded) _focus.requestFocus();
      });
    } else {
      _focus.unfocus();
    }
    widget.onExpandedChanged?.call(expanded);
  }

  void _submit() {
    final text = _controller.text;
    if (text.isEmpty) {
      _setExpanded(false);
    } else {
      widget.onSubmitted?.call(text);
    }
  }

  void _escape() {
    _controller.clear();
    widget.onChanged?.call('');
    _setExpanded(false);
  }

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    final fill = widget.color ?? base.color ?? const Color(0xFF18181B);
    final ink =
        widget.foreground ??
        (fill.computeLuminance() > 0.5 ? const Color(0xFF09090B) : const Color(0xFFFFFFFF));
    final h = widget.height;
    final full = h + widget.gap + widget.width;
    final textStyle = base.copyWith(color: ink, fontSize: h * 0.34, height: 1.2);
    return AnimatedBuilder(
      animation: _open,
      builder: (context, _) {
        final t = _open.value;
        // The layout follows the opening without its overshoot, so nothing
        // around the field jiggles; only the shapes do.
        final laidOut = ui.lerpDouble(widget.collapsedWidth, full, t.clamp(0.0, 1.0))!;
        final pillLeft = (h + widget.gap) * t;
        final pillRight = ui.lerpDouble(widget.collapsedWidth, full, t)!;
        final reveal = ((t - 0.45) / 0.45).clamp(0.0, 1.0);
        return SizedBox(
          width: laidOut,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -h,
                top: -h,
                right: -h - (pillRight - laidOut).clamp(0.0, double.infinity),
                bottom: -h,
                child: IgnorePointer(
                  child: _Goo(
                    sigma: widget.goo,
                    painter: _ShapesPainter(
                      margin: h,
                      height: h,
                      pillLeft: pillLeft,
                      pillRight: pillRight,
                      bubble: 0.86 + 0.14 * t.clamp(0.0, 1.0),
                      color: fill,
                    ),
                  ),
                ),
              ),
              // The magnifier: in the pill when collapsed, in the button
              // when open; it never moves, the pill does.
              Positioned(
                left: 0,
                top: 0,
                width: h,
                height: h,
                child: Semantics(
                  button: true,
                  label: _expanded ? 'Submit search' : widget.label,
                  excludeSemantics: true,
                  onTap: _expanded ? _submit : () => _setExpanded(true),
                  child: FocusableActionDetector(
                    mouseCursor: SystemMouseCursors.click,
                    shortcuts: const {
                      SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                      SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
                    },
                    actions: {
                      ActivateIntent: CallbackAction<ActivateIntent>(
                        onInvoke: (_) => _expanded ? _submit() : _setExpanded(true),
                      ),
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _expanded ? _submit : () => _setExpanded(true),
                      child: Center(
                        child: CustomPaint(
                          size: Size.square(h * 0.42),
                          painter: _MagnifierPainter(ink),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (t < 0.6)
                Positioned(
                  key: const ValueKey('label'),
                  left: h * 0.82,
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _setExpanded(true),
                    child: Opacity(
                      opacity: (1 - t / 0.35).clamp(0.0, 1.0),
                      child: ExcludeSemantics(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                            style: textStyle.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                // Keyed, so the field keeps its state (and the platform text
                // input) when the label before it leaves.
                key: const ValueKey('field'),
                left: pillLeft + h * 0.42,
                width: math.max(0.0, widget.width - h * 0.84),
                top: 0,
                bottom: 0,
                child: Offstage(
                  offstage: !_expanded && t < 0.05,
                  child: Opacity(
                    opacity: reveal,
                    child: Transform.translate(
                      offset: Offset(12 * (1 - reveal), 0),
                      child: _Field(
                        controller: _controller,
                        focusNode: _focus,
                        style: textStyle,
                        hint: widget.hint,
                        onChanged: widget.onChanged,
                        onSubmitted: (_) => _submit(),
                        onEscape: _escape,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EscapeIntent extends Intent {
  const _EscapeIntent();
}

/// The single-line text field with its placeholder.
class _Field extends StatefulWidget {
  const _Field({
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
    required this.onEscape,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle style;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onEscape;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;

  // Taps, double taps and drags place the caret and select, as in any field.
  late final TextSelectionGestureDetectorBuilder _gestures = TextSelectionGestureDetectorBuilder(
    delegate: this,
  );

  @override
  Widget build(BuildContext context) {
    final ink = widget.style.color ?? const Color(0xFFFFFFFF);
    return Shortcuts(
      shortcuts: const {SingleActivator(LogicalKeyboardKey.escape): _EscapeIntent()},
      child: Actions(
        actions: {_EscapeIntent: CallbackAction<_EscapeIntent>(onInvoke: (_) => widget.onEscape())},
        child: MouseRegion(
          cursor: SystemMouseCursors.text,
          child: _gestures.buildGestureDetector(
            behavior: HitTestBehavior.opaque,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.controller,
                    builder: (context, value, _) => value.text.isEmpty
                        ? ExcludeSemantics(
                            child: Text(
                              widget.hint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: widget.style.copyWith(color: ink.withValues(alpha: 0.5)),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Semantics(
                    label: widget.hint,
                    child: EditableText(
                      key: editableTextKey,
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      style: widget.style,
                      cursorColor: ink,
                      backgroundCursorColor: ink.withValues(alpha: 0.3),
                      selectionColor: ink.withValues(alpha: 0.25),
                      maxLines: 1,
                      textInputAction: TextInputAction.search,
                      rendererIgnoresPointer: true,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Matrix that keeps colours and turns alpha into a hard edge just under
/// 50%, so blurred shapes melt together where they are close.
const List<double> _threshold = [
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 20, -20 * 0.45 * 255,
];

/// The shapes, blurred and thresholded into goo.
class _Goo extends StatelessWidget {
  const _Goo({required this.sigma, required this.painter});

  final double sigma;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(painter: painter, size: Size.infinite);
    if (sigma < 0.5) return paint;
    return ImageFiltered(
      imageFilter: ui.ImageFilter.compose(
        outer: const ui.ColorFilter.matrix(_threshold),
        inner: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
      ),
      child: paint,
    );
  }
}

/// The pill and the round button, offset by [margin] so the blur has room.
class _ShapesPainter extends CustomPainter {
  const _ShapesPainter({
    required this.margin,
    required this.height,
    required this.pillLeft,
    required this.pillRight,
    required this.bubble,
    required this.color,
  });

  final double margin;
  final double height;
  final double pillLeft;
  final double pillRight;

  /// Scale of the button.
  final double bubble;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final r = height / 2;
    canvas
      ..translate(margin, margin)
      ..drawRRect(
        RRect.fromLTRBR(
          pillLeft,
          0,
          math.max(pillLeft + height, pillRight),
          height,
          Radius.circular(r),
        ),
        paint,
      )
      ..drawCircle(Offset(r, r), r * bubble, paint);
  }

  @override
  bool shouldRepaint(_ShapesPainter old) =>
      old.margin != margin ||
      old.height != height ||
      old.pillLeft != pillLeft ||
      old.pillRight != pillRight ||
      old.bubble != bubble ||
      old.color != color;
}

class _MagnifierPainter extends CustomPainter {
  const _MagnifierPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.13
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawCircle(Offset(s * 0.42, s * 0.42), s * 0.3, paint)
      ..drawLine(Offset(s * 0.65, s * 0.65), Offset(s * 0.9, s * 0.9), paint);
  }

  @override
  bool shouldRepaint(_MagnifierPainter old) => old.color != color;
}
