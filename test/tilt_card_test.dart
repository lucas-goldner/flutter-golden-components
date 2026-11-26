import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

const Key _layer = Key('layer');

/// A 300x200 tilt card centred on an 800x600 screen.
class _Host extends StatelessWidget {
  const _Host({this.reduceMotion = false, this.onTap});

  final bool reduceMotion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: TiltCard(
            onTap: onTap,
            child: const SizedBox(
              width: 300,
              height: 200,
              child: Center(
                child: TiltLayer(depth: 20, child: SizedBox(key: _layer, width: 40, height: 40)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The card's current transform.
Matrix4 _matrix(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(of: find.byType(TiltCard), matching: find.byType(Transform)).first,
    )
    .transform;

/// Whether the card is flat: no rotation terms (perspective aside).
bool _flat(WidgetTester tester) {
  final m = _matrix(tester);
  return m.entry(0, 2).abs() < 1e-6 && m.entry(1, 2).abs() < 1e-6 && m.entry(2, 1).abs() < 1e-6;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 200 && tester.binding.hasScheduledFrame; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('tilts toward the pointer and settles flat when it leaves', (tester) async {
    await tester.pumpWidget(const _Host());
    final rest = tester.getCenter(find.byKey(_layer));
    expect(_flat(tester), isTrue);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    // Top-right corner of the card.
    await mouse.moveTo(const Offset(540, 210));
    await _settle(tester);
    expect(_flat(tester), isFalse);
    final moved = tester.getCenter(find.byKey(_layer));
    expect(moved.dx, lessThan(rest.dx - 10), reason: 'the layer shifts away from the pointer');
    expect(moved.dy, greaterThan(rest.dy + 5));
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'stops once settled');

    await mouse.moveTo(Offset.zero);
    await _settle(tester);
    expect(_flat(tester), isTrue);
    await mouse.removePointer();
  });

  testWidgets('follows a finger and still taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_Host(onTap: () => taps++));
    final gesture = await tester.startGesture(const Offset(400, 300));
    await gesture.moveTo(const Offset(260, 390));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_flat(tester), isFalse);
    await gesture.up();
    await _settle(tester);
    expect(_flat(tester), isTrue);
    await tester.tap(find.byType(TiltCard));
    expect(taps, 1);
  });

  testWidgets('stays flat when motion is reduced', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(const Offset(540, 210));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(_flat(tester), isTrue);
    await mouse.removePointer();
  });
}
