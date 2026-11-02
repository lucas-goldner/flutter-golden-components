@Tags(['golden'])
library;


import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(420, 170);

const TextStyle _base = TextStyle(fontFamily: 'Roboto', color: Color(0xFFF4F4F5));

final GlobalKey _boundary = GlobalKey();

/// A small square standing in for an icon.
class _Square extends StatelessWidget {
  const _Square();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(color: IconTheme.of(context).color!, width: 2),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

/// A dark frame with a six-icon dock at the bottom.
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
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(label, style: _base.copyWith(fontSize: 11, color: const Color(0xFFA1A1AA))),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: MagnifyDock(
                        baseSize: 32,
                        magnification: 60,
                        distance: 110,
                        panelHeight: 52,
                        gap: 10,
                        items: [
                          for (final name in const [
                            'Home',
                            'Files',
                            'Apps',
                            'Stats',
                            'Mail',
                            'Theme',
                          ])
                            MagnifyDockItem(label: name, icon: const _Square()),
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

  testWidgets('MagnifyDock swells under the pointer', (tester) async {
    await tester.pumpWidget(const _Frame(label: 'at rest'));
    final frames = [await captureBoundary(tester, _boundary)];
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(10, 10));

    Future<void> hover(String name, String label, int ms) async {
      await mouse.moveTo(tester.getCenter(find.bySemanticsLabel(name)));
      await advance(tester, Duration(milliseconds: ms));
      await tester.pumpWidget(_Frame(label: label));
      frames.add(await captureBoundary(tester, _boundary));
    }

    await hover('Apps', 'over Apps, 60 ms', 60);
    await advance(tester, const Duration(milliseconds: 600));
    await tester.pumpWidget(const _Frame(label: 'over Apps, settled'));
    frames.add(await captureBoundary(tester, _boundary));
    await hover('Theme', 'over Theme, settled', 700);

    await mouse.moveTo(const Offset(10, 10));
    await advance(tester, const Duration(milliseconds: 700));
    await tester.pumpWidget(const _Frame(label: 'left, settled'));
    frames.add(await captureBoundary(tester, _boundary));
    await mouse.removePointer();
    await expectSheet(tester, frames, 'magnify_dock_hover.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
