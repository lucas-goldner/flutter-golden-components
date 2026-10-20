@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_gallery/gallery/code_view.dart';
import 'package:golden_gallery/gallery/registry.dart';
import 'package:golden_gallery/main.dart';

/// Screen sizes every page is captured at.
const Map<String, Size> _screens = {'desktop': Size(1400, 900), 'phone': Size(390, 844)};

Future<void> _pumpGallery(
  WidgetTester tester, {
  required Size size,
  required Brightness brightness,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  // Reduce motion so endlessly animating components (marquee) hold still
  // and the captures are deterministic.
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
    disableAnimations: true,
  );
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(const GalleryApp(fontFamily: 'Roboto'));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, GalleryComponent component) async {
  final card = find.text(component.name).last;
  // Cards further down the home page are below the fold on phones.
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

void main() {
  for (final MapEntry(key: screen, value: size) in _screens.entries) {
    for (final brightness in Brightness.values) {
      final suffix = '${screen}_${brightness.name}';

      testWidgets('home ($suffix)', (tester) async {
        await _pumpGallery(tester, size: size, brightness: brightness);
        await expectLater(find.byType(GalleryApp), matchesGoldenFile('home_$suffix.png'));
      });

      // Every component's playground, at every size and brightness.
      for (final component in galleryComponents) {
        testWidgets('${component.slug} preview ($suffix)', (tester) async {
          await _pumpGallery(tester, size: size, brightness: brightness);
          await _open(tester, component);
          await expectLater(
            find.byType(GalleryApp),
            matchesGoldenFile('${component.slug}_preview_$suffix.png'),
          );
        });
      }
    }
  }

  // The Code tab, once per component (desktop, dark). Kept to one variant so
  // editing a component's source only touches one golden.
  for (final component in galleryComponents) {
    testWidgets('${component.slug} code (desktop_dark)', (tester) async {
      await _pumpGallery(tester, size: _screens['desktop']!, brightness: Brightness.dark);
      // Load the source with real async first; the Code tab then reads it
      // from the cache.
      clearComponentSourceCache();
      await tester.runAsync(() => loadComponentSource(component));
      await _open(tester, component);
      await tester.tap(find.text('Code'));
      // The loaded future completes on the real event loop: yield to it once,
      // then let the frame build with the source.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(GalleryApp),
        matchesGoldenFile('${component.slug}_code_desktop_dark.png'),
      );
    });
  }
}
