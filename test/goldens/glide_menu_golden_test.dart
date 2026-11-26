@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(560, 220);

final GlobalKey _boundary = GlobalKey();

const TextStyle _base = TextStyle(fontFamily: 'Roboto', fontSize: 13, color: Color(0xFFF4F4F5));

/// A link line in a panel.
class _Link extends StatelessWidget {
  const _Link(this.text, {this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(text, style: muted ? const TextStyle(color: Color(0xFFA1A1AA)) : null),
    );
  }
}

/// A coloured tile with a caption.
class _Tile extends StatelessWidget {
  const _Tile({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 110,
          height: 56,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(height: 6),
        Text(text),
      ],
    );
  }
}

const List<GlideMenuItem> _items = [
  GlideMenuItem(
    label: 'Products',
    content: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_Link('Startup', muted: true), _Link('Bookkeeping'), _Link('Invoicing')],
          ),
          SizedBox(width: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_Link('Scaleup', muted: true), _Link('Live coaching'), _Link('Reviews')],
          ),
        ],
      ),
    ),
  ),
  GlideMenuItem(
    label: 'Pricing',
    content: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Link('Free'),
          SizedBox(width: 24),
          _Link('Team'),
          SizedBox(width: 24),
          _Link('Enterprise'),
        ],
      ),
    ),
  ),
  GlideMenuItem(
    label: 'Blog',
    content: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tile(color: Color(0xFF6366F1), text: 'Lorem ipsum'),
          SizedBox(width: 12),
          _Tile(color: Color(0xFFEC4899), text: 'Dolor sit'),
        ],
      ),
    ),
  ),
];

/// The menu in its overlay, built once so the overlay keeps its entry.
final Widget _menu = Overlay(
  initialEntries: [
    OverlayEntry(
      builder: (context) => const Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 8),
          child: GlideMenu(items: _items),
        ),
      ),
    ),
  ],
);

/// The menu near the top of a dark, labelled frame.
class _Frame extends StatelessWidget {
  const _Frame({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: const MediaQueryData(size: _size),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: _base,
          child: RepaintBoundary(
            key: _boundary,
            child: ColoredBox(
              color: const Color(0xFF0E0E10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Text(
                      label,
                      style: _base.copyWith(fontSize: 11, color: const Color(0xFFA1A1AA)),
                    ),
                  ),
                  Expanded(child: _menu),
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

  testWidgets('GlideMenu opens, glides between tabs and closes', (tester) async {
    final frames = <ui.Image>[];
    Future<void> shot(String label) async {
      await tester.pumpWidget(_Frame(label: label));
      frames.add(await captureBoundary(tester, _boundary));
    }

    await shot('at rest');
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(550, 215));
    Future<void> hover(String tab, List<int> ms, String name) async {
      await mouse.moveTo(tester.getCenter(find.text(tab)));
      await tester.pump();
      var elapsed = 0;
      for (final t in ms) {
        await tester.pump(Duration(milliseconds: t - elapsed));
        elapsed = t;
        await shot('$name, $t ms');
      }
    }

    await hover('Products', const [80, 400], 'hover Products');
    await hover('Pricing', const [100, 200, 500], 'to Pricing');
    await hover('Blog', const [140, 500], 'to Blog');

    await mouse.moveTo(const Offset(550, 215));
    await tester.pump();
    // The close timer fires within the first pump; the fade starts with
    // the frame after it.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 100));
    await shot('left, 300 ms');
    await tester.pumpAndSettle();
    await shot('closed');
    await mouse.removePointer();

    await expectSheet(tester, frames, 'glide_menu_glide.png', axis: Axis.vertical);
    await tester.pumpWidget(const SizedBox());
  });
}
