@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(440, 250);

const TextStyle _base = TextStyle(fontFamily: 'Roboto', color: Color(0xFFF4F4F5));

/// A step's heading and body.
class _Text extends StatelessWidget {
  const _Text(this.title, this.body);

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(body, style: _base.copyWith(fontSize: 12, color: const Color(0xFFA1A1AA))),
      ],
    );
  }
}

const List<FlowStep> _steps = [
  FlowStep(title: 'Account', subtitle: 'Who you are', child: _Text('Account', 'Who you are.')),
  FlowStep(
    title: 'Plan',
    subtitle: 'Pick a tier',
    child: _Text('Plan', 'Pick a tier.\nTwo lines, so the height changes.'),
  ),
  FlowStep(title: 'Invite', subtitle: 'Bring your team', child: _Text('Invite', 'Share it.')),
];

/// A dark, labelled frame around a flow.
class _Frame extends StatelessWidget {
  const _Frame({required this.boundary, required this.label, required this.child});

  final Key boundary;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: _base,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: boundary,
            child: Container(
              width: _size.width,
              height: _size.height,
              color: const Color(0xFF0E0E10),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(label, style: _base.copyWith(fontSize: 11, color: const Color(0xFFA1A1AA))),
                  const SizedBox(height: 12),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Presses Continue on [flow] and captures it at each of [ms].
Future<List<ui.Image>> _continue(
  WidgetTester tester, {
  required String name,
  required Widget flow,
  required List<int> ms,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(_Frame(boundary: key, label: name, child: flow));
  await tester.tap(find.text('Continue'));
  final frames = <ui.Image>[];
  var elapsed = 0;
  for (final t in ms) {
    await advance(tester, Duration(milliseconds: t - elapsed));
    elapsed = t;
    await tester.pumpWidget(_Frame(boundary: key, label: '$name, $t ms', child: flow));
    frames.add(await captureBoundary(tester, key));
  }
  return frames;
}

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = _size;
    view.devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset());

  testWidgets('StepFlow slides to the next step', (tester) async {
    final frames = await _continue(
      tester,
      name: 'slide',
      flow: const StepFlow(steps: _steps, indicator: StepFlowIndicator.bars),
      ms: const [0, 80, 160, 260, 600],
    );
    await expectSheet(tester, frames, 'step_flow_slide.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('StepFlow numbers: the ring glides and the check draws in', (tester) async {
    final frames = await _continue(
      tester,
      name: 'numbers',
      flow: const StepFlow(steps: _steps, transition: StepFlowTransition.fade),
      ms: const [0, 80, 160, 260, 600],
    );
    await expectSheet(tester, frames, 'step_flow_numbers.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('StepFlow looks', (tester) async {
    final images = <ui.Image>[];
    for (final (label, flow) in const <(String, StepFlow)>[
      ('dots, step 2', StepFlow(steps: _steps, initialStep: 1, indicator: StepFlowIndicator.dots)),
      ('bars, step 3', StepFlow(steps: _steps, initialStep: 2, indicator: StepFlowIndicator.bars)),
      (
        'vertical rail, step 2',
        StepFlow(steps: _steps, initialStep: 1, axis: Axis.vertical, railWidth: 140),
      ),
      (
        'completed',
        StepFlow(steps: _steps, initialStep: 3, completed: _Text('All done', 'Welcome in.')),
      ),
      (
        'accent, cannot continue',
        StepFlow(steps: _steps, initialStep: 1, canContinue: false, accentColor: Color(0xFFF5C451)),
      ),
    ]) {
      final key = GlobalKey();
      await tester.pumpWidget(_Frame(boundary: key, label: label, child: flow));
      await tester.pump(const Duration(seconds: 1));
      images.add(await captureBoundary(tester, key));
    }
    await expectSheet(tester, images, 'step_flow_looks.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
