import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A file given to a [HaloDropzone], by dragging it in or from
/// [HaloDropzone.onBrowse].
///
/// The widgets layer has no file picker or file type, so this only
/// describes the file; carry your own data in [data].
@immutable
class HaloFile {
  /// Describes a file.
  const HaloFile({required this.name, this.sizeBytes, this.preview, this.data});

  /// The file name, including its extension.
  final String name;

  /// Size in bytes, if known.
  final int? sizeBytes;

  /// A thumbnail, such as an image, shown instead of the file icon.
  final Widget? preview;

  /// Anything you want to carry along, such as the bytes or a path.
  final Object? data;

  /// The extension in lower case, or an empty string.
  String get extension => name.contains('.') ? name.split('.').last.toLowerCase() : '';

  /// The size as B, KB or MB, or null when unknown.
  String? get sizeLabel => switch (sizeBytes) {
    null => null,
    < 1024 => '$sizeBytes B',
    < 1024 * 1024 => '${(sizeBytes! / 1024).toStringAsFixed(1)} KB',
    _ => '${(sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB',
  };
}

/// A drop zone with a glowing halo along its bottom edge.
///
/// Drag [HaloFile]s (or lists of them) onto it, or tap it (Enter and Space
/// work too) to call [onBrowse]. Hovering, focusing or dragging over it
/// brightens the halo and sends a streak of light around its rim. Once
/// files arrive [onFiles] is called and the zone shows them with a check,
/// their thumbnails springing in one after another, then returns to its
/// prompt after [successDuration].
///
/// The halo is three soft, blurred bands of [colors] drifting along the
/// bottom. Colors of the surface follow the ambient text color, so it works
/// on light and dark backgrounds. When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the halo, icon and rim hold still.
class HaloDropzone extends StatefulWidget {
  /// Creates a drop zone.
  const HaloDropzone({
    super.key,
    required this.onFiles,
    this.onBrowse,
    this.multiple = true,
    this.prompt = 'Drop files here or browse',
    this.hint,
    this.successLabel = 'Files added',
    this.successDuration = const Duration(milliseconds: 2400),
    this.colors = defaultColors,
    this.radius = 16,
  });

  /// Magenta, violet and blue.
  static const List<List<Color>> defaultColors = [
    [Color(0xFFFF0080), Color(0xFF7928CA), Color(0xFF00D4FF), Color(0xFF0070F3)],
    [Color(0xFFFF4D4D), Color(0xFFF9CB28), Color(0xFFFF0080)],
    [Color(0xFF0070F3), Color(0xFF00D4FF), Color(0xFF7928CA)],
  ];

  /// Called with the files that arrive; null disables the zone.
  final ValueChanged<List<HaloFile>>? onFiles;

  /// Called on tap to choose files, for example with a file picker
  /// plugin; return null or an empty list when the user cancels.
  final Future<List<HaloFile>?> Function()? onBrowse;

  /// Whether more than one file is taken at a time.
  final bool multiple;

  /// The invitation shown while idle.
  final String prompt;

  /// A smaller line under [prompt], such as the accepted formats.
  final String? hint;

  /// Shown once files arrive.
  final String successLabel;

  /// How long the files stay shown before the prompt returns; zero keeps
  /// them.
  final Duration successDuration;

  /// The halo's bands, each a list of colors blended across the band.
  final List<List<Color>> colors;

  /// Corner radius of the zone.
  final double radius;

  @override
  State<HaloDropzone> createState() => _HaloDropzoneState();
}

class _HaloDropzoneState extends State<HaloDropzone> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<double> _time = ValueNotifier(0);
  double _offset = 0;

  /// Rim streak position (0..1 around the rim) and its visibility.
  double _trail = 0;
  double _trailOpacity = 0;
  double _lastTick = 0;

  bool _hovered = false;
  bool _focused = false;
  bool _dragging = false;
  List<HaloFile>? _arrived;
  int _arrival = 0;
  Timer? _reset;

  bool get _enabled => widget.onFiles != null;
  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  bool get _attention => _enabled && (_hovered || _focused || _dragging);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(HaloDropzone oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final still = _reduceMotion || !_enabled;
    if (still && _ticker.isActive) {
      _offset = _time.value;
      _ticker.stop();
    } else if (!still && !_ticker.isActive) {
      _lastTick = 0;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6;
    final dt = (now - _lastTick).clamp(0.0, 0.1);
    _lastTick = now;
    // The rim streak laps every 5 s while wanted, fading in and out.
    final target = _attention ? 1.0 : 0.0;
    _trailOpacity += (target - _trailOpacity) * math.min(1, dt * 6);
    if (_trailOpacity > 0.01) _trail = (_trail + dt / 5) % 1;
    _time.value = _offset + now;
  }

  @override
  void dispose() {
    _reset?.cancel();
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  void _accept(List<HaloFile> files) {
    if (!_enabled || files.isEmpty) return;
    final taken = widget.multiple ? files : files.take(1).toList();
    widget.onFiles!(taken);
    setState(() {
      _arrived = taken;
      _arrival++;
    });
    _reset?.cancel();
    if (widget.successDuration > Duration.zero) {
      _reset = Timer(widget.successDuration, () {
        if (mounted) setState(() => _arrived = null);
      });
    }
  }

  Future<void> _browse() async {
    final browse = widget.onBrowse;
    if (!_enabled || browse == null) return;
    final files = await browse();
    if (mounted && files != null) _accept(files);
  }

  static List<HaloFile>? _filesIn(Object? data) => switch (data) {
    final HaloFile file => [file],
    final List<HaloFile> files => files,
    final Iterable<Object?> items when items.every((i) => i is HaloFile) =>
      items.cast<HaloFile>().toList(),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final ink = DefaultTextStyle.of(context).style.color ?? const Color(0xFF0A0A0A);
    final dark = ink.computeLuminance() > 0.5;
    final arrived = _arrived;
    final surface = dark ? const Color(0xFF141417) : const Color(0xFFFFFFFF);
    final r = BorderRadius.circular(widget.radius);
    final reduce = _reduceMotion;

    final body = AnimatedSwitcher(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: arrived == null
          ? _Prompt(
              key: const ValueKey('prompt'),
              time: _time,
              ink: ink,
              prompt: widget.prompt,
              hint: widget.hint,
            )
          : _Arrived(
              key: ValueKey(_arrival),
              files: arrived,
              ink: ink,
              dark: dark,
              label: widget.successLabel,
              reduceMotion: reduce,
            ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: arrived == null
          ? widget.prompt
          : '${widget.successLabel}: ${arrived.map((f) => f.name).join(', ')}',
      excludeSemantics: true,
      child: Opacity(
        opacity: _enabled ? 1 : 0.55,
        child: FocusableActionDetector(
          enabled: _enabled,
          mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _browse())},
          // Hover is tracked directly: the detector only reports hover once
          // a mouse has clicked somewhere.
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _enabled ? _browse : null,
              child: DragTarget<Object>(
                onWillAcceptWithDetails: (details) {
                  final ok = _enabled && _filesIn(details.data) != null;
                  if (ok) setState(() => _dragging = true);
                  return ok;
                },
                onLeave: (_) => setState(() => _dragging = false),
                onAcceptWithDetails: (details) {
                  setState(() => _dragging = false);
                  _accept(_filesIn(details.data) ?? const []);
                },
                builder: (context, _, _) => AnimatedScale(
                  scale: _dragging ? 1.015 : 1,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: CustomPaint(
                    // The halo glows behind the 1 px-inset surface, so it reads
                    // as a lit edge and a soft glow inside the bottom.
                    painter: _HaloPainter(
                      time: _time,
                      bands: widget.colors.isEmpty ? HaloDropzone.defaultColors : widget.colors,
                      radius: widget.radius,
                      strength: _attention || arrived != null ? 0.95 : 0.6,
                    ),
                    foregroundPainter: reduce || !_enabled
                        ? null
                        : _TrailPainter(
                            time: _time,
                            state: this,
                            radius: widget.radius,
                            dark: dark,
                          ),
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: AnimatedContainer(
                        duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
                        constraints: const BoxConstraints(
                          minHeight: 170,
                          minWidth: double.infinity,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.radius - 1),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              surface.withValues(alpha: 0.97),
                              surface.withValues(alpha: 0.9),
                              surface.withValues(alpha: _attention ? 0.25 : 0.42),
                            ],
                          ),
                          border: Border.all(
                            color: ink.withValues(
                              alpha: _focused ? 0.45 : (_attention ? 0.18 : 0.1),
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF000000).withValues(alpha: dark ? 0.4 : 0.06),
                              blurRadius: _attention ? 18 : 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: r,
                          child: Center(child: body),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The idle content: a gently bobbing upload icon and the prompt.
class _Prompt extends StatelessWidget {
  const _Prompt({
    super.key,
    required this.time,
    required this.ink,
    required this.prompt,
    required this.hint,
  });

  final ValueListenable<double> time;
  final Color ink;
  final String prompt;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: time,
          builder: (context, child) => Transform.translate(
            // A slow 3 px bob, once every 4.5 s.
            offset: Offset(0, -1.5 + 1.5 * math.cos(time.value * 2 * math.pi / 4.5)),
            child: child,
          ),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ink.withValues(alpha: 0.05),
              border: Border.all(color: ink.withValues(alpha: 0.1)),
            ),
            child: CustomPaint(painter: _UploadPainter(ink.withValues(alpha: 0.7))),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          prompt,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: ink),
        ),
        if (hint case final hint?) ...[
          const SizedBox(height: 10),
          Text(
            hint,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.55)),
          ),
        ],
      ],
    );
  }
}

/// The success content: a check, the label and the files.
class _Arrived extends StatelessWidget {
  const _Arrived({
    super.key,
    required this.files,
    required this.ink,
    required this.dark,
    required this.label,
    required this.reduceMotion,
  });

  final List<HaloFile> files;
  final Color ink;
  final bool dark;
  final String label;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final green = dark ? const Color(0xFF34D399) : const Color(0xFF059669);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x2610B981),
                border: Border.all(color: const Color(0x4010B981)),
              ),
              child: CustomPaint(painter: _CheckPainter(green)),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 10,
          children: [
            for (final (i, file) in files.indexed)
              _Thumb(file: file, index: i, ink: ink, reduceMotion: reduceMotion),
          ],
        ),
      ],
    );
  }
}

/// One arrived file: icon and name, springing in after the ones before it.
class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.file,
    required this.index,
    required this.ink,
    required this.reduceMotion,
  });

  final HaloFile file;
  final int index;
  final Color ink;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: 72,
      child: Column(
        children: [
          HaloFileIcon(file: file, size: 40),
          const SizedBox(height: 6),
          Text(
            file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: ink.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
    if (reduceMotion) return content;
    // 55 ms apart, each rising and scaling up with a small overshoot.
    final delay = 0.055 * index;
    const length = 0.45;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: ((delay + length) * 1000).round()),
      builder: (context, t, child) {
        final local = ((t * (delay + length) - delay) / length).clamp(0.0, 1.0);
        final s = Curves.easeOutBack.transform(local);
        return Opacity(
          opacity: local,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - s)),
            child: Transform.scale(scale: 0.85 + 0.15 * s, child: child),
          ),
        );
      },
      child: content,
    );
  }
}

/// A small document icon for a [HaloFile]: its [HaloFile.preview] when it
/// has one, otherwise a page with a folded corner, a few lines and an
/// extension badge colored by file type.
class HaloFileIcon extends StatelessWidget {
  /// Creates a file icon.
  const HaloFileIcon({super.key, required this.file, this.size = 34});

  /// The file to show.
  final HaloFile file;

  /// Height of the icon; it is a little narrower than tall.
  final double size;

  /// Badge color for an extension.
  static Color colorFor(String extension) => switch (extension) {
    'pdf' => const Color(0xFFE5484D),
    'doc' || 'docx' => const Color(0xFF3E63DD),
    'xls' || 'xlsx' || 'csv' => const Color(0xFF30A46C),
    'ppt' || 'pptx' || 'key' => const Color(0xFFF76B15),
    'json' || 'js' || 'ts' || 'dart' => const Color(0xFFAB4ABA),
    'md' || 'txt' => const Color(0xFF8B8D98),
    'zip' || 'rar' || '7z' => const Color(0xFFAD7F58),
    _ => const Color(0xFF8B8D98),
  };

  @override
  Widget build(BuildContext context) {
    final preview = file.preview;
    return SizedBox(
      width: size * 0.82,
      height: size,
      child: preview != null
          ? ClipRRect(borderRadius: BorderRadius.circular(size * 0.14), child: preview)
          : CustomPaint(painter: _DocPainter(file.extension, colorFor(file.extension))),
    );
  }
}

class _DocPainter extends CustomPainter {
  const _DocPainter(this.extension, this.color);

  final String extension;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fold = w * 0.3;
    final page = Path()
      ..moveTo(0, h * 0.06)
      ..quadraticBezierTo(0, 0, w * 0.08, 0)
      ..lineTo(w - fold, 0)
      ..lineTo(w, fold)
      ..lineTo(w, h - h * 0.06)
      ..quadraticBezierTo(w, h, w - w * 0.08, h)
      ..lineTo(w * 0.08, h)
      ..quadraticBezierTo(0, h, 0, h - h * 0.06)
      ..close();
    canvas
      ..drawShadow(page, const Color(0x40000000), 1.5, false)
      ..drawPath(page, Paint()..color = const Color(0xFFFFFFFF))
      ..drawPath(
        page,
        Paint()
          ..color = const Color(0x1F000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      )
      ..drawPath(
        Path()
          ..moveTo(w - fold, 0)
          ..lineTo(w - fold, fold)
          ..lineTo(w, fold)
          ..close(),
        Paint()..color = const Color(0xFFE4E4E7),
      );
    final line = Paint()
      ..color = const Color(0xFFD4D4D8)
      ..strokeWidth = h * 0.045
      ..strokeCap = StrokeCap.round;
    for (final (y, end) in [(0.36, 0.72), (0.48, 0.8), (0.6, 0.6)]) {
      canvas.drawLine(Offset(w * 0.18, h * y), Offset(w * end, h * y), line);
    }
    if (extension.isEmpty) return;
    final badge = RRect.fromLTRBR(0, h * 0.7, w * 0.78, h * 0.92, Radius.circular(h * 0.04));
    canvas.drawRRect(badge, Paint()..color = color);
    final label = TextPainter(
      text: TextSpan(
        text: extension.toUpperCase().substring(0, math.min(4, extension.length)),
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: h * 0.15,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: badge.width);
    label
      ..paint(canvas, badge.center - Offset(label.width / 2, label.height / 2))
      ..dispose();
  }

  @override
  bool shouldRepaint(_DocPainter old) => old.extension != extension || old.color != color;
}

/// Three blurred bands of color drifting back and forth along the bottom.
class _HaloPainter extends CustomPainter {
  _HaloPainter({
    required this.time,
    required this.bands,
    required this.radius,
    required this.strength,
  }) : super(repaint: time);

  final ValueListenable<double> time;
  final List<List<Color>> bands;
  final double radius;
  final double strength;

  /// Per band: width and height (fractions of the zone), how far it hangs
  /// below the bottom (fraction of its height), blur, start and end of its
  /// drift (fractions of the width) and seconds per back-and-forth.
  static const List<(double, double, double, double, double, double, double)> _shapes = [
    (0.5, 0.62, 0.3, 30, -0.05, 0.6, 6),
    (0.38, 0.52, 0.3, 26, 0.6, 0.08, 5),
    (0.3, 0.46, 0.28, 22, 0.22, 0.5, 4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final zone = Offset.zero & size;
    canvas
      ..save()
      ..clipRRect(RRect.fromRectAndRadius(zone.inflate(1), Radius.circular(radius)));
    for (final (i, colors) in bands.indexed) {
      if (colors.length < 2) continue;
      final (bw, bh, hang, blur, from, to, period) = _shapes[i % _shapes.length];
      // Ease in and out between the two ends of the drift.
      final phase = 0.5 - 0.5 * math.cos(t * 2 * math.pi / period);
      final left = (from + (to - from) * phase) * size.width;
      final rect = Rect.fromLTWH(
        left,
        size.height - bh * size.height * (1 - hang),
        bw * size.width,
        bh * size.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
        Paint()
          ..shader = LinearGradient(colors: colors).createShader(rect)
          ..color = Color.fromRGBO(0, 0, 0, strength)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.time != time || old.bands != bands || old.radius != radius || old.strength != strength;
}

/// A short streak of light running around the zone's rim.
class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.time, required this.state, required this.radius, required this.dark})
    : super(repaint: time);

  final ValueListenable<double> time;
  final _HaloDropzoneState state;
  final double radius;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = state._trailOpacity;
    if (opacity < 0.01) return;
    final rim = Path()
      ..addRRect(
        RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(radius)),
      );
    final metric = rim.computeMetrics().first;
    final length = metric.length;
    final head = state._trail * length;
    const streak = 0.16;
    // The streak is drawn as short segments fading toward its tail.
    const pieces = 14;
    for (var k = 0; k < pieces; k++) {
      final a = head - length * streak * (k + 1) / pieces;
      final b = head - length * streak * k / pieces;
      final fade = 1 - k / pieces;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = (dark ? const Color(0xFFFFFFFF) : const Color(0xFF7928CA)).withValues(
          alpha: fade * opacity,
        );
      _drawSegment(canvas, metric, a, b, length, paint);
    }
  }

  void _drawSegment(
    Canvas canvas,
    ui.PathMetric metric,
    double a,
    double b,
    double length,
    Paint p,
  ) {
    double wrap(double v) => ((v % length) + length) % length;
    final from = wrap(a);
    final to = wrap(b);
    if (from <= to) {
      canvas.drawPath(metric.extractPath(from, to), p);
    } else {
      canvas
        ..drawPath(metric.extractPath(from, length), p)
        ..drawPath(metric.extractPath(0, to), p);
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) => true;
}

class _UploadPainter extends CustomPainter {
  const _UploadPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawLine(c + const Offset(0, 4), c + const Offset(0, -6), paint)
      ..drawPath(
        Path()
          ..moveTo(c.dx - 4.5, c.dy - 1.5)
          ..lineTo(c.dx, c.dy - 6)
          ..lineTo(c.dx + 4.5, c.dy - 1.5),
        paint,
      )
      ..drawLine(c + const Offset(-6, 8), c + const Offset(6, 8), paint);
  }

  @override
  bool shouldRepaint(_UploadPainter old) => old.color != color;
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 5, c.dy)
        ..lineTo(c.dx - 1.5, c.dy + 3.5)
        ..lineTo(c.dx + 5.5, c.dy - 4),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}
