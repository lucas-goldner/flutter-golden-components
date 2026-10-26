import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 200x300 area at the top left, optionally reducing motion.
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
          child: RepaintBoundary(
            key: _boundary,
            child: SizedBox(width: 200, height: 300, child: child),
          ),
        ),
      ),
    );
  }
}

final GlobalKey _boundary = GlobalKey();

/// Alpha (0-255) of the rendered pixel at [p].
Future<int> _alphaAt(WidgetTester tester, Offset p) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  final alpha = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final index = (p.dy.round() * image.width + p.dx.round()) * 4;
    image.dispose();
    return bytes.getUint8(index + 3);
  });
  return alpha!;
}

void main() {
  testWidgets('animates only while it has something to move', (tester) async {
    await tester.pumpWidget(const _Host(child: GooBlobs()));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'wax is moving');

    await tester.pumpWidget(const _Host(child: GooBlobs(speed: 0, followPointer: false)));
    await tester.pump();
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'speed 0');
  });

  testWidgets('holds still when the platform reduces motion', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true, child: GooBlobs()));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('no blobs and no pool paints nothing', (tester) async {
    await tester.pumpWidget(
      const _Host(child: GooBlobs(count: 0, pool: false, followPointer: false)),
    );
    await tester.pump();
    for (final p in const [Offset(100, 150), Offset(20, 280), Offset(180, 20)]) {
      expect(await _alphaAt(tester, p), 0);
    }
  });

  testWidgets('the pool covers the bottom edge', (tester) async {
    await tester.pumpWidget(const _Host(child: GooBlobs(count: 0, followPointer: false)));
    await tester.pump();
    expect(await _alphaAt(tester, const Offset(100, 297)), greaterThan(200));
    expect(await _alphaAt(tester, const Offset(100, 100)), 0);
  });

  testWidgets('a blob follows the pointer and leaves with it', (tester) async {
    await tester.pumpWidget(const _Host(child: GooBlobs(count: 0, pool: false, speed: 0)));
    await tester.pump();
    const spot = Offset(100, 120);
    expect(await _alphaAt(tester, spot), 0);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(400, 400));
    await mouse.moveTo(spot);
    await tester.pump();
    expect(await _alphaAt(tester, spot), greaterThan(200));

    await mouse.moveTo(const Offset(400, 400));
    await tester.pump();
    expect(await _alphaAt(tester, spot), 0);
    await mouse.removePointer();
  });

  testWidgets('an empty color list falls back to the defaults', (tester) async {
    await tester.pumpWidget(const _Host(child: GooBlobs(colors: [], speed: 0)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(GooBlobs.defaultColors, isNotEmpty);
  });
}
