import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

enum _TileStyle { gradient, card, minimal }

const _titles = [
  'Morning swim',
  'Field notes',
  'Night market',
  'Ceramics',
  'Overpass',
  'Studio',
  'Tidepool',
  'Paper kites',
  'Neon rain',
  'Orchard',
  'Long exposure',
  'Dune',
  'Copper',
  'Greenhouse',
  'Signal',
  'Lantern',
  'Harbor',
  'Moss',
  'Static',
  'Glasshouse',
  'Falls',
  'Atlas',
  'Ember',
  'Quarry',
];

const _gradients = [
  [Color(0xFFFDE68A), Color(0xFFB7800A)],
  [Color(0xFF93C5FD), Color(0xFF1D4ED8)],
  [Color(0xFFF9A8D4), Color(0xFFBE185D)],
  [Color(0xFF6EE7B7), Color(0xFF047857)],
  [Color(0xFFFDBA74), Color(0xFFC2410C)],
  [Color(0xFFC4B5FD), Color(0xFF6D28D9)],
  [Color(0xFF67E8F9), Color(0xFF0E7490)],
  [Color(0xFFFCA5A5), Color(0xFFB91C1C)],
];

/// Playground for [EndlessGlideGrid].
class EndlessGlideGridDemo extends StatefulWidget {
  const EndlessGlideGridDemo({super.key});

  @override
  State<EndlessGlideGridDemo> createState() => _EndlessGlideGridDemoState();
}

class _EndlessGlideGridDemoState extends State<EndlessGlideGridDemo> {
  late double _itemCount;
  late double _columns;
  late double _tileWidth;
  late double _tileHeight;
  late double _spacing;
  late double _radius;
  late double _friction;
  late double _tilt;
  late double _squash;
  late bool _stagger;
  late bool _labels;
  late _TileStyle _style;
  late bool _slowMo;

  int? _tapped;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    timeDilation = 1;
    super.dispose();
  }

  void _reset() {
    _itemCount = 15;
    _columns = 5;
    _tileWidth = 180;
    _tileHeight = 230;
    _spacing = 20;
    _radius = 14;
    _friction = 0.06;
    _tilt = 1;
    _squash = 1;
    _stagger = true;
    _labels = true;
    _style = _TileStyle.gradient;
    _slowMo = false;
    timeDilation = 1;
  }

  void _set(VoidCallback fn) => setState(fn);

  void _onTap(int index) {
    setState(() => _tapped = index);
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _tapped = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Playground(
      preview: _Preview(
        settings: _GridSettings(
          itemCount: _itemCount.round(),
          columns: _columns.round(),
          tileSize: Size(_tileWidth, _tileHeight),
          spacing: _spacing,
          friction: _friction,
          stagger: _stagger,
          tilt: _tilt,
          squash: _squash,
          tile: _TileSettings(style: _style, radius: _radius, labels: _labels),
        ),
        onTileTap: _onTap,
        tapped: _tapped,
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Motion',
          children: [
            SliderControl(
              label: 'Glide (velocity kept per second)',
              value: _friction,
              min: 0.005,
              max: 0.5,
              step: 0.005,
              format: (v) => '${(v * 100).toStringAsFixed(1)}%',
              onChanged: (v) => _set(() => _friction = v),
            ),
            SliderControl(
              label: 'Tilt with speed',
              value: _tilt,
              min: 0,
              max: 3,
              step: 0.1,
              format: (v) => '${v.toStringAsFixed(1)}x',
              onChanged: (v) => _set(() => _tilt = v),
            ),
            SliderControl(
              label: 'Shrink with speed',
              value: _squash,
              min: 0,
              max: 3,
              step: 0.1,
              format: (v) => '${v.toStringAsFixed(1)}x',
              onChanged: (v) => _set(() => _squash = v),
            ),
            ToggleControl(
              label: 'Slow motion (5x)',
              value: _slowMo,
              onChanged: (v) => _set(() {
                _slowMo = v;
                timeDilation = v ? 5 : 1;
              }),
            ),
          ],
        ),
        ControlSection(
          title: 'Layout',
          children: [
            ToggleControl(
              label: 'Stagger odd columns',
              value: _stagger,
              onChanged: (v) => _set(() => _stagger = v),
            ),
            SliderControl(
              label: 'Distinct tiles',
              value: _itemCount,
              min: 4,
              max: _titles.length.toDouble(),
              step: 1,
              onChanged: (v) => _set(() => _itemCount = v),
            ),
            SliderControl(
              label: 'Pattern columns',
              value: _columns,
              min: 2,
              max: 8,
              step: 1,
              onChanged: (v) => _set(() => _columns = v),
            ),
            SliderControl(
              label: 'Tile width',
              value: _tileWidth,
              min: 80,
              max: 320,
              step: 5,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _tileWidth = v),
            ),
            SliderControl(
              label: 'Tile height',
              value: _tileHeight,
              min: 80,
              max: 400,
              step: 5,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _tileHeight = v),
            ),
            SliderControl(
              label: 'Spacing',
              value: _spacing,
              min: 0,
              max: 60,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _spacing = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Tiles',
          children: [
            SegmentedControl<_TileStyle>(
              label: 'Style',
              value: _style,
              options: const {
                _TileStyle.gradient: 'Gradient',
                _TileStyle.card: 'Card',
                _TileStyle.minimal: 'Minimal',
              },
              onChanged: (v) => _set(() => _style = v),
            ),
            SliderControl(
              label: 'Corner radius',
              value: _radius,
              min: 0,
              max: 40,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _radius = v),
            ),
            ToggleControl(
              label: 'Show titles',
              value: _labels,
              onChanged: (v) => _set(() => _labels = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// How the demo tiles look.
@immutable
class _TileSettings {
  const _TileSettings({required this.style, required this.radius, required this.labels});

  final _TileStyle style;
  final double radius;
  final bool labels;
}

/// The grid settings chosen in the panel.
@immutable
class _GridSettings {
  const _GridSettings({
    required this.itemCount,
    required this.columns,
    required this.tileSize,
    required this.spacing,
    required this.friction,
    required this.stagger,
    required this.tilt,
    required this.squash,
    required this.tile,
  });

  final int itemCount;
  final int columns;
  final Size tileSize;
  final double spacing;
  final double friction;
  final bool stagger;
  final double tilt;
  final double squash;
  final _TileSettings tile;
}

/// The grid on a dark stage, with a hint pill and a tap toast. Tiles are
/// scaled down on narrow stages so a phone shows more than one column.
class _Preview extends StatelessWidget {
  const _Preview({required this.settings, required this.onTileTap, required this.tapped});

  final _GridSettings settings;
  final ValueChanged<int> onTileTap;
  final int? tapped;

  @override
  Widget build(BuildContext context) {
    final tapped = this.tapped;
    return ColoredBox(
      color: const Color(0xFF0E0E10),
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = constraints.maxWidth < 600 ? 0.65 : 1.0;
                final tile = settings.tileSize * scale;
                final spacing = settings.spacing * scale;
                return EndlessGlideGrid(
                  itemCount: settings.itemCount,
                  columns: settings.columns,
                  tileSize: tile,
                  spacing: spacing,
                  friction: settings.friction,
                  stagger: settings.stagger,
                  tilt: settings.tilt,
                  squash: settings.squash,
                  // Start mid-pattern so tiles are cut on every edge.
                  initialOffset: Offset(-tile.width * 0.4, -tile.height * 0.3),
                  onTileTap: onTileTap,
                  itemBuilder: (context, i) => _DemoTile(index: i, settings: settings.tile),
                );
              },
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: IgnorePointer(
              child: Center(
                child: _Pill(
                  text: tapped == null
                      ? 'Drag, fling or scroll in any direction'
                      : 'Tapped ${(tapped + 1).toString().padLeft(2, '0')}  ${_titles[tapped]}',
                  highlighted: tapped != null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.highlighted});

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? p.accent : const Color(0x99000000),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: highlighted ? p.onAccent : const Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}

/// One demo tile: artwork plus an optional numbered title.
class _DemoTile extends StatelessWidget {
  const _DemoTile({required this.index, required this.settings});

  final int index;
  final _TileSettings settings;

  @override
  Widget build(BuildContext context) {
    final title = '${(index + 1).toString().padLeft(2, '0')}  ${_titles[index]}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _Artwork(index: index, style: settings.style, radius: settings.radius),
        ),
        if (settings.labels) ...[
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.index, required this.style, required this.radius});

  final int index;
  final _TileStyle style;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[index % _gradients.length];
    final shape = BorderRadius.circular(radius);
    return switch (style) {
      _TileStyle.gradient => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: ClipRRect(
          borderRadius: shape,
          child: CustomPaint(painter: _OrbsPainter(seed: index)),
        ),
      ),
      _TileStyle.card => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A20),
          borderRadius: shape,
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius * 0.6),
                    gradient: LinearGradient(colors: colors),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FractionallySizedBox(
                widthFactor: 0.7,
                child: Container(height: 6, color: const Color(0x33FFFFFF)),
              ),
              const SizedBox(height: 6),
              FractionallySizedBox(
                widthFactor: 0.45,
                child: Container(height: 6, color: const Color(0x1FFFFFFF)),
              ),
            ],
          ),
        ),
      ),
      _TileStyle.minimal => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          border: Border.all(color: colors.first.withValues(alpha: 0.7), width: 1.5),
        ),
        child: Center(
          child: Text(
            (index + 1).toString().padLeft(2, '0'),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.first),
          ),
        ),
      ),
    };
  }
}

/// Soft translucent circles so gradient tiles read as artwork.
class _OrbsPainter extends CustomPainter {
  const _OrbsPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x22FFFFFF);
    for (var i = 0; i < 3; i++) {
      final k = (seed * 37 + i * 53) % 100 / 100;
      final center = Offset(size.width * (0.2 + 0.6 * k), size.height * (0.25 + 0.25 * i));
      canvas.drawCircle(center, size.shortestSide * (0.18 + 0.12 * ((seed + i) % 3)), paint);
    }
  }

  @override
  bool shouldRepaint(_OrbsPainter oldDelegate) => oldDelegate.seed != seed;
}
