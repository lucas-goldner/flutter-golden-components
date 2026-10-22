import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 300 px wide column at the top left, optionally reducing motion.
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
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 300, child: child),
        ),
      ),
    );
  }
}

/// A 40 px tall item labelled [label].
class _Item extends StatelessWidget {
  const _Item(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(height: 40, child: Text(label));
}

const List<Widget> _items = [_Item('a'), _Item('b'), _Item('c'), _Item('d')];

/// Labels in the feed, top to bottom (tree order matches column order).
List<String> _labels(WidgetTester tester) => [
  for (final e in find.byType(_Item).evaluate()) (e.widget as _Item).label,
];

const _interval = Duration(seconds: 2);

/// Advances exactly one interval, so exactly one more item arrives. (Not
/// pumpAndSettle: that keeps advancing time and lets more items arrive.)
Future<void> _arrive(WidgetTester tester) => tester.pump(_interval);

/// Lets the item already in the feed finish its spring.
Future<void> _settle(WidgetTester tester) => tester.pump(const Duration(milliseconds: 800));

void main() {
  testWidgets('reveals one item per interval, newest on top', (tester) async {
    await tester.pumpWidget(
      const _Host(
        child: LiveFeed(interval: _interval, children: _items),
      ),
    );
    expect(_labels(tester), ['a']);
    await _arrive(tester);
    expect(_labels(tester), ['b', 'a']);
    await _arrive(tester);
    expect(_labels(tester), ['c', 'b', 'a']);
  });

  testWidgets('the newest item springs in from zero height', (tester) async {
    await tester.pumpWidget(
      const _Host(
        child: LiveFeed(interval: _interval, gap: 10, children: _items),
      ),
    );
    await _settle(tester);
    final settled = tester.getSize(find.byType(LiveFeed)).height;
    expect(settled, closeTo(50, 0.5));

    await tester.pump(_interval); // 'b' inserted
    await tester.pump(const Duration(milliseconds: 50));
    final mid = tester.getSize(find.byType(LiveFeed)).height;
    expect(mid, inExclusiveRange(50, 100), reason: 'growing, not jumping');
    await _settle(tester);
    expect(tester.getSize(find.byType(LiveFeed)).height, closeTo(100, 0.5));
  });

  testWidgets('stops after the last child', (tester) async {
    await tester.pumpWidget(
      const _Host(
        child: LiveFeed(interval: _interval, children: _items),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await _arrive(tester);
    }
    expect(_labels(tester), ['d', 'c', 'b', 'a']);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('loop keeps cycling and maxVisible caps the feed', (tester) async {
    await tester.pumpWidget(
      const _Host(
        child: LiveFeed(interval: _interval, loop: true, maxVisible: 3, children: _items),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await _arrive(tester);
    }
    // Arrivals 0..5 → a b c d a b; newest three on top.
    expect(_labels(tester), ['b', 'a', 'd']);
  });

  testWidgets('playing: false pauses and resumes where it left off', (tester) async {
    await tester.pumpWidget(
      const _Host(
        child: LiveFeed(interval: _interval, children: _items),
      ),
    );
    await _arrive(tester);
    await tester.pumpWidget(
      const _Host(
        child: LiveFeed(interval: _interval, playing: false, children: _items),
      ),
    );
    await tester.pump(_interval * 4);
    await _settle(tester);
    expect(_labels(tester), ['b', 'a']);

    await tester.pumpWidget(
      const _Host(
        child: LiveFeed(interval: _interval, children: _items),
      ),
    );
    await _arrive(tester);
    expect(_labels(tester), ['c', 'b', 'a']);
  });

  testWidgets('reduced motion shows the finished feed without animating', (tester) async {
    await tester.pumpWidget(
      const _Host(
        reduceMotion: true,
        child: LiveFeed(interval: _interval, maxVisible: 3, children: _items),
      ),
    );
    expect(_labels(tester), ['d', 'c', 'b']);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('shrinking the children list keeps working', (tester) async {
    await tester.pumpWidget(
      const _Host(
        child: LiveFeed(interval: _interval, children: _items),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await _arrive(tester);
    }
    await tester.pumpWidget(
      const _Host(
        child: LiveFeed(interval: _interval, children: [_Item('a'), _Item('b')]),
      ),
    );
    await _settle(tester);
    expect(_labels(tester), ['b', 'a']);
  });
}
