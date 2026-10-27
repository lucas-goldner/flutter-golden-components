import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Which way the digits of a [DigitRoll] turn when its value changes.
enum DigitRollDirection {
  /// Up when the number grows, down when it shrinks.
  auto,

  /// Always up: 9 wraps forward to 0.
  up,

  /// Always down: 0 wraps back to 9.
  down,

  /// Whichever way is fewer steps for each digit.
  shortest,
}

/// How a [DigitRoll] writes its number.
///
/// Formatting is built in because the widgets layer has no `intl`.
@immutable
class DigitRollFormat {
  /// Creates a number format.
  const DigitRollFormat({
    this.decimals = 0,
    this.minDigits = 1,
    this.grouping = true,
    this.groupSeparator = ',',
    this.decimalSeparator = '.',
    this.prefix = '',
    this.suffix = '',
  }) : assert(decimals >= 0 && decimals <= 10),
       assert(minDigits >= 1 && minDigits <= 18);

  /// Number of fraction digits, always shown (zero padded).
  final int decimals;

  /// Minimum number of integer digits; shorter numbers get leading zeros.
  final int minDigits;

  /// Whether thousands are separated with [groupSeparator].
  final bool grouping;

  /// Placed between groups of three integer digits.
  final String groupSeparator;

  /// Placed between the integer and fraction digits.
  final String decimalSeparator;

  /// Text before the number, such as `$`. It does not roll.
  final String prefix;

  /// Text after the number, such as `%` or ` pts`. It does not roll.
  final String suffix;

  /// Writes [value] the way a [DigitRoll] with this format shows it.
  String apply(num value) {
    final cells = _cellsFor(value, this);
    return [for (final c in cells) c.digit?.toString() ?? c.text].join();
  }

  @override
  bool operator ==(Object other) =>
      other is DigitRollFormat &&
      other.decimals == decimals &&
      other.minDigits == minDigits &&
      other.grouping == grouping &&
      other.groupSeparator == groupSeparator &&
      other.decimalSeparator == decimalSeparator &&
      other.prefix == prefix &&
      other.suffix == suffix;

  @override
  int get hashCode =>
      Object.hash(decimals, minDigits, grouping, groupSeparator, decimalSeparator, prefix, suffix);
}

/// A number whose digits roll to each new [value] like an odometer.
///
/// Every digit turns on its own [spring], starting [stagger] after the digit
/// to its right, so changes ripple from the ones place outward. Digits that
/// appear (999 to 1,000) grow in while rolling up from zero, and digits that
/// go away roll back to zero and shrink out. Fast turns are smeared with a
/// vertical [motionBlur], and the numerals fade out over [edgeFade] at the
/// top and bottom of each digit.
///
/// When the platform asks to reduce motion
/// ([MediaQueryData.disableAnimations]) the digits jump straight to the new
/// value.
///
/// ```dart
/// DigitRoll(
///   value: price,
///   format: const DigitRollFormat(prefix: r'$'),
///   style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w600),
/// )
/// ```
class DigitRoll extends StatefulWidget {
  /// Creates a rolling number.
  const DigitRoll({
    super.key,
    required this.value,
    this.format = const DigitRollFormat(),
    this.style,
    this.direction = DigitRollDirection.auto,
    this.spring = defaultSpring,
    this.stagger = const Duration(milliseconds: 40),
    this.motionBlur = true,
    this.edgeFade = 0.3,
    this.rollOnMount = true,
    this.tabularFigures = true,
    this.spacing = 0,
    this.digitDecoration,
    this.digitPadding = EdgeInsets.zero,
  }) : assert(edgeFade >= 0 && edgeFade <= 0.5),
       assert(spacing >= 0);

  /// A quick spring with a small overshoot.
  static const SpringDescription defaultSpring = SpringDescription(
    mass: 1,
    stiffness: 100,
    damping: 16,
  );

  /// The number shown. Rounded to [DigitRollFormat.decimals].
  final num value;

  /// How the number is written.
  final DigitRollFormat format;

  /// Text style of the digits and symbols, merged over the ambient
  /// [DefaultTextStyle].
  final TextStyle? style;

  /// Which way digits turn.
  final DigitRollDirection direction;

  /// The spring each digit turns on.
  final SpringDescription spring;

  /// Delay between one digit starting to roll and the next one to its left.
  final Duration stagger;

  /// Whether fast-turning digits are blurred vertically.
  final bool motionBlur;

  /// Fraction of a digit's height (0 to 0.5) over which numerals fade at
  /// its top and bottom edge.
  final double edgeFade;

  /// Whether the digits spin once round to their value when first shown.
  final bool rollOnMount;

  /// Whether every digit takes the width of the widest numeral, so the
  /// number does not shift as it rolls. Otherwise widths ease between
  /// numerals.
  final bool tabularFigures;

  /// Horizontal space between neighbouring digits and symbols.
  final double spacing;

  /// Painted behind each digit, for example a tile for a flip-clock look.
  final Decoration? digitDecoration;

  /// Space between each digit and its [digitDecoration].
  final EdgeInsets digitPadding;

  @override
  State<DigitRoll> createState() => _DigitRollState();
}

/// One digit or symbol of a formatted number.
@immutable
class _CellSpec {
  const _CellSpec(this.key, this.rank, {this.digit, this.text = ''});

  /// Stable across values: digits are keyed by their place, so the tens
  /// digit of 19 and of 20 is the same cell.
  final String key;

  /// Left-to-right order; lower is further left.
  final double rank;

  /// The numeral, for digits.
  final int? digit;

  /// The text, for symbols.
  final String text;
}

List<_CellSpec> _cellsFor(num value, DigitRollFormat format) {
  final fixed = value.abs().toStringAsFixed(format.decimals);
  final [whole, ...rest] = fixed.split('.');
  final integer = whole.padLeft(format.minDigits, '0');
  final fraction = rest.isEmpty ? '' : rest.first;
  final negative = value < 0 && RegExp('[1-9]').hasMatch(fixed);
  return [
    if (negative) const _CellSpec('minus', -3e6, text: '-'),
    if (format.prefix.isNotEmpty) _CellSpec('prefix', -2e6, text: format.prefix),
    for (var i = 0; i < integer.length; i++) ...[
      // Place 0 is the ones digit.
      _CellSpec(
        'i${integer.length - 1 - i}',
        -2.0 * (integer.length - 1 - i),
        digit: int.parse(integer[i]),
      ),
      if (format.grouping && (integer.length - 1 - i) % 3 == 0 && i < integer.length - 1)
        _CellSpec(
          'g${integer.length - 1 - i}',
          1 - 2.0 * (integer.length - 1 - i),
          text: format.groupSeparator,
        ),
    ],
    if (fraction.isNotEmpty) ...[
      _CellSpec('point', 0.5, text: format.decimalSeparator),
      for (var f = 0; f < fraction.length; f++)
        _CellSpec('f$f', 1.0 + f, digit: int.parse(fraction[f])),
    ],
    if (format.suffix.isNotEmpty) _CellSpec('suffix', 3e6, text: format.suffix),
  ];
}

/// Live state of one digit or symbol.
class _Cell {
  _Cell(this.spec, {required double position, required double presence})
    : _roll = _Motion.at(position),
      _presence = _Motion.at(presence);

  _CellSpec spec;
  _Motion _roll;
  _Motion _presence;

  /// Set once the cell has left the number; it is dropped when hidden.
  bool leaving = false;

  /// Where the roll is heading, in numeral steps (unbounded: 12 shows 2).
  double get target => _roll.target;

  double position(double t) => _roll.value(t);
  double velocity(double t) => _roll.velocity(t);
  double presence(double t) => _presence.value(t).clamp(0.0, 1.0);

  void rollTo(double target, double t, SpringDescription spring, double delay) =>
      _roll = _roll.retarget(target, t, spring, delay);

  void showTo(double target, double t, SpringDescription spring, double delay) =>
      _presence = _presence.retarget(target, t, spring, delay);

  void snap() {
    _roll = _Motion.at(_roll.target);
    _presence = _Motion.at(_presence.target);
  }

  bool isDone(double t) => _roll.isDone(t) && _presence.isDone(t);
}

/// A value at rest or moving on a spring that starts at [start] seconds.
@immutable
class _Motion {
  const _Motion(this.target, this._from, this.start, this._simulation);

  const _Motion.at(double value) : this(value, value, 0, null);

  final double target;
  final double _from;
  final double start;
  final SpringSimulation? _simulation;

  double value(double t) {
    final sim = _simulation;
    if (sim == null) return target;
    if (t <= start) return _from;
    return sim.isDone(t - start) ? target : sim.x(t - start);
  }

  double velocity(double t) {
    final sim = _simulation;
    if (sim == null || t <= start || sim.isDone(t - start)) return 0;
    return sim.dx(t - start);
  }

  bool isDone(double t) => _simulation == null || (t > start && _simulation.isDone(t - start));

  /// Heads for [to], keeping the current position and speed. A motion at
  /// rest waits [delay] seconds first; one already moving turns at once.
  _Motion retarget(double to, double t, SpringDescription spring, double delay) {
    final from = value(t);
    final speed = velocity(t);
    if (from == to && speed == 0) return _Motion.at(to);
    final begin = speed == 0 ? t + delay : t;
    final sim = SpringSimulation(
      spring,
      from,
      to,
      speed,
      tolerance: const Tolerance(distance: 0.002, velocity: 0.02),
    );
    return _Motion(to, from, begin, sim);
  }
}

class _DigitRollState extends State<DigitRoll> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);

  /// Seconds on the roll clock; it only advances while something moves.
  double _now = 0;
  double _tickBase = 0;

  final Map<String, _Cell> _cells = {};
  List<_Cell> _ordered = [];
  num _shown = 0;

  _Metrics? _metrics;
  bool _introDone = false;

  /// Presence uses a stiffer, non-bouncy spring so digits never overshoot
  /// their width.
  static const SpringDescription _presenceSpring = SpringDescription(
    mass: 1,
    stiffness: 260,
    damping: 32,
  );

  double get _staggerSeconds => widget.stagger.inMicroseconds / 1e6;

  @override
  void initState() {
    super.initState();
    _shown = widget.value;
    for (final spec in _cellsFor(widget.value, widget.format)) {
      _cells[spec.key] = _Cell(spec, position: (spec.digit ?? 0).toDouble(), presence: 1);
    }
    _reorder();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _metrics = null;
    final firstBuild = !_introDone;
    _introDone = true;
    if (firstBuild && widget.rollOnMount && !_reduceMotion) {
      // Spin each digit one full turn, ones place first.
      final turn = widget.direction == DigitRollDirection.down ? -10.0 : 10.0;
      final digits = _ordered.where((c) => c.spec.digit != null).toList().reversed.toList();
      for (final (i, cell) in digits.indexed) {
        cell.rollTo(cell.target + turn, _now, widget.spring, i * _staggerSeconds);
      }
      _start();
    }
    if (_reduceMotion) _snapAll();
  }

  @override
  void didUpdateWidget(DigitRoll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style != widget.style || oldWidget.tabularFigures != widget.tabularFigures) {
      _metrics = null;
    }
    if (oldWidget.value != widget.value || oldWidget.format != widget.format) {
      _retarget();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _retarget() {
    final previous = _shown;
    _shown = widget.value;
    final trend = switch (widget.direction) {
      DigitRollDirection.auto when _shown.abs() > previous.abs() => DigitRollDirection.up,
      DigitRollDirection.auto when _shown.abs() < previous.abs() => DigitRollDirection.down,
      DigitRollDirection.auto => DigitRollDirection.shortest,
      final other => other,
    };

    final specs = _cellsFor(_shown, widget.format);
    final keep = {for (final s in specs) s.key};
    for (final spec in specs) {
      _cells.putIfAbsent(spec.key, () => _Cell(spec, position: 0, presence: 0))
        ..spec = spec
        ..leaving = false;
    }
    for (final cell in _cells.values) {
      if (!keep.contains(cell.spec.key)) cell.leaving = true;
    }

    // Each digit's new roll target; digits that leave roll back to zero.
    final moves = <(_Cell, double)>[
      for (final cell in _cells.values)
        if (cell.spec.digit case final digit?)
          (cell, cell.target + _steps(cell.target, cell.leaving ? 0 : digit, trend)),
    ]..sort((a, b) => b.$1.spec.rank.compareTo(a.$1.spec.rank));

    // Ripple from the right: only digits that actually change take a turn
    // in the stagger.
    final delays = <String, double>{};
    var turn = 0;
    for (final (cell, to) in moves) {
      final changes = to != cell.target || cell.presence(_now) < 1 || cell.leaving;
      if (!changes) continue;
      final delay = turn++ * _staggerSeconds;
      delays[cell.spec.key] = delay;
      cell.rollTo(to, _now, widget.spring, delay);
    }
    for (final cell in _cells.values) {
      final key = cell.spec.key;
      // A group separator comes and goes with the digit to its left.
      final owner = key.startsWith('g') ? 'i${key.substring(1)}' : key;
      cell.showTo(cell.leaving ? 0 : 1, _now, _presenceSpring, delays[owner] ?? 0);
    }

    _reorder();
    if (_reduceMotion) {
      _snapAll();
    } else {
      _start();
    }
  }

  /// Signed numeral steps from [from] to [digit], by [trend].
  static double _steps(double from, int digit, DigitRollDirection trend) {
    final up = (digit - from.round()) % 10;
    return switch (trend) {
      DigitRollDirection.up => up.toDouble(),
      DigitRollDirection.down => up == 0 ? 0 : up - 10.0,
      _ => up > 5 ? up - 10.0 : up.toDouble(),
    };
  }

  void _snapAll() {
    _ticker.stop();
    for (final cell in _cells.values) {
      cell.snap();
    }
    _cells.removeWhere((_, c) => c.leaving);
    _reorder();
  }

  void _reorder() {
    _ordered = _cells.values.toList()..sort((a, b) => a.spec.rank.compareTo(b.spec.rank));
  }

  void _start() {
    if (_ticker.isActive) return;
    _tickBase = _now;
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    setState(() {
      _now = _tickBase + elapsed.inMicroseconds / 1e6;
      final gone = _cells.values.where((c) => c.leaving && c.isDone(_now)).toList();
      if (gone.isNotEmpty) {
        for (final cell in gone) {
          _cells.remove(cell.spec.key);
        }
        _reorder();
      }
      if (_cells.values.every((c) => c.isDone(_now))) _ticker.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(widget.style);
    final style = base.copyWith(
      height: 1,
      fontFeatures: [
        ...?base.fontFeatures,
        if (widget.tabularFigures) const ui.FontFeature.tabularFigures(),
      ],
    );
    final scaler = MediaQuery.textScalerOf(context);
    final metrics = _metrics ??= _Metrics.measure(style, scaler, widget.format);

    return Semantics(
      label: widget.format.apply(widget.value),
      container: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final cell in _ordered)
              _CellView(
                key: ValueKey(cell.spec.key),
                spec: cell.spec,
                position: cell.position(_now),
                velocity: cell.velocity(_now),
                presence: cell.presence(_now),
                style: style,
                metrics: metrics,
                tabular: widget.tabularFigures,
                motionBlur: widget.motionBlur,
                edgeFade: widget.edgeFade,
                spacing: widget.spacing,
                decoration: widget.digitDecoration,
                padding: widget.digitPadding,
              ),
          ],
        ),
      ),
    );
  }
}

/// Measured sizes of the numerals and symbols in one text style.
@immutable
class _Metrics {
  const _Metrics(this.numeralWidths, this.symbolWidths, this.height);

  factory _Metrics.measure(TextStyle style, TextScaler scaler, DigitRollFormat format) {
    double width(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }

    final symbols = {
      for (final s in [
        format.prefix,
        '-',
        format.groupSeparator,
        format.decimalSeparator,
        format.suffix,
      ])
        if (s.isNotEmpty) s: width(s),
    };
    return _Metrics(
      [for (var d = 0; d < 10; d++) width('$d')],
      symbols,
      scaler.scale(style.fontSize ?? 14),
    );
  }

  final List<double> numeralWidths;
  final Map<String, double> symbolWidths;

  /// Line height of one numeral (the style's height is forced to 1).
  final double height;

  double get widest => numeralWidths.reduce(math.max);

  /// Width at a fractional roll [position], easing between numerals.
  double widthAt(double position) {
    final low = position.floor();
    final t = position - low;
    final a = numeralWidths[low % 10];
    final b = numeralWidths[(low + 1) % 10];
    return a + (b - a) * t;
  }
}

/// One digit window or symbol, sized by its presence.
class _CellView extends StatelessWidget {
  const _CellView({
    super.key,
    required this.spec,
    required this.position,
    required this.velocity,
    required this.presence,
    required this.style,
    required this.metrics,
    required this.tabular,
    required this.motionBlur,
    required this.edgeFade,
    required this.spacing,
    required this.decoration,
    required this.padding,
  });

  final _CellSpec spec;
  final double position;
  final double velocity;
  final double presence;
  final TextStyle style;
  final _Metrics metrics;
  final bool tabular;
  final bool motionBlur;
  final double edgeFade;
  final double spacing;
  final Decoration? decoration;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDigit = spec.digit != null;
    final width = isDigit
        ? (tabular ? metrics.widest : metrics.widthAt(position))
        : metrics.symbolWidths[spec.text] ?? 0;
    Widget child = isDigit
        ? _DigitWindow(
            position: position,
            velocity: velocity,
            style: style,
            width: width,
            height: metrics.height,
            padding: padding,
            // Bare digits fade above and below their line box; tiled ones
            // fade inside the tile.
            bleed: decoration == null ? edgeFade * metrics.height : 0,
            motionBlur: motionBlur,
            edgeFade: edgeFade,
          )
        : SizedBox(
            width: width,
            height: metrics.height,
            child: Center(child: Text(spec.text, style: style, maxLines: 1, softWrap: false)),
          );
    if (isDigit && decoration != null) {
      child = DecoratedBox(decoration: decoration!, child: child);
    } else if (!isDigit && padding.vertical > 0) {
      // Keep symbols vertically centred next to padded digits.
      child = Padding(
        padding: EdgeInsets.symmetric(vertical: padding.vertical / 2),
        child: child,
      );
    }
    child = Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing / 2),
      child: child,
    );
    if (presence >= 1) return child;
    return ClipRect(
      child: Align(
        widthFactor: presence,
        child: Opacity(opacity: presence, child: child),
      ),
    );
  }
}

/// A clipped window showing the numerals around a fractional [position].
class _DigitWindow extends StatelessWidget {
  const _DigitWindow({
    required this.position,
    required this.velocity,
    required this.style,
    required this.width,
    required this.height,
    required this.padding,
    required this.bleed,
    required this.motionBlur,
    required this.edgeFade,
  });

  final double position;

  /// Numeral steps per second.
  final double velocity;
  final TextStyle style;
  final double width;
  final double height;

  /// Room around the numeral inside the window; numerals roll through it.
  final EdgeInsets padding;

  /// How far the window reaches above and below the digit's box, so
  /// numerals can fade out without clipping the resting one.
  final double bleed;
  final bool motionBlur;
  final double edgeFade;

  @override
  Widget build(BuildContext context) {
    final box = height + padding.vertical;
    // Distance between neighbouring numerals: one full window, so at rest
    // only the current numeral is inside it.
    final pitch = box + 2 * bleed;
    final low = position.floor();
    final t = position - low;
    // Higher positions sit lower, so a growing number rolls upward.
    Widget strip = Stack(
      clipBehavior: Clip.none,
      children: [
        for (final (n, dy) in [(low, -t), if (t > 0.0005) (low + 1, 1 - t)])
          Positioned(
            left: -height,
            right: -height,
            top: dy * pitch,
            height: pitch,
            child: Padding(
              padding: padding + EdgeInsets.symmetric(vertical: bleed),
              child: Center(child: Text('${n % 10}', style: style, maxLines: 1, softWrap: false)),
            ),
          ),
      ],
    );
    final sigma = motionBlur ? ((velocity.abs() - 4) * 0.012).clamp(0.0, 0.1) * height : 0.0;
    if (sigma > 0.3) {
      strip = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 0, sigmaY: sigma, tileMode: TileMode.decal),
        child: strip,
      );
    }
    Widget window = ClipRect(child: strip);
    if (edgeFade > 0 && t > 0.0005) {
      final f = bleed > 0 ? bleed / pitch : edgeFade;
      window = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Eased falloff, so blurred numerals melt away instead of ending
          // on a hard edge.
          stops: [0, f * 0.3, f * 0.6, f, 1 - f, 1 - f * 0.6, 1 - f * 0.3, 1],
          colors: const [
            Color(0x00000000),
            Color(0x26000000),
            Color(0x99000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0x99000000),
            Color(0x26000000),
            Color(0x00000000),
          ],
        ).createShader(rect),
        child: window,
      );
    }
    return SizedBox(
      width: width + padding.horizontal,
      height: box,
      child: Stack(
        clipBehavior: Clip.none,
        children: [Positioned(left: 0, right: 0, top: -bleed, bottom: -bleed, child: window)],
      ),
    );
  }
}
