import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// A viewport of [size] at the top left, optionally reducing motion.
class _Host extends StatelessWidget {
  const _Host({required this.child, this.size = const Size(300, 60), this.reduceMotion = false});

  final Widget child;
  final Size size;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(size: size, child: child),
        ),
      ),
    );
  }
}

/// A 60 px item labelled [label].
class _Item extends StatelessWidget {
  const _Item(this.label, {this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 60, height: 40, child: Center(child: Text(label))),
    );
  }
}

/// Three 60 px items with 10 px gaps: one copy is 200 px, one period 210 px.
const List<Widget> _items = [_Item('A'), _Item('B'), _Item('C')];

/// Main-axis starts of every copy of item 'A', sorted.
List<double> _aStarts(WidgetTester tester, {bool vertical = false}) {
  final items = find.byWidgetPredicate((w) => w is _Item && w.label == 'A');
  return [
    for (var i = 0; i < items.evaluate().length; i++)
      vertical ? tester.getTopLeft(items.at(i)).dy : tester.getTopLeft(items.at(i)).dx,
  ]..sort();
}

void main() {
  testWidgets('scrolls at a constant speed in pixels per second', (tester) async {
    await tester.pumpWidget(const _Host(child: Marquee(speed: 100, gap: 10, children: _items)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // Wrapped by the 210 px period: 'A' copies sit at -100, 110, 320, ...
    expect(_aStarts(tester).first, closeTo(-100, 1));
    expect(_aStarts(tester), contains(closeTo(110, 1)));
  });

  testWidgets('reverse scrolls the other way', (tester) async {
    await tester.pumpWidget(
      const _Host(child: Marquee(speed: 100, gap: 10, reverse: true, children: _items)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(_aStarts(tester), contains(closeTo(100, 1)));
    expect(_aStarts(tester).first, closeTo(-110, 1));
  });

  testWidgets('adds copies until the viewport is always covered', (tester) async {
    await tester.pumpWidget(
      const _Host(
        size: Size(700, 60),
        child: Marquee(gap: 10, children: _items),
      ),
    );
    await tester.pump();
    await tester.pump();
    // ceil(700 / 210) + 1 = 5 copies: the last one still reaches past the
    // edge after scrolling a full period.
    expect(find.text('A'), findsNWidgets(5));
    expect(_aStarts(tester).last + 200, greaterThan(700 + 210 - 1));
  });

  testWidgets('pauseOnHover eases to a stop and resumes on exit', (tester) async {
    await tester.pumpWidget(
      const _Host(child: Marquee(speed: 100, gap: 10, pauseOnHover: true, children: _items)),
    );
    await tester.pump();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(150, 30));
    await tester.pump(const Duration(milliseconds: 16));

    // Eases rather than stopping dead: it still moves a little right after.
    final a = _aStarts(tester).first;
    await tester.pump(const Duration(milliseconds: 50));
    expect(_aStarts(tester).first, lessThan(a));

    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'stopped while hovered');
    final paused = _aStarts(tester).first;

    await mouse.moveTo(const Offset(150, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(_aStarts(tester).first, isNot(closeTo(paused, 0.5)));
    await mouse.removePointer();
  });

  testWidgets('stays still when the platform reduces motion', (tester) async {
    await tester.pumpWidget(
      const _Host(reduceMotion: true, child: Marquee(speed: 100, children: _items)),
    );
    await tester.pump();
    final before = _aStarts(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(_aStarts(tester), before);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('scrolls vertically', (tester) async {
    await tester.pumpWidget(
      const _Host(
        size: Size(60, 300),
        child: Marquee(axis: Axis.vertical, speed: 50, gap: 10, children: [_Item('A'), _Item('B')]),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // Copy length 40 + 10 + 40 = 90, period 100: 'A' at -50, 50, 150, ...
    expect(_aStarts(tester, vertical: true), contains(closeTo(-50, 1)));
  });

  testWidgets('only the first copy is visible to accessibility', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const _Host(child: Marquee(speed: 0, children: _items)));
    await tester.pump();
    expect(find.text('A'), findsAtLeastNWidgets(2));
    expect(find.bySemanticsLabel('A'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('children stay interactive', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _Host(
        child: Marquee(speed: 0, children: [_Item('A', onTap: () => taps++)]),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('A').first);
    expect(taps, 1);
  });
}
