@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(360, 380);

/// A labelled square card holding a globe.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.boundary,
    required this.label,
    required this.globe,
    this.dark = false,
  });

  final Key boundary;
  final String label;
  final Globe globe;
  final bool dark;

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
            color: dark ? const Color(0xFF0E0E10) : const Color(0xFFFFFFFF),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: dark ? const Color(0xFFA1A1AA) : const Color(0xFF6B6B74),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(child: globe),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

GlobeLatLng _center(String code) => GlobeCountry.byCode(code)!.center;

final List<GlobeArc> _arcs = [
  GlobeArc(from: _center('GBR'), to: _center('USA')),
  GlobeArc(from: _center('DEU'), to: _center('IND'), color: const Color(0xFF60A5FA)),
  GlobeArc(from: _center('FRA'), to: _center('ZAF'), color: const Color(0xFFF472B6)),
  GlobeArc(from: _center('EGY'), to: _center('BRA'), color: const Color(0xFF34D399)),
];

/// Pumps one still globe and captures it.
Future<ui.Image> _still(WidgetTester tester, String label, Globe globe, {bool dark = false}) async {
  final key = GlobalKey();
  await tester.pumpWidget(_Frame(boundary: key, label: label, globe: globe, dark: dark));
  await tester.pump();
  final image = await captureBoundary(tester, key);
  await tester.pumpWidget(const SizedBox());
  return image;
}

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = _size;
    view.devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset());

  testWidgets('Globe looks and highlights', (tester) async {
    final images = [
      await _still(
        tester,
        'Default, facing 25°N 15°E',
        const Globe(autoRotateSpeed: 0, interactive: false),
      ),
      await _still(
        tester,
        'Europe, Japan and India highlighted',
        const Globe(
          autoRotateSpeed: 0,
          interactive: false,
          initialFocus: GlobeLatLng(35, 85),
          highlights: [
            GlobeHighlight.continent(GlobeContinent.europe),
            GlobeHighlight.country('JPN', color: Color(0xFFF472B6)),
            GlobeHighlight.country('IND', color: Color(0xFF60A5FA)),
          ],
          markers: [GlobeMarker(at: GlobeLatLng(35.68, 139.69), pulse: false)],
        ),
      ),
      await _still(
        tester,
        'Dark, Americas, glow',
        const Globe(
          autoRotateSpeed: 0,
          interactive: false,
          initialFocus: GlobeLatLng(10, -80),
          sphereColor: Color(0xFF1C1C22),
          shadeColor: Color(0xFF09090B),
          dotColor: Color(0xFFD4D4D8),
          glowColor: Color(0x66F5C451),
          highlights: [GlobeHighlight.continent(GlobeContinent.southAmerica)],
        ),
        dark: true,
      ),
    ];
    await expectSheet(tester, images, 'globe_styles.png', axis: Axis.horizontal);
  });

  testWidgets('Globe arcs draw from start to end with a plane', (tester) async {
    final key = GlobalKey();
    final globe = Globe(
      autoRotateSpeed: 0,
      interactive: false,
      initialFocus: const GlobeLatLng(30, 10),
      arcs: _arcs,
      arcStagger: const Duration(milliseconds: 300),
    );
    await tester.pumpWidget(_Frame(boundary: key, label: 't = 0', globe: globe));
    await tester.pump();
    final frames = <ui.Image>[];
    var elapsed = 0;
    for (final t in const [400, 900, 1500, 2400, 3400]) {
      await advance(tester, Duration(milliseconds: t - elapsed));
      elapsed = t;
      await tester.pumpWidget(_Frame(boundary: key, label: 't = $t ms', globe: globe));
      frames.add(await captureBoundary(tester, key));
    }
    await expectSheet(tester, frames, 'globe_arcs.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
