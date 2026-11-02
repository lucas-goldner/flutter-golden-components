import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

const Map<String, String> _texts = {
  'Short': 'This is a jumping text effect',
  'Story': 'Good morning from the mountains, the coffee is finally ready',
  'Hype': 'New drop. Tonight. Be there.',
};

/// Playground for [JumpText].
class JumpTextDemo extends StatefulWidget {
  const JumpTextDemo({super.key});

  @override
  State<JumpTextDemo> createState() => _JumpTextDemoState();
}

class _JumpTextDemoState extends State<JumpTextDemo> {
  late String _text;
  late JumpTextUnit _unit;
  late double _stagger;
  late double _rise;
  late double _tilt;
  late double _damping;
  late double _size;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _text = 'Short';
    _unit = JumpTextUnit.word;
    _stagger = 50;
    _rise = 30;
    _tilt = -30;
    _damping = 10;
    _size = 34;
  }

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Applies a slider change now and replays once the slider rests.
  void _replaySoon(VoidCallback fn) {
    setState(fn);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _replay();
    });
  }

  /// Applies a change and plays the effect again.
  void _replay([VoidCallback? fn]) => setState(() {
    fn?.call();
    _run++;
  });

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: JumpText(
              _texts[_text]!,
              key: ValueKey(_run),
              unit: _unit,
              stagger: Duration(milliseconds: _stagger.round()),
              rise: _rise,
              tilt: _tilt,
              spring: SpringDescription(mass: 2, stiffness: 100, damping: _damping),
              style: TextStyle(
                fontSize: _size,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                height: 1.25,
                color: p.text,
              ),
            ),
          ),
        ),
      ),
      onReset: () => _replay(_reset),
      controls: [
        ControlSection(
          title: 'Text',
          children: [
            GalleryButton(label: 'Replay', onTap: _replay),
            SegmentedControl<String>(
              label: 'Text',
              value: _text,
              options: {for (final k in _texts.keys) k: k},
              onChanged: (v) => _replay(() => _text = v),
            ),
            SegmentedControl<JumpTextUnit>(
              label: 'Jump by',
              value: _unit,
              options: const {JumpTextUnit.word: 'Word', JumpTextUnit.character: 'Character'},
              onChanged: (v) => _replay(() {
                _unit = v;
                _stagger = v == JumpTextUnit.word ? 50 : 10;
              }),
            ),
            SliderControl(
              label: 'Size',
              value: _size,
              min: 18,
              max: 56,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => setState(() => _size = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Jump',
          children: [
            SliderControl(
              label: 'Stagger',
              value: _stagger,
              min: 0,
              max: 200,
              step: 5,
              format: (v) => '${v.round()} ms',
              onChanged: (v) => _replaySoon(() => _stagger = v),
            ),
            SliderControl(
              label: 'Rise',
              value: _rise,
              min: 0,
              max: 80,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _replaySoon(() => _rise = v),
            ),
            SliderControl(
              label: 'Tilt',
              value: _tilt,
              min: -60,
              max: 60,
              step: 1,
              format: (v) => '${v.round()}°',
              onChanged: (v) => _replaySoon(() => _tilt = v),
            ),
            SliderControl(
              label: 'Damping',
              value: _damping,
              min: 4,
              max: 40,
              step: 1,
              format: (v) => v < 12 ? '${v.round()} bouncy' : '${v.round()}',
              onChanged: (v) => _replaySoon(() => _damping = v),
            ),
          ],
        ),
      ],
    );
  }
}
