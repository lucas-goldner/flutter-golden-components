import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// A centred line on an 800x600 screen, optionally reducing motion.
class _Host extends StatelessWidget {
  const _Host({required this.child, this.reduceMotion = false});

  final Widget child;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 20, color: Color(0xFF000000)),
          child: Center(child: child),
        ),
      ),
    );
  }
}

const List<List<String>> _phrases = [
  ['alpha', 'beta'],
  ['gamma', 'delta'],
];

/// The words on screen.
Set<String> _words(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).map((t) => t.data!).toSet();

void main() {
  testWidgets('builds a phrase word by word, then moves to the next', (tester) async {
    // speed 1: first 340 ms, push 430 ms, hold 980 ms, exit 260 ms, gap 220 ms.
    await tester.pumpWidget(const _Host(child: KineticLine(phrases: _phrases, speed: 1)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_words(tester), {'alpha'});
    await tester.pump(const Duration(milliseconds: 400));
    expect(_words(tester), {'alpha', 'beta'});

    // Through the hold, exit and pause into the second phrase.
    await tester.pump(const Duration(milliseconds: 1800));
    expect(_words(tester), {'gamma'});
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the finished line sits centred', (tester) async {
    await tester.pumpWidget(const _Host(child: KineticLine(phrases: _phrases, speed: 1)));
    await tester.pump(const Duration(milliseconds: 1200));
    final left = tester.getRect(find.text('alpha'));
    final right = tester.getRect(find.text('beta'));
    expect((left.left + right.right) / 2, closeTo(400, 1));
    expect(right.left - left.right, closeTo(10, 0.5), reason: 'the word gap');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('without looping the last phrase stays and ticking stops', (tester) async {
    await tester.pumpWidget(
      const _Host(child: KineticLine(phrases: _phrases, speed: 1, loop: false)),
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    await tester.pump();
    expect(_words(tester), {'gamma', 'delta'});
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('holds the first phrase still when motion is reduced', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true, child: KineticLine(phrases: _phrases)));
    expect(_words(tester), {'alpha', 'beta'});
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
