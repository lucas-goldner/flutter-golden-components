import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// An 800x600 page, optionally reducing motion.
class _Host extends StatelessWidget {
  const _Host({required this.child, this.reduceMotion = false});

  final Widget child;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(size: const Size(800, 600), disableAnimations: reduceMotion),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );
  }
}

/// A 100x100 box.
class _Box extends StatelessWidget {
  const _Box([this.label = 'box']);

  final String label;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 100, height: 100, child: Center(child: Text(label)));
}

/// A tall scroll view with a [BlurFade] far below the fold.
class _ScrollPage extends StatelessWidget {
  const _ScrollPage({required this.controller, this.once = true});

  final ScrollController controller;
  final bool once;

  @override
  Widget build(BuildContext context) {
    // Not lazy, so the reveal exists (and listens) while off screen.
    return SingleChildScrollView(
      controller: controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 1000),
          BlurFade(inView: true, once: once, child: const _Box('below')),
          const SizedBox(height: 1000),
        ],
      ),
    );
  }
}

double _opacity(WidgetTester tester) => tester
    .widget<Opacity>(find.descendant(of: find.byType(BlurFade), matching: find.byType(Opacity)))
    .opacity;

ImageFiltered _filter(WidgetTester tester) => tester.widget<ImageFiltered>(
  find.descendant(of: find.byType(BlurFade), matching: find.byType(ImageFiltered)),
);

void main() {
  testWidgets('starts hidden and blurred, waits for the delay, then settles', (tester) async {
    await tester.pumpWidget(
      const _Host(
        child: BlurFade(delay: Duration(milliseconds: 200), child: _Box()),
      ),
    );
    expect(_opacity(tester), 0);
    expect(_filter(tester).enabled, isTrue);

    await tester.pump(const Duration(milliseconds: 150));
    expect(_opacity(tester), 0, reason: 'still waiting for the delay');

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_opacity(tester), inExclusiveRange(0, 1), reason: 'mid reveal');

    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
    expect(_filter(tester).enabled, isFalse, reason: 'no blur at rest');
  });

  testWidgets('slides in from the opposite side of its direction', (tester) async {
    const expected = {
      BlurFadeDirection.down: Offset(0, -10),
      BlurFadeDirection.up: Offset(0, 10),
      BlurFadeDirection.right: Offset(-10, 0),
      BlurFadeDirection.left: Offset(10, 0),
    };
    for (final MapEntry(key: direction, value: start) in expected.entries) {
      await tester.pumpWidget(
        _Host(
          child: Center(
            child: BlurFade(
              key: UniqueKey(),
              direction: direction,
              offset: 10,
              child: const _Box(),
            ),
          ),
        ),
      );
      final rest = const Offset(350, 250);
      expect(tester.getTopLeft(find.byType(_Box)) - rest, start, reason: '$direction start');
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(_Box)), rest, reason: '$direction rest');
    }
  });

  testWidgets('inView waits until scrolled into view', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_Host(child: _ScrollPage(controller: controller)));
    await tester.pump(const Duration(seconds: 1));
    expect(_opacity(tester), 0, reason: 'off screen: not revealed');

    controller.jumpTo(700);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
  });

  testWidgets('once: false hides when scrolled out and replays on return', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_Host(child: _ScrollPage(controller: controller, once: false)));
    controller.jumpTo(700);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);

    controller.jumpTo(0);
    await tester.pump();
    await tester.pump();
    expect(_opacity(tester), 0, reason: 'hidden again after leaving');

    controller.jumpTo(700);
    await tester.pump(); // visibility check runs after this frame
    await tester.pump(); // the reveal's first tick
    await tester.pump(const Duration(milliseconds: 100));
    expect(_opacity(tester), inExclusiveRange(0, 1), reason: 'replaying');
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
  });

  testWidgets('once: true stays revealed after scrolling away', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_Host(child: _ScrollPage(controller: controller)));
    controller.jumpTo(700);
    await tester.pump();
    await tester.pumpAndSettle();
    controller.jumpTo(0);
    await tester.pump();
    await tester.pump();
    expect(_opacity(tester), 1);
  });

  testWidgets('shows immediately when the platform reduces motion', (tester) async {
    await tester.pumpWidget(
      const _Host(
        reduceMotion: true,
        child: BlurFade(delay: Duration(seconds: 2), child: _Box()),
      ),
    );
    expect(_opacity(tester), 1);
    expect(_filter(tester).enabled, isFalse);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('disposing before the delay elapses is safe', (tester) async {
    await tester.pumpWidget(
      const _Host(
        child: BlurFade(delay: Duration(seconds: 1), child: _Box()),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
