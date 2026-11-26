import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// Waves filling an 800x600 screen, optionally reducing motion.
class _Host extends StatelessWidget {
  const _Host({required this.waves, this.reduceMotion = false});

  final WaveBackdrop waves;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(textDirection: TextDirection.ltr, child: waves),
    );
  }
}

void main() {
  testWidgets('flows while shown and shows its child', (tester) async {
    await tester.pumpWidget(const _Host(waves: WaveBackdrop(child: Text('hello'))));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.hasScheduledFrame, isTrue);
    expect(find.text('hello'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('holds still when motion is reduced or speed is 0', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true, waves: WaveBackdrop()));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(const _Host(waves: WaveBackdrop(speed: 0)));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    // Starting up again resumes the flow.
    await tester.pumpWidget(const _Host(waves: WaveBackdrop()));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the child stays interactive and the waves are silent', (tester) async {
    var taps = 0;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _Host(
        reduceMotion: true,
        waves: WaveBackdrop(
          child: Center(
            child: GestureDetector(onTap: () => taps++, child: const Text('Get started')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Get started'));
    expect(taps, 1);
    expect(find.bySemanticsLabel('Get started'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('fills the space it is given', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true, waves: WaveBackdrop()));
    expect(tester.getSize(find.byType(WaveBackdrop)), const Size(800, 600));
  });
}
