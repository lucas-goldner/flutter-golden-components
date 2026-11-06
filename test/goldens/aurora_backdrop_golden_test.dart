@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(360, 220);

final GlobalKey _boundary = GlobalKey();

/// An aurora with a headline, labelled.
class _Frame extends StatelessWidget {
  const _Frame({required this.label, required this.aurora});

  final String label;
  final AuroraBackdrop aurora;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: _boundary,
          child: SizedBox.fromSize(size: _size, child: aurora),
        ),
      ),
    );
  }
}

/// Headline text over the aurora.
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
          Text(
            'Background lights\nare cool you know.',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: color,
            ),
          ),
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

  testWidgets('AuroraBackdrop drifts over time', (tester) async {
    final frames = <ui.Image>[];
    var elapsed = 0;
    for (final t in const [0, 4000, 8000, 12000]) {
      if (elapsed == 0) {
        await tester.pumpWidget(
          _Frame(
            label: '',
            aurora: const AuroraBackdrop(
              child: _Headline(label: 'light', color: Color(0xFF0B0B12)),
            ),
          ),
        );
      }
      await tester.pump(Duration(milliseconds: t - elapsed));
      elapsed = t;
      await tester.pumpWidget(
        _Frame(
          label: '',
          aurora: AuroraBackdrop(
            child: _Headline(label: 'light, ${t ~/ 1000} s', color: const Color(0xFF0B0B12)),
          ),
        ),
      );
      frames.add(await captureBoundary(tester, _boundary));
    }
    await expectSheet(tester, frames, 'aurora_backdrop_drift.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('AuroraBackdrop looks', (tester) async {
    final images = <ui.Image>[];
    for (final (label, aurora) in const <(String, AuroraBackdrop)>[
      (
        'dark',
        AuroraBackdrop(
          dark: true,
          speed: 0,
          child: _Headline(label: 'dark', color: Color(0xFFF4F4F5)),
        ),
      ),
      (
        'warm, focus left',
        AuroraBackdrop(
          speed: 0,
          focus: Alignment(-0.9, -1),
          colors: [Color(0xFFF97316), Color(0xFFFBBF24), Color(0xFFF472B6), Color(0xFFFDE68A)],
          child: _Headline(label: 'warm, focus left', color: Color(0xFF0B0B12)),
        ),
      ),
      (
        'no blur',
        AuroraBackdrop(
          speed: 0,
          blur: 0,
          child: _Headline(label: 'no blur', color: Color(0xFF0B0B12)),
        ),
      ),
    ]) {
      await tester.pumpWidget(_Frame(label: label, aurora: aurora));
      images.add(await captureBoundary(tester, _boundary));
    }
    await expectSheet(tester, images, 'aurora_backdrop_looks.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
