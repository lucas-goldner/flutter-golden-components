import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';

enum _Palette { lava, neon, ocean, sunset, gold }

/// Blob colors and the liquid behind them.
@immutable
class _Scheme {
  const _Scheme(this.colors, this.top, this.bottom);

  final List<Color> colors;
  final Color top;
  final Color bottom;
}

const _schemes = {
  _Palette.lava: _Scheme(
    [Color(0xFFFF3CAC), Color(0xFFFF8A00), Color(0xFFFFD23F), Color(0xFF784BA0)],
    Color(0xFF1B0B2E),
    Color(0xFF3A0D2E),
  ),
  _Palette.neon: _Scheme(
    [Color(0xFF00F5D4), Color(0xFF00BBF9), Color(0xFF9B5DE5), Color(0xFFF15BB5)],
    Color(0xFF07071A),
    Color(0xFF0D1B3A),
  ),
  _Palette.ocean: _Scheme(
    [Color(0xFF48CAE4), Color(0xFF0077B6), Color(0xFF90E0EF), Color(0xFF00B4D8)],
    Color(0xFF03045E),
    Color(0xFF023E8A),
  ),
  _Palette.sunset: _Scheme(
    [Color(0xFFFF6B6B), Color(0xFFFFA94D), Color(0xFFFFD43B), Color(0xFFF06595)],
    Color(0xFF2B1055),
    Color(0xFF7597DE),
  ),
  _Palette.gold: _Scheme(
    [Color(0xFFFDE68A), Color(0xFFF5C451), Color(0xFFC98A12)],
    Color(0xFF0A0802),
    Color(0xFF241B08),
  ),
};

/// Playground for [GooBlobs].
class GooBlobsDemo extends StatefulWidget {
  const GooBlobsDemo({super.key});

  @override
  State<GooBlobsDemo> createState() => _GooBlobsDemoState();
}

class _GooBlobsDemoState extends State<GooBlobsDemo> {
  late _Palette _palette;
  late double _count;
  late double _minSize;
  late double _maxSize;
  late double _speed;
  late double _gooeyness;
  late double _glow;
  late bool _pool;
  late bool _follow;
  late bool _lamp;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _palette = _Palette.lava;
    _count = 9;
    _minSize = 0.07;
    _maxSize = 0.15;
    _speed = 1;
    _gooeyness = 1;
    _glow = 0.6;
    _pool = true;
    _follow = true;
    _lamp = true;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final scheme = _schemes[_palette]!;
    return Playground(
      preview: _Preview(
        lamp: _lamp,
        scheme: scheme,
        goo: GooBlobs(
          count: _count.round(),
          colors: scheme.colors,
          minSize: _minSize,
          maxSize: _maxSize,
          speed: _speed,
          gooeyness: _gooeyness,
          glow: _glow,
          pool: _pool,
          followPointer: _follow,
        ),
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Look',
          children: [
            ChipsControl<_Palette>(
              label: 'Colors',
              multiple: false,
              options: const {
                _Palette.lava: 'Lava',
                _Palette.neon: 'Neon',
                _Palette.ocean: 'Ocean',
                _Palette.sunset: 'Sunset',
                _Palette.gold: 'Gold',
              },
              selected: {_palette},
              onChanged: (v) => _set(() => _palette = v.single),
            ),
            SliderControl(
              label: 'Gooeyness',
              value: _gooeyness,
              min: 0,
              max: 2.5,
              step: 0.1,
              format: (v) => v.toStringAsFixed(1),
              onChanged: (v) => _set(() => _gooeyness = v),
            ),
            SliderControl(
              label: 'Glow',
              value: _glow,
              min: 0,
              max: 1,
              step: 0.05,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => _set(() => _glow = v),
            ),
            ToggleControl(
              label: 'Lamp shape',
              value: _lamp,
              onChanged: (v) => _set(() => _lamp = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Wax',
          children: [
            SliderControl(
              label: 'Blobs',
              value: _count,
              min: 0,
              max: 20,
              step: 1,
              onChanged: (v) => _set(() => _count = v),
            ),
            SliderControl(
              label: 'Smallest',
              value: _minSize,
              min: 0.03,
              max: 0.25,
              step: 0.01,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => _set(() {
                _minSize = v;
                if (_maxSize < v) _maxSize = v;
              }),
            ),
            SliderControl(
              label: 'Largest',
              value: _maxSize,
              min: 0.03,
              max: 0.3,
              step: 0.01,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => _set(() {
                _maxSize = v;
                if (_minSize > v) _minSize = v;
              }),
            ),
            SliderControl(
              label: 'Speed',
              value: _speed,
              min: 0,
              max: 4,
              step: 0.1,
              format: (v) => v == 0 ? 'paused' : '${v.toStringAsFixed(1)}x',
              onChanged: (v) => _set(() => _speed = v),
            ),
            ToggleControl(
              label: 'Pool at the bottom',
              value: _pool,
              onChanged: (v) => _set(() => _pool = v),
            ),
            ToggleControl(
              label: 'Blob follows pointer',
              value: _follow,
              onChanged: (v) => _set(() => _follow = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// The goo in a lava lamp (glass between a metal cap and base), or filling
/// the stage.
class _Preview extends StatelessWidget {
  const _Preview({required this.goo, required this.scheme, required this.lamp});

  final GooBlobs goo;
  final _Scheme scheme;
  final bool lamp;

  @override
  Widget build(BuildContext context) {
    final liquid = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [scheme.top, scheme.bottom],
        ),
      ),
      child: goo,
    );
    if (!lamp) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(borderRadius: BorderRadius.circular(20), child: liquid),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: AspectRatio(
          aspectRatio: 0.42,
          child: Column(
            children: [
              const _Metal(widthFactor: 0.42, height: 0.07, top: true),
              Expanded(
                child: FractionallySizedBox(
                  widthFactor: 0.82,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(400),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.colors.first.withValues(alpha: 0.35),
                          blurRadius: 60,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(400),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          liquid,
                          // Glass sheen.
                          const IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0x00FFFFFF),
                                    Color(0x1FFFFFFF),
                                    Color(0x00FFFFFF),
                                    Color(0x00FFFFFF),
                                  ],
                                  stops: [0.08, 0.2, 0.32, 1],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const _Metal(widthFactor: 0.62, height: 0.16, top: false),
            ],
          ),
        ),
      ),
    );
  }
}

/// A brushed-metal cap or base.
class _Metal extends StatelessWidget {
  const _Metal({required this.widthFactor, required this.height, required this.top});

  final double widthFactor;

  /// Height as a fraction of the whole lamp's height.
  final double height;
  final bool top;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: constraints.maxWidth / 0.42 * height,
          decoration: BoxDecoration(
            borderRadius: top
                ? const BorderRadius.vertical(top: Radius.circular(40), bottom: Radius.circular(6))
                : const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(14)),
            gradient: const LinearGradient(
              colors: [Color(0xFF3F3F46), Color(0xFFA1A1AA), Color(0xFF52525B), Color(0xFF27272A)],
              stops: [0, 0.35, 0.6, 1],
            ),
          ),
        ),
      ),
    );
  }
}
