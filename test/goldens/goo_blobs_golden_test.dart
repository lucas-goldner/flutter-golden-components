@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(200, 330);

/// A dark, lamp-shaped backdrop with a label.
class _Frame extends StatelessWidget {
  const _Frame({required this.boundary, required this.label, required this.goo});

  final Key boundary;
  final String label;
  final Widget goo;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: boundary,
          child: Container(
            width: _size.width,
            height: _size.height,
            color: const Color(0xFF0E0E10),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA1A1AA),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1B0B2E), Color(0xFF3A0D2E)],
                        ),
                      ),
                      child: goo,
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

/// Pumps [goo] and captures it at each of [seconds].
Future<List<ui.Image>> _timeline(
  WidgetTester tester, {
  required Widget goo,
  required String label,
  required List<int> seconds,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(_Frame(boundary: key, label: label, goo: goo));
  await tester.pump();
  final frames = <ui.Image>[];
  var elapsed = 0;
  for (final t in seconds) {
    // Coarse steps are fine: the physics clamps each step to 50 ms.
    for (var i = elapsed * 20; i < t * 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    elapsed = t;
    await tester.pumpWidget(_Frame(boundary: key, label: '$label, t = $t s', goo: goo));
    frames.add(await captureBoundary(tester, key));
  }
  return frames;
}

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = _size;
    view.devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset());

  testWidgets('GooBlobs rise, merge and sink like a lava lamp', (tester) async {
    final frames = await _timeline(
      tester,
      goo: const GooBlobs(followPointer: false),
      label: 'Lava',
      seconds: const [0, 3, 6, 9, 12, 15],
    );
    await expectSheet(tester, frames, 'goo_blobs_lava.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('GooBlobs gooeyness and glow', (tester) async {
    final images = <ui.Image>[];
    for (final (label, goo) in const [
      ('gooeyness 0, no glow', GooBlobs(followPointer: false, gooeyness: 0, glow: 0, speed: 0)),
      ('gooeyness 1, glow 0.6', GooBlobs(followPointer: false, speed: 0)),
      ('gooeyness 2, glow 1', GooBlobs(followPointer: false, gooeyness: 2, glow: 1, speed: 0)),
      (
        'neon colors',
        GooBlobs(
          followPointer: false,
          speed: 0,
          colors: [Color(0xFF00F5D4), Color(0xFF00BBF9), Color(0xFF9B5DE5)],
        ),
      ),
    ]) {
      final key = GlobalKey();
      await tester.pumpWidget(_Frame(boundary: key, label: label, goo: goo));
      await tester.pump();
      images.add(await captureBoundary(tester, key));
    }
    await expectSheet(tester, images, 'goo_blobs_looks.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
