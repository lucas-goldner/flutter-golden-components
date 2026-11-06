import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

/// Playground for [PillSelect].
class PillSelectDemo extends StatefulWidget {
  const PillSelectDemo({super.key});

  @override
  State<PillSelectDemo> createState() => _PillSelectDemoState();
}

class _PillSelectDemoState extends State<PillSelectDemo> {
  String? _fruit = 'blueberry';
  String? _theme = 'system';
  String? _plan;
  late bool _align;
  late double _height;
  late bool _disabled;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _align = true;
    _height = 36;
    _disabled = false;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: Stack(
        children: [
          // Soft colour behind, so the frosted list has something to blur.
          const Positioned(left: -40, top: -40, child: _Blob(color: Color(0x55A78BFA))),
          const Positioned(right: -30, bottom: -30, child: _Blob(color: Color(0x5560A5FA))),
          Center(
            child: DefaultTextStyle.merge(
              style: TextStyle(color: p.text),
              child: Wrap(
                spacing: 24,
                runSpacing: 24,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  _Labelled(
                    label: 'Fruit',
                    child: PillSelect<String>(
                      label: 'Fruit',
                      value: _fruit,
                      height: _height,
                      minWidth: 180,
                      alignToSelected: _align,
                      onChanged: _disabled ? null : (v) => setState(() => _fruit = v),
                      items: const [
                        PillSelectItem(value: 'apple', label: 'Apple'),
                        PillSelectItem(value: 'banana', label: 'Banana'),
                        PillSelectItem(value: 'blueberry', label: 'Blueberry'),
                        PillSelectItem(value: 'grapes', label: 'Grapes', enabled: false),
                        PillSelectItem(value: 'pineapple', label: 'Pineapple'),
                      ],
                    ),
                  ),
                  _Labelled(
                    label: 'Theme',
                    child: PillSelect<String>(
                      value: _theme,
                      height: _height,
                      alignToSelected: _align,
                      onChanged: _disabled ? null : (v) => setState(() => _theme = v),
                      items: const [
                        PillSelectItem(value: 'light', label: 'Light', icon: _Icon(_Glyph.sun)),
                        PillSelectItem(value: 'dark', label: 'Dark', icon: _Icon(_Glyph.moon)),
                        PillSelectItem(
                          value: 'system',
                          label: 'System',
                          icon: _Icon(_Glyph.laptop),
                        ),
                      ],
                    ),
                  ),
                  _Labelled(
                    label: 'Plan',
                    child: PillSelect<String>(
                      label: 'Plans',
                      placeholder: 'Choose a plan',
                      value: _plan,
                      height: _height,
                      minWidth: 160,
                      alignToSelected: _align,
                      onChanged: _disabled ? null : (v) => setState(() => _plan = v),
                      items: const [
                        PillSelectItem(value: 'free', label: 'Free'),
                        PillSelectItem(value: 'pro', label: 'Pro'),
                        PillSelectItem(value: 'team', label: 'Team'),
                        PillSelectItem(value: 'enterprise', label: 'Enterprise'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Menu',
          children: [
            SegmentedControl<bool>(
              label: 'Opens',
              value: _align,
              options: const {true: 'Over selection', false: 'Below field'},
              onChanged: (v) => _set(() => _align = v),
            ),
            SliderControl(
              label: 'Field height',
              value: _height,
              min: 28,
              max: 48,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _height = v),
            ),
            ToggleControl(
              label: 'Disabled',
              value: _disabled,
              onChanged: (v) => _set(() => _disabled = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// A small caption above a field.
class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GalleryText.value(p)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

enum _Glyph { sun, moon, laptop }

/// A small painted icon in the ambient icon color.
class _Icon extends StatelessWidget {
  const _Icon(this.glyph);

  final _Glyph glyph;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? const Color(0xFF000000);
    return SizedBox.square(dimension: 16, child: CustomPaint(painter: _GlyphPainter(glyph, color)));
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
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (glyph) {
      case _Glyph.sun:
        canvas.drawCircle(const Offset(12, 12), 4, line);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final d = Offset(math.cos(a), math.sin(a));
          canvas.drawLine(const Offset(12, 12) + d * 7.5, const Offset(12, 12) + d * 9.5, line);
        }
      case _Glyph.moon:
        canvas.drawPath(
          Path.combine(
            PathOperation.difference,
            Path()..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 8.5)),
            Path()..addOval(Rect.fromCircle(center: const Offset(16.5, 8), radius: 7.5)),
          ),
          Paint()..color = color,
        );
      case _Glyph.laptop:
        canvas
          ..drawRRect(RRect.fromLTRBR(5, 5, 19, 15, const Radius.circular(1.5)), line)
          ..drawLine(const Offset(2.5, 19), const Offset(21.5, 19), line);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph || old.color != color;
}
