import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

const List<FlowStep> _steps = [
  FlowStep(title: 'Account', subtitle: 'Who you are', child: Text('Create your account')),
  FlowStep(title: 'Plan', subtitle: 'Pick a tier', child: Text('Choose a plan')),
  FlowStep(title: 'Invite', subtitle: 'Bring your team', child: Text('Invite teammates')),
];

/// A 500 px wide flow on an 800x600 screen.
class _Host extends StatelessWidget {
  const _Host({
    this.indicator = StepFlowIndicator.numbers,
    this.axis = Axis.horizontal,
    this.linear = false,
    this.canContinue = true,
    this.reduceMotion = false,
    this.onStepChanged,
    this.onCompleted,
  });

  final StepFlowIndicator indicator;
  final Axis axis;
  final bool linear;
  final bool canContinue;
  final bool reduceMotion;
  final ValueChanged<int>? onStepChanged;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xFF18181B)),
          child: Center(
            child: SizedBox(
              width: 500,
              child: StepFlow(
                steps: _steps,
                indicator: indicator,
                axis: axis,
                linear: linear,
                canContinue: canContinue,
                onStepChanged: onStepChanged,
                onCompleted: onCompleted,
                completed: const Text('All done'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Whether [text] is on screen and fully visible (not mid-transition).
bool _showing(WidgetTester tester, String text) => find.text(text).evaluate().isNotEmpty;

void main() {
  testWidgets('Continue and Back move between steps', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(_Host(onStepChanged: changes.add));
    expect(_showing(tester, 'Create your account'), isTrue);

    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 200));
    // Mid-transition both steps are on screen.
    expect(_showing(tester, 'Create your account'), isTrue);
    expect(_showing(tester, 'Choose a plan'), isTrue);
    await tester.pumpAndSettle();
    expect(_showing(tester, 'Create your account'), isFalse);
    expect(_showing(tester, 'Choose a plan'), isTrue);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(_showing(tester, 'Create your account'), isTrue);
    expect(changes, [1, 0]);
  });

  testWidgets('the last step completes the flow', (tester) async {
    var completed = 0;
    await tester.pumpWidget(_Host(onCompleted: () => completed++));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Complete'), findsOneWidget);

    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle();
    expect(completed, 1);
    expect(_showing(tester, 'All done'), isTrue);
    expect(find.text('Back'), findsNothing, reason: 'the footer folds away');
  });

  testWidgets('Continue is disabled until the step allows it', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(_Host(canContinue: false, onStepChanged: changes.add));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
  });

  testWidgets('the indicator jumps to a step; linear flows only go back', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(_Host(linear: true, onStepChanged: changes.add));
    await tester.tap(find.bySemanticsLabel(RegExp('^Step 3 of 3')));
    await tester.pumpAndSettle();
    expect(changes, isEmpty, reason: 'step 3 not reached yet');

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^Step 1 of 3')));
    await tester.pumpAndSettle();
    expect(changes, [1, 0]);
    // Step 2 was reached before, so it can be jumped back to.
    await tester.tap(find.bySemanticsLabel(RegExp('^Step 2 of 3')));
    await tester.pumpAndSettle();
    expect(changes, [1, 0, 1]);

    await tester.pumpWidget(_Host(onStepChanged: changes.add));
    await tester.pumpAndSettle();
  });

  testWidgets('non-linear flows can jump ahead', (tester) async {
    final changes = <int>[];
    for (final indicator in StepFlowIndicator.values) {
      changes.clear();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_Host(indicator: indicator, onStepChanged: changes.add));
      await tester.tap(find.bySemanticsLabel(RegExp('^Step 3 of 3')));
      await tester.pumpAndSettle();
      expect(changes, [2], reason: indicator.name);
      expect(_showing(tester, 'Invite teammates'), isTrue);
    }
  });

  testWidgets('describes steps to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const _Host());
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Step 1 of 3, Account, completed'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 2 of 3, Plan, current'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 3 of 3, Invite, not started'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the vertical rail shows titles and subtitles', (tester) async {
    await tester.pumpWidget(const _Host(axis: Axis.vertical));
    for (final text in ['Account', 'Who you are', 'Plan', 'Pick a tier', 'Invite']) {
      expect(find.text(text), findsOneWidget);
    }
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(_showing(tester, 'Choose a plan'), isTrue);
  });

  testWidgets('switches instantly when motion is reduced', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(_showing(tester, 'Create your account'), isFalse);
    expect(_showing(tester, 'Choose a plan'), isTrue);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
