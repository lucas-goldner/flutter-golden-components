import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 300 px wide notched card centred on an 800x600 screen.
class _Host extends StatelessWidget {
  const _Host({this.reduceMotion = false, this.onHover});

  final bool reduceMotion;
  final ValueChanged<bool>? onHover;

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
              width: 300,
              child: NotchCard(
                onHoverChanged: onHover,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NotchCardMedia(
                      height: 160,
                      labels: [NotchLabel(corner: NotchCorner.bottomLeft, child: Text('FEATURED'))],
                      child: ColoredBox(color: Color(0xFF336699)),
                    ),
                    NotchCardStagger(children: [Text('Title'), Text('Body')]),
                    NotchCardReveal(child: Text('Read more')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _opacityOf(WidgetTester tester, String text) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(of: find.text(text), matching: find.byType(AnimatedOpacity)),
    )
    .opacity;

void main() {
  testWidgets('hovering zooms the media and reveals the action', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(_Host(onHover: changes.add));
    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'Read more'), 0);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Title')));
    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'Read more'), 1);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1.05);

    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'Read more'), 0);
    expect(changes, [true, false]);
    await mouse.removePointer();
  });

  testWidgets('a tap toggles hover for touch', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(_Host(onHover: changes.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'Read more'), 1);
    expect(changes, [true]);
  });

  testWidgets('the stagger brings the text in, and the label renders', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    final early = tester.widget<Opacity>(
      find.ancestor(of: find.text('Body'), matching: find.byType(Opacity)).first,
    );
    expect(early.opacity, lessThan(1));
    await tester.pumpAndSettle();
    expect(find.text('FEATURED'), findsOneWidget);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(of: find.text('Body'), matching: find.byType(Opacity)).first,
          )
          .opacity,
      1,
    );
  });

  testWidgets('no zoom and no entrance when motion is reduced', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true));
    await tester.pump();
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.tap(find.text('Title'));
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });
}
