import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 12-card carousel filling an 800x600 screen.
class _Host extends StatelessWidget {
  const _Host({this.reduceMotion = false, this.onTap, this.onFront});

  final bool reduceMotion;
  final ValueChanged<int>? onTap;
  final ValueChanged<int>? onFront;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: CylinderCarousel(
          height: 600,
          circumference: 1200,
          onCardTap: onTap,
          onFrontChanged: onFront,
          cards: [
            for (var i = 0; i < 12; i++)
              ColoredBox(
                color: const Color(0xFF3355AA),
                child: Center(child: Text('c$i')),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 300 && tester.binding.hasScheduledFrame; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('the front card is centred and only the front half is drawn', (tester) async {
    await tester.pumpWidget(const _Host());
    expect(tester.getCenter(find.text('c0')).dx, closeTo(400, 1));
    // 12 cards: those turned more than ~95 degrees away are not built.
    expect(find.text('c6'), findsNothing);
    expect(find.text('c1'), findsOneWidget);
  });

  testWidgets('dragging spins it and it settles on a card', (tester) async {
    final fronts = <int>[];
    await tester.pumpWidget(_Host(onFront: fronts.add));
    // One card is 100 px of circumference: drag ~2 cards left.
    await tester.drag(find.text('c0'), const Offset(-190, 0));
    await _settle(tester);
    expect(fronts.last, 2);
    expect(tester.getCenter(find.text('c2')).dx, closeTo(400, 1));
  });

  testWidgets('arrow keys turn it one card', (tester) async {
    final fronts = <int>[];
    await tester.pumpWidget(_Host(onFront: fronts.add));
    Focus.of(tester.element(find.text('c0'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    expect(fronts, [1]);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await _settle(tester);
    expect(fronts.last, 11);
  });

  testWidgets('tapping a card opens the lightbox; tapping again closes it', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(_Host(onTap: taps.add));
    await tester.tap(find.text('c0'));
    await _settle(tester);
    expect(taps, [0]);
    expect(find.text('c0'), findsNWidgets(2), reason: 'on the cylinder and in the lightbox');
    await tester.tapAt(const Offset(10, 10));
    await _settle(tester);
    expect(find.text('c0'), findsOneWidget);
  });

  testWidgets('turns without animating when motion is reduced', (tester) async {
    final fronts = <int>[];
    await tester.pumpWidget(_Host(reduceMotion: true, onFront: fronts.add));
    Focus.of(tester.element(find.text('c0'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(fronts, [1]);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
