@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const double _width = 420;
const TextStyle _text = TextStyle(fontFamily: 'Roboto', fontSize: 20, color: Color(0xFF18181B));

/// One labelled scenario on a light card, sized to its content.
class _Scenario extends StatelessWidget {
  const _Scenario({required this.boundary, required this.label, required this.child});

  final Key boundary;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: boundary,
            child: Container(
              width: _width,
              color: const Color(0xFFF7F6F2),
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B6B74),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x1A000000)),
                    ),
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One static scenario for the states sheet.
@immutable
class _Case {
  const _Case({
    required this.label,
    required this.text,
    this.selection,
    this.placeholder,
    this.minLines,
    this.maxLines = 1,
    this.caretColor = const Color(0xFF3B82F6),
    this.caretWidth = 2,
    this.caretRadius = 2,
    this.glowRadius = 6,
    this.glowOpacity = 0.35,
  });

  final String label;
  final String text;

  /// Where to put the cursor once focused; `null` leaves the field unfocused.
  final TextSelection? selection;
  final String? placeholder;
  final int? minLines;
  final int? maxLines;
  final Color caretColor;
  final double caretWidth;
  final double caretRadius;
  final double glowRadius;
  final double glowOpacity;
}

/// A [SmoothCaretField] configured from a [_Case].
class _CaseField extends StatelessWidget {
  const _CaseField({required this.scenario, required this.controller, required this.focus});

  final _Case scenario;
  final TextEditingController controller;
  final FocusNode focus;

  @override
  Widget build(BuildContext context) {
    return SmoothCaretField(
      controller: controller,
      focusNode: focus,
      style: _text,
      blink: false,
      placeholder: scenario.placeholder,
      minLines: scenario.minLines,
      maxLines: scenario.maxLines,
      caretColor: scenario.caretColor,
      caretWidth: scenario.caretWidth,
      caretRadius: scenario.caretRadius,
      glowRadius: scenario.glowRadius,
      glowOpacity: scenario.glowOpacity,
    );
  }
}

const List<_Case> _cases = [
  _Case(label: 'Unfocused, placeholder', text: '', placeholder: 'Type something...'),
  _Case(
    label: 'Focused, caret at rest',
    text: 'Hello, smooth caret',
    selection: TextSelection.collapsed(offset: 6),
  ),
  _Case(
    label: 'Range selected (caret hidden)',
    text: 'Hello, smooth caret',
    selection: TextSelection(baseOffset: 7, extentOffset: 13),
  ),
  _Case(
    label: 'Multi-line, caret on a wrapped line',
    text: 'The caret glides between positions and follows line wraps too.',
    selection: TextSelection.collapsed(offset: 52),
    minLines: 2,
    maxLines: 4,
  ),
  _Case(
    label: 'Custom: thick square caret with a wide glow',
    text: 'Hello, smooth caret',
    selection: TextSelection.collapsed(offset: 19),
    caretColor: Color(0xFFEC4899),
    caretWidth: 4,
    caretRadius: 0,
    glowRadius: 14,
    glowOpacity: 0.6,
  ),
];

/// Pumps [scenario], focuses it at its selection, lets the caret settle and
/// captures it.
Future<ui.Image> _capture(WidgetTester tester, _Case scenario) async {
  final key = GlobalKey();
  final controller = TextEditingController(text: scenario.text);
  final focus = FocusNode();
  await tester.pumpWidget(
    _Scenario(
      boundary: key,
      label: scenario.label,
      child: _CaseField(scenario: scenario, controller: controller, focus: focus),
    ),
  );
  final selection = scenario.selection;
  if (selection != null) {
    focus.requestFocus();
    await tester.pump();
    controller.selection = selection;
  }
  await advance(tester, const Duration(milliseconds: 600));
  final image = await captureBoundary(tester, key);
  await tester.pumpWidget(const SizedBox());
  controller.dispose();
  focus.dispose();
  return image;
}

void main() {
  setUp(() {
    // Physical size only bounds the layout; captures use the card's size.
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(_width, 400);
    view.devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset());

  testWidgets('SmoothCaretField states', (tester) async {
    final images = <ui.Image>[for (final scenario in _cases) await _capture(tester, scenario)];
    await expectSheet(tester, images, 'smooth_caret_field_states.png');
  });

  testWidgets('SmoothCaretField glides, stretches and settles', (tester) async {
    final key = GlobalKey();
    final controller = TextEditingController(text: 'Hello, smooth caret');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _Scenario(
        boundary: key,
        label: 'Jump from start to end',
        child: SmoothCaretField(
          controller: controller,
          focusNode: focus,
          style: _text,
          blink: false,
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    controller.selection = const TextSelection.collapsed(offset: 0);
    await advance(tester, const Duration(milliseconds: 400));

    // Move to the end and record the flight: start, mid-glide (stretched),
    // overshoot region, settled.
    controller.selection = const TextSelection.collapsed(offset: 19);
    final frames = <ui.Image>[];
    var elapsed = Duration.zero;
    for (final t in const [0, 32, 64, 112, 192, 600]) {
      final at = Duration(milliseconds: t);
      await advance(tester, at - elapsed);
      if (t == 0) await tester.pump();
      elapsed = at;
      await tester.pumpWidget(
        _Scenario(
          boundary: key,
          label: 'Jump from start to end, t = $t ms',
          child: SmoothCaretField(
            controller: controller,
            focusNode: focus,
            style: _text,
            blink: false,
          ),
        ),
      );
      frames.add(await captureBoundary(tester, key));
    }
    await expectSheet(tester, frames, 'smooth_caret_field_glide.png');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('SmoothCaretField blinks with a soft fade', (tester) async {
    final key = GlobalKey();
    final controller = TextEditingController(text: 'Blink');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _Scenario(
        boundary: key,
        label: 'Idle blink (500 ms delay, 1000 ms period)',
        child: SmoothCaretField(controller: controller, focusNode: focus, style: _text),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    controller.selection = const TextSelection.collapsed(offset: 5);
    await tester.pump();
    await tester.pump();

    // Times since the caret settled: solid, fading, gone, fading back in.
    final frames = <ui.Image>[];
    var elapsed = Duration.zero;
    for (final t in const [0, 960, 1000, 1040, 1300, 1480]) {
      final at = Duration(milliseconds: t);
      await advance(tester, at - elapsed);
      elapsed = at;
      await tester.pumpWidget(
        _Scenario(
          boundary: key,
          label: 'Idle blink (500 ms delay, 1000 ms period), t = $t ms',
          child: SmoothCaretField(controller: controller, focusNode: focus, style: _text),
        ),
      );
      frames.add(await captureBoundary(tester, key));
    }
    await expectSheet(tester, frames, 'smooth_caret_field_blink.png');
    await tester.pumpWidget(const SizedBox());
  });
}
