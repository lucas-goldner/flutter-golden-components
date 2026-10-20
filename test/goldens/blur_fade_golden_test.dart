@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const List<List<Color>> _gradients = [
  [Color(0xFFFDE68A), Color(0xFFB7800A)],
  [Color(0xFF93C5FD), Color(0xFF1D4ED8)],
  [Color(0xFFF9A8D4), Color(0xFFBE185D)],
  [Color(0xFF6EE7B7), Color(0xFF047857)],
  [Color(0xFFC4B5FD), Color(0xFF6D28D9)],
  [Color(0xFFFDBA74), Color(0xFFC2410C)],
];

const TextStyle _small = TextStyle(
  fontFamily: 'Roboto',
  fontSize: 10,
  fontWeight: FontWeight.w500,
  color: Color(0xFFA1A1AA),
);

/// A gradient tile with a bold label.
class _Tile extends StatelessWidget {
  const _Tile({required this.index, required this.label, this.size = 72});

  final int index;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradients[index % _gradients.length],
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}

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
            width: 470,
            color: const Color(0xFF0E0E10),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _small.copyWith(fontSize: 11)),
                const SizedBox(height: 14),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One reveal per direction, plus a scale-in, side by side.
class _Directions extends StatelessWidget {
  const _Directions();

  @override
  Widget build(BuildContext context) {
    const variants = <(String, BlurFade)>[
      ('down', BlurFade(offset: 16, child: _Tile(index: 0, label: 'D', size: 60))),
      (
        'up',
        BlurFade(
          offset: 16,
          direction: BlurFadeDirection.up,
          child: _Tile(index: 1, label: 'U', size: 60),
        ),
      ),
      (
        'left',
        BlurFade(
          offset: 16,
          direction: BlurFadeDirection.left,
          child: _Tile(index: 2, label: 'L', size: 60),
        ),
      ),
      (
        'right',
        BlurFade(
          offset: 16,
          direction: BlurFadeDirection.right,
          child: _Tile(index: 3, label: 'R', size: 60),
        ),
      ),
      (
        'scale 0.8',
        BlurFade(offset: 0, scale: 0.8, blur: 10, child: _Tile(index: 4, label: 'S', size: 60)),
      ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (label, fade) in variants)
          Column(
            children: [
              SizedBox(width: 80, height: 88, child: Center(child: fade)),
              const SizedBox(height: 6),
              Text(label, style: _small),
            ],
          ),
      ],
    );
  }
}

/// Six tiles revealed with an 80 ms stagger.
class _Stagger extends StatelessWidget {
  const _Stagger();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 6; i++)
          BlurFade(
            delay: Duration(milliseconds: 80 * i),
            offset: 12,
            child: _Tile(index: i, label: '${i + 1}'),
          ),
      ],
    );
  }
}

/// Pumps [child] and captures it at each of [times] (ms since mount).
Future<List<ui.Image>> _timeline(
  WidgetTester tester, {
  required Widget child,
  required String label,
  required List<int> times,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(_Frame(boundary: key, label: '$label, t = 0 ms', child: child));
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

  testWidgets('BlurFade directions over time (400 ms, ease out)', (tester) async {
    final frames = await _timeline(
      tester,
      child: const _Directions(),
      label: 'Reveal by direction',
      times: const [0, 64, 128, 224, 448],
    );
    await expectSheet(tester, frames, 'blur_fade_directions.png');
  });

  testWidgets('BlurFade staggered group', (tester) async {
    final frames = await _timeline(
      tester,
      child: const _Stagger(),
      label: 'Stagger, 80 ms apart',
      times: const [0, 160, 320, 480, 880],
    );
    await expectSheet(tester, frames, 'blur_fade_stagger.png');
  });
}
