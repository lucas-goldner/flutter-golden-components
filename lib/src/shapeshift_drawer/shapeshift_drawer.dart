import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// What [ShapeshiftDrawer.of] gives the trigger and the views.
class ShapeshiftDrawerController extends InheritedWidget {
  const ShapeshiftDrawerController._({
    required this.isOpen,
    required this.view,
    required this.canGoBack,
    required _ShapeshiftDrawerState state,
    required super.child,
  }) : _state = state;

  final _ShapeshiftDrawerState _state;

  /// Whether the drawer is showing.
  final bool isOpen;

  /// Name of the view being shown.
  final String view;

  /// Whether [back] has a view to return to.
  final bool canGoBack;

  /// Opens the drawer, on its initial view or on [view].
  void open([String? view]) => _state._open(view);

  /// Closes the drawer.
  void close() => _state._close();

  /// Morphs the drawer into the view named [view].
  void show(String view) => _state._show(view);

  /// Morphs back to the previous view, if any.
  void back() => _state._back();

  @override
  bool updateShouldNotify(ShapeshiftDrawerController old) =>
      old.isOpen != isOpen || old.view != view || old.canGoBack != canGoBack;
}

/// A bottom drawer that changes shape as it moves between views.
///
/// [child] (usually a button) opens it, through
/// `ShapeshiftDrawer.of(context).open()`. The drawer floats up from the
/// bottom over a dimmed backdrop and shows one of [views] at a time. Any
/// view can call `show('name')` to morph into another: the content
/// cross-fades while the sheet's height eases to fit the new view, and
/// `back()` returns to where it came from. Drag the sheet down, tap the
/// backdrop, press Escape or use the close button to dismiss it; it opens
/// on [initialView] again next time.
///
/// Build views with [ShapeshiftDrawerHeader], [ShapeshiftDrawerTile] and
/// [ShapeshiftDrawerAction], or anything else. Needs an [Overlay] above it,
/// which [WidgetsApp] provides. When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the drawer and its views switch
/// without animating.
class ShapeshiftDrawer extends StatefulWidget {
  /// Creates a drawer.
  const ShapeshiftDrawer({
    super.key,
    required this.views,
    required this.child,
    this.initialView = 'default',
    this.onOpenChanged,
    this.onViewChanged,
    this.showCloseButton = true,
    this.maxWidth = 361,
    this.radius = 36,
    this.color,
    this.barrierColor = const Color(0x4D000000),
  });

  /// The views by name; [initialView] is shown first.
  final Map<String, WidgetBuilder> views;

  /// What opens the drawer, usually a button that calls
  /// `ShapeshiftDrawer.of(context).open()`.
  final Widget child;

  /// The view shown when the drawer opens.
  final String initialView;

  /// Called when the drawer opens or closes.
  final ValueChanged<bool>? onOpenChanged;

  /// Called with the name of each view shown.
  final ValueChanged<String>? onViewChanged;

  /// Whether to show a round close button in the top corner.
  final bool showCloseButton;

  /// Widest the sheet gets.
  final double maxWidth;

  /// Corner radius of the sheet.
  final double radius;

  /// Sheet color. Defaults to white, or near-black when the ambient text
  /// is light.
  final Color? color;

  /// The tint over the page while the drawer is open.
  final Color barrierColor;

  /// The drawer above [context], for its trigger and views.
  static ShapeshiftDrawerController of(BuildContext context) {
    final controller = context.dependOnInheritedWidgetOfExactType<ShapeshiftDrawerController>();
    assert(controller != null, 'No ShapeshiftDrawer above this context.');
    return controller!;
  }

  @override
  State<ShapeshiftDrawer> createState() => _ShapeshiftDrawerState();
}

class _ShapeshiftDrawerState extends State<ShapeshiftDrawer> with SingleTickerProviderStateMixin {
  static const Curve _slideCurve = Cubic(0.32, 0.72, 0, 1);

  final OverlayPortalController _portal = OverlayPortalController();
  final FocusScopeNode _focus = FocusScopeNode(debugLabel: 'ShapeshiftDrawer');
  final GlobalKey _sheetKey = GlobalKey();

  /// 0 hidden below the bottom edge, 1 fully up.
  late final AnimationController _slide =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
        ..addStatusListener((status) {
          if (status == AnimationStatus.dismissed && _portal.isShowing) {
            _portal.hide();
            if (mounted) setState(() => _history = [widget.initialView]);
          }
        });

  bool _isOpen = false;
  late List<String> _history = [widget.initialView];

  /// How far the sheet has been dragged down, in pixels.
  double _drag = 0;

  /// Whether the last view change went back, for the transition direction.
  bool _wentBack = false;

  String get _view => _history.last;
  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void dispose() {
    _slide.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _open([String? view]) {
    setState(() {
      _isOpen = true;
      _drag = 0;
      if (view != null && view != _view) _history = [view];
    });
    _portal.show();
    if (_reduceMotion) {
      _slide.value = 1;
    } else {
      _slide.animateTo(1, curve: _slideCurve);
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isOpen) _focus.requestFocus();
    });
    widget.onOpenChanged?.call(true);
  }

  void _close() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    if (_reduceMotion) {
      _slide.value = 0;
    } else {
      _slide.animateBack(0, curve: _slideCurve);
    }
    widget.onOpenChanged?.call(false);
  }

  void _show(String view) {
    if (view == _view) return;
    assert(widget.views.containsKey(view), 'No view named "$view".');
    setState(() {
      _wentBack = false;
      _history = [..._history, view];
    });
    widget.onViewChanged?.call(view);
  }

  void _back() {
    if (_history.length < 2) return;
    setState(() {
      _wentBack = true;
      _history = _history.sublist(0, _history.length - 1);
    });
    widget.onViewChanged?.call(_view);
  }

  double get _sheetHeight {
    final box = _sheetKey.currentContext?.findRenderObject() as RenderBox?;
    return box != null && box.hasSize ? box.size.height : 300;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      final next = _drag + d.delta.dy;
      // Dragging up meets growing resistance; down follows the finger.
      _drag = next >= 0 ? next : -math.sqrt(-next) * 2;
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final travel = _sheetHeight + 16;
    final velocity = d.primaryVelocity ?? 0;
    if (_drag > travel * 0.25 || velocity > 500) {
      // Hand the dragged distance over to the slide so it keeps going.
      _slide.value = 1 - (_drag / travel).clamp(0.0, 1.0);
      setState(() => _drag = 0);
      _close();
    } else {
      setState(() => _drag = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShapeshiftDrawerController._(
      isOpen: _isOpen,
      view: _view,
      canGoBack: _history.length > 1,
      state: this,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) => _Overlay(state: this),
        child: widget.child,
      ),
    );
  }
}

/// The backdrop and the sheet.
class _Overlay extends StatelessWidget {
  const _Overlay({required this.state});

  final _ShapeshiftDrawerState state;

  @override
  Widget build(BuildContext context) {
    final widget = state.widget;
    final ink = DefaultTextStyle.of(state.context).style.color ?? const Color(0xFF0A0A0A);
    final dark = ink.computeLuminance() > 0.5;
    final sheetColor = widget.color ?? (dark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF));
    final reduce = state._reduceMotion;
    return ShapeshiftDrawerController._(
      isOpen: state._isOpen,
      view: state._view,
      canGoBack: state._history.length > 1,
      state: state,
      child: DefaultTextStyle.merge(
        style: DefaultTextStyle.of(state.context).style,
        child: FocusScope(
          node: state._focus,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
              state._close();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: AnimatedBuilder(
            animation: state._slide,
            builder: (context, _) {
              final t = state._slide.value;
              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: state._close,
                      child: ColoredBox(
                        color: widget.barrierColor.withValues(
                          alpha: widget.barrierColor.a * t.clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: FractionalTranslation(
                      // Fully below the bottom edge (and its 16 px gap) at 0.
                      translation: Offset(0, (1 - t) * 1.12),
                      child: Transform.translate(
                        offset: Offset(0, state._drag),
                        child: Center(
                          child: GestureDetector(
                            onVerticalDragUpdate: state._onDragUpdate,
                            onVerticalDragEnd: state._onDragEnd,
                            child: ConstrainedBox(
                              key: state._sheetKey,
                              constraints: BoxConstraints(
                                maxWidth: widget.maxWidth,
                                maxHeight: MediaQuery.sizeOf(context).height - 48,
                              ),
                              child: Semantics(
                                scopesRoute: true,
                                explicitChildNodes: true,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: sheetColor,
                                    borderRadius: BorderRadius.circular(widget.radius),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x33000000),
                                        blurRadius: 40,
                                        offset: Offset(0, 16),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(widget.radius),
                                    child: Stack(
                                      children: [
                                        _Views(
                                          view: state._view,
                                          builder: widget.views[state._view],
                                          back: state._wentBack,
                                          reduceMotion: reduce,
                                        ),
                                        if (widget.showCloseButton)
                                          Positioned(
                                            top: 26,
                                            right: 26,
                                            child: _CloseButton(ink: ink, onTap: state._close),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The current view, cross-fading into the next while the height eases.
class _Views extends StatelessWidget {
  const _Views({
    required this.view,
    required this.builder,
    required this.back,
    required this.reduceMotion,
  });

  final String view;
  final WidgetBuilder? builder;
  final bool back;
  final bool reduceMotion;

  static const Curve _ease = Cubic(0.26, 0.08, 0.25, 1);

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: AnimatedSwitcher(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        switchInCurve: _ease,
        switchOutCurve: _ease,
        // The leaving view floats on top so the height follows the new one.
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [
            for (final p in previous) Positioned(top: 0, left: 0, right: 0, child: p),
            ?current,
          ],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: back ? 1.04 : 0.96, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(view),
          child: Builder(builder: (context) => builder?.call(context) ?? const SizedBox.shrink()),
        ),
      ),
    );
    if (reduceMotion) return SingleChildScrollView(child: content);
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: const Cubic(0.25, 1, 0.5, 1),
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(physics: const ClampingScrollPhysics(), child: content),
    );
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.ink, required this.onTap});

  final Color ink;
  final VoidCallback onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.ink.withValues(alpha: 0.06),
            ),
            child: CustomPaint(painter: _CrossPainter(widget.ink.withValues(alpha: 0.55))),
          ),
        ),
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(c + const Offset(-4.5, -4.5), c + const Offset(4.5, 4.5), p)
      ..drawLine(c + const Offset(4.5, -4.5), c + const Offset(-4.5, 4.5), p);
  }

  @override
  bool shouldRepaint(_CrossPainter old) => old.color != color;
}

/// The top of a drawer view: an optional [icon], a [title] and a
/// [description].
class ShapeshiftDrawerHeader extends StatelessWidget {
  /// Creates a view header.
  const ShapeshiftDrawerHeader({super.key, required this.title, this.description, this.icon});

  /// The view's title.
  final String title;

  /// A line or two under the title.
  final String? description;

  /// Shown above the title.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final ink = DefaultTextStyle.of(context).style.color ?? const Color(0xFF0A0A0A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon case final icon?) ...[
          IconTheme.merge(
            data: IconThemeData(color: ink, size: 40),
            child: icon,
          ),
          const SizedBox(height: 16),
        ],
        Padding(
          // Leave room for the close button.
          padding: const EdgeInsets.only(right: 40),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              height: 1.2,
              color: ink,
            ),
          ),
        ),
        if (description case final description?) ...[
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(fontSize: 16, height: 1.45, color: ink.withValues(alpha: 0.55)),
          ),
        ],
      ],
    );
  }
}

/// A full-width menu row in a drawer view, usually opening another view.
class ShapeshiftDrawerTile extends StatefulWidget {
  /// Creates a menu row.
  const ShapeshiftDrawerTile({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.destructive = false,
  });

  /// The row's text.
  final String label;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Shown before [label].
  final Widget? icon;

  /// Whether the row does something destructive; shown in red.
  final bool destructive;

  @override
  State<ShapeshiftDrawerTile> createState() => _ShapeshiftDrawerTileState();
}

class _ShapeshiftDrawerTileState extends State<ShapeshiftDrawerTile> {
  bool _pressed = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ink = DefaultTextStyle.of(context).style.color ?? const Color(0xFF0A0A0A);
    final color = widget.destructive ? const Color(0xFFE5484D) : ink;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: (widget.destructive ? color : ink).withValues(alpha: _hover ? 0.1 : 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  if (widget.icon case final icon?) ...[
                    IconTheme.merge(
                      data: IconThemeData(color: color, size: 18),
                      child: icon,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
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

/// A pill button for the bottom of a drawer view.
class ShapeshiftDrawerAction extends StatefulWidget {
  /// Creates an action button.
  const ShapeshiftDrawerAction({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.destructive = false,
  });

  /// The button's text.
  final String label;

  /// Called when the button is tapped.
  final VoidCallback onTap;

  /// Whether this is the main action (filled).
  final bool primary;

  /// Whether the action is destructive (red).
  final bool destructive;

  @override
  State<ShapeshiftDrawerAction> createState() => _ShapeshiftDrawerActionState();
}

class _ShapeshiftDrawerActionState extends State<ShapeshiftDrawerAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ink = DefaultTextStyle.of(context).style.color ?? const Color(0xFF0A0A0A);
    final dark = ink.computeLuminance() > 0.5;
    final accent = widget.destructive
        ? const Color(0xFFE5484D)
        : (dark ? ink : const Color(0xFF18181B));
    final filled = widget.primary || widget.destructive;
    final fill = filled ? accent : ink.withValues(alpha: 0.06);
    final text = filled
        ? (accent.computeLuminance() > 0.5 ? const Color(0xFF0A0A0A) : const Color(0xFFFFFFFF))
        : ink;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 120),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(999)),
              child: Text(
                widget.label,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
