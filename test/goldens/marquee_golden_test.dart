@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const List<String> _tags = ['Flutter', 'Dart', 'Widgets', 'Animation', 'Physics', 'Gestures'];

const List<Color> _colors = [
  Color(0xFFF5C451),
  Color(0xFF60A5FA),
  Color(0xFFF472B6),
  Color(0xFF34D399),
  Color(0xFFFB923C),
  Color(0xFFA78BFA),
];

/// A pill with a colored dot.
class _Tag extends StatelessWidget {
  const _Tag(this.index);

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _colors[index], shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            _tags[index],
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFF4F4F5),
            ),
          ),
        ],
      ),
    );
  }
}

const List<Widget> _row = [_Tag(0), _Tag(1), _Tag(2), _Tag(3), _Tag(4), _Tag(5)];

/// A labelled dark card holding [child], captured as one frame.
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
            color: const Color(0xFF0E0E10),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two rows running in opposite directions with faded edges.
class _TwoRows extends StatelessWidget {
  const _TwoRows();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 440,
      child: Column(
        spacing: 10,
        children: [
          Marquee(speed: 60, gap: 10, fadeExtent: 48, children: _row),
          Marquee(speed: 60, gap: 10, fadeExtent: 48, reverse: true, children: _row),
        ],
      ),
    );
  }
}

/// A vertical strip.
class _Column extends StatelessWidget {
  const _Column();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Marquee(axis: Axis.vertical, speed: 60, gap: 8, fadeExtent: 32, children: _row),
    );
  }
}

/// Pumps [child] and captures it at each of [times] (milliseconds), with a
/// per-frame label; [before] runs once after the first frame.
Future<List<ui.Image>> _timeline(
  WidgetTester tester, {
  required Widget child,
  required String label,
  required List<int> times,
  Future<void> Function()? before,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(_Frame(boundary: key, label: '$label, t = 0 ms', child: child));
  await tester.pump();
  await before?.call();
  final frames = <ui.Image>[];
  var elapsed = 0;
  for (final t in times) {
    await advance(tester, Duration(milliseconds: t - elapsed));
    elapsed = t;
    await tester.pumpWidget(_Frame(boundary: key, label: '$label, t = $t ms', child: child));
    frames.add(await captureBoundary(tester, key));
  }
  return frames;
}

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(480, 300);
    view.devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset());

  testWidgets('Marquee rows over time (forward and reverse, faded edges)', (tester) async {
    final frames = await _timeline(
      tester,
      child: const _TwoRows(),
      label: '60 px/s, top forward, bottom reverse',
      times: const [0, 500, 1000, 2000],
    );
    await expectSheet(tester, frames, 'marquee_rows.png');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Marquee vertical over time', (tester) async {
    final frames = await _timeline(
      tester,
      child: const _Column(),
      label: 'vertical',
      times: const [0, 600, 1200, 1800],
    );
    await expectSheet(tester, frames, 'marquee_vertical.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Marquee eases to a stop on hover', (tester) async {
    TestGesture? mouse;
    final frames = await _timeline(
      tester,
      child: const SizedBox(
        width: 440,
        child: Marquee(speed: 120, gap: 10, pauseOnHover: true, children: _row),
      ),
      label: 'hovered at t = 0 (120 px/s)',
      times: const [0, 80, 200, 400, 1000],
      before: () async {
        mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse!.addPointer(location: const Offset(200, 40));
      },
    );
    await mouse!.removePointer();
    await expectSheet(tester, frames, 'marquee_hover_pause.png');
    await tester.pumpWidget(const SizedBox());
  });
}
