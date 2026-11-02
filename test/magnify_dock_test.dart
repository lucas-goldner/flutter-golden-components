import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// A five-item dock at the bottom centre of an 800x600 screen.
class _Host extends StatelessWidget {
  const _Host({this.reduceMotion = false, this.onTap});

  final bool reduceMotion;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xFF000000)),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: MagnifyDock(
              items: [
                for (var i = 0; i < 5; i++)
                  MagnifyDockItem(
                    label: 'App $i',
                    icon: const SizedBox(width: 10, height: 10),
                    onTap: () => onTap?.call(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Width of item [i] (its button's box).
double _size(WidgetTester tester, int i) => tester.getSize(find.bySemanticsLabel('App $i')).width;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 200 && tester.binding.hasScheduledFrame; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('icons swell near the pointer and shrink when it leaves', (tester) async {
    await tester.pumpWidget(const _Host());
    expect(_size(tester, 2), 40);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(400, 100));
    await mouse.moveTo(tester.getCenter(find.bySemanticsLabel('App 2')));
    await _settle(tester);
    expect(_size(tester, 2), closeTo(80, 1), reason: 'right under the pointer');
    expect(_size(tester, 1), allOf(greaterThan(40), lessThan(80)), reason: 'a neighbour');
    expect(find.text('App 2'), findsOneWidget, reason: 'label shows');

    await mouse.moveTo(const Offset(400, 100));
    await _settle(tester);
    for (var i = 0; i < 5; i++) {
      expect(_size(tester, i), 40);
    }
    await mouse.removePointer();
  });

  testWidgets('tapping an icon calls its onTap', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(_Host(onTap: taps.add));
    await tester.tap(find.bySemanticsLabel('App 3'));
    await _settle(tester);
    expect(taps, [3]);
  });

  testWidgets('a focused icon magnifies and activates with Enter', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(_Host(onTap: taps.add));
    final second = find.descendant(
      of: find.byType(FocusableActionDetector).at(1),
      matching: find.byType(GestureDetector),
    );
    Focus.of(tester.element(second)).requestFocus();
    await tester.pump();
    await _settle(tester);
    expect(_size(tester, 1), closeTo(80, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, [1]);
  });

  testWidgets('sizes jump when motion is reduced', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(400, 100));
    await mouse.moveTo(tester.getCenter(find.bySemanticsLabel('App 0')));
    await tester.pump();
    expect(_size(tester, 0), closeTo(80, 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await mouse.removePointer();
  });
}
