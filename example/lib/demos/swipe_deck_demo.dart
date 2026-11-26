import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

const List<(String, String, List<Color>)> _slides = [
  ('Dunes', 'Golden hour over the sand sea', [Color(0xFFF59E0B), Color(0xFFEF4444)]),
  ('Fjord', 'Still water under steep cliffs', [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
  ('Canopy', 'Light through a rainforest roof', [Color(0xFF10B981), Color(0xFF3B82F6)]),
  ('Aurora', 'Green ribbons over the tundra', [Color(0xFF22D3EE), Color(0xFF8B5CF6)]),
  ('Bloom', 'A hillside of wild poppies', [Color(0xFFEC4899), Color(0xFFF97316)]),
];

/// Playground for [SwipeDeck].
class SwipeDeckDemo extends StatefulWidget {
  const SwipeDeckDemo({super.key});

  @override
  State<SwipeDeckDemo> createState() => _SwipeDeckDemoState();
}

class _SwipeDeckDemoState extends State<SwipeDeckDemo> {
  late bool _autoplay;
  late double _seconds;
  late double _fraction;
  late double _sideScale;
  late bool _loop;
  int _current = 0;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _autoplay = true;
    _seconds = 4;
    _fraction = 0.86;
    _sideScale = 0.92;
    _loop = true;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: p.text),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwipeDeck(
                  // The page fraction is fixed per controller: rebuild on change.
                  key: ValueKey((_run, _fraction)),
                  viewportFraction: _fraction,
                  sideScale: _sideScale,
                  loop: _loop,
                  autoplay: _autoplay ? Duration(milliseconds: (_seconds * 1000).round()) : null,
                  onChanged: (i) => setState(() => _current = i),
                  slides: [for (final slide in _slides) _Slide(slide: slide)],
                ),
                const SizedBox(height: 12),
                Text(
                  '${_slides[_current].$1}: ${_current + 1} of ${_slides.length}',
                  style: GalleryText.value(p),
                ),
              ],
            ),
          ),
        ),
      ),
      onReset: () => _set(() {
        _reset();
        _run++;
      }),
      controls: [
        ControlSection(
          title: 'Autoplay',
          children: [
            ToggleControl(
              label: 'Advance on its own',
              value: _autoplay,
              onChanged: (v) => _set(() => _autoplay = v),
            ),
            SliderControl(
              label: 'Every',
              value: _seconds,
              min: 1,
              max: 10,
              step: 0.5,
              format: (v) => '$v s',
              onChanged: (v) => _set(() => _seconds = v),
            ),
            ToggleControl(
              label: 'Wrap to the first slide',
              value: _loop,
              onChanged: (v) => _set(() => _loop = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Layout',
          children: [
            SliderControl(
              label: 'Slide width',
              value: _fraction,
              min: 0.6,
              max: 1,
              step: 0.02,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => _set(() => _fraction = v),
            ),
            SliderControl(
              label: 'Side scale',
              value: _sideScale,
              min: 0.7,
              max: 1,
              step: 0.01,
              onChanged: (v) => _set(() => _sideScale = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// A gradient "photo" with a caption.
class _Slide extends StatelessWidget {
  const _Slide({required this.slide});

  final (String, String, List<Color>) slide;

  @override
  Widget build(BuildContext context) {
    final (title, caption, colors) = slide;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFFFFF),
              ),
            ),
            Text(caption, style: const TextStyle(fontSize: 14, color: Color(0xD9FFFFFF))),
          ],
        ),
      ),
    );
  }
}
