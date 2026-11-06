import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// An aurora filling an 800x600 screen, optionally reducing motion.
class _Host extends StatelessWidget {
  const _Host({required this.aurora, this.reduceMotion = false});

  final AuroraBackdrop aurora;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(textDirection: TextDirection.ltr, child: aurora),
    );
  }
}

void main() {
  testWidgets('drifts while shown and shows its child', (tester) async {
    await tester.pumpWidget(const _Host(aurora: AuroraBackdrop(child: Text('hello'))));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.hasScheduledFrame, isTrue);
    expect(find.text('hello'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('holds still when motion is reduced or speed is 0', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true, aurora: AuroraBackdrop()));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(const _Host(aurora: AuroraBackdrop(speed: 0)));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('the child stays interactive and the aurora is silent', (tester) async {
    var taps = 0;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _Host(
        reduceMotion: true,
        aurora: AuroraBackdrop(
          child: Center(
            child: GestureDetector(onTap: () => taps++, child: const Text('Debug now')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Debug now'));
    expect(taps, 1);
    expect(find.bySemanticsLabel('Debug now'), findsOneWidget);
    handle.dispose();
  });
}
