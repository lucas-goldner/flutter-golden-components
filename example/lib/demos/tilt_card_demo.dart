import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

/// Playground for [TiltCard].
class TiltCardDemo extends StatefulWidget {
  const TiltCardDemo({super.key});

  @override
  State<TiltCardDemo> createState() => _TiltCardDemoState();
}

class _TiltCardDemoState extends State<TiltCardDemo> {
  late double _tilt;
  late double _depth;
  late double _scale;
  late double _stiffness;
  late bool _glare;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _tilt = 12;
    _depth = 24;
    _scale = 1.03;
    _stiffness = 14;
    _glare = true;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: Center(
        child: TiltCard(
          maxTilt: _tilt,
          hoverScale: _scale,
          stiffness: _stiffness,
          glare: _glare,
          radius: 24,
          child: Container(
            width: 300,
            height: 380,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: p.isDark ? 0.35 : 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TiltLayer(
                  depth: _depth * 0.4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'HOVER ME',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                TiltLayer(
                  depth: _depth,
                  child: const Center(
                    child: Text('✦', style: TextStyle(fontSize: 72, color: Color(0xE6FFFFFF))),
                  ),
                ),
                const Spacer(),
                TiltLayer(
                  depth: _depth * 0.7,
                  child: const Text(
                    'Tilt toward\nthe pointer',
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Tilt',
          children: [
            SliderControl(
              label: 'Max tilt',
              value: _tilt,
              min: 0,
              max: 30,
              step: 1,
              format: (v) => '${v.round()}°',
              onChanged: (v) => _set(() => _tilt = v),
            ),
            SliderControl(
              label: 'Layer depth',
              value: _depth,
              min: 0,
              max: 48,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _depth = v),
            ),
            SliderControl(
              label: 'Hover scale',
              value: _scale,
              min: 1,
              max: 1.1,
              step: 0.005,
              onChanged: (v) => _set(() => _scale = v),
            ),
            SliderControl(
              label: 'Follow speed',
              value: _stiffness,
              min: 4,
              max: 30,
              step: 1,
              onChanged: (v) => _set(() => _stiffness = v),
            ),
            ToggleControl(label: 'Glare', value: _glare, onChanged: (v) => _set(() => _glare = v)),
          ],
        ),
      ],
    );
  }
}
