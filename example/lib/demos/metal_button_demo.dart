import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

/// Playground for [MetalButton].
class MetalButtonDemo extends StatefulWidget {
  const MetalButtonDemo({super.key});

  @override
  State<MetalButtonDemo> createState() => _MetalButtonDemoState();
}

class _MetalButtonDemoState extends State<MetalButtonDemo> {
  late MetalPreset _preset;
  late double _strength;
  late double _ring;
  late double _speed;
  late bool _glow;
  late bool _paused;
  int _presses = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _preset = MetalPreset.chromatic;
    _strength = 0.9;
    _ring = 2;
    _speed = 1;
    _glow = true;
    _paused = false;
  }

  void _set(VoidCallback fn) => setState(fn);

  void _press() => setState(() => _presses++);

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('LIQUID METAL', style: GalleryText.overline(p)),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final (style, label) in const [
                    (MetalButtonStyle.filled, 'Continue'),
                    (MetalButtonStyle.outline, 'Outline'),
                    (MetalButtonStyle.soft, 'Soft'),
                    (MetalButtonStyle.ghost, 'Ghost'),
                  ])
                    MetalButton(
                      style: style,
                      preset: _preset,
                      strength: _strength,
                      ringWidth: _ring,
                      speed: _speed,
                      glow: _glow,
                      paused: _paused,
                      onPressed: _press,
                      child: Text(label),
                    ),
                  for (final (glyph, label) in const [('+', 'Add'), ('\u2192', 'Next')])
                    MetalButton(
                      width: 40,
                      style: MetalButtonStyle.outline,
                      preset: _preset,
                      strength: _strength,
                      ringWidth: _ring + 1,
                      speed: _speed,
                      glow: _glow,
                      paused: _paused,
                      semanticLabel: label,
                      onPressed: _press,
                      child: Text(glyph, style: const TextStyle(fontSize: 17)),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: 520,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0B0D),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: Color(0xFFF4F4F5)),
                  child: Center(
                    child: MetalButton(
                      height: 44,
                      style: MetalButtonStyle.filled,
                      preset: _preset,
                      strength: _strength,
                      ringWidth: _ring,
                      speed: _speed,
                      glow: _glow,
                      paused: _paused,
                      onPressed: _press,
                      child: Text(switch (_preset) {
                        MetalPreset.chromatic => 'Chromatic',
                        MetalPreset.silver => 'Silver',
                        MetalPreset.gold => 'Gold',
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _presses == 0 ? 'Tap or Tab to a button' : 'Pressed $_presses times',
                style: GalleryText.body(p),
              ),
            ],
          ),
        ),
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Metal',
          children: [
            SegmentedControl<MetalPreset>(
              label: 'Preset',
              value: _preset,
              options: const {
                MetalPreset.chromatic: 'Chromatic',
                MetalPreset.silver: 'Silver',
                MetalPreset.gold: 'Gold',
              },
              onChanged: (v) => _set(() => _preset = v),
            ),
            SliderControl(
              label: 'Strength',
              value: _strength,
              min: 0,
              max: 1,
              step: 0.05,
              onChanged: (v) => _set(() => _strength = v),
            ),
            SliderControl(
              label: 'Ring width',
              value: _ring,
              min: 1,
              max: 6,
              step: 0.5,
              format: (v) => '$v px',
              onChanged: (v) => _set(() => _ring = v),
            ),
            ToggleControl(label: 'Glow', value: _glow, onChanged: (v) => _set(() => _glow = v)),
          ],
        ),
        ControlSection(
          title: 'Motion',
          children: [
            SliderControl(
              label: 'Speed',
              value: _speed,
              min: 0,
              max: 4,
              step: 0.25,
              format: (v) => '${v}x',
              onChanged: (v) => _set(() => _speed = v),
            ),
            ToggleControl(
              label: 'Paused',
              value: _paused,
              onChanged: (v) => _set(() => _paused = v),
            ),
          ],
        ),
      ],
    );
  }
}
