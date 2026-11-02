import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// What a [JumpText] animates one at a time.
enum JumpTextUnit {
  /// Each word (and the space after it) jumps on its own.
  word,

  /// Each character jumps on its own. Words still wrap as a whole.
  character,
}

/// Text whose words (or characters) jump up into place one after another,
/// like story captions.
///
/// Every unit starts [rise] pixels below its place, tilted by [tilt]
/// degrees and transparent, and springs into place on [spring]; each one
/// starts [stagger] after the previous. The effect plays once when the
/// widget is first shown and again whenever [text] or [unit] change; give
/// the widget a new [Key] to replay it.
///
/// When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the text appears in place at once.
class JumpText extends StatefulWidget {
  /// Creates jumping text.
  const JumpText(
    this.text, {
    super.key,
    this.unit = JumpTextUnit.word,
    this.style,
    this.textAlign = TextAlign.center,
    this.spring = defaultSpring,
    this.stagger,
    this.delay = Duration.zero,
    this.rise = 30,
    this.tilt = -30,
    this.onComplete,
  });

  /// A heavy, bouncy spring: a quick overshoot that rings out.
  static const SpringDescription defaultSpring = SpringDescription(
    mass: 2,
    stiffness: 100,
    damping: 10,
  );

  /// The text to show.
  final String text;

  /// Whether words or characters jump one at a time.
  final JumpTextUnit unit;

  /// Text style, merged over the ambient [DefaultTextStyle].
  final TextStyle? style;

  /// How lines are aligned when the text wraps.
  final TextAlign textAlign;

  /// The spring each unit jumps on.
  final SpringDescription spring;

  /// Delay between units. Defaults to 50 ms per word or 10 ms per
  /// character.
  final Duration? stagger;

  /// Delay before the first unit starts.
  final Duration delay;

  /// How far below its place each unit starts, in logical pixels.
  final double rise;

  /// How far each unit starts rotated, in degrees (negative tilts left).
  final double tilt;

  /// Called once every unit has settled.
  final VoidCallback? onComplete;

  @override
  State<JumpText> createState() => _JumpTextState();
}

class _JumpTextState extends State<JumpText> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);

  /// Seconds since the effect started; null once it has settled.
  double? _elapsed = 0;

  late List<List<String>> _groups;
  late SpringSimulation _simulation;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _play();
  }

  @override
  void didUpdateWidget(JumpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spring != widget.spring) {
      _simulation = _newSimulation();
    }
    if (oldWidget.text != widget.text || oldWidget.unit != widget.unit) {
      _prepare();
      _elapsed = 0;
      _play();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _prepare() {
    _groups = _split(widget.text, widget.unit);
    _simulation = _newSimulation();
  }

  SpringSimulation _newSimulation() => SpringSimulation(
    widget.spring,
    0,
    1,
    0,
    tolerance: const Tolerance(distance: 0.001, velocity: 0.01),
  );

  /// Groups that wrap as a whole: a word with its following space, split
  /// into characters in character mode.
  static List<List<String>> _split(String text, JumpTextUnit unit) {
    final words = RegExp(r'\S+\s*|\s+').allMatches(text).map((m) => m[0]!);
    return [
      for (final word in words) unit == JumpTextUnit.word ? [word] : word.characters.toList(),
    ];
  }

  int get _count => _groups.fold(0, (sum, g) => sum + g.length);

  double get _staggerSeconds {
    final stagger =
        widget.stagger ?? Duration(milliseconds: widget.unit == JumpTextUnit.word ? 50 : 10);
    return stagger.inMicroseconds / 1e6;
  }

  double get _delaySeconds => widget.delay.inMicroseconds / 1e6;

  void _play() {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce || _count == 0) {
      _ticker.stop();
      _elapsed = null;
      return;
    }
    if (_elapsed != null && !_ticker.isActive) {
      _ticker
        ..stop()
        ..start();
    }
  }

  void _tick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final last = _delaySeconds + (_count - 1) * _staggerSeconds;
    setState(() => _elapsed = t);
    if (t > last && _simulation.isDone(t - last)) {
      _ticker.stop();
      setState(() => _elapsed = null);
      widget.onComplete?.call();
    }
  }

  /// Progress of unit [index] (0 hidden, 1 in place; overshoots past 1).
  double _progress(int index) {
    final elapsed = _elapsed;
    if (elapsed == null) return 1;
    final t = elapsed - _delaySeconds - index * _staggerSeconds;
    return t <= 0 ? 0 : _simulation.x(t);
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    var index = 0;
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: Wrap(
          alignment: switch (widget.textAlign) {
            TextAlign.left || TextAlign.start => WrapAlignment.start,
            TextAlign.right || TextAlign.end => WrapAlignment.end,
            TextAlign.justify => WrapAlignment.spaceBetween,
            TextAlign.center => WrapAlignment.center,
          },
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            for (final group in _groups)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final unit in group)
                    _Unit(
                      text: unit,
                      style: style,
                      progress: _progress(index++),
                      rise: widget.rise,
                      tilt: widget.tilt,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// One word or character, posed by its jump [progress].
class _Unit extends StatelessWidget {
  const _Unit({
    required this.text,
    required this.style,
    required this.progress,
    required this.rise,
    required this.tilt,
  });

  final String text;
  final TextStyle style;
  final double progress;
  final double rise;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    // Non-breaking spaces keep a trailing space's width at the end of a
    // wrapped line.
    final label = Text(text.replaceAll(' ', ' '), style: style, maxLines: 1, softWrap: false);
    if (progress == 1) return label;
    final left = 1 - progress;
    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, rise * left),
        child: Transform.rotate(angle: tilt * left * math.pi / 180, child: label),
      ),
    );
  }
}
