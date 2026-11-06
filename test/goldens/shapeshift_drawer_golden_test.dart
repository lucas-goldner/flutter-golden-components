@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(320, 420);

final GlobalKey _boundary = GlobalKey();

class _Trigger extends StatelessWidget {
  const _Trigger();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ShapeshiftDrawer.of(context).open(),
      child: const Text('Open'),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    final drawer = ShapeshiftDrawer.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShapeshiftDrawerHeader(title: 'Options'),
        const SizedBox(height: 16),
        ShapeshiftDrawerTile(label: 'View private key', onTap: () => drawer.show('key')),
        const SizedBox(height: 8),
        ShapeshiftDrawerTile(label: 'Remove wallet', destructive: true, onTap: () {}),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShapeshiftDrawerHeader(
          title: 'Private key',
          description: 'Your private key is like a password. Never share it with anyone.',
        ),
        const SizedBox(height: 70),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: ShapeshiftDrawerAction(label: 'Back', onTap: () {}),
            ),
            Expanded(
              child: ShapeshiftDrawerAction(label: 'Reveal', primary: true, onTap: () {}),
            ),
          ],
        ),
      ],
    );
  }
}

/// A page with the drawer, captured whole.
class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: const MediaQueryData(size: _size),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Roboto', color: Color(0xFF0A0A0A)),
          child: RepaintBoundary(
            key: _boundary,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => ColoredBox(
                    color: const Color(0xFFF4F4F5),
                    child: Center(
                      child: ShapeshiftDrawer(
                        views: {
                          'default': (context) => const _Home(),
                          'key': (context) => const _Key(),
                        },
                        child: const _Trigger(),
                      ),
                    ),
                  ),
                ),
              ],
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

  testWidgets('ShapeshiftDrawer opens and morphs into another view', (tester) async {
    await tester.pumpWidget(const _Page());
    final frames = <ui.Image>[];
    await tester.tap(find.text('Open'));
    await tester.pump();
    await advance(tester, const Duration(milliseconds: 120));
    frames.add(await captureBoundary(tester, _boundary));
    await advance(tester, const Duration(milliseconds: 500));
    frames.add(await captureBoundary(tester, _boundary));

    await tester.tap(find.text('View private key'));
    await tester.pump();
    for (final ms in const [80, 80, 400]) {
      await advance(tester, Duration(milliseconds: ms));
      frames.add(await captureBoundary(tester, _boundary));
    }
    await expectSheet(tester, frames, 'shapeshift_drawer_morph.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
