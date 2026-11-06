@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(420, 220);

final GlobalKey _boundary = GlobalKey();

const List<Color> _colors = [
  Color(0xFFFF6F91),
  Color(0xFF7FB2FF),
  Color(0xFF3DE07A),
  Color(0xFFFFB86B),
  Color(0xFFA18CD1),
  Color(0xFF4FACFE),
  Color(0xFFF6D365),
  Color(0xFF5EE7DF),
  Color(0xFFFA709A),
  Color(0xFF30CFD0),
];

/// A ten-card carousel.
class _Frame extends StatelessWidget {
  const _Frame();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: _boundary,
          child: SizedBox.fromSize(
            size: _size,
            child: CylinderCarousel(
              height: _size.height,
              circumference: 900,
              cards: [
                for (final (i, c) in _colors.indexed)
                  ColoredBox(
                    color: c,
                    child: Center(
                      child: Text(
                        '$i',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = _size;
    view.devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset());

  testWidgets('CylinderCarousel spins with a drag and settles on a card', (tester) async {
    await tester.pumpWidget(const _Frame());
    final frames = <ui.Image>[await captureBoundary(tester, _boundary)];
    final gesture = await tester.startGesture(const Offset(210, 110));
    for (var i = 1; i <= 12; i++) {
      await gesture.moveBy(const Offset(-10, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    frames.add(await captureBoundary(tester, _boundary));
    await gesture.up();
    var elapsed = 0;
    for (final t in const [80, 200, 900]) {
      await advance(tester, Duration(milliseconds: t - elapsed));
      elapsed = t;
      frames.add(await captureBoundary(tester, _boundary));
    }
    await expectSheet(tester, frames, 'cylinder_carousel_spin.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
