@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(240, 120);

const TextStyle _base = TextStyle(fontFamily: 'Roboto', color: Color(0xFFF4F4F5));

/// A dark, labelled frame with [child] centred in it.
class _Frame extends StatelessWidget {
  const _Frame({required this.boundary, required this.label, required this.child});

  final Key boundary;
  final String label;
  final Widget child;

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
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _base.copyWith(fontSize: 11, color: const Color(0xFFA1A1AA))),
                Expanded(
                  child: Center(
                    child: DefaultTextStyle(
                      style: _base.copyWith(fontSize: 44, fontWeight: FontWeight.w600),
                      child: child,
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

/// Up and down rolls of the same change, one above the other.
class _Directions extends StatelessWidget {
  const _Directions({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 28,
      children: [
        for (final direction in const [DigitRollDirection.up, DigitRollDirection.down])
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DigitRoll(value: value, rollOnMount: false, direction: direction),
              Text(direction.name, style: _base.copyWith(fontSize: 10)),
            ],
          ),
      ],
    );
  }
}

/// Shows [before], switches to [after] and captures the roll at each of
/// [ms] milliseconds.
Future<List<ui.Image>> _timeline(
  WidgetTester tester, {
  required String change,
  required Widget before,
  required Widget after,
  required List<int> ms,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(_Frame(boundary: key, label: change, child: before));
  await tester.pumpWidget(_Frame(boundary: key, label: change, child: after));
  final frames = <ui.Image>[];
  var elapsed = 0;
  for (final t in ms) {
    await advance(tester, Duration(milliseconds: t - elapsed));
    elapsed = t;
    await tester.pumpWidget(_Frame(boundary: key, label: '$change, $t ms', child: after));
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

  testWidgets('DigitRoll ripples from the ones place outward', (tester) async {
    final frames = await _timeline(
      tester,
      change: '1284 to 1290',
      before: const DigitRoll(value: 1284, rollOnMount: false),
      after: const DigitRoll(value: 1290, rollOnMount: false),
      ms: const [0, 48, 96, 160, 240, 360, 600, 1500],
    );
    await expectSheet(tester, frames, 'digit_roll_ripple.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('DigitRoll grows new places in and shrinks old ones away', (tester) async {
    final grow = await _timeline(
      tester,
      change: '999 to 1000',
      before: const DigitRoll(value: 999, rollOnMount: false),
      after: const DigitRoll(value: 1000, rollOnMount: false),
      ms: const [0, 64, 144, 256, 1500],
    );
    final shrink = await _timeline(
      tester,
      change: '1000 to 5',
      before: const DigitRoll(value: 1000, rollOnMount: false),
      after: const DigitRoll(value: 5, rollOnMount: false),
      ms: const [0, 96, 192, 320, 1500],
    );
    await expectSheet(tester, grow, 'digit_roll_grow.png', axis: Axis.horizontal);
    await expectSheet(tester, shrink, 'digit_roll_shrink.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('DigitRoll directions: the same change rolled up and down', (tester) async {
    final frames = await _timeline(
      tester,
      change: '3 to 4',
      before: const _Directions(value: 3),
      after: const _Directions(value: 4),
      ms: const [0, 80, 160, 280, 1500],
    );
    await expectSheet(tester, frames, 'digit_roll_directions.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('DigitRoll formats and looks', (tester) async {
    final images = <ui.Image>[];
    for (final (label, roll) in [
      (
        'grouping',
        const DigitRoll(value: 1234567, rollOnMount: false, style: TextStyle(fontSize: 32)),
      ),
      (
        'price, 2 decimals',
        const DigitRoll(
          value: 1249.5,
          rollOnMount: false,
          format: DigitRollFormat(prefix: r'$', decimals: 2),
          style: TextStyle(fontSize: 34),
        ),
      ),
      (
        'negative, suffix',
        const DigitRoll(value: -42, rollOnMount: false, format: DigitRollFormat(suffix: '%')),
      ),
      (
        'tiles, min 2 digits',
        DigitRoll(
          value: 7,
          rollOnMount: false,
          format: const DigitRollFormat(minDigits: 2),
          spacing: 6,
          digitPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          digitDecoration: BoxDecoration(
            color: const Color(0xFF1F1F26),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
        ),
      ),
    ]) {
      final key = GlobalKey();
      await tester.pumpWidget(_Frame(boundary: key, label: label, child: roll));
      images.add(await captureBoundary(tester, key));
    }
    await expectSheet(tester, images, 'digit_roll_looks.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('DigitRoll spins once on mount', (tester) async {
    final key = GlobalKey();
    final frames = <ui.Image>[];
    var elapsed = 0;
    for (final t in const [0, 80, 160, 280, 440, 1500]) {
      await advance(tester, Duration(milliseconds: t - elapsed));
      elapsed = t;
      await tester.pumpWidget(
        _Frame(boundary: key, label: 'mount, $t ms', child: const DigitRoll(value: 2048)),
      );
      frames.add(await captureBoundary(tester, key));
    }
    await expectSheet(tester, frames, 'digit_roll_intro.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
