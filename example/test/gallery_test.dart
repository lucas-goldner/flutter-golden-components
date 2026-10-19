import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_gallery/gallery/playground.dart';
import 'package:golden_gallery/gallery/registry.dart';
import 'package:golden_gallery/main.dart';

void main() {
  _everyComponentOpens();
  for (final size in const [Size(1400, 900), Size(390, 844)]) {
    testWidgets('home lists components and opens them at ${size.width}px', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const GalleryApp());
      await tester.pumpAndSettle();
      final first = galleryComponents.first;
      expect(find.text(first.name), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Star on GitHub'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('@LucasGoldner'), findsOneWidget);
      expect(find.text('lucas-goldner.com'), findsOneWidget);

      await tester.tap(find.text(first.name).last);
      await tester.pumpAndSettle();
      expect(find.byType(SmoothCaretField), findsWidgets);
      expect(find.text('Settings'), findsOneWidget);

      // Changing a setting and resetting must not throw.
      await tester.tap(find.text('Bouncy'));
      await tester.pump();
      await tester.tap(find.text('Reset'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });
  }
}

void _everyComponentOpens() {
  for (final size in const [Size(1400, 900), Size(390, 844)]) {
    for (final component in galleryComponents) {
      testWidgets('${component.slug} opens, plays and resets at ${size.width}px', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(const GalleryApp());
        await tester.pumpAndSettle();
        final card = find.text(component.name).last;
        await tester.ensureVisible(card);
        await tester.tap(card);
        // Some playgrounds animate forever (marquee), so pump fixed time
        // instead of waiting to settle.
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Settings'), findsOneWidget);
        // Fling across the preview, then reset.
        await tester.flingFrom(
          tester.getCenter(find.byType(Playground)) - Offset(0, size.height * 0.15),
          const Offset(-150, -60),
          1500,
        );
        await tester.pump(const Duration(seconds: 3));
        await tester.tap(find.text('Reset'));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }
}
