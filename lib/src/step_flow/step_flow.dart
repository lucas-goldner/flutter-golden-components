import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// One step of a [StepFlow].
@immutable
class FlowStep {
  /// Creates a step.
  const FlowStep({required this.child, this.title, this.subtitle, this.icon});

  /// The step's content.
  final Widget child;

  /// Short name, shown in the vertical rail and read by screen readers.
  final String? title;

  /// A line under [title] in the vertical rail.
  final String? subtitle;

  /// Shown in the step's badge instead of its number (numbers indicator).
  final Widget? icon;
}

/// How a [StepFlow] marks its progress.
enum StepFlowIndicator {
  /// Numbered badges joined by lines, with a ring gliding to the current one.
  numbers,

  /// Small dots; the current one stretches into a pill.
  dots,

  /// One bar per step, filled up to the current one.
  bars,
}

/// How a [StepFlow] swaps one step's content for the next.
enum StepFlowTransition {
  /// The new step slides in from the side it lies on.
  slide,

  /// The new step fades in with a slight drift.
  fade,

  /// No animation.
  none,
}

/// A multi-step flow: a step indicator, the current step's content and a
/// Back / Continue footer.
///
/// Moving between steps slides (or fades) the content in the direction of
/// travel while its height eases to the new step. Finished steps get a
/// check that draws itself in, and in the [StepFlowIndicator.numbers] style
/// a ring glides to the current step. Indicators can be tapped to jump
/// between steps; with [linear] only steps already reached can be. After
/// the last step [completed] is shown and the footer folds away.
///
/// Laid out [Axis.horizontal] (indicator on top) or [Axis.vertical] (a rail
/// of titled steps beside the content). Colors come from the ambient
/// [DefaultTextStyle] unless [accentColor] is given. When the platform asks
/// to reduce motion ([MediaQueryData.disableAnimations]) everything
/// switches instantly.
class StepFlow extends StatefulWidget {
  /// Creates a step flow.
  const StepFlow({
    super.key,
    required this.steps,
    this.initialStep = 0,
    this.onStepChanged,
    this.onCompleted,
    this.completed,
    this.indicator = StepFlowIndicator.numbers,
    this.axis = Axis.horizontal,
    this.transition = StepFlowTransition.slide,
    this.linear = false,
    this.tappableIndicator = true,
    this.canContinue = true,
    this.showFooter = true,
    this.backLabel = 'Back',
    this.nextLabel = 'Continue',
    this.finishLabel = 'Complete',
    this.accentColor,
    this.duration = const Duration(milliseconds: 420),
    this.railWidth = 200,
  }) : assert(initialStep >= 0);

  /// The steps, in order.
  final List<FlowStep> steps;

  /// The step shown first (0-based). Pass `steps.length` to start completed;
  /// larger values are clamped to that.
  final int initialStep;

  /// Called with the new step index whenever the step changes.
  final ValueChanged<int>? onStepChanged;

  /// Called when the last step is completed.
  final VoidCallback? onCompleted;

  /// Shown after the last step is completed.
  final Widget? completed;

  /// How progress is marked.
  final StepFlowIndicator indicator;

  /// [Axis.horizontal] puts the indicator on top; [Axis.vertical] puts a
  /// rail of steps beside the content.
  final Axis axis;

  /// How content changes between steps.
  final StepFlowTransition transition;

  /// Whether only steps already reached can be jumped to from the
  /// indicator.
  final bool linear;

  /// Whether the indicator can be tapped to change step.
  final bool tappableIndicator;

  /// Whether the Continue / Complete button is enabled, for example once
  /// the current step's form is valid.
  final bool canContinue;

  /// Whether to show the Back / Continue footer.
  final bool showFooter;

  /// Label of the back button.
  final String backLabel;

  /// Label of the continue button.
  final String nextLabel;

  /// Label of the continue button on the last step.
  final String finishLabel;

  /// Color of finished and current steps and the continue button.
  /// Defaults to the ambient text color.
  final Color? accentColor;

  /// Length of the step change animation.
  final Duration duration;

  /// Width of the rail in [Axis.vertical] layouts.
  final double railWidth;

  @override
  State<StepFlow> createState() => _StepFlowState();
}

class _StepFlowState extends State<StepFlow> with SingleTickerProviderStateMixin {
  late int _step = math.min(widget.initialStep, widget.steps.length);
  late int _reached = _step;

  /// The step being left, while the swap animation runs.
  int? _previous;

  late final AnimationController _swap = AnimationController(vsync: this, value: 1);

  bool get _done => _step >= widget.steps.length;
  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  Duration get _duration => _reduceMotion ? Duration.zero : widget.duration;

  @override
  void dispose() {
    _swap.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    if (step == _step || step < 0 || step > widget.steps.length) return;
    setState(() {
      _previous = _step;
      _step = step;
      _reached = math.max(_reached, step);
    });
    if (_duration == Duration.zero || widget.transition == StepFlowTransition.none) {
      _swap.value = 1;
      _previous = null;
    } else {
      _swap
        ..duration = _duration
        ..forward(from: 0).whenCompleteOrCancel(() {
          if (mounted) setState(() => _previous = null);
        });
    }
    widget.onStepChanged?.call(step);
    if (step == widget.steps.length) widget.onCompleted?.call();
  }

  bool _canJumpTo(int step) =>
      widget.tappableIndicator && !_done && step != _step && (!widget.linear || step <= _reached);

  @override
  Widget build(BuildContext context) {
    final ink = DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    final colors = _FlowColors(ink: ink, accent: widget.accentColor ?? ink);
    final indicator = _Indicator(
      style: widget.indicator,
      axis: widget.axis,
      steps: widget.steps,
      current: _step,
      colors: colors,
      duration: _duration,
      canJumpTo: _canJumpTo,
      onTap: _goTo,
    );
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Content(
          animation: _swap,
          transition: widget.transition,
          duration: _duration,
          forward: _previous == null || _previous! < _step,
          incoming: KeyedSubtree(
            key: ValueKey(_step),
            child: _done ? widget.completed ?? const SizedBox.shrink() : widget.steps[_step].child,
          ),
          outgoing: switch (_previous) {
            null => null,
            final p when p >= widget.steps.length => KeyedSubtree(
              key: ValueKey(p),
              child: widget.completed ?? const SizedBox.shrink(),
            ),
            final p => KeyedSubtree(key: ValueKey(p), child: widget.steps[p].child),
          },
        ),
        if (widget.showFooter)
          _Resize(
            duration: _duration,
            child: _done
                ? const SizedBox(width: double.infinity)
                : _Footer(
                    colors: colors,
                    duration: _duration,
                    showBack: _step > 0,
                    backLabel: widget.backLabel,
                    nextLabel: _step == widget.steps.length - 1
                        ? widget.finishLabel
                        : widget.nextLabel,
                    canContinue: widget.canContinue,
                    onBack: () => _goTo(_step - 1),
                    onNext: () => _goTo(_step + 1),
                  ),
          ),
      ],
    );

    return switch (widget.axis) {
      Axis.horizontal => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [indicator, const SizedBox(height: 24), body],
      ),
      Axis.vertical => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: widget.railWidth, child: indicator),
          const SizedBox(width: 24),
          Expanded(child: body),
        ],
      ),
    };
  }
}

@immutable
class _FlowColors {
  const _FlowColors({required this.ink, required this.accent});

  final Color ink;
  final Color accent;

  Color get muted => ink.withValues(alpha: 0.5);
  Color get faint => ink.withValues(alpha: 0.12);
  Color get onAccent =>
      accent.computeLuminance() > 0.45 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
}

// ------------------------------------------------------------- content

/// The current step's content, swapping in from the side it lies on while
/// the height eases to fit.
class _Content extends StatelessWidget {
  const _Content({
    required this.animation,
    required this.transition,
    required this.duration,
    required this.forward,
    required this.incoming,
    required this.outgoing,
  });

  final Animation<double> animation;
  final StepFlowTransition transition;
  final Duration duration;
  final bool forward;
  final Widget incoming;
  final Widget? outgoing;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: _Resize(
        duration: duration,
        child: LayoutBuilder(
          builder: (context, constraints) => AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(animation.value);
              final outgoing = this.outgoing;
              final shift = switch (transition) {
                StepFlowTransition.slide => constraints.maxWidth * 0.6,
                StepFlowTransition.fade => 16.0,
                StepFlowTransition.none => 0.0,
              };
              final sign = forward ? 1.0 : -1.0;
              return Stack(
                clipBehavior: Clip.none,
                fit: StackFit.passthrough,
                children: [
                  if (outgoing != null && t < 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: IgnorePointer(
                        child: _Shifted(dx: -sign * shift * t, opacity: 1 - t, child: outgoing),
                      ),
                    ),
                  _Shifted(dx: sign * shift * (1 - t), opacity: t, child: incoming),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// [AnimatedSize], or just [child] when [duration] is zero (an
/// [AnimatedSize] with no duration re-dirties itself during layout).
class _Resize extends StatelessWidget {
  const _Resize({required this.duration, required this.child});

  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

class _Shifted extends StatelessWidget {
  const _Shifted({required this.dx, required this.opacity, required this.child});

  final double dx;
  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(offset: Offset(dx, 0), child: child),
    );
  }
}

// ------------------------------------------------------------- footer

class _Footer extends StatelessWidget {
  const _Footer({
    required this.colors,
    required this.duration,
    required this.showBack,
    required this.backLabel,
    required this.nextLabel,
    required this.canContinue,
    required this.onBack,
    required this.onNext,
  });

  final _FlowColors colors;
  final Duration duration;
  final bool showBack;
  final String backLabel;
  final String nextLabel;
  final bool canContinue;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: AnimatedOpacity(
              duration: duration,
              opacity: showBack ? 1 : 0,
              child: IgnorePointer(
                ignoring: !showBack,
                child: ExcludeSemantics(
                  excluding: !showBack,
                  child: _FlowButton(
                    label: backLabel,
                    primary: false,
                    chevron: AxisDirection.left,
                    colors: colors,
                    onTap: onBack,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: _FlowButton(
              label: nextLabel,
              primary: true,
              chevron: AxisDirection.right,
              colors: colors,
              onTap: canContinue ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded footer button with a chevron.
class _FlowButton extends StatefulWidget {
  const _FlowButton({
    required this.label,
    required this.primary,
    required this.chevron,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool primary;
  final AxisDirection chevron;
  final _FlowColors colors;
  final VoidCallback? onTap;

  @override
  State<_FlowButton> createState() => _FlowButtonState();
}

class _FlowButtonState extends State<_FlowButton> {
  bool _hover = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final enabled = widget.onTap != null;
    final ink = widget.primary ? c.onAccent : c.ink;
    final chevron = SizedBox.square(
      dimension: 14,
      child: CustomPaint(painter: _ChevronPainter(widget.chevron, ink)),
    );
    final label = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w600, height: 1.2),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap?.call()),
        },
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: enabled ? 1 : 0.4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: widget.primary
                      ? Color.lerp(c.accent, c.onAccent, _hover && enabled ? 0.1 : 0)
                      : c.ink.withValues(alpha: _hover && enabled ? 0.1 : 0.05),
                  border: Border.all(
                    color: _focused ? c.accent : c.ink.withValues(alpha: widget.primary ? 0 : 0.1),
                    width: _focused ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: widget.chevron == AxisDirection.left
                      ? [chevron, Flexible(child: label)]
                      : [Flexible(child: label), chevron],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.direction, this.color);

  final AxisDirection direction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final left = direction == AxisDirection.left;
    final path = Path()
      ..moveTo(w * (left ? 0.62 : 0.38), w * 0.2)
      ..lineTo(w * (left ? 0.32 : 0.68), w * 0.5)
      ..lineTo(w * (left ? 0.62 : 0.38), w * 0.8);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.direction != direction || old.color != color;
}

// ------------------------------------------------------------- indicator

/// Where a step stands relative to the current one.
enum _Status { done, current, upcoming }

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.style,
    required this.axis,
    required this.steps,
    required this.current,
    required this.colors,
    required this.duration,
    required this.canJumpTo,
    required this.onTap,
  });

  final StepFlowIndicator style;
  final Axis axis;
  final List<FlowStep> steps;
  final int current;
  final _FlowColors colors;
  final Duration duration;
  final bool Function(int step) canJumpTo;
  final ValueChanged<int> onTap;

  _Status _statusOf(int i) =>
      i < current ? _Status.done : (i == current ? _Status.current : _Status.upcoming);

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++)
            _Tap(
              step: i,
              total: steps.length,
              title: steps[i].title,
              status: _statusOf(i),
              enabled: canJumpTo(i),
              onTap: onTap,
              child: _RailItem(
                step: steps[i],
                index: i,
                last: i == steps.length - 1,
                status: _statusOf(i),
                colors: colors,
                duration: duration,
              ),
            ),
        ],
      );
    }
    return switch (style) {
      StepFlowIndicator.numbers => _NumbersRow(
        steps: steps,
        current: current,
        colors: colors,
        duration: duration,
        statusOf: _statusOf,
        canJumpTo: canJumpTo,
        onTap: onTap,
      ),
      StepFlowIndicator.dots || StepFlowIndicator.bars => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: style == StepFlowIndicator.bars ? 8 : 0,
        children: [
          for (var i = 0; i < steps.length; i++)
            if (style == StepFlowIndicator.bars)
              Expanded(
                child: _Tap(
                  step: i,
                  total: steps.length,
                  title: steps[i].title,
                  status: _statusOf(i),
                  enabled: canJumpTo(i),
                  onTap: onTap,
                  child: _Bar(
                    filled: i <= current,
                    colors: colors,
                    duration: duration,
                    hitPadding: 10,
                  ),
                ),
              )
            else
              _Tap(
                step: i,
                total: steps.length,
                title: steps[i].title,
                status: _statusOf(i),
                enabled: canJumpTo(i),
                onTap: onTap,
                child: _Dot(status: _statusOf(i), colors: colors, duration: duration),
              ),
        ],
      ),
    };
  }
}

/// Makes an indicator item tappable and describes it to screen readers.
class _Tap extends StatelessWidget {
  const _Tap({
    required this.step,
    required this.total,
    required this.title,
    required this.status,
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  final int step;
  final int total;
  final String? title;
  final _Status status;
  final bool enabled;
  final ValueChanged<int> onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final state = switch (status) {
      _Status.done => 'completed',
      _Status.current => 'current',
      _Status.upcoming => 'not started',
    };
    return Semantics(
      button: enabled,
      selected: status == _Status.current,
      label: 'Step ${step + 1} of $total${title == null ? '' : ', $title'}, $state',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => onTap(step) : null,
          child: child,
        ),
      ),
    );
  }
}

/// Numbered badges joined by connectors, with a ring that glides to the
/// current badge.
class _NumbersRow extends StatelessWidget {
  const _NumbersRow({
    required this.steps,
    required this.current,
    required this.colors,
    required this.duration,
    required this.statusOf,
    required this.canJumpTo,
    required this.onTap,
  });

  static const double _badge = 32;
  static const double _ring = 6;

  final List<FlowStep> steps;
  final int current;
  final _FlowColors colors;
  final Duration duration;
  final _Status Function(int) statusOf;
  final bool Function(int) canJumpTo;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _badge + _ring * 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final n = steps.length;
          final width = constraints.maxWidth;
          final gap = n == 1 ? 0.0 : (width - _badge - _ring * 2) / (n - 1);
          final active = math.min(current, n - 1);
          return Stack(
            children: [
              for (var i = 0; i < n - 1; i++)
                Positioned(
                  left: _ring + _badge + i * gap + 6,
                  width: gap - _badge - 12,
                  top: _ring + _badge / 2 - 1.5,
                  height: 3,
                  child: _Bar(
                    filled: i < current,
                    colors: colors,
                    duration: duration,
                    thickness: 3,
                  ),
                ),
              AnimatedPositioned(
                duration: duration,
                curve: Curves.easeOutBack,
                left: active * gap,
                top: 0,
                width: _badge + _ring * 2,
                height: _badge + _ring * 2,
                child: AnimatedOpacity(
                  duration: duration,
                  opacity: current < n ? 1 : 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.accent.withValues(alpha: 0.14),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < n; i++)
                Positioned(
                  left: _ring + i * gap,
                  top: _ring,
                  width: _badge,
                  height: _badge,
                  child: _Tap(
                    step: i,
                    total: n,
                    title: steps[i].title,
                    status: statusOf(i),
                    enabled: canJumpTo(i),
                    onTap: onTap,
                    child: _Badge(
                      number: i + 1,
                      icon: steps[i].icon,
                      status: statusOf(i),
                      colors: colors,
                      duration: duration,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A round step badge: a check when done, filled when current, outlined
/// when upcoming.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.number,
    required this.icon,
    required this.status,
    required this.colors,
    required this.duration,
    this.size = 32,
  });

  final int number;
  final Widget? icon;
  final _Status status;
  final _FlowColors colors;
  final Duration duration;
  final double size;

  @override
  Widget build(BuildContext context) {
    final filled = status != _Status.upcoming;
    final ink = filled ? colors.onAccent : colors.muted;
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? colors.accent : colors.faint.withValues(alpha: 0.06),
        border: Border.all(color: filled ? colors.accent : colors.faint, width: 1.5),
      ),
      child: status == _Status.done
          ? _Check(color: ink, duration: duration, size: size * 0.5)
          : IconTheme(
              data: IconThemeData(color: ink, size: size * 0.5),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: ink,
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
                child: icon ?? Text('$number'),
              ),
            ),
    );
  }
}

/// A check mark that draws itself in.
class _Check extends StatelessWidget {
  const _Check({required this.color, required this.duration, required this.size});

  final Color color;
  final Duration duration;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: duration == Duration.zero ? 1 : 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _CheckPainter(t, color)),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final path = Path()
      ..moveTo(w * 0.16, w * 0.54)
      ..lineTo(w * 0.42, w * 0.78)
      ..lineTo(w * 0.86, w * 0.26);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress || old.color != color;
}

/// A rounded bar whose accent fill grows in from the left.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.filled,
    required this.colors,
    required this.duration,
    this.thickness = 4,
    this.hitPadding = 0,
  });

  final bool filled;
  final _FlowColors colors;
  final Duration duration;
  final double thickness;

  /// Extra tappable room above and below the bar.
  final double hitPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: hitPadding),
      child: Container(
        height: thickness,
        decoration: BoxDecoration(
          color: colors.faint,
          borderRadius: BorderRadius.circular(thickness / 2),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: filled ? 1 : 0),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: t,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(thickness / 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A dot that stretches into a pill for the current step.
class _Dot extends StatelessWidget {
  const _Dot({required this.status, required this.colors, required this.duration});

  final _Status status;
  final _FlowColors colors;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutBack,
        width: status == _Status.current ? 26 : 9,
        height: 9,
        decoration: BoxDecoration(
          color: status == _Status.upcoming ? colors.faint : colors.accent,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}

/// One row of the vertical rail: a badge, its title and subtitle, and a
/// connector down to the next step.
class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.step,
    required this.index,
    required this.last,
    required this.status,
    required this.colors,
    required this.duration,
  });

  final FlowStep step;
  final int index;
  final bool last;
  final _Status status;
  final _FlowColors colors;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final current = status == _Status.current;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              _Badge(
                number: index + 1,
                icon: step.icon,
                status: status,
                colors: colors,
                duration: duration,
                size: 30,
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    constraints: const BoxConstraints(minHeight: 18),
                    color: status == _Status.done ? colors.accent : colors.faint,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 5, bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step.title case final title?)
                    AnimatedDefaultTextStyle(
                      duration: duration,
                      // Merged over the ambient style so the font family carries over.
                      style: DefaultTextStyle.of(context).style.merge(
                        TextStyle(
                          color: status == _Status.upcoming ? colors.muted : colors.ink,
                          fontSize: 14,
                          fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      child: Text(title),
                    ),
                  if (step.subtitle case final subtitle?)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle, style: TextStyle(color: colors.muted, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
