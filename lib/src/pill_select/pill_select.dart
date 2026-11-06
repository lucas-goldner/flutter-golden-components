import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// One option of a [PillSelect].
@immutable
class PillSelectItem<T> {
  /// Creates an option.
  const PillSelectItem({required this.value, required this.label, this.icon, this.enabled = true});

  /// The value reported to [PillSelect.onChanged].
  final T value;

  /// The text shown.
  final String label;

  /// Shown before [label], in the list and in the field once chosen.
  final Widget? icon;

  /// Whether the option can be chosen; disabled options are dimmed.
  final bool enabled;
}

/// A pill-shaped select whose options open in a frosted popup.
///
/// Tapping the field (or pressing Enter, Space or Down while it is focused)
/// opens a translucent, blurred list of [items]. With [alignToSelected] the
/// list opens so the selected option sits exactly over the field, like a
/// desktop menu; otherwise it drops below. Hover or the arrow keys
/// highlight options, Enter or a tap chooses one, and Escape or a tap
/// outside closes the list. The chosen option shows a tick.
///
/// The select is controlled: it shows [value] and reports choices through
/// [onChanged]. Colors follow the ambient text color, so it works on light
/// and dark backgrounds. When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the list appears without animating.
class PillSelect<T> extends StatefulWidget {
  /// Creates a select.
  const PillSelect({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.placeholder = 'Select…',
    this.label,
    this.height = 36,
    this.minWidth,
    this.menuMinWidth = 160,
    this.alignToSelected = true,
  });

  /// The options, in order.
  final List<PillSelectItem<T>> items;

  /// The chosen value, or null for none.
  final T? value;

  /// Called with the value of a chosen option; null disables the select.
  final ValueChanged<T>? onChanged;

  /// Shown in the field when nothing is chosen.
  final String placeholder;

  /// A muted heading at the top of the list, also read by screen readers.
  final String? label;

  /// Height of the field.
  final double height;

  /// Narrowest the field gets.
  final double? minWidth;

  /// Narrowest the list gets.
  final double menuMinWidth;

  /// Whether the list opens with the selected option over the field.
  final bool alignToSelected;

  @override
  State<PillSelect<T>> createState() => _PillSelectState<T>();
}

class _PillSelectState<T> extends State<PillSelect<T>> with SingleTickerProviderStateMixin {
  static const double _itemHeight = 36;
  static const double _labelHeight = 32;

  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _fieldKey = GlobalKey();
  final Object _tapGroup = Object();
  final FocusNode _focus = FocusNode(debugLabel: 'PillSelect');
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    reverseDuration: const Duration(milliseconds: 110),
  );

  bool _open = false;
  bool _hover = false;
  bool _focused = false;
  int _highlight = -1;

  bool get _enabled => widget.onChanged != null;
  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  int get _selected => widget.items.indexWhere((i) => i.value == widget.value);

  @override
  void dispose() {
    _reveal.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setOpen(bool open) {
    if (open == _open || (open && !_enabled)) return;
    setState(() {
      _open = open;
      _highlight = open ? _selected : -1;
    });
    if (open) {
      _portal.show();
      _focus.requestFocus();
      _reduceMotion ? _reveal.value = 1 : _reveal.forward(from: 0);
    } else if (_reduceMotion) {
      _reveal.value = 0;
      _portal.hide();
    } else {
      _reveal.reverse().whenComplete(() {
        if (mounted && !_open) _portal.hide();
      });
    }
  }

  void _highlightAt(int i) {
    if (widget.items[i].enabled && i != _highlight) setState(() => _highlight = i);
  }

  void _choose(int i) {
    final item = widget.items[i];
    if (!item.enabled) return;
    widget.onChanged?.call(item.value);
    _setOpen(false);
  }

  /// The next enabled option from [from] in [step] direction.
  int _next(int from, int step) {
    final n = widget.items.length;
    for (var k = 1; k <= n; k++) {
      final i = ((from + step * k) % n + n) % n;
      if (widget.items[i].enabled) return i;
    }
    return from;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || !_enabled) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final activate =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space;
    if (!_open) {
      if (activate || key == LogicalKeyboardKey.arrowDown) {
        _setOpen(true);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.arrowDown && widget.items.isNotEmpty) {
      setState(() => _highlight = _next(_highlight, 1));
    } else if (key == LogicalKeyboardKey.arrowUp && widget.items.isNotEmpty) {
      setState(() => _highlight = _next(_highlight < 0 ? 0 : _highlight, -1));
    } else if (activate) {
      if (_highlight >= 0) _choose(_highlight);
    } else if (key == LogicalKeyboardKey.escape) {
      _setOpen(false);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = _Colors.of(context);
    final selected = _selected;
    final item = selected >= 0 ? widget.items[selected] : null;
    return Semantics(
      button: true,
      enabled: _enabled,
      expanded: _open,
      label: widget.label,
      value: item?.label ?? widget.placeholder,
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        onFocusChange: (f) => setState(() => _focused = f),
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (context) => _Menu<T>(state: this, colors: colors),
          child: TapRegion(
            groupId: _tapGroup,
            child: MouseRegion(
              cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
              onEnter: (_) => setState(() => _hover = true),
              onExit: (_) => setState(() => _hover = false),
              child: GestureDetector(
                onTap: () => _setOpen(!_open),
                child: Opacity(
                  opacity: _enabled ? 1 : 0.5,
                  child: AnimatedContainer(
                    key: _fieldKey,
                    duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
                    height: widget.height,
                    constraints: BoxConstraints(minWidth: widget.minWidth ?? 0),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: colors.ink.withValues(alpha: _hover || _open ? 0.08 : 0.04),
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      border: Border.all(
                        color: colors.ink.withValues(alpha: _focused && !_open ? 0.4 : 0.12),
                      ),
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(color: colors.ink, size: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item?.icon case final icon?) ...[icon, const SizedBox(width: 8)],
                          Flexible(
                            child: Text(
                              item?.label ?? widget.placeholder,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: item == null ? colors.muted : colors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox.square(
                            dimension: 14,
                            child: CustomPaint(painter: _UnfoldPainter(colors.muted)),
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
    );
  }
}

/// Colors derived from the ambient text color.
@immutable
class _Colors {
  const _Colors({required this.ink, required this.dark});

  factory _Colors.of(BuildContext context) {
    final ink = DefaultTextStyle.of(context).style.color ?? const Color(0xFF0A0A0A);
    return _Colors(ink: ink, dark: ink.computeLuminance() > 0.5);
  }

  final Color ink;
  final bool dark;

  Color get muted => ink.withValues(alpha: 0.55);
  Color get panel => dark ? const Color(0xC71C1C21) : const Color(0xB8FFFFFF);
}

/// The popup list, positioned against the field.
class _Menu<T> extends StatelessWidget {
  const _Menu({required this.state, required this.colors});

  final _PillSelectState<T> state;
  final _Colors colors;

  @override
  Widget build(BuildContext context) {
    final widget = state.widget;
    final field = state._fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (field == null || overlay == null || !field.hasSize) return const SizedBox.shrink();
    final fieldRect = field.localToGlobal(Offset.zero, ancestor: overlay) & field.size;
    final width = math.max(fieldRect.width + 8, widget.menuMinWidth);
    final labelHeight = widget.label == null ? 0.0 : _PillSelectState._labelHeight;
    final selected = state._selected;
    final contentHeight = 8 + labelHeight + widget.items.length * _PillSelectState._itemHeight;
    final screen = overlay.size;
    final height = math.min(contentHeight, math.max(80.0, screen.height - 16));
    var top = fieldRect.bottom + 4;
    var left = fieldRect.left;
    if (widget.alignToSelected && selected >= 0) {
      // Put the selected row's text right where the field's text is.
      top =
          fieldRect.top -
          (4 + labelHeight + selected * _PillSelectState._itemHeight) +
          (fieldRect.height - _PillSelectState._itemHeight) / 2;
      left = fieldRect.left - 4;
    }
    top = top.clamp(8.0, math.max(8.0, screen.height - 8 - height));
    left = left.clamp(8.0, math.max(8.0, screen.width - 8 - width));
    // Grow from the point of the field the list covers.
    final origin = Alignment(0, (((fieldRect.center.dy - top) / height) * 2 - 1).clamp(-1.0, 1.0));
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: TapRegion(
        groupId: state._tapGroup,
        onTapOutside: (_) => state._setOpen(false),
        child: AnimatedBuilder(
          animation: state._reveal,
          builder: (context, child) {
            final t = Curves.easeOutCubic.transform(state._reveal.value);
            return Opacity(
              opacity: t,
              child: Transform.scale(scale: 0.96 + 0.04 * t, alignment: origin, child: child),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: colors.dark ? 0.5 : 0.22),
                  blurRadius: 44,
                  spreadRadius: -12,
                  offset: const Offset(0, 22),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.ink.withValues(alpha: 0.06)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(4),
                    children: [
                      if (widget.label case final label?)
                        SizedBox(
                          height: labelHeight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                label,
                                style: TextStyle(fontSize: 12, color: colors.muted),
                              ),
                            ),
                          ),
                        ),
                      for (final (i, item) in widget.items.indexed)
                        _Row(
                          item: item,
                          colors: colors,
                          selected: i == selected,
                          highlighted: i == state._highlight,
                          onHover: () => state._highlightAt(i),
                          onTap: () => state._choose(i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One option in the list.
class _Row extends StatelessWidget {
  const _Row({
    required this.item,
    required this.colors,
    required this.selected,
    required this.highlighted,
    required this.onHover,
    required this.onTap,
  });

  final PillSelectItem<Object?> item;
  final _Colors colors;
  final bool selected;
  final bool highlighted;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: item.enabled,
      label: item.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: item.enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => onHover(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: item.enabled ? onTap : null,
          child: Opacity(
            opacity: item.enabled ? 1 : 0.45,
            child: Container(
              height: _PillSelectState._itemHeight,
              padding: const EdgeInsets.only(left: 12, right: 10),
              decoration: BoxDecoration(
                color: highlighted && item.enabled
                    ? colors.ink.withValues(alpha: 0.08)
                    : const Color(0x00000000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: colors.ink, size: 16),
                child: Row(
                  children: [
                    if (item.icon case final icon?) ...[icon, const SizedBox(width: 10)],
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: TextStyle(fontSize: 14, color: colors.ink),
                      ),
                    ),
                    SizedBox.square(
                      dimension: 14,
                      child: selected ? CustomPaint(painter: _TickPainter(colors.ink)) : null,
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

/// Two small chevrons, one up and one down.
class _UnfoldPainter extends CustomPainter {
  const _UnfoldPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(
        Path()
          ..moveTo(w * 0.28, w * 0.4)
          ..lineTo(w * 0.5, w * 0.18)
          ..lineTo(w * 0.72, w * 0.4),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(w * 0.28, w * 0.6)
          ..lineTo(w * 0.5, w * 0.82)
          ..lineTo(w * 0.72, w * 0.6),
        paint,
      );
  }

  @override
  bool shouldRepaint(_UnfoldPainter old) => old.color != color;
}

/// A check mark.
class _TickPainter extends CustomPainter {
  const _TickPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.18, w * 0.52)
        ..lineTo(w * 0.42, w * 0.76)
        ..lineTo(w * 0.84, w * 0.26),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.13
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.color != color;
}
