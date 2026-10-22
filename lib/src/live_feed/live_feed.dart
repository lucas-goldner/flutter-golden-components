import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// A vertical feed that reveals its [children] one at a time, newest on top,
/// like incoming notifications.
///
/// Every [interval] the next child springs in at the top (growing from its
/// top edge while scaling and fading in) and pushes the others down. By
/// default it stops after the last child; with [loop] it starts over, and
/// [maxVisible] caps how many items stay in the feed (the oldest drop off
/// the bottom).
///
/// The feed grows downwards, so give it a clipped, bounded area (and maybe a
/// fade at the bottom). When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the items are shown without
/// animation.
class LiveFeed extends StatefulWidget {
  /// Creates a live feed.
  const LiveFeed({
    super.key,
    required this.children,
    this.interval = const Duration(seconds: 1),
    this.gap = 16,
    this.loop = false,
    this.maxVisible,
    this.playing = true,
    this.spring = const SpringDescription(mass: 1, stiffness: 350, damping: 40),
  }) : assert(gap >= 0),
       assert(maxVisible == null || maxVisible > 0);

  /// Items in the order they arrive.
  final List<Widget> children;

  /// Time between two arrivals.
  final Duration interval;

  /// Vertical space between items.
  final double gap;

  /// Start over with the first child after the last one.
  final bool loop;

  /// Most items kept in the feed; older ones are dropped. Null keeps all.
  final int? maxVisible;

  /// Whether new items keep arriving. Set to false to pause.
  final bool playing;

  /// Spring each new item settles with.
  final SpringDescription spring;

  @override
  State<LiveFeed> createState() => _LiveFeedState();
}

class _LiveFeedState extends State<LiveFeed> {
  /// Arrival numbers of the items in the feed, newest first. Arrival `n`
  /// shows child `n % children.length`; the number keys the item, so a
  /// child that comes round again animates in afresh.
  final List<int> _arrivals = [];
  Timer? _timer;
  bool _reduceMotion = false;

  int get _count => widget.children.length;

  @override
  void initState() {
    super.initState();
    if (_count > 0) _arrivals.add(0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _schedule();
  }

  @override
  void didUpdateWidget(LiveFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_arrivals.isEmpty && _count > 0) _arrivals.add(0);
    if (!widget.loop) _arrivals.removeWhere((n) => n >= _count);
    _trim();
    if (oldWidget.interval != widget.interval ||
        oldWidget.playing != widget.playing ||
        oldWidget.loop != widget.loop ||
        oldWidget.children.length != _count) {
      _schedule();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _hasNext => _count > 0 && (widget.loop || (_arrivals.firstOrNull ?? -1) < _count - 1);

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (_reduceMotion || !widget.playing || !_hasNext) return;
    _timer = Timer(widget.interval, () {
      if (!mounted) return;
      setState(() {
        _arrivals.insert(0, (_arrivals.firstOrNull ?? -1) + 1);
        _trim();
      });
      _schedule();
    });
  }

  void _trim() {
    final max = widget.maxVisible;
    if (max != null && _arrivals.length > max) _arrivals.removeRange(max, _arrivals.length);
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();
    // Reduced motion: no arrivals over time, just the feed as it would end
    // up (all children, newest first, capped).
    final arrivals = _reduceMotion
        ? [for (var n = _count - 1; n >= 0; n--) n].take(widget.maxVisible ?? _count)
        : _arrivals;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final n in arrivals)
          _FeedItem(
            key: ValueKey(n),
            gap: widget.gap,
            spring: widget.spring,
            animate: !_reduceMotion,
            child: widget.children[n % _count],
          ),
      ],
    );
  }
}

/// One item, springing in from its top edge when first inserted.
class _FeedItem extends StatefulWidget {
  const _FeedItem({
    super.key,
    required this.gap,
    required this.spring,
    required this.animate,
    required this.child,
  });

  final double gap;
  final SpringDescription spring;
  final bool animate;
  final Widget child;

  @override
  State<_FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<_FeedItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
    value: widget.animate ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.animateWith(SpringSimulation(widget.spring, 0, 1, 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.gap),
        child: widget.child,
      ),
      builder: (context, child) {
        final t = _controller.value.clamp(0.0, 1.0);
        return ClipRect(
          clipBehavior: t >= 1 ? Clip.none : Clip.hardEdge,
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: t,
            child: Opacity(
              opacity: t,
              child: Transform.scale(scale: t, alignment: Alignment.topCenter, child: child),
            ),
          ),
        );
      },
    );
  }
}
