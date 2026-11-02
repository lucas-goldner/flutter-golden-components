import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

/// Playground for [MorphCard].
class MorphCardDemo extends StatefulWidget {
  const MorphCardDemo({super.key});

  @override
  State<MorphCardDemo> createState() => _MorphCardDemoState();
}

class _MorphCardDemoState extends State<MorphCardDemo> {
  late double _cardRadius;
  late double _dialogRadius;
  late double _maxWidth;
  late double _blur;
  late double _stiffness;
  late double _damping;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _cardRadius = 12;
    _dialogRadius = 24;
    _maxWidth = 500;
    _blur = 4;
    _stiffness = 385;
    _damping = 36;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: Center(
        child: MorphCard(
          semanticLabel: 'EB27 lamp',
          cardRadius: _cardRadius,
          dialogRadius: _dialogRadius,
          dialogMaxWidth: _maxWidth,
          barrierBlur: _blur,
          spring: SpringDescription(mass: 1, stiffness: _stiffness, damping: _damping),
          color: p.surface,
          borderColor: p.border,
          card: SizedBox(
            width: 270,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 192, child: _LampArt(lampSize: 88)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('EB27', style: GalleryText.label(p).copyWith(fontSize: 14)),
                            Text(
                              'Edouard Wilfrid Buquet',
                              style: GalleryText.body(p).copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: p.border),
                        ),
                        child: Text('+', style: TextStyle(fontSize: 14, color: p.muted, height: 1)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          dialog: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 220, child: _LampArt(lampSize: 104)),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EB27', style: GalleryText.title(p).copyWith(fontSize: 24)),
                          Text('Edouard Wilfrid Buquet', style: GalleryText.body(p)),
                          MorphCardReveal(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'A double-arm desk lamp from 1925, handmade from nickel-plated '
                                'brass, aluminium and varnished wood. Its counterweighted arms '
                                'hold any position without springs or screws.\n\n'
                                'Tap outside, press Escape or use the close button to morph '
                                'back into the card.',
                                style: GalleryText.body(p),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(top: 16, right: 16, child: MorphCardClose(color: Color(0xFFFFFFFF))),
            ],
          ),
        ),
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Shape',
          children: [
            SliderControl(
              label: 'Card radius',
              value: _cardRadius,
              min: 0,
              max: 32,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _cardRadius = v),
            ),
            SliderControl(
              label: 'Dialog radius',
              value: _dialogRadius,
              min: 0,
              max: 48,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _dialogRadius = v),
            ),
            SliderControl(
              label: 'Dialog width',
              value: _maxWidth,
              min: 320,
              max: 720,
              step: 10,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _maxWidth = v),
            ),
            SliderControl(
              label: 'Backdrop blur',
              value: _blur,
              min: 0,
              max: 16,
              step: 0.5,
              format: (v) => '${v.toStringAsFixed(1)} px',
              onChanged: (v) => _set(() => _blur = v),
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
              max: 900,
              step: 5,
              onChanged: (v) => _set(() => _stiffness = v),
            ),
            SliderControl(
              label: 'Damping',
              value: _damping,
              min: 8,
              max: 60,
              step: 1,
              format: (v) => v < 26 ? '${v.round()} bouncy' : '${v.round()}',
              onChanged: (v) => _set(() => _damping = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// A warm gradient with a pendant lamp on it.
class _LampArt extends StatelessWidget {
  const _LampArt({required this.lampSize});

  final double lampSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF9177), Color(0xFFF6B967), Color(0xFFF4D25A)],
        ),
      ),
      child: Center(
        child: SizedBox.square(
          dimension: lampSize,
          child: const CustomPaint(painter: _LampPainter()),
        ),
      ),
    );
  }
}

class _LampPainter extends CustomPainter {
  const _LampPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final paint = Paint()..color = const Color(0xD9FFFFFF);
    final line = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      // Cord.
      ..drawLine(const Offset(12, 3), const Offset(12, 6.5), line..strokeWidth = 1.8)
      // Shade: a dome with a flat rim.
      ..drawPath(
        Path()
          ..moveTo(4.5, 14.5)
          ..arcToPoint(const Offset(19.5, 14.5), radius: const Radius.circular(7.5))
          ..close(),
        line..strokeWidth = 2,
      )
      ..drawRRect(RRect.fromLTRBR(4, 13.6, 20, 15.6, const Radius.circular(1)), paint)
      // Bulb.
      ..drawCircle(const Offset(12, 17), 2.6, paint);
  }

  @override
  bool shouldRepaint(_LampPainter old) => false;
}
