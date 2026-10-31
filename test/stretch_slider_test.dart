import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

const Key _end = Key('end');

/// A 400 px wide slider (or 300 px tall when [vertical]) that keeps its own
/// value, centred on an 800x600 screen.
class _Host extends StatefulWidget {
  const _Host({
    this.initial = 0.5,
    this.vertical = false,
    this.jumpOnTap = true,
    this.divisions,
    this.enabled = true,
    this.reduceMotion = false,
    this.onChanged,
  });

  final double initial;
  final bool vertical;
  final bool jumpOnTap;
  final int? divisions;
  final bool enabled;
  final bool reduceMotion;
  final ValueChanged<double>? onChanged;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late double _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: widget.reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xFF000000)),
          child: Center(
            child: StretchSlider(
              value: _value,
              axis: widget.vertical ? Axis.vertical : Axis.horizontal,
              length: widget.vertical ? 300 : 400,
              jumpOnTap: widget.jumpOnTap,
              divisions: widget.divisions,
              semanticLabel: 'Volume',
              trailing: const SizedBox(key: _end, width: 20, height: 20),
              onChanged: widget.enabled
                  ? (v) {
                      setState(() => _value = v);
                      widget.onChanged?.call(v);
                    }
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// The track's rectangle: the slider minus its trailing widget.
Rect _track(WidgetTester tester) {
  final slider = tester.getRect(find.byType(StretchSlider));
  final end = tester.getRect(find.byKey(_end));
  return slider.width > slider.height
      ? Rect.fromLTRB(slider.left, slider.top, end.left - 10, slider.bottom)
      : Rect.fromLTRB(slider.left, end.bottom + 10, slider.right, slider.bottom);
}

void main() {
  testWidgets('tapping the track jumps to that value', (tester) async {
    final values = <double>[];
    await tester.pumpWidget(_Host(initial: 0, onChanged: values.add));
    final track = _track(tester);
    await tester.tapAt(Offset(track.left + track.width * 0.25, track.center.dy));
    await tester.pumpAndSettle();
    expect(values.last, closeTo(0.25, 0.01));
  });

  testWidgets('dragging past the end stretches, then snaps back', (tester) async {
    double? last;
    await tester.pumpWidget(_Host(initial: 0.9, onChanged: (v) => last = v));
    final restX = tester.getCenter(find.byKey(_end)).dx;
    final track = _track(tester);

    final gesture = await tester.startGesture(Offset(track.right - 20, track.center.dy));
    await gesture.moveBy(const Offset(30, 0));
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();
    expect(last, 1.0, reason: 'clamped at the maximum');
    final pulled = tester.getCenter(find.byKey(_end)).dx;
    expect(pulled, greaterThan(restX + 10), reason: 'the end follows the stretch');
    expect(pulled, lessThan(restX + 40 + 0.01), reason: 'never past maxStretch');

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.byKey(_end)).dx, closeTo(restX, 0.01));
  });

  testWidgets('relative mode ignores taps and drags from the current value', (tester) async {
    final values = <double>[];
    await tester.pumpWidget(_Host(initial: 0.2, jumpOnTap: false, onChanged: values.add));
    final track = _track(tester);
    await tester.tapAt(Offset(track.left + track.width * 0.8, track.center.dy));
    await tester.pumpAndSettle();
    expect(values, isEmpty);

    await tester.dragFrom(
      Offset(track.left + track.width * 0.8, track.center.dy),
      Offset(track.width * 0.3, 0),
    );
    await tester.pumpAndSettle();
    expect(values.last, closeTo(0.5, 0.02));
  });

  testWidgets('snaps to divisions', (tester) async {
    final values = <double>[];
    await tester.pumpWidget(_Host(initial: 0, divisions: 4, onChanged: values.add));
    final track = _track(tester);
    await tester.tapAt(Offset(track.left + track.width * 0.4, track.center.dy));
    await tester.pumpAndSettle();
    expect(values.last, 0.5);
  });

  testWidgets('vertical sliders grow upward', (tester) async {
    final values = <double>[];
    await tester.pumpWidget(_Host(vertical: true, initial: 0, onChanged: values.add));
    final track = _track(tester);
    await tester.tapAt(Offset(track.center.dx, track.bottom - track.height * 0.75));
    await tester.pumpAndSettle();
    expect(values.last, closeTo(0.75, 0.01));
  });

  testWidgets('keyboard adjusts the focused slider', (tester) async {
    final values = <double>[];
    await tester.pumpWidget(_Host(initial: 0.5, onChanged: values.add));
    Focus.of(tester.element(find.byKey(_end))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(values.last, closeTo(0.51, 0.001));
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    expect(values.last, 1.0);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    expect(values.last, 0.0);
    await tester.pumpAndSettle();
  });

  testWidgets('disabled sliders ignore input', (tester) async {
    await tester.pumpWidget(const _Host(enabled: false));
    final track = _track(tester);
    await tester.tapAt(track.centerLeft + const Offset(10, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<StretchSlider>(find.byType(StretchSlider)).value, 0.5);
  });

  testWidgets('reduced motion: no spring back, no easing', (tester) async {
    await tester.pumpWidget(const _Host(initial: 0.9, reduceMotion: true));
    final restX = tester.getCenter(find.byKey(_end)).dx;
    final track = _track(tester);
    final gesture = await tester.startGesture(Offset(track.right - 10, track.center.dy));
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.getCenter(find.byKey(_end)).dx, closeTo(restX, 0.01));
  });

  testWidgets('describes itself to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const _Host(initial: 0.3));
    expect(
      tester.getSemantics(find.byType(StretchSlider)),
      matchesSemantics(
        label: 'Volume',
        value: '30%',
        increasedValue: '35%',
        decreasedValue: '25%',
        isSlider: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    handle.dispose();
  });
}
