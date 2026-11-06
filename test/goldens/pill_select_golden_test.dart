@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(300, 280);

final GlobalKey _boundary = GlobalKey();

/// A select on a page with a soft colour spot behind it.
class _Page extends StatelessWidget {
  const _Page({required this.label, this.dark = false, this.align = true});

  final String label;
  final bool dark;
  final bool align;

  @override
  Widget build(BuildContext context) {
    final ink = dark ? const Color(0xFFF4F4F5) : const Color(0xFF0A0A0A);
    return MediaQuery(
      data: const MediaQueryData(size: _size, disableAnimations: true),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: TextStyle(fontFamily: 'Roboto', color: ink),
          child: RepaintBoundary(
            key: _boundary,
            child: TapRegionSurface(
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => Container(
                      color: dark ? const Color(0xFF0E0E10) : const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.all(12),
                      child: Stack(
                        children: [
                          const Positioned(
                            right: -20,
                            bottom: -20,
                            width: 200,
                            height: 200,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [Color(0x8860A5FA), Color(0x0060A5FA)],
                                ),
                              ),
                            ),
                          ),
                          Text(label, style: const TextStyle(fontSize: 11)),
                          Align(
                            alignment: const Alignment(0, -0.2),
                            child: PillSelect<String>(
                              label: 'Fruit',
                              value: 'blueberry',
                              minWidth: 150,
                              alignToSelected: align,
                              onChanged: (_) {},
                              items: const [
                                PillSelectItem(value: 'apple', label: 'Apple'),
                                PillSelectItem(value: 'banana', label: 'Banana'),
                                PillSelectItem(value: 'blueberry', label: 'Blueberry'),
                                PillSelectItem(value: 'grapes', label: 'Grapes', enabled: false),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

  testWidgets('PillSelect closed and open', (tester) async {
    final images = <ui.Image>[];
    for (final (page, open) in const [
      (_Page(label: 'closed'), false),
      (_Page(label: 'open over the selection'), true),
      (_Page(label: 'open below the field', align: false), true),
      (_Page(label: 'dark, open', dark: true), true),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(page);
      if (open) {
        await tester.tap(find.text('Blueberry'));
        await tester.pump();
        await tester.pump();
      }
      images.add(await captureBoundary(tester, _boundary));
    }
    await expectSheet(tester, images, 'pill_select_states.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
