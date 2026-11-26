import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// A five-slide deck, 500 px wide, on an 800x600 screen.
class _Host extends StatelessWidget {
  const _Host({this.onChanged, this.autoplay, this.loop = true, this.reduceMotion = false});

  final ValueChanged<int>? onChanged;
  final Duration? autoplay;
  final bool loop;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xFF000000)),
          child: Center(
            child: SizedBox(
              width: 500,
              child: SwipeDeck(
                onChanged: onChanged,
                autoplay: autoplay,
                loop: loop,
                slides: [
                  for (var i = 0; i < 5; i++)
                    ColoredBox(
                      color: const Color(0xFF3355AA),
                      child: Center(child: Text('s$i')),
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

void main() {
  testWidgets('a swipe moves one slide; a short drag springs back', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(_Host(onChanged: changes.add));
    await tester.fling(find.text('s0'), const Offset(-200, 0), 1200);
    await tester.pumpAndSettle();
    expect(changes, [1]);
    expect(tester.getCenter(find.text('s1')).dx, closeTo(400, 1));

    await tester.timedDrag(find.text('s1'), const Offset(-60, 0), const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(changes, [1], reason: 'not far enough');
    expect(tester.getCenter(find.text('s1')).dx, closeTo(400, 1));
  });

  testWidgets('neighbours are smaller and dimmer', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.pump();
    final front = tester.widget<Opacity>(
      find.ancestor(of: find.text('s0'), matching: find.byType(Opacity)).first,
    );
    final side = tester.widget<Opacity>(
      find.ancestor(of: find.text('s1'), matching: find.byType(Opacity)).first,
    );
    expect(front.opacity, 1);
    expect(side.opacity, lessThan(1));
  });

  testWidgets('dots and arrow keys move it', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(_Host(onChanged: changes.add));
    await tester.tap(find.bySemanticsLabel('Go to slide 4'));
    await tester.pumpAndSettle();
    expect(changes.last, 3);

    Focus.of(tester.element(find.text('s3'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(changes.last, 4);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(changes.last, 4, reason: 'already at the end');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(changes.last, 3);
  });

  testWidgets('autoplay advances, wraps around, and stops without loop', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(_Host(onChanged: changes.add, autoplay: const Duration(seconds: 2)));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }
    expect(changes, [1, 2, 3, 4, 0]);

    changes.clear();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      _Host(onChanged: changes.add, autoplay: const Duration(seconds: 1), loop: false),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }
    expect(changes, [1, 2, 3, 4]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('jumps without gliding when motion is reduced', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(_Host(onChanged: changes.add, reduceMotion: true));
    await tester.tap(find.bySemanticsLabel('Go to slide 3'));
    await tester.pump();
    await tester.pump();
    expect(changes, [2]);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
