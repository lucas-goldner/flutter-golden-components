import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_gallery/gallery/dart_highlighter.dart';
import 'package:golden_gallery/gallery/registry.dart';
import 'package:golden_gallery/main.dart';

void main() {
  test('tokenizer classifies Dart tokens', () {
    final tokens = tokenizeDart("final x = Foo(1); // hi\nbuild('s');");
    DartToken kindOf(String text) => tokens.firstWhere((t) => t.$1 == text).$2;
    expect(kindOf('final'), DartToken.keyword);
    expect(kindOf('Foo'), DartToken.type);
    expect(kindOf('1'), DartToken.number);
    expect(kindOf('// hi'), DartToken.comment);
    expect(kindOf('build'), DartToken.function);
    expect(kindOf("'s'"), DartToken.string);
    // Tokenizing never drops or reorders characters.
    const code = "class A<T> { @override void f() => g<int>(r'x', 0x1F); }";
    expect(tokenizeDart(code).map((t) => t.$1).join(), code);
  });

  testWidgets('every component ships its source as an asset', (tester) async {
    for (final c in galleryComponents) {
      final code = await tester.runAsync(() => rootBundle.loadString(c.sourceAsset));
      expect(code, contains('package:flutter/widgets.dart'), reason: c.sourcePath);
    }
  });

  testWidgets('Code tab shows the source and Copy puts it on the clipboard', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });

    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(galleryComponents.first.name).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Code'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    expect(
      find.textContaining(galleryComponents.first.sourcePath, findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.text('Copy code').first);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    expect(copied, contains('class SmoothCaretField'));
    expect(find.text('Copied'), findsWidgets);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
  });
}
