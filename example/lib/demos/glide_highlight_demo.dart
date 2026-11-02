import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

enum _Look { soft, card, accent }

/// Playground for [GlideHighlight].
class GlideHighlightDemo extends StatefulWidget {
  const GlideHighlightDemo({super.key});

  @override
  State<GlideHighlightDemo> createState() => _GlideHighlightDemoState();
}

class _GlideHighlightDemoState extends State<GlideHighlightDemo> {
  late _Look _look;
  late double _stiffness;
  late double _damping;
  late bool _hoverGrid;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _look = _Look.card;
    _stiffness = 440;
    _damping = 33;
    _hoverGrid = true;
  }

  @override
  Widget build(BuildContext context) {
    final spring = SpringDescription(mass: 1, stiffness: _stiffness, damping: _damping);
    return Playground(
      preview: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: KeyedSubtree(
              key: ValueKey(_run),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Tabs(look: _look, spring: spring),
                  const SizedBox(height: 22),
                  _Toolbar(look: _look, spring: spring),
                  const SizedBox(height: 30),
                  _CardGrid(look: _look, spring: spring, hover: _hoverGrid),
                ],
              ),
            ),
          ),
        ),
      ),
      onReset: () => setState(() {
        _reset();
        _run++;
      }),
      controls: [
        ControlSection(
          title: 'Highlight',
          children: [
            SegmentedControl<_Look>(
              label: 'Look',
              value: _look,
              options: const {_Look.soft: 'Soft', _Look.card: 'Card', _Look.accent: 'Accent'},
              onChanged: (v) => setState(() => _look = v),
            ),
            ToggleControl(
              label: 'Cards follow hover',
              value: _hoverGrid,
              onChanged: (v) => setState(() => _hoverGrid = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Spring',
          children: [
            SliderControl(
              label: 'Stiffness',
              value: _stiffness,
              min: 60,
              max: 1000,
              step: 10,
              onChanged: (v) => setState(() => _stiffness = v),
            ),
            SliderControl(
              label: 'Damping',
              value: _damping,
              min: 8,
              max: 60,
              step: 1,
              format: (v) => v < 26 ? '${v.round()} bouncy' : '${v.round()}',
              onChanged: (v) => setState(() => _damping = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// The highlight's decoration for a [_Look].
BoxDecoration _decoration(GalleryPalette p, _Look look, double radius) => switch (look) {
  _Look.soft => BoxDecoration(
    color: p.text.withValues(alpha: 0.07),
    borderRadius: BorderRadius.circular(radius),
  ),
  _Look.card => BoxDecoration(
    color: p.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: p.border),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF000000).withValues(alpha: p.isDark ? 0.4 : 0.08),
        blurRadius: 6,
        offset: const Offset(0, 1),
      ),
    ],
  ),
  _Look.accent => BoxDecoration(
    color: p.accent.withValues(alpha: 0.18),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: p.accent.withValues(alpha: 0.6)),
  ),
};

/// A segmented Day / Week / Month / Year control.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.look, required this.spring});

  final _Look look;
  final SpringDescription spring;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.text.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: GlideHighlight<String>(
        items: const ['Day', 'Week', 'Month', 'Year'],
        initialValue: 'Day',
        spring: spring,
        decoration: _decoration(p, look, 7),
        itemBuilder: (context, item, active) => AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 160),
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? p.text : p.muted,
          ),
          child: Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 7),
            alignment: Alignment.center,
            child: Text(item),
          ),
        ),
      ),
    );
  }
}

/// A row of icon buttons.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.look, required this.spring});

  final _Look look;
  final SpringDescription spring;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: GlideHighlight<_Glyph>(
        items: _Glyph.values,
        initialValue: _Glyph.phone,
        spring: spring,
        decoration: _decoration(p, look == _Look.card ? _Look.soft : look, 8),
        layoutBuilder: (children) =>
            Row(mainAxisSize: MainAxisSize.min, spacing: 4, children: children),
        itemBuilder: (context, glyph, active) => Semantics(
          label: glyph.label,
          child: SizedBox.square(
            dimension: 40,
            child: Center(child: _Icon(glyph, color: active ? p.text : p.muted)),
          ),
        ),
      ),
    );
  }
}

/// A grid of component cards that the highlight follows on hover.
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.look, required this.spring, required this.hover});

  final _Look look;
  final SpringDescription spring;
  final bool hover;

  static const List<(String, String)> _cards = [
    ('Dialog', 'Enhances modal presentations.'),
    ('Popover', 'For small interactive overlays.'),
    ('Accordion', 'Collapsible sections for more content.'),
    ('Collapsible', 'Collapsible sections for more content.'),
    ('Drag to Reorder', 'Reorder items with drag and drop.'),
    ('Swipe to Delete', 'Delete items with swipe gestures.'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return SizedBox(
      width: 3 * 220 + 2 * 12,
      child: GlideHighlight<int>(
        items: [for (var i = 0; i < _cards.length; i++) i],
        hover: hover,
        spring: spring,
        decoration: _decoration(p, look == _Look.card ? _Look.soft : look, 12),
        layoutBuilder: (children) => Wrap(spacing: 12, runSpacing: 12, children: children),
        itemBuilder: (context, i, active) => SizedBox(
          width: 220,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_cards[i].$1, style: GalleryText.label(p).copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 40,
                  child: Text(_cards[i].$2, style: GalleryText.body(p).copyWith(fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Toolbar icons, painted (the widgets layer ships none).
enum _Glyph {
  home('Home'),
  person('Profile'),
  gear('Settings'),
  phone('Calls');

  const _Glyph(this.label);

  final String label;
}

class _Icon extends StatelessWidget {
  const _Icon(this.glyph, {required this.color});

  final _Glyph glyph;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(dimension: 20, child: CustomPaint(painter: _GlyphPainter(glyph, color)));
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
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (glyph) {
      case _Glyph.home:
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 10.5)
            ..lineTo(12, 3.5)
            ..lineTo(20.5, 10.5)
            ..moveTo(5.5, 9)
            ..lineTo(5.5, 20)
            ..lineTo(18.5, 20)
            ..lineTo(18.5, 9)
            ..moveTo(10, 20)
            ..lineTo(10, 14.5)
            ..lineTo(14, 14.5)
            ..lineTo(14, 20),
          line,
        );
      case _Glyph.person:
        canvas
          ..drawCircle(const Offset(12, 8), 3.8, line)
          ..drawPath(
            Path()
              ..moveTo(4.5, 20)
              ..cubicTo(5, 15.5, 8, 13.8, 12, 13.8)
              ..cubicTo(16, 13.8, 19, 15.5, 19.5, 20)
              ..close(),
            line,
          );
      case _Glyph.gear:
        // Eight square-ish teeth around a ring, with a hole in the middle.
        final outline = Path();
        const teeth = 8;
        for (var k = 0; k < teeth * 4; k++) {
          final a = (k - 0.5) * math.pi * 2 / (teeth * 4);
          final r = (k % 4 < 2) ? 9.0 : 6.8;
          final point = Offset(12 + math.cos(a) * r, 12 + math.sin(a) * r);
          k == 0 ? outline.moveTo(point.dx, point.dy) : outline.lineTo(point.dx, point.dy);
        }
        outline.close();
        canvas
          ..drawPath(outline, line)
          ..drawCircle(const Offset(12, 12), 3, line);
      case _Glyph.phone:
        canvas.drawPath(
          Path()
            ..moveTo(5, 4)
            ..lineTo(8.5, 4)
            ..lineTo(10, 8.5)
            ..lineTo(8, 10)
            ..cubicTo(9, 12.5, 11.5, 15, 14, 16)
            ..lineTo(15.5, 14)
            ..lineTo(20, 15.5)
            ..lineTo(20, 19)
            ..cubicTo(20, 19.8, 19.4, 20.4, 18.6, 20.3)
            ..cubicTo(10.6, 19.6, 4.4, 13.4, 3.7, 5.4)
            ..cubicTo(3.6, 4.6, 4.2, 4, 5, 4)
            ..close(),
          line,
        );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph || old.color != color;
}
