import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

const Map<String, List<Color>> _palettes = {
  'Neon': WaveBackdrop.defaultColors,
  'Sunset': [Color(0xFFF97316), Color(0xFFFBBF24), Color(0xFFF472B6), Color(0xFFEF4444)],
  'Ocean': [Color(0xFF0EA5E9), Color(0xFF14B8A6), Color(0xFF6366F1), Color(0xFF22D3EE)],
  'Forest': [Color(0xFF22C55E), Color(0xFF84CC16), Color(0xFF10B981), Color(0xFFA3E635)],
};

/// Playground for [WaveBackdrop].
class WaveBackdropDemo extends StatefulWidget {
  const WaveBackdropDemo({super.key});

  @override
  State<WaveBackdropDemo> createState() => _WaveBackdropDemoState();
}

class _WaveBackdropDemoState extends State<WaveBackdropDemo> {
  late String _palette;
  late double _speed;
  late double _width;
  late double _blur;
  late double _opacity;
  late double _amplitude;
  late double _center;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _palette = 'Neon';
    _speed = 1;
    _width = 50;
    _blur = 10;
    _opacity = 0.5;
    _amplitude = 0.35;
    _center = 0.5;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: WaveBackdrop(
        dark: p.isDark,
        background: p.background,
        colors: _palettes[_palette]!,
        speed: _speed,
        waveWidth: _width,
        blur: _blur,
        opacity: _opacity,
        amplitude: _amplitude,
        center: _center,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hero waves are cool',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Leverage the power of canvas to create a beautiful hero section',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w300, color: p.text),
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
            SliderControl(
              label: 'Wave width',
              value: _width,
              min: 8,
              max: 120,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _width = v),
            ),
            SliderControl(
              label: 'Softness',
              value: _blur,
              min: 0,
              max: 40,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _blur = v),
            ),
            SliderControl(
              label: 'Opacity',
              value: _opacity,
              min: 0.1,
              max: 1,
              step: 0.05,
              onChanged: (v) => _set(() => _opacity = v),
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
              max: 5,
              step: 0.25,
              format: (v) => v == 0 ? 'still' : '${v}x',
              onChanged: (v) => _set(() => _speed = v),
            ),
            SliderControl(
              label: 'Swing',
              value: _amplitude,
              min: 0,
              max: 0.9,
              step: 0.05,
              onChanged: (v) => _set(() => _amplitude = v),
            ),
            SliderControl(
              label: 'Height',
              value: _center,
              min: 0,
              max: 1,
              step: 0.05,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => _set(() => _center = v),
            ),
          ],
        ),
      ],
    );
  }
}
