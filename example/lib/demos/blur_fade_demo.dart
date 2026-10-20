import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

enum _Content { tiles, text }

/// Playground for [BlurFade].
class BlurFadeDemo extends StatefulWidget {
  const BlurFadeDemo({super.key});

  @override
  State<BlurFadeDemo> createState() => _BlurFadeDemoState();
}

class _BlurFadeDemoState extends State<BlurFadeDemo> {
  late _Content _content;
  late BlurFadeDirection _direction;
  late double _duration;
  late double _stagger;
  late double _offset;
  late double _blur;
  late double _scale;
  late bool _inView;
  late bool _once;

  /// Bumped to remount the preview and replay every reveal.
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _content = _Content.tiles;
    _direction = BlurFadeDirection.down;
    _duration = 400;
    _stagger = 60;
    _offset = 6;
    _blur = 6;
    _scale = 1;
    _inView = true;
    _once = true;
  }

  /// Applies a change and replays, so every tweak is visible right away.
  void _set(VoidCallback fn) => setState(() {
    fn();
    _run++;
  });

  @override
  Widget build(BuildContext context) {
    return Playground(
      preview: _Preview(
        key: ValueKey(_run),
        settings: _FadeSettings(
          content: _content,
          direction: _direction,
          duration: Duration(milliseconds: _duration.round()),
          stagger: Duration(milliseconds: _stagger.round()),
          offset: _offset,
          blur: _blur,
          scale: _scale,
          inView: _inView,
          once: _once,
        ),
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Playback',
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GalleryButton(label: 'Replay', onTap: () => _set(() {})),
            ),
            SegmentedControl<_Content>(
              label: 'Content',
              value: _content,
              options: const {_Content.tiles: 'Tiles', _Content.text: 'Text'},
              onChanged: (v) => _set(() => _content = v),
            ),
            ToggleControl(
              label: 'Wait until scrolled into view',
              value: _inView,
              onChanged: (v) => _set(() => _inView = v),
            ),
            ToggleControl(
              label: 'Replay when scrolled back in',
              value: !_once,
              onChanged: (v) => _set(() => _once = !v),
            ),
          ],
        ),
        ControlSection(
          title: 'Motion',
          children: [
            SegmentedControl<BlurFadeDirection>(
              label: 'Direction',
              value: _direction,
              options: const {
                BlurFadeDirection.down: 'Down',
                BlurFadeDirection.up: 'Up',
                BlurFadeDirection.left: 'Left',
                BlurFadeDirection.right: 'Right',
              },
              onChanged: (v) => _set(() => _direction = v),
            ),
            SliderControl(
              label: 'Duration',
              value: _duration,
              min: 100,
              max: 1500,
              step: 50,
              format: (v) => '${v.round()} ms',
              onChanged: (v) => _set(() => _duration = v),
            ),
            SliderControl(
              label: 'Stagger',
              value: _stagger,
              min: 0,
              max: 250,
              step: 10,
              format: (v) => '${v.round()} ms',
              onChanged: (v) => _set(() => _stagger = v),
            ),
            SliderControl(
              label: 'Travel',
              value: _offset,
              min: 0,
              max: 60,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _offset = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Look',
          children: [
            SliderControl(
              label: 'Blur',
              value: _blur,
              min: 0,
              max: 24,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _blur = v),
            ),
            SliderControl(
              label: 'Start scale',
              value: _scale,
              min: 0.5,
              max: 1.2,
              step: 0.01,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => _set(() => _scale = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// The settings chosen in the panel.
@immutable
class _FadeSettings {
  const _FadeSettings({
    required this.content,
    required this.direction,
    required this.duration,
    required this.stagger,
    required this.offset,
    required this.blur,
    required this.scale,
    required this.inView,
    required this.once,
  });

  final _Content content;
  final BlurFadeDirection direction;
  final Duration duration;
  final Duration stagger;
  final double offset;
  final double blur;
  final double scale;
  final bool inView;
  final bool once;
}

/// A [BlurFade] configured from [_FadeSettings], the [index]th in sequence.
class _Fade extends StatelessWidget {
  const _Fade({required this.settings, required this.index, required this.child});

  final _FadeSettings settings;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return BlurFade(
      duration: s.duration,
      // With inView each item waits for itself, so only stagger the ones
      // that start on screen together.
      delay: s.stagger * (s.inView ? index % 6 : index),
      direction: s.direction,
      offset: s.offset,
      blur: s.blur,
      scale: s.scale,
      inView: s.inView,
      inViewMargin: 30,
      once: s.once,
      child: child,
    );
  }
}

/// Scrollable stage holding the chosen content.
class _Preview extends StatelessWidget {
  const _Preview({super.key, required this.settings});

  final _FadeSettings settings;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: switch (settings.content) {
              _Content.tiles => _Masonry(
                settings: settings,
                columns: constraints.maxWidth >= 600 ? 3 : 2,
              ),
              _Content.text => _Article(settings: settings),
            },
          ),
        ),
      ),
    );
  }
}

const _gradients = [
  [Color(0xFFFDE68A), Color(0xFFB7800A)],
  [Color(0xFF93C5FD), Color(0xFF1D4ED8)],
  [Color(0xFFF9A8D4), Color(0xFFBE185D)],
  [Color(0xFF6EE7B7), Color(0xFF047857)],
  [Color(0xFFC4B5FD), Color(0xFF6D28D9)],
  [Color(0xFFFDBA74), Color(0xFFC2410C)],
  [Color(0xFF67E8F9), Color(0xFF0E7490)],
];

/// Columns of alternating landscape and portrait tiles.
class _Masonry extends StatelessWidget {
  const _Masonry({required this.settings, required this.columns});

  final _FadeSettings settings;
  final int columns;

  static const _count = 15;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 14,
      children: [
        for (var c = 0; c < columns; c++)
          Expanded(
            child: Column(
              spacing: 14,
              children: [
                // Row-major order, so the stagger sweeps across columns.
                for (var i = c; i < _count; i += columns)
                  _Fade(
                    settings: settings,
                    index: i,
                    child: AspectRatio(
                      aspectRatio: (i ~/ columns).isEven == c.isEven ? 4 / 3 : 3 / 4,
                      child: _Swatch(index: i),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradients[index % _gradients.length],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            (index + 1).toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xE6FFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}

const _paragraphs = [
  'Every block on this page fades in from a soft blur the moment it scrolls into view, '
      'sliding a few pixels into place.',
  'Stagger the delay across a group and the content reads top to bottom, like it is being '
      'written for you.',
  'Turn on replay and scroll back up: blocks that left the screen hide again and reveal '
      'once more on the way back.',
  'When the system asks to reduce motion, everything simply appears, no animation.',
  'It wraps any widget: text, images, cards or whole sections.',
  'Built with the widgets library only, so it fits whatever design system you use.',
];

/// A heading plus paragraphs, each revealed in turn.
class _Article extends StatelessWidget {
  const _Article({required this.settings});

  final _FadeSettings settings;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Fade(
          settings: settings,
          index: 0,
          child: Text(
            'Content that arrives softly',
            style: GalleryText.title(p).copyWith(fontSize: 34),
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < _paragraphs.length * 2; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _Fade(
              settings: settings,
              index: i + 1,
              child: Text(
                _paragraphs[i % _paragraphs.length],
                style: GalleryText.body(p).copyWith(fontSize: 17, height: 1.6, color: p.text),
              ),
            ),
          ),
      ],
    );
  }
}
