import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

enum _Falloff { linear, smooth }

/// Playground for [MagnifyDock].
class MagnifyDockDemo extends StatefulWidget {
  const MagnifyDockDemo({super.key});

  @override
  State<MagnifyDockDemo> createState() => _MagnifyDockDemoState();
}

class _MagnifyDockDemoState extends State<MagnifyDockDemo> {
  late double _base;
  late double _magnification;
  late double _distance;
  late _Falloff _falloff;
  late double _stiffness;
  late double _damping;
  String _opened = 'Hover the dock, or tap an icon';

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _base = 40;
    _magnification = 80;
    _distance = 150;
    _falloff = _Falloff.linear;
    _stiffness = 150;
    _damping = 12;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: Column(
        children: [
          Expanded(
            child: Center(child: Text(_opened, style: GalleryText.body(p))),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: p.text),
                child: MagnifyDock(
                  baseSize: _base,
                  magnification: _magnification,
                  distance: _distance,
                  falloff: _falloff == _Falloff.linear ? Curves.linear : Curves.easeInOutSine,
                  spring: SpringDescription(mass: 0.1, stiffness: _stiffness, damping: _damping),
                  panelColor: p.isDark ? const Color(0xFF17171B) : const Color(0xFFF1F0EC),
                  itemColor: p.isDark ? const Color(0xFF26262C) : const Color(0xFFE2E1DC),
                  items: [
                    for (final glyph in _Glyph.values)
                      MagnifyDockItem(
                        label: glyph.label,
                        icon: _Icon(glyph),
                        onTap: () => setState(() => _opened = 'Opened ${glyph.label}'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Magnification',
          children: [
            SliderControl(
              label: 'Base size',
              value: _base,
              min: 28,
              max: 64,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() {
                _base = v;
                if (_magnification < v) _magnification = v;
              }),
            ),
            SliderControl(
              label: 'Magnified size',
              value: _magnification,
              min: 28,
              max: 128,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _magnification = v < _base ? _base : v),
            ),
            SliderControl(
              label: 'Reach',
              value: _distance,
              min: 40,
              max: 400,
              step: 5,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _distance = v),
            ),
            SegmentedControl<_Falloff>(
              label: 'Falloff',
              value: _falloff,
              options: const {_Falloff.linear: 'Linear', _Falloff.smooth: 'Smooth'},
              onChanged: (v) => _set(() => _falloff = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Spring',
          children: [
            SliderControl(
              label: 'Stiffness',
              value: _stiffness,
              min: 40,
              max: 600,
              step: 10,
              onChanged: (v) => _set(() => _stiffness = v),
            ),
            SliderControl(
              label: 'Damping',
              value: _damping,
              min: 4,
              max: 30,
              step: 1,
              format: (v) => v < 8 ? '${v.round()} wobbly' : '${v.round()}',
              onChanged: (v) => _set(() => _damping = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dock icons, painted (the widgets layer ships none).
enum _Glyph {
  home('Home'),
  archive('Products'),
  apps('Components'),
  activity('Activity'),
  notes('Change log'),
  mail('Email'),
  theme('Theme');

  const _Glyph(this.label);

  final String label;
}

class _Icon extends StatelessWidget {
  const _Icon(this.glyph);

  final _Glyph glyph;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? const Color(0xFF000000);
    return SizedBox.square(dimension: 24, child: CustomPaint(painter: _GlyphPainter(glyph, color)));
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);

  final _Glyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    RRect box(double l, double t, double r, double b, [double radius = 2]) =>
        RRect.fromLTRBR(l, t, r, b, Radius.circular(radius));
    switch (glyph) {
      case _Glyph.home:
        canvas.drawPath(
          Path()
            ..moveTo(4, 10.5)
            ..lineTo(12, 4)
            ..lineTo(20, 10.5)
            ..lineTo(20, 20)
            ..lineTo(14.5, 20)
            ..lineTo(14.5, 14.5)
            ..lineTo(9.5, 14.5)
            ..lineTo(9.5, 20)
            ..lineTo(4, 20)
            ..close(),
          line,
        );
      case _Glyph.archive:
        canvas
          ..drawRRect(box(3.5, 4, 20.5, 8.5, 1.5), line)
          ..drawRRect(box(5, 8.5, 19, 20), line)
          ..drawLine(const Offset(10, 12.5), const Offset(14, 12.5), line);
      case _Glyph.apps:
        canvas
          ..drawRRect(box(4, 4, 10.5, 10.5), line)
          ..drawRRect(box(4, 13.5, 10.5, 20), line)
          ..drawRRect(box(13.5, 13.5, 20, 20), line)
          ..drawPath(
            Path()
              ..moveTo(16.75, 3.5)
              ..lineTo(20.5, 7.25)
              ..lineTo(16.75, 11)
              ..lineTo(13, 7.25)
              ..close(),
            line,
          );
      case _Glyph.activity:
        canvas
          ..drawRRect(box(3.5, 4.5, 20.5, 19.5, 3), line)
          ..drawPath(
            Path()
              ..moveTo(6.5, 12.5)
              ..lineTo(9, 12.5)
              ..lineTo(10.8, 9)
              ..lineTo(13.2, 16)
              ..lineTo(15, 12.5)
              ..lineTo(17.5, 12.5),
            line,
          );
      case _Glyph.notes:
        canvas.drawRRect(box(5.5, 3.5, 18.5, 20.5), line);
        for (final y in const [8.0, 12.0, 16.0]) {
          canvas.drawLine(Offset(8.5, y), Offset(y == 16 ? 12.5 : 15.5, y), line);
        }
      case _Glyph.mail:
        canvas
          ..drawRRect(box(3.5, 5.5, 20.5, 18.5), line)
          ..drawPath(
            Path()
              ..moveTo(4.5, 7)
              ..lineTo(12, 12.5)
              ..lineTo(19.5, 7),
            line,
          );
      case _Glyph.theme:
        canvas
          ..drawCircle(const Offset(12, 12), 7.5, line)
          ..drawArc(
            Rect.fromCircle(center: const Offset(12, 12), radius: 7.5),
            -1.5708,
            3.1416,
            true,
            Paint()..color = color,
          );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph || old.color != color;
}
