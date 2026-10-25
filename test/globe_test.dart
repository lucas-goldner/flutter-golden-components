import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 400x400 globe at the top left, optionally reducing motion.
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
          child: SizedBox.square(dimension: 400, child: child),
        ),
      ),
    );
  }
}

const _center = Offset(200, 200);

void main() {
  group('GlobeCountry', () {
    test('looks countries up by ISO code, case-insensitively', () {
      final japan = GlobeCountry.byCode('jpn')!;
      expect(japan.name, 'Japan');
      expect(japan.continent, GlobeContinent.asia);
      expect(japan.center.latitude, closeTo(36.6, 1.5));
      expect(japan.center.longitude, closeTo(138, 2));
      expect(GlobeCountry.byCode('XXX'), isNull);
    });

    test('covers every continent', () {
      expect(GlobeCountry.all.length, greaterThan(200));
      for (final continent in GlobeContinent.values) {
        expect(GlobeCountry.all.where((c) => c.continent == continent), isNotEmpty);
      }
      expect(GlobeCountry.byCode('BRA')!.continent, GlobeContinent.southAmerica);
      expect(GlobeCountry.byCode('FRA')!.continent, GlobeContinent.europe);
    });
  });

  test('highlights match a country or a whole continent', () {
    final france = GlobeCountry.byCode('FRA')!;
    final kenya = GlobeCountry.byCode('KEN')!;
    expect(const GlobeHighlight.country('fra').matches(france), isTrue);
    expect(const GlobeHighlight.country('FRA').matches(kenya), isFalse);
    expect(const GlobeHighlight.continent(GlobeContinent.africa).matches(kenya), isTrue);
    expect(const GlobeHighlight.continent(GlobeContinent.africa).matches(france), isFalse);
  });

  test('arcs, markers and highlights compare by value', () {
    expect(
      const GlobeArc(from: GlobeLatLng(1, 2), to: GlobeLatLng(3, 4)),
      const GlobeArc(from: GlobeLatLng(1, 2), to: GlobeLatLng(3, 4)),
    );
    expect(
      const GlobeMarker(at: GlobeLatLng(1, 2)).hashCode,
      const GlobeMarker(at: GlobeLatLng(1, 2)).hashCode,
    );
    expect(const GlobeHighlight.country('JPN'), const GlobeHighlight.country('JPN'));
  });

  testWidgets('tapping reports the country in front, not the ocean', (tester) async {
    final taps = <GlobeCountry>[];
    await tester.pumpWidget(
      _Host(
        child: Globe(
          autoRotateSpeed: 0,
          initialFocus: GlobeCountry.byCode('FRA')!.center,
          onCountryTap: taps.add,
        ),
      ),
    );
    await tester.tapAt(_center);
    expect(taps.single.code, 'FRA');

    await tester.pumpWidget(
      _Host(
        child: Globe(
          key: UniqueKey(),
          autoRotateSpeed: 0,
          initialFocus: const GlobeLatLng(0, -30), // mid-Atlantic
          onCountryTap: taps.add,
        ),
      ),
    );
    await tester.tapAt(_center);
    expect(taps, hasLength(1));
  });

  testWidgets('the controller turns the globe to a place', (tester) async {
    final controller = GlobeController();
    addTearDown(controller.dispose);
    final taps = <GlobeCountry>[];
    await tester.pumpWidget(
      _Host(
        child: Globe(
          autoRotateSpeed: 0,
          controller: controller,
          initialFocus: const GlobeLatLng(20, 0),
          onCountryTap: taps.add,
        ),
      ),
    );
    controller.focusCountry(
      GlobeCountry.byCode('JPN')!,
      duration: const Duration(milliseconds: 300),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'still turning');
    await tester.pumpAndSettle();
    await tester.tapAt(_center);
    expect(taps.single.code, 'JPN');
  });

  testWidgets('dragging spins the globe with momentum', (tester) async {
    final taps = <GlobeCountry>[];
    await tester.pumpWidget(
      _Host(
        child: Globe(
          autoRotateSpeed: 0,
          initialFocus: GlobeCountry.byCode('FRA')!.center,
          onCountryTap: taps.add,
        ),
      ),
    );
    await tester.fling(find.byType(Globe), const Offset(-120, 0), 800);
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'momentum');
    await tester.pumpAndSettle();
    await tester.tapAt(_center);
    expect(taps.single.code, isNot('FRA'), reason: 'turned east, away from France');
  });

  testWidgets('only ticks while something moves', (tester) async {
    await tester.pumpWidget(const _Host(child: Globe(autoRotateSpeed: 0)));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'nothing to animate');

    await tester.pumpWidget(const _Host(child: Globe(autoRotateSpeed: 10)));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'auto rotation');
  });

  testWidgets('non-looping arcs stop the clock once drawn', (tester) async {
    await tester.pumpWidget(
      const _Host(
        child: Globe(
          autoRotateSpeed: 0,
          loopArcs: false,
          arcDuration: Duration(milliseconds: 500),
          arcs: [GlobeArc(from: GlobeLatLng(51, 0), to: GlobeLatLng(40, -74))],
        ),
      ),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('holds still when the platform reduces motion', (tester) async {
    await tester.pumpWidget(
      const _Host(
        reduceMotion: true,
        child: Globe(
          markers: [GlobeMarker(at: GlobeLatLng(0, 0))],
          arcs: [GlobeArc(from: GlobeLatLng(51, 0), to: GlobeLatLng(40, -74))],
        ),
      ),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
