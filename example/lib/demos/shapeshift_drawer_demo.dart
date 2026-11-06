import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

/// Playground for [ShapeshiftDrawer].
class ShapeshiftDrawerDemo extends StatefulWidget {
  const ShapeshiftDrawerDemo({super.key});

  @override
  State<ShapeshiftDrawerDemo> createState() => _ShapeshiftDrawerDemoState();
}

class _ShapeshiftDrawerDemoState extends State<ShapeshiftDrawerDemo> {
  late bool _closeButton;
  late double _width;
  late double _radius;
  String _status = 'Closed';

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _closeButton = true;
    _width = 361;
    _radius = 36;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: Center(
        child: DefaultTextStyle.merge(
          style: TextStyle(color: p.text),
          child: ShapeshiftDrawer(
            showCloseButton: _closeButton,
            maxWidth: _width,
            radius: _radius,
            color: p.surface,
            onOpenChanged: (open) => setState(() => _status = open ? 'Open: default' : 'Closed'),
            onViewChanged: (view) => setState(() => _status = 'Open: $view'),
            views: {
              'default': (context) => const _Options(),
              'key': (context) => const _PrivateKey(),
              'phrase': (context) => const _Phrase(),
              'remove': (context) => const _Remove(),
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Trigger(),
                const SizedBox(height: 14),
                Text(_status, style: GalleryText.value(p)),
              ],
            ),
          ),
        ),
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Sheet',
          children: [
            ToggleControl(
              label: 'Close button',
              value: _closeButton,
              onChanged: (v) => _set(() => _closeButton = v),
            ),
            SliderControl(
              label: 'Max width',
              value: _width,
              min: 300,
              max: 520,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _width = v),
            ),
            SliderControl(
              label: 'Corner radius',
              value: _radius,
              min: 12,
              max: 48,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _radius = v),
            ),
          ],
        ),
      ],
    );
  }
}

class _Trigger extends StatelessWidget {
  const _Trigger();

  @override
  Widget build(BuildContext context) {
    return GalleryButton(
      label: 'Open wallet options',
      onTap: () => ShapeshiftDrawer.of(context).open(),
    );
  }
}

class _Options extends StatelessWidget {
  const _Options();

  @override
  Widget build(BuildContext context) {
    final drawer = ShapeshiftDrawer.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShapeshiftDrawerHeader(title: 'Options'),
        const SizedBox(height: 20),
        ShapeshiftDrawerTile(
          label: 'View private key',
          icon: const _Icon(_Glyph.lock),
          onTap: () => drawer.show('key'),
        ),
        const SizedBox(height: 8),
        ShapeshiftDrawerTile(
          label: 'View recovery phrase',
          icon: const _Icon(_Glyph.doc),
          onTap: () => drawer.show('phrase'),
        ),
        const SizedBox(height: 8),
        ShapeshiftDrawerTile(
          label: 'Remove wallet',
          icon: const _Icon(_Glyph.trash),
          destructive: true,
          onTap: () => drawer.show('remove'),
        ),
      ],
    );
  }
}

class _PrivateKey extends StatefulWidget {
  const _PrivateKey();

  @override
  State<_PrivateKey> createState() => _PrivateKeyState();
}

class _PrivateKeyState extends State<_PrivateKey> {
  final Set<int> _checked = {};

  static const List<String> _points = [
    'Your private key is like a password for your wallet.',
    'If someone gets it, they can drain your wallet.',
    'Never share it with anyone, not even support.',
  ];

  @override
  Widget build(BuildContext context) {
    final drawer = ShapeshiftDrawer.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShapeshiftDrawerHeader(
          icon: _Icon(_Glyph.shield, size: 40),
          title: 'Private key',
          description: 'Tick each point to confirm you understand before revealing it.',
        ),
        const SizedBox(height: 18),
        for (final (i, point) in _points.indexed)
          _Check(
            text: point,
            checked: _checked.contains(i),
            onTap: () =>
                setState(() => _checked.contains(i) ? _checked.remove(i) : _checked.add(i)),
          ),
        const SizedBox(height: 18),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: ShapeshiftDrawerAction(label: 'Back', onTap: drawer.back),
            ),
            Expanded(
              child: Opacity(
                opacity: _checked.length == _points.length ? 1 : 0.45,
                child: ShapeshiftDrawerAction(
                  label: 'Reveal',
                  primary: true,
                  onTap: () {
                    if (_checked.length == _points.length) drawer.close();
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Phrase extends StatefulWidget {
  const _Phrase();

  @override
  State<_Phrase> createState() => _PhraseState();
}

class _PhraseState extends State<_Phrase> {
  bool _shown = false;

  static const List<String> _words = [
    'lunar',
    'meadow',
    'copper',
    'violin',
    'harbor',
    'ember',
    'quartz',
    'saddle',
    'orbit',
    'thistle',
    'canvas',
    'drift',
  ];

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final drawer = ShapeshiftDrawer.of(context);
    final grid = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (i, word) in _words.indexed)
          Container(
            width: 92,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: p.text.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${i + 1}. $word', style: TextStyle(fontSize: 13, color: p.text)),
          ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShapeshiftDrawerHeader(
          icon: _Icon(_Glyph.doc, size: 40),
          title: 'Recovery phrase',
          description: 'Write these words down in order and keep them somewhere safe.',
        ),
        const SizedBox(height: 18),
        ImageFiltered(
          enabled: !_shown,
          imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: grid,
        ),
        const SizedBox(height: 18),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: ShapeshiftDrawerAction(label: 'Back', onTap: drawer.back),
            ),
            Expanded(
              child: ShapeshiftDrawerAction(
                label: _shown ? 'Done' : 'Reveal',
                primary: true,
                onTap: () => _shown ? drawer.close() : setState(() => _shown = true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Remove extends StatelessWidget {
  const _Remove();

  @override
  Widget build(BuildContext context) {
    final drawer = ShapeshiftDrawer.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShapeshiftDrawerHeader(
          icon: _Icon(_Glyph.warning, size: 40, color: Color(0xFFE5484D)),
          title: 'Remove this wallet?',
          description: 'You can only get it back with your recovery phrase.',
        ),
        const SizedBox(height: 20),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: ShapeshiftDrawerAction(label: 'Cancel', onTap: drawer.back),
            ),
            Expanded(
              child: ShapeshiftDrawerAction(
                label: 'Remove',
                destructive: true,
                onTap: drawer.close,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A tickable warning row.
class _Check extends StatelessWidget {
  const _Check({required this.text, required this.checked, required this.onTap});

  final String text;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Semantics(
      checked: checked,
      label: text,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        builder: (context, hover, pressed) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: checked ? p.text : const Color(0x00000000),
                  border: Border.all(
                    color: p.text.withValues(alpha: checked ? 1 : 0.3),
                    width: 1.5,
                  ),
                ),
                child: checked ? _Icon(_Glyph.tick, size: 14, color: p.surface) : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: GalleryText.body(p).copyWith(fontSize: 15))),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Glyph { lock, doc, trash, shield, warning, tick }

/// A painted icon, in [color] or the ambient icon color.
class _Icon extends StatelessWidget {
  const _Icon(this.glyph, {this.size = 18, this.color});

  final _Glyph glyph;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GlyphPainter(glyph, c)),
    );
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
      case _Glyph.lock:
        canvas
          ..drawRRect(RRect.fromLTRBR(5, 11, 19, 21, const Radius.circular(2.5)), line)
          ..drawPath(
            Path()
              ..moveTo(8, 11)
              ..lineTo(8, 7.5)
              ..arcToPoint(const Offset(16, 7.5), radius: const Radius.circular(4))
              ..lineTo(16, 11),
            line,
          );
      case _Glyph.doc:
        canvas.drawRRect(RRect.fromLTRBR(5.5, 3, 18.5, 21, const Radius.circular(2.5)), line);
        for (final y in const [8.0, 12.0, 16.0]) {
          canvas.drawLine(Offset(9, y), Offset(y == 16 ? 12.5 : 15, y), line);
        }
      case _Glyph.trash:
        canvas
          ..drawLine(const Offset(4, 6.5), const Offset(20, 6.5), line)
          ..drawPath(
            Path()
              ..moveTo(9, 6.5)
              ..lineTo(9.5, 3.5)
              ..lineTo(14.5, 3.5)
              ..lineTo(15, 6.5),
            line,
          )
          ..drawPath(
            Path()
              ..moveTo(6, 6.5)
              ..lineTo(7, 20.5)
              ..lineTo(17, 20.5)
              ..lineTo(18, 6.5),
            line,
          );
      case _Glyph.shield:
        canvas
          ..drawPath(
            Path()
              ..moveTo(12, 2.5)
              ..lineTo(19.5, 5.5)
              ..lineTo(19.5, 11)
              ..cubicTo(19.5, 16, 16, 19.5, 12, 21.5)
              ..cubicTo(8, 19.5, 4.5, 16, 4.5, 11)
              ..lineTo(4.5, 5.5)
              ..close(),
            line,
          )
          ..drawPath(
            Path()
              ..moveTo(8.5, 12)
              ..lineTo(11, 14.5)
              ..lineTo(15.5, 9.5),
            line,
          );
      case _Glyph.warning:
        canvas
          ..drawPath(
            Path()
              ..moveTo(12, 3)
              ..lineTo(22, 20.5)
              ..lineTo(2, 20.5)
              ..close(),
            line,
          )
          ..drawLine(const Offset(12, 9.5), const Offset(12, 14), line)
          ..drawCircle(const Offset(12, 17.3), 0.6, line);
      case _Glyph.tick:
        canvas.drawPath(
          Path()
            ..moveTo(6, 12.5)
            ..lineTo(10, 16.5)
            ..lineTo(18, 8),
          line..strokeWidth = 2.6,
        );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph || old.color != color;
}
