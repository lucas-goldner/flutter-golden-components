import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Timing and motion of a [KineticLine]. Durations are scaled by
/// [KineticLine.speed].
@immutable
class KineticLineTiming {
  /// Creates a timing.
  const KineticLineTiming({
    this.firstWord = const Duration(milliseconds: 340),
    this.push = const Duration(milliseconds: 430),
    this.hold = const Duration(milliseconds: 980),
    this.exit = const Duration(milliseconds: 260),
    this.between = const Duration(milliseconds: 220),
    this.entryOffset = 88,
    this.wordGap = 10,
    this.firstWordDrop = 6,
    this.entryScale = 0.992,
    this.entryBlur = 3.5,
    this.pushBlur = 0.8,
    this.exitRise = 6,
    this.exitBlur = 2.5,
    this.curve = const Cubic(0.2, 0.8, 0.2, 1),
    this.exitCurve = const Cubic(0.4, 0, 0.2, 1),
  });

  /// The first word fading up into the centre.
  final Duration firstWord;

  /// Each later word sliding in while the line re-centres.
  final Duration push;

  /// How long the finished phrase rests.
  final Duration hold;

  /// The whole line lifting out.
  final Duration exit;

  /// The pause before the next phrase.
  final Duration between;

  /// How far to the right of its place a new word starts.
  final double entryOffset;

  /// Space between words.
  final double wordGap;

  /// How far below the centre the first word starts.
  final double firstWordDrop;

  /// Scale an entering word starts at.
  final double entryScale;

  /// Blur an entering word starts with.
  final double entryBlur;

  /// Blur the line picks up while it is pushed along.
  final double pushBlur;

  /// How far the line rises as it leaves.
  final double exitRise;

  /// Blur the line ends with as it leaves.
  final double exitBlur;

  /// Easing of entries and pushes.
  final Curve curve;

  /// Easing of the exit.
  final Curve exitCurve;
}

/// A line of text that builds itself word by word around its centre.
///
/// The first word of a phrase fades up in the middle. Every following word
/// slides in from the right with a soft blur and pushes the words before it
/// over, so the growing line always stays centred. The finished phrase
/// holds, lifts out, and the next of [phrases] begins; with [loop] off the
/// last phrase stays.
///
/// When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the first phrase is shown complete
/// and holds still.
class KineticLine extends StatefulWidget {
  /// Creates a kinetic line.
  const KineticLine({
    super.key,
    this.phrases = defaultPhrases,
    this.style,
    this.speed = 0.72,
    this.timing = const KineticLineTiming(),
    this.loop = true,
  }) : assert(speed > 0);

  /// A short sample: three phrases of three words.
  static const List<List<String>> defaultPhrases = [
    ['Each', 'word', 'arrives'],
    ['Center', 'holds', 'still'],
    ['Builds', 'one', 'line'],
  ];

  /// Phrases to cycle through, each a list of words.
  final List<List<String>> phrases;

  /// Text style, merged over the ambient [DefaultTextStyle].
  final TextStyle? style;

  /// Multiplies every duration in [timing]: lower is faster.
  final double speed;

  /// Durations, distances and easing.
  final KineticLineTiming timing;

  /// Whether to start over after the last phrase.
  final bool loop;

  @override
  State<KineticLine> createState() => _KineticLineState();
}

/// Where a word is and how it looks at one moment.
@immutable
class _Pose {
  const _Pose(this.x, this.y, this.scale, this.blur, this.opacity);

  const _Pose.rest(double x) : this(x, 0, 1, 0, 1);

  final double x;
  final double y;
  final double scale;
  final double blur;
  final double opacity;

  static _Pose lerp(_Pose a, _Pose b, double t) {
    double mix(double p, double q) => p + (q - p) * t;
    return _Pose(
      mix(a.x, b.x),
      mix(a.y, b.y),
      mix(a.scale, b.scale),
      mix(a.blur, b.blur),
      mix(a.opacity, b.opacity),
    );
  }

  /// From [from] through [via] (reached at [at]) to [to], at eased [t].
  static _Pose path(_Pose from, _Pose via, double at, _Pose to, double t) =>
      t <= at ? lerp(from, via, at == 0 ? 1 : t / at) : lerp(via, to, (t - at) / (1 - at));
}

/// One measured phrase: its words, their widths, and their centres.
@immutable
class _Phrase {
  const _Phrase(this.words, this.widths);

  final List<String> words;
  final List<double> widths;

  /// Centres of the first [count] words when they sit centred as a line.
  List<double> centres(int count, double gap) {
    final shown = widths.take(count).toList();
    final total = shown.fold(0.0, (sum, w) => sum + w) + gap * math.max(0, shown.length - 1);
    final centres = <double>[];
    var cursor = -total / 2;
    for (final w in shown) {
      centres.add(cursor + w / 2);
      cursor += w + gap;
    }
    return centres;
  }

  double width(double gap) =>
      widths.fold(0.0, (sum, w) => sum + w) + gap * math.max(0, widths.length - 1);
}

class _KineticLineState extends State<KineticLine> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);

  /// Milliseconds into the whole cycle.
  double _t = 0;

  List<_Phrase>? _measured;
  Object? _measuredFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measured = null;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(KineticLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_samePhrases(oldWidget.phrases, widget.phrases)) {
      _measured = null;
      _t = 0;
      if (_ticker.isActive) {
        _ticker
          ..stop()
          ..start();
      }
    }
    if (oldWidget.style != widget.style) _measured = null;
  }

  static bool _samePhrases(List<List<String>> a, List<List<String>> b) =>
      a.length == b.length &&
      [
        for (var i = 0; i < a.length; i++) a[i].join('\u0001') == b[i].join('\u0001'),
      ].every((x) => x);

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) => setState(() => _t = elapsed.inMicroseconds / 1000);

  List<List<String>> get _phrases => [
    for (final p in widget.phrases)
      if (p.isNotEmpty) p,
  ];

  List<_Phrase> _measure(TextStyle style, TextScaler scaler) {
    final key = (style, scaler, widget.phrases);
    if (_measured != null && _measuredFor == key) return _measured!;
    _measuredFor = key;
    double width(String word) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }

    return _measured = [
      for (final words in _phrases) _Phrase(words, [for (final w in words) width(w)]),
    ];
  }

  double _ms(Duration d, double min) => math.max(min, d.inMicroseconds / 1000 * widget.speed);

  @override
  Widget build(BuildContext context) {
    final ambient = DefaultTextStyle.of(context).style.merge(widget.style);
    final fontSize = ambient.fontSize ?? 32;
    // Slightly tight tracking reads best at display sizes.
    final style = ambient.copyWith(
      letterSpacing: ambient.letterSpacing ?? -0.025 * fontSize,
      height: ambient.height ?? 1.1,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final phrases = _measure(style, scaler);
    if (phrases.isEmpty) return const SizedBox.shrink();

    final timing = widget.timing;
    final first = _ms(timing.firstWord, 180);
    final push = _ms(timing.push, 180);
    final hold = _ms(timing.hold, 380);
    final exit = _ms(timing.exit, 140);
    final between = _ms(timing.between, 120);
    final gap = timing.wordGap;
    double length(int words) => first + math.max(0, words - 1) * push + hold + exit + between;

    // Find the phrase playing at _t and the time into it. Without looping,
    // the last phrase stays once it is built.
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    var index = 0;
    var t = _t;
    if (reduce) {
      // Long after the first phrase is built; it then holds forever.
      t = double.maxFinite;
    } else {
      if (widget.loop) {
        t %= phrases.fold(0.0, (sum, p) => sum + length(p.words.length));
      }
      while (index < phrases.length - 1 && t >= length(phrases[index].words.length)) {
        t -= length(phrases[index].words.length);
        index++;
      }
      if (widget.loop) t %= length(phrases[index].words.length);
    }
    final phrase = phrases[index];
    final n = phrase.words.length;
    final buildEnd = first + (n - 1) * push;
    final holdEnd = (!widget.loop && index == phrases.length - 1) || reduce
        ? double.infinity
        : buildEnd + hold;

    final poses = <_Pose>[];
    if (t < first) {
      final p = timing.curve.transform((t / first).clamp(0.0, 1.0));
      final drop = timing.firstWordDrop;
      poses.add(
        _Pose.path(
          _Pose(0, drop, timing.entryScale, timing.entryBlur, 0),
          _Pose(0, drop * 0.35, 0.998, timing.entryBlur * 0.45, 0.78),
          0.58,
          const _Pose.rest(0),
          p,
        ),
      );
    } else if (t < buildEnd) {
      // Word `step` is entering; the ones before it are pushed along.
      final step = 1 + ((t - first) ~/ push);
      final p = timing.curve.transform(((t - first - (step - 1) * push) / push).clamp(0.0, 1.0));
      final now = phrase.centres(step, gap);
      final next = phrase.centres(step + 1, gap);
      for (var i = 0; i < step; i++) {
        poses.add(
          _Pose.path(
            _Pose.rest(now[i]),
            _Pose(now[i] + (next[i] - now[i]) * 0.58, 0, 1, timing.pushBlur, 1),
            0.52,
            _Pose.rest(next[i]),
            p,
          ),
        );
      }
      final target = next[step];
      final start = target + timing.entryOffset;
      poses.add(
        _Pose.path(
          _Pose(start, 0, timing.entryScale, timing.entryBlur, 0),
          _Pose(start + (target - start) * 0.72, 0, 0.998, timing.entryBlur * 0.38, 0.84),
          0.6,
          _Pose.rest(target),
          p,
        ),
      );
    } else {
      final centres = phrase.centres(n, gap);
      if (t < holdEnd) {
        poses.addAll(centres.map(_Pose.rest));
      } else if (t < holdEnd + exit) {
        final p = timing.exitCurve.transform(((t - holdEnd) / exit).clamp(0.0, 1.0));
        final rise = -timing.exitRise;
        for (final x in centres) {
          poses.add(
            _Pose.path(
              _Pose.rest(x),
              _Pose(x, rise * 0.45, 1, timing.exitBlur * 0.55, 0.62),
              0.52,
              _Pose(x, rise, 1, timing.exitBlur, 0),
              p,
            ),
          );
        }
      }
    }

    if (!widget.loop && holdEnd.isInfinite && t >= buildEnd && _ticker.isActive) {
      // Finished for good: stop ticking once the last phrase is built.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ticker.stop();
      });
    }

    final lineHeight = scaler.scale(fontSize) * (style.height ?? 1.1);
    final widest = phrases.fold(0.0, (w, p) => math.max(w, p.width(gap)));
    return Semantics(
      label: phrase.words.join(' '),
      liveRegion: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: widest + timing.entryOffset * 0.5,
          height: lineHeight + 2 * math.max(timing.firstWordDrop, timing.exitRise),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              for (final (i, pose) in poses.indexed)
                _Word(text: phrase.words[i], style: style, pose: pose),
            ],
          ),
        ),
      ),
    );
  }
}

/// One word at its [pose].
class _Word extends StatelessWidget {
  const _Word({required this.text, required this.style, required this.pose});

  final String text;
  final TextStyle style;
  final _Pose pose;

  @override
  Widget build(BuildContext context) {
    Widget child = Text(text, style: style, maxLines: 1, softWrap: false);
    if (pose.scale != 1) child = Transform.scale(scale: pose.scale, child: child);
    if (pose.blur > 0.05) {
      child = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: pose.blur / 2,
          sigmaY: pose.blur / 2,
          tileMode: TileMode.decal,
        ),
        child: child,
      );
    }
    return Opacity(
      opacity: pose.opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(pose.x, pose.y),
        child: OverflowBox(maxWidth: double.infinity, child: child),
      ),
    );
  }
}
