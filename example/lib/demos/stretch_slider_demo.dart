import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

enum _Scene { player, controlCenter, editor }

/// How the sliders in every scene feel, from the settings panel.
@immutable
class _Feel {
  const _Feel({
    required this.maxStretch,
    required this.bounce,
    required this.thicken,
    required this.dim,
  });

  final double maxStretch;

  /// 0 (no overshoot) to 1 (very bouncy).
  final double bounce;
  final bool thicken;
  final bool dim;

  SpringDescription get spring =>
      SpringDescription(mass: 1, stiffness: 400, damping: 40 - 32 * bounce);

  /// The active thickness for a slider of [thickness].
  double active(double thickness, double grown) => thicken ? grown : thickness;

  double get idleOpacity => dim ? 0.7 : 1;
}

/// Playground for [StretchSlider].
class StretchSliderDemo extends StatefulWidget {
  const StretchSliderDemo({super.key});

  @override
  State<StretchSliderDemo> createState() => _StretchSliderDemoState();
}

class _StretchSliderDemoState extends State<StretchSliderDemo> {
  late _Scene _scene;
  late double _maxStretch;
  late double _bounce;
  late bool _thicken;
  late bool _dim;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _scene = _Scene.controlCenter;
    _maxStretch = 40;
    _bounce = 0.7;
    _thicken = true;
    _dim = true;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final feel = _Feel(maxStretch: _maxStretch, bounce: _bounce, thicken: _thicken, dim: _dim);
    return Playground(
      preview: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: KeyedSubtree(
              key: ValueKey((_scene, _run)),
              child: switch (_scene) {
                _Scene.player => _Player(feel: feel),
                _Scene.controlCenter => _ControlCenter(feel: feel),
                _Scene.editor => _Editor(feel: feel),
              },
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
          title: 'Scene',
          children: [
            SegmentedControl<_Scene>(
              label: 'Example',
              value: _scene,
              options: const {
                _Scene.player: 'Player',
                _Scene.controlCenter: 'Control',
                _Scene.editor: 'Editor',
              },
              onChanged: (v) => _set(() => _scene = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Stretch',
          children: [
            SliderControl(
              label: 'Max stretch',
              value: _maxStretch,
              min: 0,
              max: 120,
              step: 5,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _maxStretch = v),
            ),
            SliderControl(
              label: 'Snap-back bounce',
              value: _bounce,
              min: 0,
              max: 1,
              step: 0.05,
              onChanged: (v) => _set(() => _bounce = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Track',
          children: [
            ToggleControl(
              label: 'Thicken when active',
              value: _thicken,
              onChanged: (v) => _set(() => _thicken = v),
            ),
            ToggleControl(
              label: 'Dim when idle',
              value: _dim,
              onChanged: (v) => _set(() => _dim = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// A rounded card on the gallery surface.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Container(
      width: 340,
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: p.isDark ? 0.45 : 0.08),
            blurRadius: 40,
            spreadRadius: -12,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: p.text),
        child: child,
      ),
    );
  }
}

/// Album art: a soft gradient.
class _Art extends StatelessWidget {
  const _Art();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC), Color(0xFFFFE29F)],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

// ---------------------------------------------------------------- player

class _Player extends StatefulWidget {
  const _Player({required this.feel});

  final _Feel feel;

  @override
  State<_Player> createState() => _PlayerState();
}

class _PlayerState extends State<_Player> with SingleTickerProviderStateMixin {
  static const double _song = 214;

  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  double _position = 84;
  double _volume = 0.64;
  bool _playing = true;
  bool _seeking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Playback is an endless animation: hold still when motion is reduced.
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _ticker.isActive) _ticker.stop();
    if (!still && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (!_playing || _seeking) return;
    final next = math.min(_song, _position + dt);
    // Only rebuild when the shown second changes or the bar moves a pixel.
    if ((next - _position).abs() < 0.2 && next < _song) return;
    setState(() {
      _position = next;
      if (_position >= _song) _playing = false;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  static String _clock(double seconds) {
    final s = seconds.round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final feel = widget.feel;
    final times = GalleryText.value(p);
    return _Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: const SizedBox(width: 64, height: 64, child: _Art()),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cirrus', style: GalleryText.heading(p).copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('Open Skies', style: GalleryText.body(p)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StretchSlider(
            value: _position,
            max: _song,
            thickness: 5,
            activeThickness: feel.active(5, 9),
            idleOpacity: feel.idleOpacity,
            maxStretch: feel.maxStretch,
            stretchSpring: feel.spring,
            trackColor: p.text.withValues(alpha: 0.12),
            fillColor: p.text,
            semanticLabel: 'Seek',
            semanticFormatter: _clock,
            onChangeStart: (_) => _seeking = true,
            onChanged: (v) => setState(() => _position = v),
            onChangeEnd: (_) => _seeking = false,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_clock(_position), style: times),
              Text('−${_clock(_song - _position)}', style: times),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 22,
            children: [
              _IconButton(
                glyph: _Glyph.skipBack,
                label: 'Restart',
                onTap: () => setState(() => _position = 0),
              ),
              _IconButton(
                glyph: _playing ? _Glyph.pause : _Glyph.play,
                label: _playing ? 'Pause' : 'Play',
                size: 52,
                boxed: true,
                onTap: () => setState(() {
                  if (_position >= _song) _position = 0;
                  _playing = !_playing;
                }),
              ),
              _IconButton(
                glyph: _Glyph.skipForward,
                label: 'Skip to end',
                onTap: () => setState(() {
                  _position = _song;
                  _playing = false;
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StretchSlider(
            value: _volume,
            thickness: 5,
            activeThickness: feel.active(5, 9),
            idleOpacity: feel.idleOpacity,
            maxStretch: feel.maxStretch,
            stretchSpring: feel.spring,
            trackColor: p.text.withValues(alpha: 0.12),
            fillColor: p.text,
            contentColor: p.muted,
            semanticLabel: 'Volume',
            leading: const _Icon(_Glyph.speakerLow, size: 18),
            trailing: const _Icon(_Glyph.speakerHigh, size: 18),
            onChanged: (v) => setState(() => _volume = v),
          ),
        ],
      ),
    );
  }
}

/// A tappable glyph, optionally in a rounded box.
class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.glyph,
    required this.label,
    required this.onTap,
    this.size = 36,
    this.boxed = false,
  });

  final _Glyph glyph;
  final String label;
  final VoidCallback onTap;
  final double size;
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        builder: (context, hover, pressed) => AnimatedScale(
          scale: pressed ? 0.9 : 1,
          duration: const Duration(milliseconds: 140),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: boxed
                ? BoxDecoration(
                    color: hover ? p.border : p.surfaceAlt,
                    borderRadius: BorderRadius.circular(size * 0.32),
                    border: Border.all(color: p.border),
                  )
                : null,
            child: IconTheme(
              data: IconThemeData(color: p.text),
              child: _Icon(glyph, size: boxed ? 24 : 22),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- control center

class _ControlCenter extends StatefulWidget {
  const _ControlCenter({required this.feel});

  final _Feel feel;

  @override
  State<_ControlCenter> createState() => _ControlCenterState();
}

class _ControlCenterState extends State<_ControlCenter> {
  double _brightness = 0.72;
  double _volume = 0.4;
  final Map<_Glyph, bool> _toggles = {
    _Glyph.wifi: true,
    _Glyph.bluetooth: true,
    _Glyph.airplane: false,
    _Glyph.moon: false,
  };

  static const Map<_Glyph, String> _names = {
    _Glyph.wifi: 'Wi-Fi',
    _Glyph.bluetooth: 'Bluetooth',
    _Glyph.airplane: 'Airplane mode',
    _Glyph.moon: 'Do not disturb',
  };

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final speaker = switch (_volume) {
      <= 0 => _Glyph.speakerOff,
      < 0.5 => _Glyph.speakerLow,
      _ => _Glyph.speakerHigh,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.isDark ? const Color(0xFF1C1C21) : const Color(0xFFE6E5E9),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 14,
        children: [
          Container(
            width: 182,
            height: 182,
            decoration: BoxDecoration(
              color: p.text.withValues(alpha: p.isDark ? 0.08 : 0.07),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 18,
              children: [
                for (final MapEntry(key: glyph, value: on) in _toggles.entries)
                  _Toggle(
                    glyph: glyph,
                    label: _names[glyph]!,
                    on: on,
                    onTap: () => setState(() => _toggles[glyph] = !on),
                  ),
              ],
            ),
          ),
          _Pill(
            feel: widget.feel,
            value: _brightness,
            glyph: _Glyph.sun,
            label: 'Brightness',
            onChanged: (v) => setState(() => _brightness = v),
          ),
          _Pill(
            feel: widget.feel,
            value: _volume,
            glyph: speaker,
            label: 'Volume',
            onChanged: (v) => setState(() => _volume = v),
          ),
        ],
      ),
    );
  }
}

/// A round control-center toggle.
class _Toggle extends StatelessWidget {
  const _Toggle({required this.glyph, required this.label, required this.on, required this.onTap});

  final _Glyph glyph;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final fill = p.isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B);
    final ink = p.isDark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF);
    return Semantics(
      toggled: on,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        builder: (context, hover, pressed) => AnimatedScale(
          scale: pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? fill : p.surface,
              boxShadow: on
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF000000).withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: IconTheme(
              data: IconThemeData(color: on ? ink : p.text),
              child: _Icon(glyph, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tall control-center pill: the fill rises from the bottom.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.feel,
    required this.value,
    required this.glyph,
    required this.label,
    required this.onChanged,
  });

  final _Feel feel;
  final double value;
  final _Glyph glyph;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return StretchSlider(
      value: value,
      axis: Axis.vertical,
      length: 182,
      thickness: 84,
      activeThickness: feel.active(84, 88),
      radius: 26,
      jumpOnTap: false,
      insideTrack: true,
      idleOpacity: 1,
      maxStretch: feel.maxStretch,
      stretchSpring: feel.spring,
      trackColor: p.text.withValues(alpha: p.isDark ? 0.1 : 0.08),
      fillColor: p.isDark ? const Color(0xFFF4F4F5) : const Color(0xFFFFFFFF),
      contentColor: p.text.withValues(alpha: 0.7),
      fillContentColor: const Color(0xFF18181B),
      semanticLabel: label,
      leading: _Icon(glyph, size: 26),
      onChanged: onChanged,
    );
  }
}

// ---------------------------------------------------------------- editor

class _Editor extends StatefulWidget {
  const _Editor({required this.feel});

  final _Feel feel;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  double _exposure = 24;
  double _warmth = -30;
  double _angle = -3;

  static String _signed(double v) => v > 0 ? '+${v.round()}' : '${v.round()}';

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final radians = _angle * math.pi / 180;
    // Zoom in just enough that the rotated photo still covers the frame.
    final cover = math.cos(radians.abs()) + 2 * math.sin(radians.abs());
    final brightness = 1 + _exposure / 220;
    return _Card(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Adjust', style: GalleryText.heading(p).copyWith(fontSize: 16)),
              const Spacer(),
              GalleryButton(
                label: 'Reset',
                onTap: () => setState(() {
                  _exposure = 0;
                  _warmth = 0;
                  _angle = 0;
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.matrix([
                      brightness, 0, 0, 0, 0, //
                      0, brightness, 0, 0, 0,
                      0, 0, brightness, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
                    child: Transform.rotate(
                      angle: radians,
                      child: Transform.scale(scale: cover, child: const _Art()),
                    ),
                  ),
                  ColoredBox(
                    color: (_warmth >= 0 ? const Color(0xFFFF8A2A) : const Color(0xFF2A7DFF))
                        .withValues(alpha: (_warmth.abs() / 100 * 0.35).clamp(0.0, 1.0)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Adjustment(
            label: 'Exposure',
            text: _signed(_exposure),
            slider: _EditorSlider(
              feel: widget.feel,
              value: _exposure,
              label: 'Exposure',
              onChanged: (v) => setState(() => _exposure = v),
            ),
          ),
          _Adjustment(
            label: 'Warmth',
            text: _signed(_warmth),
            slider: _EditorSlider(
              feel: widget.feel,
              value: _warmth,
              label: 'Warmth',
              onChanged: (v) => setState(() => _warmth = v),
            ),
          ),
          _Adjustment(
            label: 'Straighten',
            text: '${_signed(_angle)}°',
            slider: _EditorSlider(
              feel: widget.feel,
              value: _angle,
              label: 'Straighten',
              range: 10,
              stepped: true,
              onChanged: (v) => setState(() => _angle = v),
            ),
          ),
        ],
      ),
    );
  }
}

/// A label and value above an editor slider.
class _Adjustment extends StatelessWidget {
  const _Adjustment({required this.label, required this.text, required this.slider});

  final String label;
  final String text;
  final Widget slider;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GalleryText.label(p).copyWith(fontSize: 14)),
              Text(text, style: GalleryText.value(p).copyWith(fontSize: 13)),
            ],
          ),
          slider,
        ],
      ),
    );
  }
}

/// A signed slider centred on zero, with a thumb.
class _EditorSlider extends StatelessWidget {
  const _EditorSlider({
    required this.feel,
    required this.value,
    required this.label,
    required this.onChanged,
    this.range = 100,
    this.stepped = false,
  });

  final _Feel feel;
  final double value;
  final String label;
  final ValueChanged<double> onChanged;
  final double range;
  final bool stepped;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return StretchSlider(
      value: value,
      min: -range,
      max: range,
      origin: 0,
      divisions: (range * 2).round(),
      showTicks: stepped,
      thumb: true,
      thickness: 4,
      activeThickness: feel.active(4, 8),
      idleOpacity: 1,
      maxStretch: feel.maxStretch,
      stretchSpring: feel.spring,
      trackColor: p.text.withValues(alpha: 0.12),
      fillColor: p.text,
      semanticLabel: label,
      semanticFormatter: (v) => v.round().toString(),
      onChanged: onChanged,
    );
  }
}

// ---------------------------------------------------------------- glyphs

/// Small line icons painted for the demo (the widgets layer ships none).
enum _Glyph {
  speakerOff,
  speakerLow,
  speakerHigh,
  sun,
  wifi,
  bluetooth,
  airplane,
  moon,
  play,
  pause,
  skipBack,
  skipForward,
}

/// Paints a [_Glyph] in the ambient [IconTheme] color.
class _Icon extends StatelessWidget {
  const _Icon(this.glyph, {this.size = 24});

  final _Glyph glyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? const Color(0xFF000000);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GlyphPainter(glyph, color)),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);

  final _Glyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 24 x 24 grid.
    canvas.scale(size.width / 24);
    final fill = Paint()..color = color;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (glyph) {
      case _Glyph.speakerOff || _Glyph.speakerLow || _Glyph.speakerHigh:
        canvas.drawPath(
          Path()
            ..moveTo(3, 9.5)
            ..lineTo(7, 9.5)
            ..lineTo(12, 5)
            ..lineTo(12, 19)
            ..lineTo(7, 14.5)
            ..lineTo(3, 14.5)
            ..close(),
          fill..strokeJoin = StrokeJoin.round,
        );
        if (glyph == _Glyph.speakerOff) {
          canvas
            ..drawLine(const Offset(16, 9.5), const Offset(21, 14.5), line)
            ..drawLine(const Offset(21, 9.5), const Offset(16, 14.5), line);
        } else {
          final waves = glyph == _Glyph.speakerHigh ? 2 : 1;
          for (var i = 0; i < waves; i++) {
            final r = 4.0 + i * 4;
            canvas.drawArc(
              Rect.fromCircle(center: const Offset(12, 12), radius: r),
              -0.85,
              1.7,
              false,
              line,
            );
          }
        }
      case _Glyph.sun:
        canvas.drawCircle(const Offset(12, 12), 4, line);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final d = Offset(math.cos(a), math.sin(a));
          canvas.drawLine(const Offset(12, 12) + d * 7.5, const Offset(12, 12) + d * 9.5, line);
        }
      case _Glyph.wifi:
        for (final r in const [4.5, 9.0, 13.5]) {
          canvas.drawArc(
            Rect.fromCircle(center: const Offset(12, 19.5), radius: r),
            -math.pi / 2 - 0.75,
            1.5,
            false,
            line..strokeWidth = 2.2,
          );
        }
        canvas.drawCircle(const Offset(12, 19.5), 1.6, fill);
      case _Glyph.bluetooth:
        canvas.drawPath(
          Path()
            ..moveTo(6.5, 7.5)
            ..lineTo(17, 17)
            ..lineTo(12, 21.5)
            ..lineTo(12, 2.5)
            ..lineTo(17, 7)
            ..lineTo(6.5, 16.5),
          line,
        );
      case _Glyph.airplane:
        canvas.drawPath(
          Path()
            ..moveTo(12, 2)
            ..cubicTo(13.2, 2, 13.6, 3.4, 13.6, 4.5)
            ..lineTo(13.6, 9.2)
            ..lineTo(21.5, 13.8)
            ..lineTo(21.5, 15.8)
            ..lineTo(13.6, 13.4)
            ..lineTo(13.6, 18.4)
            ..lineTo(16, 20.2)
            ..lineTo(16, 21.8)
            ..lineTo(12, 20.8)
            ..lineTo(8, 21.8)
            ..lineTo(8, 20.2)
            ..lineTo(10.4, 18.4)
            ..lineTo(10.4, 13.4)
            ..lineTo(2.5, 15.8)
            ..lineTo(2.5, 13.8)
            ..lineTo(10.4, 9.2)
            ..lineTo(10.4, 4.5)
            ..cubicTo(10.4, 3.4, 10.8, 2, 12, 2)
            ..close(),
          fill,
        );
      case _Glyph.moon:
        canvas.drawPath(
          Path.combine(
            PathOperation.difference,
            Path()..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 8.5)),
            Path()..addOval(Rect.fromCircle(center: const Offset(16.5, 8), radius: 7.5)),
          ),
          fill,
        );
      case _Glyph.play:
        canvas.drawPath(
          Path()
            ..moveTo(7.5, 4.5)
            ..lineTo(19.5, 12)
            ..lineTo(7.5, 19.5)
            ..close(),
          fill,
        );
      case _Glyph.pause:
        for (final x in const [6.0, 14.0]) {
          canvas.drawRRect(RRect.fromLTRBR(x, 5, x + 4, 19, const Radius.circular(1.2)), fill);
        }
      case _Glyph.skipBack || _Glyph.skipForward:
        if (glyph == _Glyph.skipBack) {
          canvas
            ..translate(24, 0)
            ..scale(-1, 1);
        }
        canvas
          ..drawPath(
            Path()
              ..moveTo(5, 5.5)
              ..lineTo(15.5, 12)
              ..lineTo(5, 18.5)
              ..close(),
            fill,
          )
          ..drawRRect(RRect.fromLTRBR(16.5, 5.5, 19.5, 18.5, const Radius.circular(1)), fill);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph || old.color != color;
}
