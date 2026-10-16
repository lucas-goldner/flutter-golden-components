import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_gallery/gallery/registry.dart';
import 'package:golden_gallery/main.dart';

void main() {
  for (final size in const [Size(1400, 900), Size(390, 844)]) {
    testWidgets('home lists components and opens them at ${size.width}px', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const GalleryApp());
      await tester.pumpAndSettle();
      final first = galleryComponents.first;
      expect(find.text(first.name), findsWidgets);

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
