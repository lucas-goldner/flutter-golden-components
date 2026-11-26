@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(420, 300);

final GlobalKey _boundary = GlobalKey();

const TextStyle _base = TextStyle(fontFamily: 'Roboto', color: Color(0xFFF4F4F5));

/// A gradient standing in for a photo.
class _Photo extends StatelessWidget {
  const _Photo(this.colors);

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}

const List<ImageHoverItem> _items = [
  ImageHoverItem(
    title: 'About',
    subtitle: 'Learn what we do here',
    image: _Photo([Color(0xFF6366F1), Color(0xFFEC4899)]),
  ),
  ImageHoverItem(
    title: 'Clients',
    subtitle: 'We work with great people',
    image: _Photo([Color(0xFF10B981), Color(0xFF3B82F6)]),
  ),
  ImageHoverItem(
    title: 'Portfolio',
    subtitle: 'Our work speaks for itself',
    image: _Photo([Color(0xFFF59E0B), Color(0xFFEF4444)]),
  ),
];

/// The list on a dark, labelled frame.
class _Frame extends StatelessWidget {
  const _Frame({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Directionality(
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
              color: const Color(0xFF0E0E10),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: _base.copyWith(fontSize: 11, color: const Color(0xFFA1A1AA))),
                  const SizedBox(height: 4),
                  const ImageHoverList(
                    items: _items,
                    imageSize: Size(120, 82),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    titleStyle: TextStyle(fontSize: 34),
                    highlight: Color(0xFFF5C451),
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

  testWidgets('ImageHoverList reveals and drags an image', (tester) async {
    final frames = <ui.Image>[];
    Future<void> shot(String label) async {
      await tester.pumpWidget(_Frame(label: label));
      frames.add(await captureBoundary(tester, _boundary));
    }

    await tester.pumpWidget(const _Frame(label: 'at rest'));
    await shot('at rest');
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(410, 290));
    final about = tester.getCenter(find.text('A')) + const Offset(60, 0);
    await mouse.moveTo(about);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await shot('enter About, 80 ms');
    await advance(tester, const Duration(milliseconds: 600));
    await shot('About, settled');

    // Sweep right: the image trails and leans into the move.
    for (var i = 1; i <= 6; i++) {
      await mouse.moveTo(about + Offset(30.0 * i, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await shot('sweeping right');

    await mouse.moveTo(tester.getCenter(find.text('P')) + const Offset(140, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await shot('onto Portfolio, 120 ms');
    await advance(tester, const Duration(milliseconds: 800));
    await shot('Portfolio, settled');

    await mouse.moveTo(const Offset(410, 290));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await shot('leaving, 100 ms');
    await advance(tester, const Duration(milliseconds: 800));
    await shot('left');
    await mouse.removePointer();

    await expectSheet(tester, frames, 'image_hover_list_hover.png', axis: Axis.vertical);
    await tester.pumpWidget(const SizedBox());
  });
}
