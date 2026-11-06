@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(320, 360);

final GlobalKey _boundary = GlobalKey();

const TextStyle _base = TextStyle(fontFamily: 'Roboto', color: Color(0xFF09090B));

/// A gradient standing in for a photo.
class _Photo extends StatelessWidget {
  const _Photo();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF2CD3D1), Color(0xFF2A6C95), Color(0xFF3B1E6E)],
        ),
      ),
    );
  }
}

/// A notched card with labels in [corners].
class _Frame extends StatelessWidget {
  const _Frame({required this.hovered, this.dark = false});

  final bool hovered;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final ink = dark ? const Color(0xFFF4F4F5) : const Color(0xFF09090B);
    return MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: _base.copyWith(color: ink),
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: _boundary,
              child: Container(
                width: _size.width,
                height: _size.height,
                color: dark ? const Color(0xFF0E0E10) : const Color(0xFFF4F4F5),
                padding: const EdgeInsets.all(16),
                child: NotchCard(
                  hovered: hovered,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const NotchCardMedia(
                        height: 190,
                        labels: [
                          NotchLabel(
                            corner: NotchCorner.bottomLeft,
                            child: Text(
                              'FEATURED',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          NotchLabel(
                            corner: NotchCorner.topRight,
                            color: Color(0xFF18181B),
                            radius: 16,
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            child: Text(
                              'New',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFAFAFA),
                              ),
                            ),
                          ),
                        ],
                        child: _Photo(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          hovered ? 'Alpine Adventures (hovered)' : 'Alpine Adventures',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Labels in all four corners at once.
class _Corners extends StatelessWidget {
  const _Corners();

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: _base,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: _boundary,
              child: Container(
                width: _size.width,
                height: _size.height,
                color: const Color(0xFFF4F4F5),
                padding: const EdgeInsets.all(16),
                child: NotchCard(
                  child: NotchCardMedia(
                    height: 326,
                    wash: 0,
                    labels: [
                      for (final corner in NotchCorner.values)
                        NotchLabel(corner: corner, child: Text(corner.name)),
                    ],
                    child: const _Photo(),
                  ),
                ),
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

  testWidgets('NotchCard looks', (tester) async {
    final images = <ui.Image>[];
    for (final frame in const <Widget>[
      _Frame(hovered: false),
      _Frame(hovered: true),
      _Frame(hovered: false, dark: true),
      _Corners(),
    ]) {
      await tester.pumpWidget(frame);
      await tester.pump(const Duration(seconds: 1));
      images.add(await captureBoundary(tester, _boundary));
    }
    await expectSheet(tester, images, 'notch_card_looks.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
