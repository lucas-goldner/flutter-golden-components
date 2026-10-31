import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

/// Playground for [StepFlow].
class StepFlowDemo extends StatefulWidget {
  const StepFlowDemo({super.key});

  @override
  State<StepFlowDemo> createState() => _StepFlowDemoState();
}

class _StepFlowDemoState extends State<StepFlowDemo> {
  late StepFlowIndicator _indicator;
  late Axis _axis;
  late StepFlowTransition _transition;
  late bool _linear;
  late bool _requirePlan;
  late double _duration;

  /// The plan picked on step 2, if any.
  int? _plan;

  /// Bumped to start the flow over.
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _indicator = StepFlowIndicator.bars;
    _axis = Axis.horizontal;
    _transition = StepFlowTransition.slide;
    _linear = false;
    _requirePlan = true;
    _duration = 420;
    _plan = null;
  }

  void _set(VoidCallback fn) => setState(fn);

  void _restart() => setState(() {
    _plan = null;
    _run++;
  });

  @override
  Widget build(BuildContext context) {
    return Playground(
      preview: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _Card(
              width: _axis == Axis.vertical ? 620 : 440,
              child: _Flow(
                key: ValueKey(_run),
                indicator: _indicator,
                axis: _axis,
                transition: _transition,
                linear: _linear,
                requirePlan: _requirePlan,
                duration: Duration(milliseconds: _duration.round()),
                plan: _plan,
                onPlan: (v) => setState(() => _plan = v),
                onRestart: _restart,
              ),
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
          title: 'Indicator',
          children: [
            SegmentedControl<StepFlowIndicator>(
              label: 'Style',
              value: _indicator,
              options: const {
                StepFlowIndicator.numbers: 'Numbers',
                StepFlowIndicator.dots: 'Dots',
                StepFlowIndicator.bars: 'Bars',
              },
              onChanged: (v) => _set(() => _indicator = v),
            ),
            SegmentedControl<Axis>(
              label: 'Layout',
              value: _axis,
              options: const {Axis.horizontal: 'Top', Axis.vertical: 'Side rail'},
              onChanged: (v) => _set(() => _axis = v),
            ),
            ToggleControl(
              label: 'Linear (only revisit reached steps)',
              value: _linear,
              onChanged: (v) => _set(() => _linear = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Motion',
          children: [
            SegmentedControl<StepFlowTransition>(
              label: 'Transition',
              value: _transition,
              options: const {
                StepFlowTransition.slide: 'Slide',
                StepFlowTransition.fade: 'Fade',
                StepFlowTransition.none: 'None',
              },
              onChanged: (v) => _set(() => _transition = v),
            ),
            SliderControl(
              label: 'Duration',
              value: _duration,
              min: 150,
              max: 1200,
              step: 10,
              format: (v) => '${v.round()} ms',
              onChanged: (v) => _set(() => _duration = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Flow',
          children: [
            ToggleControl(
              label: 'Require a plan to continue',
              value: _requirePlan,
              onChanged: (v) => _set(() => _requirePlan = v),
            ),
            GalleryButton(label: 'Start over', onTap: _restart),
          ],
        ),
      ],
    );
  }
}

/// The onboarding flow shown in the playground.
class _Flow extends StatefulWidget {
  const _Flow({
    super.key,
    required this.indicator,
    required this.axis,
    required this.transition,
    required this.linear,
    required this.requirePlan,
    required this.duration,
    required this.plan,
    required this.onPlan,
    required this.onRestart,
  });

  final StepFlowIndicator indicator;
  final Axis axis;
  final StepFlowTransition transition;
  final bool linear;
  final bool requirePlan;
  final Duration duration;
  final int? plan;
  final ValueChanged<int> onPlan;
  final VoidCallback onRestart;

  @override
  State<_Flow> createState() => _FlowState();
}

class _FlowState extends State<_Flow> {
  int _step = 0;

  static const List<(String, String, String)> _plans = [
    ('Starter', 'For personal projects', r'$0'),
    ('Team', 'Up to 10 seats', r'$24'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final plan = widget.plan;
    return StepFlow(
      indicator: widget.indicator,
      axis: widget.axis,
      transition: widget.transition,
      linear: widget.linear,
      duration: widget.duration,
      canContinue: !(widget.requirePlan && _step == 1 && plan == null),
      onStepChanged: (v) => setState(() => _step = v),
      completed: _Completed(onRestart: widget.onRestart),
      steps: [
        const FlowStep(
          title: 'Account',
          subtitle: 'Who you are',
          child: _StepText(
            title: 'Create your account',
            body: 'It takes less than a minute. You can change everything later.',
          ),
        ),
        FlowStep(
          title: 'Plan',
          subtitle: 'Pick a tier',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _StepText(title: 'Choose a plan'),
              for (final (i, (name, detail, price)) in _plans.indexed)
                _PlanOption(
                  name: name,
                  detail: detail,
                  price: price,
                  selected: plan == i,
                  onTap: () => widget.onPlan(i),
                ),
            ],
          ),
        ),
        FlowStep(
          title: 'Invite',
          subtitle: 'Bring your team',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StepText(
                title: 'Invite teammates',
                body: 'Share the link below with anyone who should join.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: p.text.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'studio.app/join/7f3k',
                  style: TextStyle(fontFamily: 'GalleryMono', fontSize: 13, color: p.text),
                ),
              ),
            ],
          ),
        ),
        FlowStep(
          title: 'Review',
          subtitle: 'All set?',
          child: _StepText(
            title: 'All set?',
            body:
                'Plan: ${plan == null ? 'not chosen' : _plans[plan].$1}. '
                'You can invite more people any time.',
          ),
        ),
      ],
    );
  }
}

/// A rounded card on the gallery surface.
class _Card extends StatelessWidget {
  const _Card({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: width,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(26),
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
      child: DefaultTextStyle.merge(
        style: TextStyle(color: p.text),
        child: child,
      ),
    );
  }
}

/// A step's heading and optional body text.
class _StepText extends StatelessWidget {
  const _StepText({required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GalleryText.heading(p).copyWith(fontSize: 18, letterSpacing: -0.3)),
        if (body case final body?)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(body, style: GalleryText.body(p)),
          ),
      ],
    );
  }
}

/// A selectable plan row.
class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.name,
    required this.detail,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String detail;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Semantics(
        selected: selected,
        child: Pressable(
          onTap: onTap,
          builder: (context, hover, pressed) => AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: p.text.withValues(alpha: selected ? 0.08 : (hover ? 0.05 : 0.03)),
              border: Border.all(color: p.text.withValues(alpha: selected ? 0.4 : 0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GalleryText.label(p).copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(detail, style: GalleryText.body(p).copyWith(fontSize: 12.5)),
                    ],
                  ),
                ),
                Text(price, style: GalleryText.label(p).copyWith(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown once the flow is complete.
class _Completed extends StatelessWidget {
  const _Completed({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(shape: BoxShape.circle, color: p.text),
          child: CustomPaint(painter: _TickPainter(p.surface)),
        ),
        const SizedBox(height: 14),
        Text('Workspace ready', style: GalleryText.heading(p).copyWith(fontSize: 18)),
        const SizedBox(height: 4),
        Text('Welcome in.', style: GalleryText.body(p)),
        const SizedBox(height: 16),
        GalleryButton(label: 'Start over', onTap: onRestart),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _TickPainter extends CustomPainter {
  const _TickPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.3, w * 0.52)
        ..lineTo(w * 0.45, w * 0.66)
        ..lineTo(w * 0.72, w * 0.36),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.color != color;
}
