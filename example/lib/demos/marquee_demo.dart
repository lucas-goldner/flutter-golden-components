import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

enum _Content { reviews, logos, tags }

/// Playground for [Marquee].
class MarqueeDemo extends StatefulWidget {
  const MarqueeDemo({super.key});

  @override
  State<MarqueeDemo> createState() => _MarqueeDemoState();
}

class _MarqueeDemoState extends State<MarqueeDemo> {
  late _Content _content;
  late double _speed;
  late double _gap;
  late double _fade;
  late double _rows;
  late bool _reverse;
  late bool _alternate;
  late bool _vertical;
  late bool _pauseOnHover;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _content = _Content.reviews;
    _speed = 40;
    _gap = 16;
    _fade = 120;
    _rows = 2;
    _reverse = false;
    _alternate = true;
    _vertical = false;
    _pauseOnHover = true;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    return Playground(
      preview: _Preview(
        settings: _MarqueeSettings(
          content: _content,
          speed: _speed,
          gap: _gap,
          fade: _fade,
          rows: _rows.round(),
          reverse: _reverse,
          alternate: _alternate,
          vertical: _vertical,
          pauseOnHover: _pauseOnHover,
        ),
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Content',
          children: [
            SegmentedControl<_Content>(
              label: 'Items',
              value: _content,
              options: const {
                _Content.reviews: 'Reviews',
                _Content.logos: 'Logos',
                _Content.tags: 'Tags',
              },
              onChanged: (v) => _set(() => _content = v),
            ),
            SliderControl(
              label: _vertical ? 'Columns' : 'Rows',
              value: _rows,
              min: 1,
              max: 3,
              step: 1,
              onChanged: (v) => _set(() => _rows = v),
            ),
            ToggleControl(
              label: 'Alternate direction per row',
              value: _alternate,
              onChanged: (v) => _set(() => _alternate = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Motion',
          children: [
            SliderControl(
              label: 'Speed',
              value: _speed,
              min: 0,
              max: 300,
              step: 5,
              format: (v) => '${v.round()} px/s',
              onChanged: (v) => _set(() => _speed = v),
            ),
            ToggleControl(
              label: 'Reverse',
              value: _reverse,
              onChanged: (v) => _set(() => _reverse = v),
            ),
            ToggleControl(
              label: 'Vertical',
              value: _vertical,
              onChanged: (v) => _set(() => _vertical = v),
            ),
            ToggleControl(
              label: 'Pause on hover',
              value: _pauseOnHover,
              onChanged: (v) => _set(() => _pauseOnHover = v),
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
              max: 64,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _gap = v),
            ),
            SliderControl(
              label: 'Edge fade',
              value: _fade,
              min: 0,
              max: 240,
              step: 4,
              format: (v) => v == 0 ? 'off' : '${v.round()} px',
              onChanged: (v) => _set(() => _fade = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// The marquee settings chosen in the panel.
@immutable
class _MarqueeSettings {
  const _MarqueeSettings({
    required this.content,
    required this.speed,
    required this.gap,
    required this.fade,
    required this.rows,
    required this.reverse,
    required this.alternate,
    required this.vertical,
    required this.pauseOnHover,
  });

  final _Content content;
  final double speed;
  final double gap;
  final double fade;
  final int rows;
  final bool reverse;
  final bool alternate;
  final bool vertical;
  final bool pauseOnHover;
}

/// One marquee per row (or column), centered on the stage.
class _Preview extends StatelessWidget {
  const _Preview({required this.settings});

  final _MarqueeSettings settings;

  @override
  Widget build(BuildContext context) {
    final s = settings;
    final strips = [
      for (var i = 0; i < s.rows; i++)
        Marquee(
          // A new key per layout so switching axis/content starts cleanly.
          key: ValueKey((s.vertical, s.content, i)),
          axis: s.vertical ? Axis.vertical : Axis.horizontal,
          reverse: s.reverse != (s.alternate && i.isOdd),
          speed: s.speed,
          gap: s.gap,
          fadeExtent: s.fade,
          pauseOnHover: s.pauseOnHover,
          children: [for (var j = 0; j < 6; j++) _Item(content: s.content, index: (i * 3 + j) % 9)],
        ),
    ];
    return Center(
      child: s.vertical
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(mainAxisSize: MainAxisSize.min, spacing: s.gap, children: strips),
            )
          // Scrolls when the rows are taller than the stage (phones).
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(mainAxisSize: MainAxisSize.min, spacing: s.gap, children: strips),
            ),
    );
  }
}

/// One marquee item of the chosen [content] kind.
class _Item extends StatelessWidget {
  const _Item({required this.content, required this.index});

  final _Content content;
  final int index;

  @override
  Widget build(BuildContext context) => switch (content) {
    _Content.reviews => _ReviewCard(review: _reviews[index]),
    _Content.logos => _Logo(name: _logos[index]),
    _Content.tags => _Tag(name: _tags[index], color: _colors[index % _colors.length]),
  };
}

@immutable
class _Review {
  const _Review(this.name, this.handle, this.body);

  final String name;
  final String handle;
  final String body;
}

const _reviews = [
  _Review('Jack', '@jack', "I've never seen anything like this before. It's amazing."),
  _Review('Jill', '@jill', "I don't know what to say. I'm speechless."),
  _Review('John', '@john', 'Dropped it into our app in five minutes. Zero dependencies.'),
  _Review('Jane', '@jane', 'The hover pause is so smooth. My cursor feels expensive.'),
  _Review('Jenny', '@jenny', 'Finally a marquee that fills ultra-wide screens.'),
  _Review('James', '@james', 'Widgets library only? Works with our custom design system.'),
  _Review('Joan', '@joan', 'Reduced motion support out of the box. Love it.'),
  _Review('Jules', '@jules', 'Vertical mode makes a great testimonial wall.'),
  _Review('Jo', '@jo', 'Speed in px/s means short and long rows match.'),
];

const _logos = [
  'Northwind',
  'Lumen',
  'Copperline',
  'Halcyon',
  'Vertex',
  'Orbital',
  'Juniper',
  'Kestrel',
  'Basalt',
];

const _tags = [
  'Flutter',
  'Dart',
  'Widgets',
  'Animation',
  'Physics',
  'Gestures',
  'Rendering',
  'Semantics',
  'Layout',
];

const _colors = [
  Color(0xFFF5C451),
  Color(0xFF60A5FA),
  Color(0xFFF472B6),
  Color(0xFF34D399),
  Color(0xFFFB923C),
  Color(0xFFA78BFA),
];

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final _Review review;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final color = _colors[_reviews.indexOf(review) % _colors.length];
    return Container(
      width: 256,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.4)],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text),
                  ),
                  Text(review.handle, style: TextStyle(fontSize: 12, color: p.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.body, style: TextStyle(fontSize: 14, height: 1.4, color: p.text)),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: p.muted, width: 2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              color: p.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: p.text),
          ),
        ],
      ),
    );
  }
}
