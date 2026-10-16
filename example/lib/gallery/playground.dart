import 'package:flutter/widgets.dart';

import 'controls.dart';
import 'theme.dart';

/// Lays out a live preview next to (or above) its settings panel.
class Playground extends StatelessWidget {
  const Playground({
    super.key,
    required this.preview,
    required this.controls,
    required this.onReset,
  });

  final Widget preview;
  final List<Widget> controls;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth >= 760;
        final stage = _Stage(child: preview);
        final panel = _ControlsPanel(controls: controls, onReset: onReset);
        if (side) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: stage),
              Container(width: 1, color: p.border),
              SizedBox(width: 320, child: panel),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: (constraints.maxHeight * 0.5).clamp(280.0, 460.0), child: stage),
            Container(height: 1, color: p.border),
            Expanded(child: panel),
          ],
        );
      },
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return ClipRect(
      child: CustomPaint(painter: _DotGridPainter(p.border), child: child),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const gap = 22.0;
    for (var y = gap / 2; y < size.height; y += gap) {
      for (var x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => oldDelegate.color != color;
}

class _ControlsPanel extends StatefulWidget {
  const _ControlsPanel({required this.controls, required this.onReset});

  final List<Widget> controls;
  final VoidCallback onReset;

  @override
  State<_ControlsPanel> createState() => _ControlsPanelState();
}

class _ControlsPanelState extends State<_ControlsPanel> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return ColoredBox(
      color: p.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
            child: Row(
              children: [
                Expanded(child: Text('Settings', style: GalleryText.heading(p))),
                GalleryButton(label: 'Reset', onTap: widget.onReset),
              ],
            ),
          ),
          Container(height: 1, color: p.border),
          Expanded(
            child: RawScrollbar(
              controller: _scroll,
              thumbColor: p.muted.withValues(alpha: 0.4),
              radius: const Radius.circular(3),
              thickness: 5,
              child: ListView(
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + MediaQuery.paddingOf(context).bottom),
                children: widget.controls,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
