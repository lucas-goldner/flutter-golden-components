import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

const Key _image0 = Key('image0');
const Key _image1 = Key('image1');

const List<ImageHoverItem> _items = [
  ImageHoverItem(
    title: 'About',
    subtitle: 'Learn what we do here',
    image: ColoredBox(key: _image0, color: Color(0xFF3B82F6)),
  ),
  ImageHoverItem(
    title: 'Clients',
    subtitle: 'We work with great people',
    image: ColoredBox(key: _image1, color: Color(0xFFEF4444)),
  ),
];

/// A 600 px wide list at the top of an 800x600 screen.
class _Host extends StatelessWidget {
  const _Host({this.onTap, this.reduceMotion = false});

  final ValueChanged<int>? onTap;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xFF18181B)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 600,
              child: ImageHoverList(items: _items, onTap: onTap),
            ),
          ),
        ),
      ),
    );
  }
}

Future<TestGesture> _mouse(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: const Offset(790, 590));
  addTearDown(gesture.removePointer);
  return gesture;
}

void main() {
  testWidgets('hovering a link shows its image under the pointer', (tester) async {
    await tester.pumpWidget(const _Host());
    expect(find.byKey(_image0), findsNothing);

    final mouse = await _mouse(tester);
    final spot = tester.getCenter(find.text('A'));
    await mouse.moveTo(spot);
    await tester.pumpAndSettle();
    expect(find.byKey(_image0), findsOneWidget);
    expect(tester.getCenter(find.byKey(_image0)), offsetMoreOrLessEquals(spot, epsilon: 1));

    // Moving on, the image trails behind, then catches up.
    await mouse.moveTo(spot + const Offset(200, 0));
    await tester.pump(const Duration(milliseconds: 32));
    expect(tester.getCenter(find.byKey(_image0)).dx, lessThan(spot.dx + 190));
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.byKey(_image0)),
      offsetMoreOrLessEquals(spot + const Offset(200, 0), epsilon: 1),
    );

    // The next link swaps its image in.
    await mouse.moveTo(tester.getCenter(find.text('C')));
    await tester.pumpAndSettle();
    expect(find.byKey(_image1), findsOneWidget);
    expect(find.byKey(_image0), findsNothing);

    await mouse.moveTo(const Offset(790, 590));
    await tester.pumpAndSettle();
    expect(find.byKey(_image1), findsNothing, reason: 'hidden once the pointer leaves');
  });

  testWidgets('the hovered title slides over and the arrow appears', (tester) async {
    await tester.pumpWidget(const _Host());
    final restX = tester.getTopLeft(find.text('A')).dx;
    final mouse = await _mouse(tester);
    await mouse.moveTo(tester.getCenter(find.text('A')));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('A')).dx, closeTo(restX + 14, 0.5));
    expect(tester.getTopLeft(find.text('C')).dx, closeTo(restX, 0.5));
  });

  testWidgets('taps, touches and the keyboard activate links', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(_Host(onTap: taps.add));
    await tester.tap(find.text('C'));
    expect(taps, [1]);

    // A finger held down shows the image until it lifts.
    final finger = await tester.startGesture(tester.getCenter(find.text('A')));
    await tester.pumpAndSettle();
    expect(find.byKey(_image0), findsOneWidget);
    await finger.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_image0), findsNothing);

    Focus.of(tester.element(find.text('A'))).requestFocus();
    await tester.pumpAndSettle();
    expect(find.byKey(_image0), findsOneWidget, reason: 'focus shows the image');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, [1, 0]);
  });

  testWidgets('reduced motion: no lag, no slide', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true));
    final restX = tester.getTopLeft(find.text('A')).dx;
    final mouse = await _mouse(tester);
    final spot = tester.getCenter(find.text('A'));
    await mouse.moveTo(spot);
    await tester.pump();
    expect(tester.getCenter(find.byKey(_image0)), offsetMoreOrLessEquals(spot, epsilon: 0.5));
    expect(tester.getTopLeft(find.text('A')).dx, restX);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('describes links to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_Host(onTap: (_) {}));
    expect(find.bySemanticsLabel('About, Learn what we do here'), findsOneWidget);
    expect(find.bySemanticsLabel('Clients, We work with great people'), findsOneWidget);
    handle.dispose();
  });
}
