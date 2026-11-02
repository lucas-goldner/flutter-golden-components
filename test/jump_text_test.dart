import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// Centred text on an 800x600 screen, optionally reducing motion.
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

/// Opacity of the unit showing [text] (1 once it has settled).
double _opacity(WidgetTester tester, String text) {
  final opacity = find.ancestor(of: find.text(text), matching: find.byType(Opacity));
  return opacity.evaluate().isEmpty ? 1 : tester.widget<Opacity>(opacity.first).opacity;
}

void main() {
  testWidgets('words jump in one after another, then settle', (tester) async {
    var done = 0;
    await tester.pumpWidget(_Host(child: JumpText('one two three', onComplete: () => done++)));
    expect(_opacity(tester, 'one '), 0);
    await tester.pump(const Duration(milliseconds: 60));
    expect(_opacity(tester, 'one '), greaterThan(0));
    expect(_opacity(tester, 'three'), 0, reason: 'starts 100 ms after the first word');

    for (var i = 0; i < 300 && tester.binding.hasScheduledFrame; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(done, 1);
    expect(find.byType(Opacity), findsNothing, reason: 'settled units are plain text');
  });

  testWidgets('character mode keeps words together', (tester) async {
    await tester.pumpWidget(const _Host(child: JumpText('hi yo', unit: JumpTextUnit.character)));
    for (final c in ['h', 'i', ' ', 'y', 'o']) {
      expect(find.text(c), findsOneWidget);
    }
    // One Row per word, so the Wrap only breaks between words.
    expect(find.byType(Row), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('changing the text replays the effect', (tester) async {
    await tester.pumpWidget(const _Host(child: JumpText('first')));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const _Host(child: JumpText('second')));
    expect(_opacity(tester, 'second'), 0);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('appears at once when motion is reduced', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true, child: JumpText('calm text')));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('reads as one label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const _Host(reduceMotion: true, child: JumpText('hello there')));
    expect(find.bySemanticsLabel('hello there'), findsOneWidget);
    handle.dispose();
  });
}
