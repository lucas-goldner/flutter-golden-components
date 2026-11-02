import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// One icon of a [MagnifyDock].
@immutable
class MagnifyDockItem {
  /// Creates a dock item.
  const MagnifyDockItem({required this.label, required this.icon, this.onTap});

  /// Shown above the icon while it is hovered or focused, and read by
  /// screen readers.
  final String label;

  /// The icon, drawn at half the item's size.
  final Widget icon;

  /// Called when the item is tapped or activated with Enter or Space.
  final VoidCallback? onTap;
}

/// A dock whose icons swell as the pointer passes over them.
///
/// Each item is a [baseSize] circle. While the pointer moves along the
/// dock, every item springs toward a size between [baseSize] and
/// [magnification] depending on how close the pointer is to its centre:
/// full size right under the pointer, falling off along [falloff] to
/// [baseSize] at [distance] pixels away. The dock grows taller so the
/// swollen icons have room, and the item under the pointer shows its label
/// above it. Touch input drags across the dock the same way, and a focused
/// item magnifies as if the pointer were over it.
///
/// When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) sizes change without springing.
class MagnifyDock extends StatefulWidget {
  /// Creates a dock.
  const MagnifyDock({
    super.key,
    required this.items,
    this.baseSize = 40,
    this.magnification = 80,
    this.distance = 150,
    this.falloff = Curves.linear,
    this.gap = 16,
    this.panelHeight = 64,
    this.spring = defaultSpring,
    this.panelColor,
    this.itemColor,
    this.labelColor,
  }) : assert(baseSize > 0),
       assert(magnification >= baseSize),
       assert(distance > 0);

  /// A light, snappy spring.
  static const SpringDescription defaultSpring = SpringDescription(
    mass: 0.1,
    stiffness: 150,
    damping: 12,
  );

  /// The icons, left to right.
  final List<MagnifyDockItem> items;

  /// Size of an item at rest.
  final double baseSize;

  /// Size of an item right under the pointer.
  final double magnification;

  /// How far from an item's centre the pointer still magnifies it.
  final double distance;

  /// How magnification falls off with distance, from 0 (under the pointer)
  /// to 1 ([distance] away).
  final Curve falloff;

  /// Space between items.
  final double gap;

  /// Height of the dock panel itself.
  final double panelHeight;

  /// The spring every size moves on.
  final SpringDescription spring;

  /// Panel color. Defaults to the ambient text color at 4%.
  final Color? panelColor;

  /// Item circle color. Defaults to the ambient text color at 10%.
  final Color? itemColor;

  /// Background of the hover label. Defaults to [itemColor].
  final Color? labelColor;

  @override
  State<MagnifyDock> createState() => _MagnifyDockState();
}

/// A value moving on a spring toward a target.
class _Spring {
  _Spring(this.value) : target = value;

  double value;
  double target;
  double velocity = 0;

  /// Advances by [dt] seconds; returns whether it is still moving.
  bool step(double dt, SpringDescription s) {
    var left = dt;
    while (left > 0) {
      // Small fixed steps keep the light spring stable.
      final h = math.min(1 / 600, left);
      final a = (-s.stiffness * (value - target) - s.damping * velocity) / s.mass;
      velocity += a * h;
      value += velocity * h;
      left -= h;
    }
    if ((value - target).abs() < 0.01 && velocity.abs() < 0.5) {
      value = target;
      velocity = 0;
      return false;
    }
    return true;
  }

  void jump() {
    value = target;
    velocity = 0;
  }
}

class _MagnifyDockState extends State<MagnifyDock> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  final GlobalKey _panelKey = GlobalKey();
  late List<GlobalKey> _keys;
  late List<_Spring> _sizes;
  late final _Spring _height = _Spring(widget.panelHeight);

  /// Item under the pointer (or focused), whose label shows.
  int? _hovered;

  /// Item with keyboard focus.
  int? _focused;

  /// Pointer x in global coordinates while it is over the dock.
  double? _pointerX;

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// The dock's height while magnified, so swollen icons and labels fit.
  double get _raisedHeight => math.max(widget.panelHeight, widget.magnification * 1.5 + 4);

  @override
  void initState() {
    super.initState();
    _resetItems();
  }

  void _resetItems() {
    _keys = [for (final _ in widget.items) GlobalKey()];
    _sizes = [for (final _ in widget.items) _Spring(widget.baseSize)];
  }

  @override
  void didUpdateWidget(MagnifyDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _resetItems();
      _hovered = null;
      _focused = null;
    }
    _retarget();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  double _sizeFor(double x, Rect rect) {
    final t = widget.falloff.transform(
      ((x - rect.center.dx).abs() / widget.distance).clamp(0.0, 1.0),
    );
    return widget.magnification + (widget.baseSize - widget.magnification) * t;
  }

  /// Sets every target from the pointer (or the focused item) and starts
  /// the springs.
  void _retarget() {
    var x = _pointerX;
    final focused = _focused;
    if (x == null && focused != null) x = _rectOf(_keys[focused])?.center.dx;
    final engaged = x != null;
    _height.target = engaged ? _raisedHeight : widget.panelHeight;
    for (var i = 0; i < _sizes.length; i++) {
      final rect = engaged ? _rectOf(_keys[i]) : null;
      _sizes[i].target = rect == null ? widget.baseSize : _sizeFor(x!, rect);
    }
    if (_reduceMotion) {
      _height.jump();
      for (final s in _sizes) {
        s.jump();
      }
    } else if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _pointer(Offset global) {
    int? hovered;
    for (var i = 0; i < _keys.length; i++) {
      if (_rectOf(_keys[i])?.contains(global) ?? false) hovered = i;
    }
    final over = (_rectOf(_panelKey)?.contains(global) ?? false) || hovered != null;
    if (!over) return _leave();
    setState(() {
      _pointerX = global.dx;
      _hovered = hovered;
    });
    _retarget();
  }

  void _leave() {
    if (_pointerX == null && _hovered == null) return;
    setState(() {
      _pointerX = null;
      _hovered = _focused;
    });
    _retarget();
  }

  void _focus(int index, bool focused) {
    setState(() {
      _focused = focused ? index : (_focused == index ? null : _focused);
      if (_pointerX == null) _hovered = _focused;
    });
    _retarget();
  }

  void _tick(Duration elapsed) {
    final dt = math.min((elapsed - _last).inMicroseconds / 1e6, 1 / 20);
    _last = elapsed;
    var moving = _height.step(dt, widget.spring);
    for (final s in _sizes) {
      moving = s.step(dt, widget.spring) || moving;
    }
    if (!moving) _ticker.stop();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ink = DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    final itemColor = widget.itemColor ?? ink.withValues(alpha: 0.1);
    // A solid label: light on dark text, dark on light text.
    final labelColor =
        widget.labelColor ??
        (ink.computeLuminance() < 0.5 ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C21));
    final n = widget.items.length;
    final width =
        32 +
        _sizes.fold(0.0, (sum, s) => sum + math.max(0, s.value)) +
        widget.gap * math.max(0, n - 1);
    final panel = Container(
      key: _panelKey,
      width: width,
      height: widget.panelHeight,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: widget.panelColor ?? ink.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: OverflowBox(
        // Swollen icons grow up out of the panel.
        alignment: Alignment.bottomCenter,
        maxHeight: double.infinity,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: widget.gap,
          children: [
            for (var i = 0; i < widget.items.length; i++)
              _DockItem(
                key: _keys[i],
                item: widget.items[i],
                size: math.max(0, _sizes[i].value),
                color: itemColor,
                labelColor: labelColor,
                ink: ink,
                showLabel: _hovered == i,
                onFocus: (f) => _focus(i, f),
              ),
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      label: 'Dock',
      child: MouseRegion(
        onHover: (e) => _pointer(e.position),
        onExit: (_) => _leave(),
        child: Listener(
          onPointerDown: (e) {
            if (e.kind != PointerDeviceKind.mouse) _pointer(e.position);
          },
          onPointerMove: (e) {
            if (e.kind != PointerDeviceKind.mouse) _pointer(e.position);
          },
          onPointerUp: (e) {
            if (e.kind != PointerDeviceKind.mouse) _leave();
          },
          onPointerCancel: (_) => _leave(),
          child: SizedBox(
            height: math.max(widget.panelHeight, _height.value),
            child: Align(alignment: Alignment.bottomCenter, child: panel),
          ),
        ),
      ),
    );
  }
}

/// One round dock item with its icon and hover label.
class _DockItem extends StatelessWidget {
  const _DockItem({
    super.key,
    required this.item,
    required this.size,
    required this.color,
    required this.labelColor,
    required this.ink,
    required this.showLabel,
    required this.onFocus,
  });

  final MagnifyDockItem item;
  final double size;
  final Color color;
  final Color labelColor;
  final Color ink;
  final bool showLabel;
  final ValueChanged<bool> onFocus;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onFocusChange: onFocus,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => item.onTap?.call()),
        },
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        child: GestureDetector(
          onTap: item.onTap,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ),
                SizedBox.square(
                  dimension: size / 2,
                  child: IconTheme.merge(
                    data: IconThemeData(color: ink.withValues(alpha: 0.75)),
                    child: FittedBox(child: item.icon),
                  ),
                ),
                Positioned(
                  left: -80,
                  right: -80,
                  top: -26,
                  child: IgnorePointer(
                    child: _Label(
                      text: item.label,
                      shown: showLabel,
                      background: labelColor,
                      ink: ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The small label that floats up above a hovered item.
class _Label extends StatelessWidget {
  const _Label({
    required this.text,
    required this.shown,
    required this.background,
    required this.ink,
  });

  final String text;
  final bool shown;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final duration = (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: shown ? 1 : 0),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, t, child) => t <= 0.001
          ? const SizedBox.shrink()
          : Opacity(
              opacity: t,
              child: Transform.translate(offset: Offset(0, -10 * t), child: child),
            ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ink.withValues(alpha: 0.08)),
          ),
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.8)),
          ),
        ),
      ),
    );
  }
}
