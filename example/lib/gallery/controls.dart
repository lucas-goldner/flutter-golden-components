import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// A titled group of playground controls.
class ControlSection extends StatelessWidget {
  const ControlSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title.toUpperCase(), style: GalleryText.overline(p)),
          const SizedBox(height: 12),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label, this.value, this.trailing});

  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: GalleryText.label(p))),
        if (value != null) Text(value!, style: GalleryText.value(p)),
        ?trailing,
      ],
    );
  }
}

/// A horizontal slider drawn with plain widgets.
///
/// Drag or tap the track; arrow keys nudge it when focused.
class SliderControl extends StatefulWidget {
  const SliderControl({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step,
    this.format,
  });

  final String label;
  final double value;
  final double min;
  final double max;

  /// Snaps the value to multiples of this step.
  final double? step;
  final String Function(double value)? format;
  final ValueChanged<double> onChanged;

  @override
  State<SliderControl> createState() => _SliderControlState();
}

class _SliderControlState extends State<SliderControl> {
  bool _hover = false;
  bool _dragging = false;
  bool _focused = false;

  double get _t => ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  double _snap(double v) {
    final step = widget.step;
    if (step != null && step > 0) v = (v / step).round() * step;
    return v.clamp(widget.min, widget.max);
  }

  void _setFromDx(double dx, double width) {
    final t = (dx / width).clamp(0.0, 1.0);
    final v = _snap(widget.min + t * (widget.max - widget.min));
    if (v != widget.value) widget.onChanged(v);
  }

  void _nudge(int dir) {
    final step = widget.step ?? (widget.max - widget.min) / 100;
    widget.onChanged(_snap(widget.value + dir * step));
  }

  String _formatted([double? value]) {
    final v = value ?? widget.value;
    final f = widget.format;
    if (f != null) return f(v);
    final step = widget.step ?? 0.01;
    final decimals = step >= 1 ? 0 : math.max(0, -(math.log(step) / math.ln10).floor());
    return v.toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final active = _hover || _dragging || _focused;
    return Semantics(
      slider: true,
      label: widget.label,
      value: _formatted(),
      increasedValue: _formatted(
        _snap(widget.value + (widget.step ?? (widget.max - widget.min) / 100)),
      ),
      decreasedValue: _formatted(
        _snap(widget.value - (widget.step ?? (widget.max - widget.min) / 100)),
      ),
      onIncrease: () => _nudge(1),
      onDecrease: () => _nudge(-1),
      child: FocusableActionDetector(
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        mouseCursor: SystemMouseCursors.click,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowRight): _NudgeIntent(1),
          SingleActivator(LogicalKeyboardKey.arrowUp): _NudgeIntent(1),
          SingleActivator(LogicalKeyboardKey.arrowLeft): _NudgeIntent(-1),
          SingleActivator(LogicalKeyboardKey.arrowDown): _NudgeIntent(-1),
        },
        actions: {_NudgeIntent: CallbackAction<_NudgeIntent>(onInvoke: (i) => _nudge(i.direction))},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LabelRow(label: widget.label, value: _formatted()),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _setFromDx(d.localPosition.dx, width),
                  onHorizontalDragStart: (d) {
                    setState(() => _dragging = true);
                    _setFromDx(d.localPosition.dx, width);
                  },
                  onHorizontalDragUpdate: (d) => _setFromDx(d.localPosition.dx, width),
                  onHorizontalDragEnd: (_) => setState(() => _dragging = false),
                  onHorizontalDragCancel: () => setState(() => _dragging = false),
                  child: SizedBox(
                    height: 22,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: p.surfaceAlt,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Container(
                          height: 4,
                          width: width * _t,
                          decoration: BoxDecoration(
                            color: p.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Positioned(
                          left: width * _t - 8,
                          child: AnimatedScale(
                            scale: _dragging ? 1.2 : (active ? 1.08 : 1),
                            duration: const Duration(milliseconds: 140),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: p.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: p.accent, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: p.accent.withValues(alpha: active ? 0.35 : 0.0),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NudgeIntent extends Intent {
  const _NudgeIntent(this.direction);
  final int direction;
}

/// An on/off switch drawn with plain widgets.
class ToggleControl extends StatelessWidget {
  const ToggleControl({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Semantics(
      toggled: value,
      label: label,
      child: Pressable(
        onTap: () => onChanged(!value),
        builder: (context, hover, pressed) => _LabelRow(
          label: label,
          trailing: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 36,
            height: 20,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value ? p.accent : p.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: value ? p.accent : p.border),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: value ? p.onAccent : p.muted,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of mutually exclusive options.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;

  /// Option values mapped to their display labels, in order.
  final Map<T, String> options;
  final T? value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabelRow(label: label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(9)),
          child: Row(
            children: [
              for (final entry in options.entries)
                Expanded(
                  child: Semantics(
                    selected: entry.key == value,
                    button: true,
                    child: Pressable(
                      onTap: () => onChanged(entry.key),
                      builder: (context, hover, pressed) {
                        final selected = entry.key == value;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? p.surface
                                : (hover ? p.surface.withValues(alpha: 0.4) : null),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              if (selected)
                                BoxShadow(
                                  color: const Color(0xFF000000).withValues(alpha: 0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            entry.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                              color: selected ? p.text : p.muted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A row of color swatches.
class ColorControl extends StatelessWidget {
  const ColorControl({
    super.key,
    required this.label,
    required this.colors,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<Color> colors;
  final Color value;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabelRow(label: label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in colors)
              Pressable(
                onTap: () => onChanged(c),
                builder: (context, hover, pressed) {
                  final selected = c.toARGB32() == value.toARGB32();
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 26,
                    height: 26,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? p.text : (hover ? p.border : const Color(0x00000000)),
                        width: 2,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// A flat text button.
class GalleryButton extends StatelessWidget {
  const GalleryButton({super.key, required this.label, required this.onTap, this.leading});

  final String label;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        builder: (context, hover, pressed) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: pressed
                ? p.surfaceAlt
                : (hover ? p.surfaceAlt.withValues(alpha: 0.7) : p.surface),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 6)],
              Text(label, style: GalleryText.label(p)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tap target that reports hover and press state to its builder.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.onTap, required this.builder});

  final VoidCallback onTap;
  final Widget Function(BuildContext context, bool hover, bool pressed) builder;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (v) => setState(() => _hover = v),
      actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: widget.builder(context, _hover, _pressed),
      ),
    );
  }
}
