@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(360, 230);

final GlobalKey _boundary = GlobalKey();

const List<List<Color>> _colors = [
  [Color(0xFF6366F1), Color(0xFFEC4899)],
  [Color(0xFF10B981), Color(0xFF3B82F6)],
  [Color(0xFFF59E0B), Color(0xFFEF4444)],
  [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
];

/// A gradient slide with a big number.
class _Slide extends StatelessWidget {
  const _Slide(this.index);

  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(colors: _colors[index])),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'Roboto', color: Color(0xFFF4F4F5)),
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: _boundary,
            child: Container(
              width: _size.width,
              height: _size.height,
              color: const Color(0xFF0E0E10),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SwipeDeck(slides: [for (var i = 0; i < 4; i++) _Slide(i)]),
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

  testWidgets('SwipeDeck follows a drag and snaps to the next slide', (tester) async {
    await tester.pumpWidget(const _Page());
    final frames = <ui.Image>[await captureBoundary(tester, _boundary)];
    final gesture = await tester.startGesture(const Offset(180, 100));
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(-16, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    frames.add(await captureBoundary(tester, _boundary));
    await gesture.up();
    for (final ms in const [80, 600]) {
      await advance(tester, Duration(milliseconds: ms));
      frames.add(await captureBoundary(tester, _boundary));
    }
    await expectSheet(tester, frames, 'swipe_deck_swipe.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
