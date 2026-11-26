@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(360, 220);

final GlobalKey _boundary = GlobalKey();

/// The waves at the golden's size.
class _Frame extends StatelessWidget {
  const _Frame({required this.waves});

  final WaveBackdrop waves;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: _boundary,
          child: SizedBox.fromSize(size: _size, child: waves),
        ),
      ),
    );
  }
}

/// A label and a headline over the waves.
class _Headline extends StatelessWidget {
  const _Headline({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: color),
          ),
          const Spacer(),
          Center(
            child: Text(
              'Ride the wave',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const Spacer(),
        ],
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

  testWidgets('WaveBackdrop flows over time', (tester) async {
    final frames = <ui.Image>[];
    var elapsed = 0;
    for (final t in const [0, 2000, 4000, 6000]) {
      await tester.pumpWidget(
        _Frame(
          waves: WaveBackdrop(
            child: _Headline(label: '${t ~/ 1000} s', color: const Color(0xFFF4F4F5)),
          ),
        ),
      );
      await tester.pump(Duration(milliseconds: t - elapsed));
      elapsed = t;
      frames.add(await captureBoundary(tester, _boundary));
    }
    await expectSheet(tester, frames, 'wave_backdrop_flow.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('WaveBackdrop looks', (tester) async {
    final images = <ui.Image>[];
    for (final waves in const <WaveBackdrop>[
      WaveBackdrop(
        dark: false,
        speed: 0,
        child: _Headline(label: 'light', color: Color(0xFF0B0B12)),
      ),
      WaveBackdrop(
        speed: 0,
        waveWidth: 22,
        blur: 0,
        opacity: 0.8,
        child: _Headline(label: 'thin, sharp', color: Color(0xFFF4F4F5)),
      ),
      WaveBackdrop(
        speed: 0,
        center: 0.8,
        amplitude: 0.2,
        colors: [Color(0xFFF97316), Color(0xFFFBBF24), Color(0xFFF472B6)],
        child: _Headline(label: 'warm, low', color: Color(0xFFF4F4F5)),
      ),
    ]) {
      await tester.pumpWidget(_Frame(waves: waves));
      images.add(await captureBoundary(tester, _boundary));
    }
    await expectSheet(tester, images, 'wave_backdrop_looks.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
