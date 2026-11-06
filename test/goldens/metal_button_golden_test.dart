@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(440, 150);

final GlobalKey _boundary = GlobalKey();

/// A row of buttons on a light or dark background.
class _Row extends StatelessWidget {
  const _Row({required this.dark, required this.preset, required this.time});

  final bool dark;
  final MetalPreset preset;
  final String time;

  @override
  Widget build(BuildContext context) {
    final ink = dark ? const Color(0xFFF4F4F5) : const Color(0xFF0A0A0A);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: TextStyle(fontFamily: 'Roboto', color: ink),
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: _boundary,
            child: Container(
              width: _size.width,
              height: _size.height,
              color: dark ? const Color(0xFF0E0E10) : const Color(0xFFFFFFFF),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${preset.name}, ${dark ? 'dark' : 'light'}, $time',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final style in MetalButtonStyle.values)
                        MetalButton(
                          preset: preset,
                          style: style,
                          onPressed: () {},
                          child: Text(style.name),
                        ),
                      MetalButton(
                        preset: preset,
                        width: 40,
                        ringWidth: 3,
                        semanticLabel: 'Add',
                        onPressed: () {},
                        child: const Text('+', style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                  const Spacer(),
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

  testWidgets('MetalButton presets and styles', (tester) async {
    final images = <ui.Image>[];
    for (final (dark, preset) in const [
      (false, MetalPreset.chromatic),
      (true, MetalPreset.chromatic),
      (false, MetalPreset.silver),
      (true, MetalPreset.gold),
    ]) {
      await tester.pumpWidget(_Row(dark: dark, preset: preset, time: '0 s'));
      images.add(await captureBoundary(tester, _boundary));
    }
    await expectSheet(tester, images, 'metal_button_looks.png');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('MetalButton ring flows over time', (tester) async {
    final images = <ui.Image>[];
    var elapsed = 0;
    for (final t in const [0, 1500, 3000]) {
      if (elapsed == 0) {
        await tester.pumpWidget(const _Row(dark: true, preset: MetalPreset.chromatic, time: ''));
      }
      await tester.pump(Duration(milliseconds: t - elapsed));
      elapsed = t;
      await tester.pumpWidget(
        _Row(dark: true, preset: MetalPreset.chromatic, time: '${t / 1000} s'),
      );
      images.add(await captureBoundary(tester, _boundary));
    }
    await expectSheet(tester, images, 'metal_button_flow.png');
    await tester.pumpWidget(const SizedBox());
  });
}
