import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A highlight that glides behind whichever item is active.
///
/// Every one of [items] is built by [itemBuilder] and laid out by
/// [layoutBuilder] (a row by default; a wrap, column or grid works too).
/// One [decoration] sits behind the active item and glides to the next one
/// on [spring] when the selection changes, so a row of tabs, a toolbar or a
/// grid of cards shares a single moving highlight. It fades in when nothing
/// was active and fades out when the selection is cleared.
///
/// Items activate on tap, Enter or Space, or on hover with [hover] (where
/// leaving an item clears the selection). Pass [value] to control the
/// selection from outside; otherwise it starts at [initialValue].
///
/// When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the highlight jumps instead.
class GlideHighlight<T> extends StatefulWidget {
  /// Creates a gliding highlight over [items].
  const GlideHighlight({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.value,
    this.initialValue,
    this.onChanged,
    this.decoration = const BoxDecoration(
      color: Color(0x14000000),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    this.spring = defaultSpring,
    this.hover = false,
    this.layoutBuilder,
  });

  /// A quick spring with a hint of overshoot.
  static const SpringDescription defaultSpring = SpringDescription(
    mass: 1,
    stiffness: 440,
    damping: 33,
  );

  /// The items, in order.
  final List<T> items;

  /// Builds one item; `active` is true for the highlighted one.
  final Widget Function(BuildContext context, T item, bool active) itemBuilder;

  /// The active item when the selection is controlled from outside.
  final T? value;

  /// The item active at first when [value] is not given.
  final T? initialValue;

  /// Called with the newly active item, or null when it is cleared.
  final ValueChanged<T?>? onChanged;

  /// How the highlight looks.
  final Decoration decoration;

  /// The spring the highlight glides on.
  final SpringDescription spring;

  /// Whether items activate on hover instead of tap.
  final bool hover;

  /// Arranges the built items; defaults to a [Row] sized to its content.
  final Widget Function(List<Widget> children)? layoutBuilder;

  @override
  State<GlideHighlight<T>> createState() => _GlideHighlightState<T>();
}

class _GlideHighlightState<T> extends State<GlideHighlight<T>> with TickerProviderStateMixin {
  final GlobalKey _stackKey = GlobalKey();
  final Map<T, GlobalKey> _keys = {};

  /// 0 at the old rect, 1 at the new one (overshoots on the spring).
  late final AnimationController _move = AnimationController.unbounded(vsync: this, value: 1)
    ..addStatusListener((status) {
      // The spring stops within its tolerance; land exactly on the item.
      if (status == AnimationStatus.completed) _move.value = 1;
    });

  /// Highlight opacity.
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  late T? _active = widget.value ?? widget.initialValue;
  Rect? _from;
  Rect? _to;

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    if (_active != null) _fade.value = 1;
  }

  @override
  void didUpdateWidget(GlideHighlight<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _active) {
      _select(widget.value, notify: false);
    }
  }

  @override
  void dispose() {
    _move.dispose();
    _fade.dispose();
    super.dispose();
  }

  Rect? _rectOf(T item) {
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final box = _keys[item]?.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || box == null || !stack.hasSize || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero, ancestor: stack) & box.size;
  }

  Rect? get _current {
    final to = _to;
    if (to == null) return null;
    final from = _from;
    return from == null ? to : Rect.lerp(from, to, _move.value);
  }

  void _select(T? item, {bool notify = true}) {
    if (item == _active) return;
    final target = item == null ? null : _rectOf(item);
    setState(() {
      _active = item;
      if (item == null) {
        _reduceMotion ? _fade.value = 0 : _fade.reverse();
        return;
      }
      if (target != null) {
        final showing = _fade.value > 0.01 && _to != null;
        if (showing && !_reduceMotion) {
          // Glide from wherever the highlight is now, even mid-glide.
          _from = _current;
          _to = target;
          _move.animateWith(SpringSimulation(widget.spring, 0, 1, 0));
        } else {
          _from = null;
          _to = target;
          _move.value = 1;
        }
      }
      _reduceMotion ? _fade.value = 1 : _fade.forward();
    });
    if (notify) widget.onChanged?.call(item);
  }

  /// Follows layout changes (resizes, reflow) once a frame is laid out.
  void _sync(Duration _) {
    if (!mounted) return;
    final item = _active;
    if (item == null) return;
    final target = _rectOf(item);
    if (target == null) return;
    if (_to == null || (!_move.isAnimating && target != _to)) {
      setState(() {
        _from = null;
        _to = target;
        _move.value = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback(_sync);
    final children = [
      for (final item in widget.items)
        _Item(
          key: _keys.putIfAbsent(item, GlobalKey.new),
          active: item == _active,
          hover: widget.hover,
          onActivate: () => _select(item),
          onLeave: () {
            if (_active == item) _select(null);
          },
          child: widget.itemBuilder(context, item, item == _active),
        ),
    ];
    return Stack(
      key: _stackKey,
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_move, _fade]),
          builder: (context, _) {
            final rect = _current;
            if (rect == null || _fade.value <= 0) return const SizedBox.shrink();
            return Positioned.fromRect(
              rect: rect,
              child: IgnorePointer(
                child: Opacity(
                  opacity: Curves.easeOut.transform(_fade.value),
                  child: DecoratedBox(decoration: widget.decoration),
                ),
              ),
            );
          },
        ),
        widget.layoutBuilder?.call(children) ??
            Row(mainAxisSize: MainAxisSize.min, children: children),
      ],
    );
  }
}

/// One item: tap, keyboard and hover activation, and its semantics.
class _Item extends StatelessWidget {
  const _Item({
    super.key,
    required this.active,
    required this.hover,
    required this.onActivate,
    required this.onLeave,
    required this.child,
  });

  final bool active;
  final bool hover;
  final VoidCallback onActivate;
  final VoidCallback onLeave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => onActivate())},
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        child: MouseRegion(
          onEnter: hover ? (_) => onActivate() : null,
          onExit: hover ? (_) => onLeave() : null,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onActivate, child: child),
        ),
      ),
    );
  }
}
