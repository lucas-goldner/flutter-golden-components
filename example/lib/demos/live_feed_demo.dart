import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

enum _Content { notifications, chat, activity }

/// Playground for [LiveFeed].
class LiveFeedDemo extends StatefulWidget {
  const LiveFeedDemo({super.key});

  @override
  State<LiveFeedDemo> createState() => _LiveFeedDemoState();
}

class _LiveFeedDemoState extends State<LiveFeedDemo> {
  late _Content _content;
  late double _interval;
  late double _gap;
  late bool _loop;
  late bool _cap;
  late double _maxVisible;
  late bool _playing;
  late double _stiffness;
  late double _damping;
  late bool _fade;

  /// Bumped to restart the feed from the first item.
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _content = _Content.notifications;
    _interval = 1000;
    _gap = 14;
    _loop = true;
    _cap = true;
    _maxVisible = 8;
    _playing = true;
    _stiffness = 350;
    _damping = 40;
    _fade = true;
  }

  void _set(VoidCallback fn) => setState(fn);

  /// Applies a change that only makes sense from a fresh start.
  void _restart(VoidCallback fn) => setState(() {
    fn();
    _run++;
  });

  @override
  Widget build(BuildContext context) {
    return Playground(
      preview: _Preview(
        fade: _fade,
        feed: LiveFeed(
          key: ValueKey((_run, _content)),
          interval: Duration(milliseconds: _interval.round()),
          gap: _gap,
          loop: _loop,
          maxVisible: _cap ? _maxVisible.round() : null,
          playing: _playing,
          spring: SpringDescription(mass: 1, stiffness: _stiffness, damping: _damping),
          children: [for (final item in _items[_content]!) _FeedCard(item: item)],
        ),
      ),
      onReset: () => _restart(_reset),
      controls: [
        ControlSection(
          title: 'Playback',
          children: [
            Row(
              spacing: 8,
              children: [
                GalleryButton(
                  label: _playing ? 'Pause' : 'Play',
                  onTap: () => _set(() => _playing = !_playing),
                ),
                GalleryButton(label: 'Restart', onTap: () => _restart(() {})),
              ],
            ),
            SegmentedControl<_Content>(
              label: 'Content',
              value: _content,
              options: const {
                _Content.notifications: 'Alerts',
                _Content.chat: 'Chat',
                _Content.activity: 'Activity',
              },
              onChanged: (v) => _restart(() => _content = v),
            ),
            SliderControl(
              label: 'Interval',
              value: _interval,
              min: 200,
              max: 3000,
              step: 100,
              format: (v) => '${(v / 1000).toStringAsFixed(1)} s',
              onChanged: (v) => _set(() => _interval = v),
            ),
            ToggleControl(
              label: 'Loop forever',
              value: _loop,
              onChanged: (v) => _set(() => _loop = v),
            ),
            ToggleControl(
              label: 'Cap visible items',
              value: _cap,
              onChanged: (v) => _set(() => _cap = v),
            ),
            SliderControl(
              label: 'Max visible',
              value: _maxVisible,
              min: 2,
              max: 16,
              step: 1,
              onChanged: (v) => _set(() => _maxVisible = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Spring',
          children: [
            SliderControl(
              label: 'Stiffness',
              value: _stiffness,
              min: 50,
              max: 1200,
              step: 10,
              onChanged: (v) => _set(() => _stiffness = v),
            ),
            SliderControl(
              label: 'Damping',
              value: _damping,
              min: 5,
              max: 80,
              step: 1,
              onChanged: (v) => _set(() => _damping = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Layout',
          children: [
            SliderControl(
              label: 'Gap',
              value: _gap,
              min: 0,
              max: 40,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _gap = v),
            ),
            ToggleControl(
              label: 'Fade out at the bottom',
              value: _fade,
              onChanged: (v) => _set(() => _fade = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// The feed in a clipped column, with an optional fade at the bottom.
class _Preview extends StatelessWidget {
  const _Preview({required this.feed, required this.fade});

  final LiveFeed feed;
  final bool fade;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: 0,
              maxHeight: double.infinity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: feed,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (fade)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 160,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [p.background, p.background.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

@immutable
class _Item {
  const _Item(this.title, this.subtitle, this.time, this.color, this.glyph);

  final String title;
  final String subtitle;
  final String time;
  final Color color;

  /// One or two characters shown in the badge.
  final String glyph;
}

const _items = <_Content, List<_Item>>{
  _Content.notifications: [
    _Item('Payment received', 'Invoice #1042 · \$249.00', '15m', Color(0xFF00C9A7), '\$'),
    _Item('New sign-up', 'mia@example.com joined', '10m', Color(0xFFFFB800), '+'),
    _Item('New message', 'Can we ship this today?', '5m', Color(0xFFFF3D71), 'M'),
    _Item('Deploy finished', 'production · 42 s', '2m', Color(0xFF1E86FF), 'D'),
    _Item('Review requested', 'PR #318 · LiveFeed', '1m', Color(0xFFA78BFA), 'R'),
    _Item('Build failed', 'nightly · 2 tests', 'now', Color(0xFFF97316), '!'),
  ],
  _Content.chat: [
    _Item('Ada', 'Morning! Coffee later?', '9:01', Color(0xFFF472B6), 'A'),
    _Item('Linus', 'Pushed the fix!', '9:03', Color(0xFF60A5FA), 'L'),
    _Item('Grace', 'Looks great on my phone', '9:04', Color(0xFF34D399), 'G'),
    _Item('Alan', 'Can you add a pause button?', '9:06', Color(0xFFFBBF24), 'A'),
    _Item('Ada', 'Shipping it now', '9:07', Color(0xFFF472B6), 'A'),
  ],
  _Content.activity: [
    _Item('Starred the repo', 'flutter-golden-components', '3h', Color(0xFFF5C451), 'S'),
    _Item('Opened an issue', '#27 Vertical marquee', '2h', Color(0xFF22D3EE), '#'),
    _Item('Merged a PR', '#318 Add LiveFeed', '1h', Color(0xFFA78BFA), 'M'),
    _Item('Released v0.2.0', '4 new components', '20m', Color(0xFF34D399), 'v'),
    _Item('Commented', '"The spring feels so good"', '5m', Color(0xFF60A5FA), 'C'),
  ],
};

class _FeedCard extends StatefulWidget {
  const _FeedCard({required this.item});

  final _Item item;

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final item = widget.item;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: p.isDark ? 0.25 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  item.glyph,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: p.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(item.time, style: GalleryText.value(p)),
            ],
          ),
        ),
      ),
    );
  }
}
