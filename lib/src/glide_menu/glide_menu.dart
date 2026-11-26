import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// One tab of a [GlideMenu] and the panel it opens.
@immutable
class GlideMenuItem {
  /// Creates a tab labelled [label] that opens [content].
  const GlideMenuItem({required this.label, required this.content});

  /// The tab's text.
  final String label;

  /// What the dropdown shows for this tab, laid out at its natural size
  /// and scaled down if that is wider than the screen.
  final Widget content;
}

/// A row of tabs whose dropdown glides between them.
///
/// Hover (or tap) a tab and a panel drops in below it. Move to another tab
/// and the same panel glides over and resizes to the new content, which
/// slides in from the side you moved toward while the old content slides
/// out the other way. A small nub on the panel points at the open tab.
/// Leaving both the tabs and the panel closes it after [closeDelay]; so
/// does tapping outside or pressing Escape.
///
/// The panel floats in the nearest [Overlay], so the menu can sit in a
/// header without making room for it.
///
/// When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the panel jumps and swaps instantly.
class GlideMenu extends StatefulWidget {
  /// Creates a glide menu.
  const GlideMenu({
    super.key,
    required this.items,
    this.onChanged,
    this.panelColor,
    this.borderColor,
    this.radius = 14,
    this.gap = 10,
    this.duration = const Duration(milliseconds: 320),
    this.closeDelay = const Duration(milliseconds: 160),
    this.tabStyle,
  });

  /// The tabs, left to right.
  final List<GlideMenuItem> items;

  /// Called with the index of the tab whose panel opens, or null when the
  /// panel closes.
  final ValueChanged<int?>? onChanged;

  /// Background of the panel. Defaults to near-black on light text and
  /// white on dark text, matching the ambient text colour.
  final Color? panelColor;

  /// Outline of the panel. Defaults to a faint ambient text colour.
  final Color? borderColor;

  /// Corner radius of the panel.
  final double radius;

  /// Space between the tabs and the panel.
  final double gap;

  /// Length of a glide or resize.
  final Duration duration;

  /// How long the pointer may be away before the panel closes.
  final Duration closeDelay;

  /// Style of the tab labels, merged over the ambient text style.
  final TextStyle? tabStyle;

  @override
  State<GlideMenu> createState() => _GlideMenuState();
}

class _GlideMenuState extends State<GlideMenu> with SingleTickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();
  final Object _group = Object();
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..addStatusListener(_onReveal);
  late List<GlobalKey> _tabKeys = _keys(widget.items.length);

  /// The open tab, if any.
  int? _open;

  /// The tab opened before [_open], to know which way content slides; once
  /// closed, the tab that was open last.
  int _previous = 0;

  /// Where the panel's centre sits, measured from the row's left edge.
  double _center = 0;

  /// Bumped each time the panel opens from closed, so it appears in place
  /// instead of gliding from where it last was.
  int _session = 0;

  bool _overTabs = false;
  bool _overPanel = false;
  Timer? _closeTimer;

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static List<GlobalKey> _keys(int n) => [for (var i = 0; i < n; i++) GlobalKey()];

  @override
  void didUpdateWidget(GlideMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _tabKeys = _keys(widget.items.length);
      if ((_open ?? -1) >= widget.items.length) _close();
    }
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _reveal.dispose();
    super.dispose();
  }

  void _onReveal(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _portal.isShowing) _portal.hide();
  }

  /// The horizontal centre of tab [index], from the row's left edge.
  double? _tabCenter(int index) {
    final tab = _tabKeys[index].currentContext?.findRenderObject() as RenderBox?;
    final row = context.findRenderObject() as RenderBox?;
    if (tab == null || row == null || !tab.attached) return null;
    return tab.localToGlobal(tab.size.center(Offset.zero), ancestor: row).dx;
  }

  void _show(int index) {
    _closeTimer?.cancel();
    if (_open == index) return;
    final center = _tabCenter(index);
    if (center == null) return;
    setState(() {
      if (_open == null) {
        _session++;
        _previous = index;
      } else {
        _previous = _open!;
      }
      _open = index;
      _center = center;
    });
    _portal.show();
    if (_reduceMotion) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
    widget.onChanged?.call(index);
  }

  void _close() {
    _closeTimer?.cancel();
    if (_open == null) return;
    setState(() {
      // Keep showing the last content while the panel fades out.
      _previous = _open!;
      _open = null;
    });
    if (_reduceMotion) {
      _reveal.value = 0;
    } else {
      _reveal.reverse();
    }
    widget.onChanged?.call(null);
  }

  void _toggle(int index) => _open == index ? _close() : _show(index);

  /// Closes once the pointer has been away from both tabs and panel for a
  /// moment, so crossing the gap between them doesn't close it.
  void _maybeClose() {
    _closeTimer?.cancel();
    if (_overTabs || _overPanel) return;
    _closeTimer = Timer(widget.closeDelay, () {
      if (mounted && !_overTabs && !_overPanel) _close();
    });
  }

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    final ink = base.color ?? const Color(0xFF000000);
    final light = ink.computeLuminance() > 0.5;
    final panel = widget.panelColor ?? (light ? const Color(0xFF18181B) : const Color(0xFFFFFFFF));
    final border = widget.borderColor ?? ink.withValues(alpha: 0.12);
    final open = _open;
    return TapRegion(
      groupId: _group,
      onTapOutside: (_) => _close(),
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (context) => _Panel(
            link: _link,
            group: _group,
            reveal: _reveal,
            center: _center,
            session: _session,
            gap: widget.gap,
            color: panel,
            border: border,
            radius: widget.radius,
            duration: _reduceMotion ? Duration.zero : widget.duration,
            textStyle: base,
            index: open ?? _previous,
            direction: open == null ? 0 : (open - _previous).sign,
            content: widget.items[(open ?? _previous).clamp(0, widget.items.length - 1)].content,
            onHover: (over) {
              _overPanel = over;
              if (over) {
                _closeTimer?.cancel();
              } else {
                _maybeClose();
              }
            },
          ),
          child: MouseRegion(
            onEnter: (_) => _overTabs = true,
            onExit: (_) {
              _overTabs = false;
              _maybeClose();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.items.length; i++)
                  _Tab(
                    key: _tabKeys[i],
                    label: widget.items[i].label,
                    open: open == i,
                    style: base.merge(widget.tabStyle),
                    reduceMotion: _reduceMotion,
                    onHover: () => _show(i),
                    onToggle: () => _toggle(i),
                    onOpen: () => _show(i),
                    onDismiss: _close,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tab: its label, a chevron that flips while open, and a soft pill
/// behind it while open.
class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.label,
    required this.open,
    required this.style,
    required this.reduceMotion,
    required this.onHover,
    required this.onToggle,
    required this.onOpen,
    required this.onDismiss,
  });

  final String label;
  final bool open;
  final TextStyle style;
  final bool reduceMotion;
  final VoidCallback onHover;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ink = style.color ?? const Color(0xFF000000);
    final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 200);
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowDown): _OpenIntent(),
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => onToggle()),
        _OpenIntent: CallbackAction<_OpenIntent>(onInvoke: (_) => onOpen()),
        DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) => onDismiss()),
      },
      child: Semantics(
        button: true,
        expanded: open,
        label: label,
        onTap: onToggle,
        excludeSemantics: true,
        child: MouseRegion(
          onEnter: (_) => onHover(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: ink.withValues(alpha: open ? 0.08 : 0),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: style),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: duration,
                    curve: Curves.easeOut,
                    child: CustomPaint(
                      size: Size.square((style.fontSize ?? 14) * 0.7),
                      painter: _ChevronPainter(ink),
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

class _OpenIntent extends Intent {
  const _OpenIntent();
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.15, s * 0.35)
        ..lineTo(s * 0.5, s * 0.7)
        ..lineTo(s * 0.85, s * 0.35),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, s * 0.14)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

/// The floating panel: it glides to [center], resizes to [content] and
/// slides content in from [direction].
class _Panel extends StatelessWidget {
  const _Panel({
    required this.link,
    required this.group,
    required this.reveal,
    required this.center,
    required this.session,
    required this.gap,
    required this.color,
    required this.border,
    required this.radius,
    required this.duration,
    required this.textStyle,
    required this.index,
    required this.direction,
    required this.content,
    required this.onHover,
  });

  final LayerLink link;
  final Object group;
  final Animation<double> reveal;
  final double center;
  final int session;
  final double gap;
  final Color color;
  final Color border;
  final double radius;
  final Duration duration;
  final TextStyle textStyle;
  final int index;
  final int direction;
  final Widget content;
  final ValueChanged<bool> onHover;

  static const double _nub = 12;

  @override
  Widget build(BuildContext context) {
    const curve = Curves.easeOutCubic;
    return Align(
      alignment: Alignment.topLeft,
      child: TweenAnimationBuilder<double>(
        // A new session starts at the tab instead of gliding from the last.
        key: ValueKey(session),
        tween: Tween(end: center),
        duration: duration,
        curve: curve,
        builder: (context, x, child) => CompositedTransformFollower(
          link: link,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topCenter,
          offset: Offset(x, 0),
          child: child,
        ),
        child: TapRegion(
          groupId: group,
          child: MouseRegion(
            onEnter: (_) => onHover(true),
            onExit: (_) => onHover(false),
            child: FadeTransition(
              opacity: reveal,
              child: AnimatedBuilder(
                animation: reveal,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, 8 * (1 - curve.transform(reveal.value))),
                  child: child,
                ),
                // The transparent strip over the panel bridges the gap, so
                // the pointer can cross it without the panel closing.
                child: Padding(
                  padding: EdgeInsets.only(top: gap),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(color: border),
                          borderRadius: BorderRadius.circular(radius),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x29000000),
                              blurRadius: 30,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(radius),
                          child: _Resize(
                            duration: duration,
                            curve: curve,
                            child: DefaultTextStyle(
                              style: textStyle,
                              child: _Slides(
                                index: index,
                                direction: direction,
                                duration: duration,
                                child: content,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // The nub: a small diamond poking up at the tab.
                      Positioned(
                        top: -_nub / 2,
                        child: Transform.rotate(
                          angle: math.pi / 4,
                          child: Container(
                            width: _nub,
                            height: _nub,
                            decoration: BoxDecoration(
                              color: color,
                              border: Border(
                                top: BorderSide(color: border),
                                left: BorderSide(color: border),
                              ),
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(2)),
                            ),
                          ),
                        ),
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

/// Eases the panel to its content's size; with no [duration] it simply
/// takes that size (a zero-length [AnimatedSize] would relayout itself).
class _Resize extends StatelessWidget {
  const _Resize({required this.duration, required this.curve, required this.child});

  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

/// Swaps panel contents: the new one slides in from [direction] while the
/// old one slides out the other way. Only the new one sets the size.
class _Slides extends StatelessWidget {
  const _Slides({
    required this.index,
    required this.direction,
    required this.duration,
    required this.child,
  });

  final int index;
  final int direction;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final current = ValueKey(index);
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      // A fresh closure each build, so the outgoing content picks up the
      // latest direction too.
      transitionBuilder: (child, animation) {
        final incoming = child.key == current;
        final from = Offset((incoming ? direction : -direction) * 0.3, 0);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: from, end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
      layoutBuilder: (current, previous) => Stack(
        clipBehavior: Clip.none,
        children: [
          for (final child in previous) Positioned(left: 0, top: 0, child: child),
          ?current,
        ],
      ),
      // Content takes its natural size, however tall the overlay is; if
      // that is wider than the screen it is scaled down to fit.
      child: KeyedSubtree(
        key: current,
        child: UnconstrainedBox(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 24),
            child: FittedBox(fit: BoxFit.scaleDown, child: child),
          ),
        ),
      ),
    );
  }
}
