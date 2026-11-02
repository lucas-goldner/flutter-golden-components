import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

const Map<String, List<List<String>>> _sets = {
  'Sample': KineticLine.defaultPhrases,
  'Launch': [
    ['Design', 'it'],
    ['Build', 'it', 'fast'],
    ['Ship', 'it', 'today'],
  ],
  'Long': [
    ['Every', 'word', 'finds', 'its', 'place'],
    ['The', 'line', 'stays', 'centred'],
  ],
};

/// Playground for [KineticLine].
class KineticLineDemo extends StatefulWidget {
  const KineticLineDemo({super.key});

  @override
  State<KineticLineDemo> createState() => _KineticLineDemoState();
}

class _KineticLineDemoState extends State<KineticLineDemo> {
  late String _set;
  late double _speed;
  late double _size;
  late double _offset;
  late bool _blur;
  late bool _loop;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _set = 'Sample';
    _speed = 0.72;
    _size = 34;
    _offset = 88;
    _blur = true;
    _loop = true;
  }

  void _change(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520, minHeight: 300),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.border),
            ),
            alignment: Alignment.center,
            child: ClipRect(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: KineticLine(
                    key: ValueKey((_run, _set, _loop)),
                    phrases: _sets[_set]!,
                    speed: _speed,
                    loop: _loop,
                    timing: KineticLineTiming(
                      entryOffset: _offset,
                      entryBlur: _blur ? 3.5 : 0,
                      pushBlur: _blur ? 0.8 : 0,
                      exitBlur: _blur ? 2.5 : 0,
                    ),
                    style: TextStyle(fontSize: _size, fontWeight: FontWeight.w500, color: p.text),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      onReset: () => _change(() {
        _reset();
        _run++;
      }),
      controls: [
        ControlSection(
          title: 'Phrases',
          children: [
            SegmentedControl<String>(
              label: 'Set',
              value: _set,
              options: {for (final k in _sets.keys) k: k},
              onChanged: (v) => _change(() => _set = v),
            ),
            ToggleControl(label: 'Loop', value: _loop, onChanged: (v) => _change(() => _loop = v)),
            GalleryButton(label: 'Restart', onTap: () => _change(() => _run++)),
          ],
        ),
        ControlSection(
          title: 'Motion',
          children: [
            SliderControl(
              label: 'Speed',
              value: _speed,
              min: 0.3,
              max: 2,
              step: 0.02,
              format: (v) => '${v.toStringAsFixed(2)}x time',
              onChanged: (v) => _change(() => _speed = v),
            ),
            SliderControl(
              label: 'Entry offset',
              value: _offset,
              min: 0,
              max: 200,
              step: 2,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _change(() => _offset = v),
            ),
            ToggleControl(
              label: 'Motion blur',
              value: _blur,
              onChanged: (v) => _change(() => _blur = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Text',
          children: [
            SliderControl(
              label: 'Size',
              value: _size,
              min: 18,
              max: 56,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _change(() => _size = v),
            ),
          ],
        ),
      ],
    );
  }
}
