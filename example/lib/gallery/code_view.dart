import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'controls.dart';
import 'dart_highlighter.dart';
import 'registry.dart';
import 'theme.dart';

final Map<String, Future<String>> _sourceCache = {};

/// Loads a component's source, which the package ships as an asset.
Future<String> loadComponentSource(GalleryComponent component, {AssetBundle? bundle}) {
  return _sourceCache[component.sourceAsset] ??= (bundle ?? rootBundle).loadString(
    component.sourceAsset,
  );
}

/// Copies a component's source to the clipboard and briefly confirms it.
class CopyCodeButton extends StatefulWidget {
  const CopyCodeButton({super.key, required this.component, this.compact = false});

  final GalleryComponent component;

  /// Shows "Copy" instead of "Copy code", for tight layouts.
  final bool compact;

  @override
  State<CopyCodeButton> createState() => _CopyCodeButtonState();
}

class _CopyCodeButtonState extends State<CopyCodeButton> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final code = await loadComponentSource(widget.component);
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return GalleryButton(
      label: _copied ? 'Copied' : (widget.compact ? 'Copy' : 'Copy code'),
      onTap: _copy,
      leading: SizedBox.square(
        dimension: 12,
        child: CustomPaint(painter: _copied ? _CheckPainter(p.accent) : _CopyPainter(p.text)),
      ),
    );
  }
}

/// Read-only, syntax highlighted view of a component's source.
class CodeView extends StatefulWidget {
  const CodeView({super.key, required this.component});

  final GalleryComponent component;

  @override
  State<CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  late Future<String> _source = loadComponentSource(widget.component);
  final _vertical = ScrollController();
  final _horizontal = ScrollController();

  @override
  void didUpdateWidget(CodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.component != widget.component) _source = loadComponentSource(widget.component);
  }

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gallery = GalleryTheme.paletteOf(context);
    final code = gallery.isDark ? CodePalette.dark : CodePalette.light;
    return ColoredBox(
      color: code.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FileBar(component: widget.component, source: _source),
          Container(height: 1, color: gallery.border),
          Expanded(
            child: FutureBuilder<String>(
              future: _source,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Could not load ${widget.component.sourcePath}',
                      style: GalleryText.body(gallery),
                    ),
                  );
                }
                final source = snap.data;
                if (source == null) return const SizedBox.shrink();
                return _CodeBody(
                  source: source,
                  palette: code,
                  vertical: _vertical,
                  horizontal: _horizontal,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FileBar extends StatelessWidget {
  const _FileBar({required this.component, required this.source});

  final GalleryComponent component;
  final Future<String> source;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: component.sourcePath),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: FutureBuilder<String>(
                      future: source,
                      builder: (context, snap) => Text(
                        snap.hasData ? '   ${'\n'.allMatches(snap.data!).length + 1} lines' : '',
                        style: GalleryText.value(p),
                      ),
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: kMonoFont, fontSize: 12, color: p.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Font bundled by the gallery for code.
const String kMonoFont = 'GalleryMono';

class _CodeBody extends StatelessWidget {
  const _CodeBody({
    required this.source,
    required this.palette,
    required this.vertical,
    required this.horizontal,
  });

  final String source;
  final CodePalette palette;
  final ScrollController vertical;
  final ScrollController horizontal;

  @override
  Widget build(BuildContext context) {
    const fontSize = 13.0;
    const height = 1.55;
    // A forced strut keeps the gutter and code lines exactly aligned.
    const strut = StrutStyle(
      fontFamily: kMonoFont,
      fontSize: fontSize,
      height: height,
      forceStrutHeight: true,
    );
    final base = TextStyle(
      fontFamily: kMonoFont,
      fontSize: fontSize,
      height: height,
      color: palette.plain,
    );
    final lines = '\n'.allMatches(source).length + 1;
    final numbers = List.generate(lines, (i) => '${i + 1}').join('\n');
    final thumb = palette.lineNumber.withValues(alpha: 0.6);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return RawScrollbar(
      controller: vertical,
      thumbColor: thumb,
      radius: const Radius.circular(3),
      thickness: 6,
      child: SingleChildScrollView(
        controller: vertical,
        padding: EdgeInsets.only(top: 14, bottom: 24 + bottom),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: palette.gutter,
              padding: const EdgeInsets.only(left: 16, right: 18),
              child: Text(
                numbers,
                textAlign: TextAlign.right,
                strutStyle: strut,
                style: base.copyWith(color: palette.lineNumber),
              ),
            ),
            Expanded(
              child: RawScrollbar(
                controller: horizontal,
                thumbColor: thumb,
                radius: const Radius.circular(3),
                thickness: 6,
                child: SingleChildScrollView(
                  controller: horizontal,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 24, bottom: 10),
                  child: Text.rich(
                    TextSpan(style: base, children: highlightDart(source, palette)),
                    strutStyle: strut,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyPainter extends CustomPainter {
  _CopyPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.32, s * 0.32, s * 0.62, s * 0.62),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.18, s * 0.66)
        ..lineTo(s * 0.06, s * 0.66)
        ..lineTo(s * 0.06, s * 0.06)
        ..lineTo(s * 0.66, s * 0.06)
        ..lineTo(s * 0.66, s * 0.18),
      paint..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CopyPainter oldDelegate) => oldDelegate.color != color;
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.1, s * 0.55)
        ..lineTo(s * 0.4, s * 0.82)
        ..lineTo(s * 0.92, s * 0.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) => oldDelegate.color != color;
}
