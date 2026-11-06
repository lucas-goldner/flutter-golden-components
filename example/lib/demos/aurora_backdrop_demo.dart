import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

const Map<String, List<Color>> _palettes = {
  'Cool': AuroraBackdrop.defaultColors,
  'Warm': [Color(0xFFF97316), Color(0xFFFBBF24), Color(0xFFF472B6), Color(0xFFFDE68A)],
  'Mint': [Color(0xFF34D399), Color(0xFF22D3EE), Color(0xFFA7F3D0), Color(0xFF60A5FA)],
  'Gold': [Color(0xFFF5C451), Color(0xFFFDE68A), Color(0xFFD99A1E), Color(0xFFFFF1C2)],
};

const Map<String, Alignment> _focuses = {
  'Top right': Alignment(0.9, -1.1),
  'Top': Alignment(0, -1.2),
  'Top left': Alignment(-0.9, -1.1),
};

/// Playground for [AuroraBackdrop].
class AuroraBackdropDemo extends StatefulWidget {
  const AuroraBackdropDemo({super.key});

  @override
  State<AuroraBackdropDemo> createState() => _AuroraBackdropDemoState();
}

class _AuroraBackdropDemoState extends State<AuroraBackdropDemo> {
  late String _palette;
  late String _focus;
  late double _speed;
  late double _intensity;
  late double _blur;
  late double _angle;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _palette = 'Cool';
    _focus = 'Top right';
    _speed = 1;
    _intensity = 0.7;
    _blur = 22;
    _angle = 10;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: AuroraBackdrop(
        dark: p.isDark,
        background: p.background,
        colors: _palettes[_palette]!,
        focus: _focuses[_focus]!,
        speed: _speed,
        intensity: _intensity,
        blur: _blur,
        angle: _angle,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Background lights are cool you know.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'And this, is chemical burn.',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: p.text),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: p.text,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('Debug now', style: TextStyle(fontSize: 14, color: p.background)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Look',
          children: [
            SegmentedControl<String>(
              label: 'Palette',
              value: _palette,
              options: {for (final k in _palettes.keys) k: k},
              onChanged: (v) => _set(() => _palette = v),
            ),
            SegmentedControl<String>(
              label: 'Glow from',
              value: _focus,
              options: {for (final k in _focuses.keys) k: k},
              onChanged: (v) => _set(() => _focus = v),
            ),
            SliderControl(
              label: 'Intensity',
              value: _intensity,
              min: 0,
              max: 1,
              step: 0.05,
              onChanged: (v) => _set(() => _intensity = v),
            ),
            SliderControl(
              label: 'Softness',
              value: _blur,
              min: 0,
              max: 48,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _blur = v),
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
              max: 6,
              step: 0.25,
              format: (v) => v == 0 ? 'still' : '${v}x',
              onChanged: (v) => _set(() => _speed = v),
            ),
            SliderControl(
              label: 'Tilt',
              value: _angle,
              min: -30,
              max: 30,
              step: 1,
              format: (v) => '${v.round()}°',
              onChanged: (v) => _set(() => _angle = v),
            ),
          ],
        ),
      ],
    );
  }
}
