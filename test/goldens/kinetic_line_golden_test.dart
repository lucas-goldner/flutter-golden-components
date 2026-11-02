@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(300, 100);

const TextStyle _base = TextStyle(fontFamily: 'Roboto', color: Color(0xFFF4F4F5));

/// A dark, labelled frame with the line centred in it.
class _Frame extends StatelessWidget {
  const _Frame({required this.boundary, required this.label, required this.child});

  final Key boundary;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: _base.copyWith(fontSize: 28, fontWeight: FontWeight.w500),
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: boundary,
            child: Container(
              width: _size.width,
              height: _size.height,
              color: const Color(0xFF0E0E10),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: _base.copyWith(fontSize: 11, color: const Color(0xFFA1A1AA))),
                  Expanded(child: Center(child: child)),
                ],
              ),
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

  testWidgets('KineticLine builds, holds and lifts out', (tester) async {
    // speed 1: first 340, push 430 (x2), hold 980, exit 260 ms.
    const line = KineticLine(
      speed: 1,
      phrases: [
        ['Builds', 'one', 'line'],
        ['Next', 'phrase'],
      ],
    );
    final key = GlobalKey();
    final frames = <ui.Image>[];
    var elapsed = 0;
    for (final (t, what) in const [
      (120, 'first word'),
      (500, 'push'),
      (560, 'push'),
      (900, 'push'),
      (1300, 'built'),
      (2300, 'exit'),
      (2500, 'gone'),
    ]) {
      if (elapsed == 0) await tester.pumpWidget(_Frame(boundary: key, label: '', child: line));
      await advance(tester, Duration(milliseconds: t - elapsed));
      elapsed = t;
      await tester.pumpWidget(_Frame(boundary: key, label: '$what, $t ms', child: line));
      frames.add(await captureBoundary(tester, key));
    }
    await expectSheet(tester, frames, 'kinetic_line_build.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
