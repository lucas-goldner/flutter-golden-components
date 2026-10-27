import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

enum _Scene { countdown, pricing, basic }

/// The roll settings every scene shares.
@immutable
class _Roll {
  const _Roll({
    required this.direction,
    required this.spring,
    required this.stagger,
    required this.motionBlur,
    required this.edgeFade,
    required this.tabular,
  });

  final DigitRollDirection? direction;
  final SpringDescription spring;
  final Duration stagger;
  final bool motionBlur;
  final double edgeFade;
  final bool tabular;
}

/// Playground for [DigitRoll].
class DigitRollDemo extends StatefulWidget {
  const DigitRollDemo({super.key});

  @override
  State<DigitRollDemo> createState() => _DigitRollDemoState();
}

class _DigitRollDemoState extends State<DigitRollDemo> {
  late _Scene _scene;
  late DigitRollDirection? _direction;
  late double _stiffness;
  late double _damping;
  late double _stagger;
  late bool _motionBlur;
  late double _edgeFade;
  late bool _tabular;

  /// Bumped to rebuild the scene from scratch (and replay the intro).
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _scene = _Scene.countdown;
    _direction = null;
    _stiffness = 100;
    _damping = 16;
    _stagger = 40;
    _motionBlur = true;
    _edgeFade = 0.3;
    _tabular = true;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final roll = _Roll(
      direction: _direction,
      spring: SpringDescription(mass: 1, stiffness: _stiffness, damping: _damping),
      stagger: Duration(milliseconds: _stagger.round()),
      motionBlur: _motionBlur,
      edgeFade: _edgeFade,
      tabular: _tabular,
    );
    return Playground(
      preview: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: KeyedSubtree(
              key: ValueKey((_scene, _run)),
              child: switch (_scene) {
                _Scene.countdown => _Countdown(roll: roll),
                _Scene.pricing => _Pricing(roll: roll),
                _Scene.basic => _Basic(roll: roll),
              },
            ),
          ),
        ),
      ),
      onReset: () => _set(() {
        _reset();
        _run++;
      }),
      controls: [
        ControlSection(
          title: 'Scene',
          children: [
            SegmentedControl<_Scene>(
              label: 'Example',
              value: _scene,
              options: const {
                _Scene.countdown: 'Countdown',
                _Scene.pricing: 'Pricing',
                _Scene.basic: 'Basic',
              },
              onChanged: (v) => _set(() => _scene = v),
            ),
            GalleryButton(label: 'Replay intro', onTap: () => _set(() => _run++)),
          ],
        ),
        ControlSection(
          title: 'Roll',
          children: [
            SegmentedControl<DigitRollDirection?>(
              label: 'Direction',
              value: _direction,
              options: const {
                null: 'Scene',
                DigitRollDirection.auto: 'Auto',
                DigitRollDirection.up: 'Up',
                DigitRollDirection.down: 'Down',
                DigitRollDirection.shortest: 'Short',
              },
              onChanged: (v) => _set(() => _direction = v),
            ),
            SliderControl(
              label: 'Stagger',
              value: _stagger,
              min: 0,
              max: 200,
              step: 5,
              format: (v) => '${v.round()} ms',
              onChanged: (v) => _set(() => _stagger = v),
            ),
            ToggleControl(
              label: 'Motion blur',
              value: _motionBlur,
              onChanged: (v) => _set(() => _motionBlur = v),
            ),
            SliderControl(
              label: 'Edge fade',
              value: _edgeFade,
              min: 0,
              max: 0.5,
              step: 0.05,
              onChanged: (v) => _set(() => _edgeFade = v),
            ),
            ToggleControl(
              label: 'Tabular figures',
              value: _tabular,
              onChanged: (v) => _set(() => _tabular = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Spring',
          children: [
            SliderControl(
              label: 'Stiffness',
              value: _stiffness,
              min: 20,
              max: 600,
              step: 10,
              onChanged: (v) => _set(() => _stiffness = v),
            ),
            SliderControl(
              label: 'Damping',
              value: _damping,
              min: 4,
              max: 60,
              step: 1,
              onChanged: (v) => _set(() => _damping = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// A rounded card on the gallery surface.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(24), this.width});

  final Widget child;
  final EdgeInsets padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: p.isDark ? 0.45 : 0.08),
            blurRadius: 40,
            spreadRadius: -12,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A small square button with a glyph.
class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.glyph, required this.label, required this.onTap});

  final String glyph;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap ?? () {},
        builder: (context, hover, pressed) => AnimatedScale(
          scale: pressed && enabled ? 0.92 : 1,
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hover && enabled ? p.border : p.surfaceAlt,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: p.border),
            ),
            child: Text(
              glyph,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1,
                color: enabled ? p.text : p.muted.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Counts down to a launch, one tile per digit.
class _Countdown extends StatefulWidget {
  const _Countdown({required this.roll});

  final _Roll roll;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> with SingleTickerProviderStateMixin {
  static const int _start = ((2 * 24 + 14) * 60 + 37) * 60 + 9;

  late final Ticker _ticker = createTicker(_tick);
  int _left = _start;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The clock is an endless animation: hold still when motion is reduced.
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _ticker.isActive) _ticker.stop();
    if (!still && !_ticker.isActive) _ticker.start();
  }

  void _tick(Duration elapsed) {
    final left = math.max(0, _start - elapsed.inSeconds);
    if (left != _left) setState(() => _left = left);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final parts = [
      ('Days', _left ~/ 86400),
      ('Hours', _left ~/ 3600 % 24),
      ('Minutes', _left ~/ 60 % 60),
      ('Seconds', _left % 60),
    ];
    return _Card(
      padding: const EdgeInsets.fromLTRB(32, 26, 32, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Public beta opens in', style: GalleryText.body(p)),
          const SizedBox(height: 22),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, (name, value)) in parts.indexed) ...[
                if (i > 0) const _Colon(),
                _CountdownUnit(name: name, value: value, roll: widget.roll),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Colon extends StatelessWidget {
  const _Colon();

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return SizedBox(
      width: 30,
      height: 76,
      child: Center(
        child: Text(
          ':',
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w500, color: p.muted),
        ),
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  const _CountdownUnit({required this.name, required this.value, required this.roll});

  final String name;
  final int value;
  final _Roll roll;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Column(
      children: [
        DigitRoll(
          value: value,
          format: const DigitRollFormat(minDigits: 2),
          direction: roll.direction ?? DigitRollDirection.down,
          spring: roll.spring,
          stagger: roll.stagger,
          motionBlur: roll.motionBlur,
          edgeFade: roll.edgeFade,
          tabularFigures: roll.tabular,
          spacing: 6,
          style: TextStyle(fontSize: 52, fontWeight: FontWeight.w600, color: p.text),
          digitPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          digitDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [p.surfaceAlt, p.surface],
            ),
            border: Border.all(color: p.border),
          ),
        ),
        const SizedBox(height: 10),
        Text(name, style: GalleryText.value(p)),
      ],
    );
  }
}

/// A pricing card whose total rolls as seats and billing change.
class _Pricing extends StatefulWidget {
  const _Pricing({required this.roll});

  final _Roll roll;

  @override
  State<_Pricing> createState() => _PricingState();
}

class _PricingState extends State<_Pricing> {
  bool _yearly = false;
  int _seats = 5;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final roll = widget.roll;
    final perSeat = _yearly ? 19 : 24;
    final total = _seats * perSeat * (_yearly ? 12 : 1);
    return _Card(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Team', style: GalleryText.heading(p).copyWith(fontSize: 17)),
              const Spacer(),
              _Billing(yearly: _yearly, onChanged: (v) => setState(() => _yearly = v)),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DigitRoll(
                value: total,
                format: const DigitRollFormat(prefix: r'$'),
                direction: roll.direction ?? DigitRollDirection.auto,
                spring: roll.spring,
                stagger: roll.stagger,
                motionBlur: roll.motionBlur,
                edgeFade: roll.edgeFade,
                tabularFigures: roll.tabular,
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  color: p.text,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(_yearly ? '/ year' : '/ month', style: GalleryText.body(p)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              DigitRoll(
                value: perSeat,
                format: const DigitRollFormat(prefix: r'$'),
                rollOnMount: false,
                spring: roll.spring,
                motionBlur: roll.motionBlur,
                edgeFade: roll.edgeFade,
                style: TextStyle(fontSize: 14, color: p.muted),
              ),
              Text(
                ' per seat, billed ${_yearly ? 'yearly' : 'monthly'}',
                // Line height 1, like the rolling price next to it.
                style: GalleryText.body(p).copyWith(height: 1),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: p.border),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('Seats', style: GalleryText.label(p).copyWith(fontSize: 15)),
              const Spacer(),
              _RoundButton(
                glyph: '−',
                label: 'Remove a seat',
                onTap: _seats <= 1 ? null : () => setState(() => _seats--),
              ),
              SizedBox(
                width: 52,
                child: Center(
                  child: DigitRoll(
                    value: _seats,
                    rollOnMount: false,
                    spring: roll.spring,
                    motionBlur: roll.motionBlur,
                    edgeFade: roll.edgeFade,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.text),
                  ),
                ),
              ),
              _RoundButton(
                glyph: '+',
                label: 'Add a seat',
                onTap: _seats >= 99 ? null : () => setState(() => _seats++),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Monthly / yearly switch for the pricing card.
class _Billing extends StatelessWidget {
  const _Billing({required this.yearly, required this.onChanged});

  final bool yearly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, value) in const [('Monthly', false), ('Yearly', true)])
            Pressable(
              onTap: () => onChanged(value),
              builder: (context, hover, pressed) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == yearly ? p.surface : null,
                  borderRadius: BorderRadius.circular(9),
                  border: value == yearly ? Border.all(color: p.border) : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: value == yearly ? p.text : p.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A big number with buttons to nudge or scramble it.
class _Basic extends StatefulWidget {
  const _Basic({required this.roll});

  final _Roll roll;

  @override
  State<_Basic> createState() => _BasicState();
}

class _BasicState extends State<_Basic> {
  final math.Random _random = math.Random(7);
  int _value = 1284;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final roll = widget.roll;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DigitRoll(
          value: _value,
          direction: roll.direction ?? DigitRollDirection.auto,
          spring: roll.spring,
          stagger: roll.stagger,
          motionBlur: roll.motionBlur,
          edgeFade: roll.edgeFade,
          tabularFigures: roll.tabular,
          style: TextStyle(
            fontSize: 112,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
            color: p.text,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            _RoundButton(
              glyph: '−',
              label: 'Decrease',
              onTap: _value <= 0 ? null : () => setState(() => _value--),
            ),
            _RoundButton(glyph: '+', label: 'Increase', onTap: () => setState(() => _value++)),
            GalleryButton(
              label: 'Random',
              onTap: () => setState(() => _value = _random.nextInt(99999)),
            ),
          ],
        ),
      ],
    );
  }
}
