@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(260, 150);

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
      child: DefaultTextStyle(
        style: _base,
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

/// A small square standing in for an icon.
class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: IconTheme.of(context).color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// A horizontal volume slider, 160 px long.
class _Line extends StatelessWidget {
  const _Line({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return StretchSlider(
      value: value,
      length: 160,
      leading: const _Dot(),
      trailing: const _Dot(),
      onChanged: (_) {},
    );
  }
}

/// A control-center style vertical pill.
class _Pill extends StatelessWidget {
  const _Pill({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return StretchSlider(
      value: value,
      axis: Axis.vertical,
      length: 96,
      thickness: 48,
      activeThickness: 50,
      radius: 16,
      jumpOnTap: false,
      insideTrack: true,
      idleOpacity: 1,
      maxStretch: 24,
      trackColor: const Color(0x1FFFFFFF),
      fillColor: const Color(0xFFF4F4F5),
      leading: const _Dot(),
      onChanged: (_) {},
    );
  }
}

/// Holds a drag past the end at [pull] px beyond the track, then lets go,
/// capturing the frames at [ms] after release.
Future<List<ui.Image>> _pullAndRelease(
  WidgetTester tester, {
  required Widget slider,
  required String name,
  required Offset from,
  required Offset pull,
  required List<int> ms,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(_Frame(boundary: key, label: '$name at rest', child: slider));
  final frames = [await captureBoundary(tester, key)];

  final gesture = await tester.startGesture(from);
  for (var i = 1; i <= 8; i++) {
    await gesture.moveTo(from + pull * (i / 8));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await advance(tester, const Duration(milliseconds: 300));
  await tester.pumpWidget(_Frame(boundary: key, label: '$name, held', child: slider));
  frames.add(await captureBoundary(tester, key));

  await gesture.up();
  var elapsed = 0;
  for (final t in ms) {
    await advance(tester, Duration(milliseconds: t - elapsed));
    elapsed = t;
    await tester.pumpWidget(_Frame(boundary: key, label: 'released, $t ms', child: slider));
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

  testWidgets('StretchSlider stretches past the end and springs back', (tester) async {
    final frames = await _pullAndRelease(
      tester,
      slider: const _Line(value: 1),
      name: 'line',
      // The track spans x = 50..210 on the 75 px centre line.
      from: const Offset(200, 81),
      pull: const Offset(90, 0),
      ms: const [32, 80, 140, 220, 600],
    );
    await expectSheet(tester, frames, 'stretch_slider_line.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('StretchSlider pill stretches upward and springs back', (tester) async {
    final frames = await _pullAndRelease(
      tester,
      slider: const _Pill(value: 0.8),
      name: 'pill',
      from: const Offset(130, 81),
      pull: const Offset(0, -110),
      ms: const [32, 80, 140, 220, 600],
    );
    await expectSheet(tester, frames, 'stretch_slider_pill.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('StretchSlider looks', (tester) async {
    final images = <ui.Image>[];
    for (final (label, slider) in <(String, Widget)>[
      ('outside icons', const _Line(value: 0.62)),
      (
        'signed, thumb, from 0',
        StretchSlider(
          value: -30,
          min: -100,
          max: 100,
          origin: 0,
          thumb: true,
          length: 200,
          thickness: 4,
          idleOpacity: 1,
          onChanged: (_) {},
        ),
      ),
      (
        'divisions with ticks',
        StretchSlider(
          value: 0.25,
          divisions: 8,
          showTicks: true,
          thickness: 10,
          length: 200,
          idleOpacity: 1,
          onChanged: (_) {},
        ),
      ),
      ('inside, vertical', const _Pill(value: 0.35)),
      ('disabled', const StretchSlider(value: 0.4, length: 200, onChanged: null)),
    ]) {
      final key = GlobalKey();
      await tester.pumpWidget(_Frame(boundary: key, label: label, child: slider));
      await tester.pump(const Duration(milliseconds: 500));
      images.add(await captureBoundary(tester, key));
    }
    await expectSheet(tester, images, 'stretch_slider_looks.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
