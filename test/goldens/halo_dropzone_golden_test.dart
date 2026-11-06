@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(420, 250);

final GlobalKey _boundary = GlobalKey();

const List<HaloFile> _files = [
  HaloFile(name: 'quarterly-report.pdf', sizeBytes: 240000),
  HaloFile(name: 'budget.xlsx', sizeBytes: 52000),
  HaloFile(name: 'notes.md', sizeBytes: 1800),
];

/// A drop zone on a light or dark page.
class _Page extends StatelessWidget {
  const _Page({required this.label, this.dark = false});

  final String label;
  final bool dark;

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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 10),
                  HaloDropzone(
                    hint: 'Images, PDF, Office, JSON, Markdown',
                    successDuration: Duration.zero,
                    onFiles: (_) {},
                    onBrowse: () async => _files,
                  ),
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

  testWidgets('HaloDropzone idle, hovered and with files', (tester) async {
    final images = <ui.Image>[];
    for (final dark in [false, true]) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_Page(label: dark ? 'dark, idle' : 'idle', dark: dark));
      await tester.pump(const Duration(seconds: 1));
      images.add(await captureBoundary(tester, _boundary));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(5, 5));
      await mouse.moveTo(const Offset(210, 140));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpWidget(_Page(label: 'hovered: brighter halo, rim streak', dark: dark));
      images.add(await captureBoundary(tester, _boundary));

      await tester.tap(find.byType(HaloDropzone));
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpWidget(_Page(label: 'files added', dark: dark));
      images.add(await captureBoundary(tester, _boundary));
      await mouse.removePointer();
    }
    await expectSheet(tester, images, 'halo_dropzone_states.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
