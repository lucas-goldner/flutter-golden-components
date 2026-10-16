import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

enum _Preset { standard, snappy, bouncy, lazy, custom }

enum _Layout { single, multi, both }

const _presets = <_Preset, SpringDescription>{
  _Preset.standard: SpringDescription(mass: 1, stiffness: 520, damping: 34),
  _Preset.snappy: SpringDescription(mass: 1, stiffness: 1200, damping: 70),
  _Preset.bouncy: SpringDescription(mass: 1, stiffness: 260, damping: 12),
  _Preset.lazy: SpringDescription(mass: 2, stiffness: 120, damping: 30),
};

const _caretColors = [
  Color(0xFFF5C451),
  Color(0xFF3B82F6),
  Color(0xFFEC4899),
  Color(0xFF10B981),
  Color(0xFFF97316),
  Color(0xFF8B5CF6),
];

/// Playground for [SmoothCaretField].
class SmoothCaretDemo extends StatefulWidget {
  const SmoothCaretDemo({super.key});

  @override
  State<SmoothCaretDemo> createState() => _SmoothCaretDemoState();
}

class _SmoothCaretDemoState extends State<SmoothCaretDemo> {
  final _single = TextEditingController(text: 'Hello, smooth caret');
  final _multi = TextEditingController(
    text:
        'Click anywhere in this paragraph, use the arrow keys or just type. '
        'The caret glides between positions instead of jumping, and follows '
        'line wraps too.',
  );
  final _singleFocus = FocusNode();
  final _multiFocus = FocusNode();

  // Settings (defaults mirror SmoothCaretField's).
  late _Preset _preset;
  late double _stiffness;
  late double _damping;
  late double _mass;
  late Color _color;
  late double _width;
  late double _radius;
  late double _glow;
  late double _glowOpacity;
  late double _stretch;
  late double _maxStretch;
  late double _squash;
  late bool _blink;
  late double _blinkMs;
  late double _blinkDelayMs;
  late double _fontSize;
  late _Layout _layout;
  late bool _slowMo;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    timeDilation = 1;
    _single.dispose();
    _multi.dispose();
    _singleFocus.dispose();
    _multiFocus.dispose();
    super.dispose();
  }

  void _reset() {
    _applyPreset(_Preset.standard);
    _color = _caretColors.first;
    _width = 2;
    _radius = 2;
    _glow = 6;
    _glowOpacity = 0.35;
    _stretch = 0.012;
    _maxStretch = 14;
    _squash = 0.0004;
    _blink = true;
    _blinkMs = 1000;
    _blinkDelayMs = 500;
    _fontSize = 18;
    _layout = _Layout.both;
    _slowMo = false;
    timeDilation = 1;
  }

  void _applyPreset(_Preset preset) {
    _preset = preset;
    final spring = _presets[preset];
    if (spring == null) return;
    _stiffness = spring.stiffness;
    _damping = spring.damping;
    _mass = spring.mass;
  }

  void _set(VoidCallback fn) {
    setState(fn);
    _refocus();
  }

  void _setSpring(VoidCallback fn) => _set(() {
    fn();
    _preset = _Preset.custom;
  });

  /// On pointer/keyboard platforms, hands focus back to a field so the caret
  /// stays visible while settings change. Skipped on phones, where focusing
  /// would pop the keyboard over the settings.
  void _refocus() {
    final touch =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
    if (touch || _singleFocus.hasFocus || _multiFocus.hasFocus) return;
    if (_layout == _Layout.multi) {
      _multiFocus.requestFocus();
    } else {
      _singleFocus.requestFocus();
    }
  }

  SmoothCaretField _field({
    required TextEditingController controller,
    required FocusNode focus,
    required TextStyle style,
    required bool multiline,
  }) {
    return SmoothCaretField(
      controller: controller,
      focusNode: focus,
      style: style,
      placeholder: 'Type something...',
      caretColor: _color,
      caretWidth: _width,
      caretRadius: _radius,
      spring: SpringDescription(mass: _mass, stiffness: _stiffness, damping: _damping),
      stretch: _stretch,
      maxStretch: _maxStretch,
      squash: _squash,
      glowRadius: _glow,
      glowOpacity: _glowOpacity,
      blink: _blink,
      blinkPeriod: Duration(milliseconds: _blinkMs.round()),
      blinkDelay: Duration(milliseconds: _blinkDelayMs.round()),
      minLines: multiline ? 3 : null,
      maxLines: multiline ? 6 : 1,
    );
  }

  Widget _preview(GalleryPalette p) {
    final style = TextStyle(fontSize: _fontSize, height: 1.4, color: p.text);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_layout != _Layout.multi)
                _FieldCard(
                  label: 'Single line',
                  focus: _singleFocus,
                  accent: _color,
                  child: _field(
                    controller: _single,
                    focus: _singleFocus,
                    style: style,
                    multiline: false,
                  ),
                ),
              if (_layout == _Layout.both) const SizedBox(height: 16),
              if (_layout != _Layout.single)
                _FieldCard(
                  label: 'Multi-line',
                  focus: _multiFocus,
                  accent: _color,
                  child: _field(
                    controller: _multi,
                    focus: _multiFocus,
                    style: style.copyWith(fontSize: _fontSize * 0.85),
                    multiline: true,
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                'Tap a field, then move the cursor with taps or arrow keys.',
                textAlign: TextAlign.center,
                style: GalleryText.body(p).copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: _preview(p),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Spring',
          children: [
            SegmentedControl<_Preset>(
              label: 'Preset',
              value: _preset,
              options: const {
                _Preset.standard: 'Default',
                _Preset.snappy: 'Snappy',
                _Preset.bouncy: 'Bouncy',
                _Preset.lazy: 'Lazy',
              },
              onChanged: (v) => _set(() => _applyPreset(v)),
            ),
            SliderControl(
              label: 'Stiffness',
              value: _stiffness,
              min: 40,
              max: 1600,
              step: 10,
              onChanged: (v) => _setSpring(() => _stiffness = v),
            ),
            SliderControl(
              label: 'Damping',
              value: _damping,
              min: 2,
              max: 100,
              step: 1,
              onChanged: (v) => _setSpring(() => _damping = v),
            ),
            SliderControl(
              label: 'Mass',
              value: _mass,
              min: 0.2,
              max: 5,
              step: 0.1,
              onChanged: (v) => _setSpring(() => _mass = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Caret',
          children: [
            ColorControl(
              label: 'Color',
              colors: _caretColors,
              value: _color,
              onChanged: (v) => _set(() => _color = v),
            ),
            SliderControl(
              label: 'Width',
              value: _width,
              min: 1,
              max: 8,
              step: 0.5,
              format: (v) => '${v.toStringAsFixed(1)} px',
              onChanged: (v) => _set(() => _width = v),
            ),
            SliderControl(
              label: 'Corner radius',
              value: _radius,
              min: 0,
              max: 4,
              step: 0.5,
              format: (v) => '${v.toStringAsFixed(1)} px',
              onChanged: (v) => _set(() => _radius = v),
            ),
            SliderControl(
              label: 'Glow',
              value: _glow,
              min: 0,
              max: 24,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _glow = v),
            ),
            SliderControl(
              label: 'Glow opacity',
              value: _glowOpacity,
              min: 0,
              max: 1,
              step: 0.05,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => _set(() => _glowOpacity = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Motion',
          children: [
            SliderControl(
              label: 'Stretch',
              value: _stretch,
              min: 0,
              max: 0.05,
              step: 0.001,
              format: (v) => (v * 1000).toStringAsFixed(0),
              onChanged: (v) => _set(() => _stretch = v),
            ),
            SliderControl(
              label: 'Max stretch',
              value: _maxStretch,
              min: 0,
              max: 40,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _maxStretch = v),
            ),
            SliderControl(
              label: 'Squash',
              value: _squash,
              min: 0,
              max: 0.002,
              step: 0.0001,
              format: (v) => (v * 10000).toStringAsFixed(0),
              onChanged: (v) => _set(() => _squash = v),
            ),
            ToggleControl(
              label: 'Slow motion (5x)',
              value: _slowMo,
              onChanged: (v) => _set(() {
                _slowMo = v;
                timeDilation = v ? 5 : 1;
              }),
            ),
          ],
        ),
        ControlSection(
          title: 'Blink',
          children: [
            ToggleControl(
              label: 'Blink when idle',
              value: _blink,
              onChanged: (v) => _set(() => _blink = v),
            ),
            SliderControl(
              label: 'Period',
              value: _blinkMs,
              min: 300,
              max: 2400,
              step: 50,
              format: (v) => '${v.round()} ms',
              onChanged: (v) => _set(() => _blinkMs = v),
            ),
            SliderControl(
              label: 'Delay after moving',
              value: _blinkDelayMs,
              min: 0,
              max: 1500,
              step: 50,
              format: (v) => '${v.round()} ms',
              onChanged: (v) => _set(() => _blinkDelayMs = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Text',
          children: [
            SegmentedControl<_Layout>(
              label: 'Fields',
              value: _layout,
              options: const {
                _Layout.single: 'Single',
                _Layout.multi: 'Multi-line',
                _Layout.both: 'Both',
              },
              onChanged: (v) => _set(() => _layout = v),
            ),
            SliderControl(
              label: 'Font size',
              value: _fontSize,
              min: 12,
              max: 40,
              step: 1,
              format: (v) => '${v.round()} pt',
              onChanged: (v) => _set(() => _fontSize = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bordered card around a field that lights up while it has focus.
class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.label,
    required this.focus,
    required this.accent,
    required this.child,
  });

  final String label;
  final FocusNode focus;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return ListenableBuilder(
      listenable: focus,
      builder: (context, _) {
        final focused = focus.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focused ? accent.withValues(alpha: 0.8) : p.border,
              width: focused ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: focused
                    ? accent.withValues(alpha: 0.16)
                    : const Color(0xFF000000).withValues(alpha: p.isDark ? 0.3 : 0.04),
                blurRadius: focused ? 18 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: focused ? accent : p.muted,
                ),
              ),
              const SizedBox(height: 6),
              child,
            ],
          ),
        );
      },
    );
  }
}
