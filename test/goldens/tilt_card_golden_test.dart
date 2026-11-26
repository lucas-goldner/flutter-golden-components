@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(300, 260);

final GlobalKey _boundary = GlobalKey();

const TextStyle _base = TextStyle(fontFamily: 'Roboto', color: Color(0xFFFFFFFF));

/// A gradient card with a floating title and badge.
class _Page extends StatelessWidget {
  const _Page({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: _boundary,
          child: Container(
            width: _size.width,
            height: _size.height,
            color: const Color(0xFF0E0E10),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _base.copyWith(fontSize: 11, color: const Color(0xFFA1A1AA))),
                Expanded(
                  child: Center(
                    child: TiltCard(
                      maxTilt: 16,
                      child: Container(
                        width: 200,
                        height: 170,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TiltLayer(
                              depth: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0x33FFFFFF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('NEW', style: _base.copyWith(fontSize: 10)),
                              ),
                            ),
                            const Spacer(),
                            TiltLayer(
                              depth: 22,
                              child: Text(
                                'Floating\ntitle',
                                style: _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
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

  testWidgets('TiltCard tilts toward the pointer', (tester) async {
    final images = <ui.Image>[];
    await tester.pumpWidget(const _Page(label: 'at rest'));
    images.add(await captureBoundary(tester, _boundary));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    for (final (label, at) in const [
      ('pointer top left', Offset(60, 60)),
      ('pointer top right', Offset(245, 60)),
      ('pointer bottom right', Offset(245, 220)),
      ('pointer bottom left', Offset(60, 220)),
    ]) {
      await mouse.moveTo(at);
      await advance(tester, const Duration(milliseconds: 800));
      await tester.pumpWidget(_Page(label: label));
      images.add(await captureBoundary(tester, _boundary));
    }
    await mouse.removePointer();
    await expectSheet(tester, images, 'tilt_card_tilt.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
