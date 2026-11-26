@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(380, 110);

final GlobalKey _boundary = GlobalKey();

const TextStyle _base = TextStyle(fontFamily: 'Roboto', color: Color(0xFFF4F4F5));

/// The search on a dark, labelled frame.
class _Frame extends StatelessWidget {
  const _Frame({required this.label, required this.search});

  final String label;
  final Widget search;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: const MediaQueryData(size: _size),
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
                color: const Color(0xFF0E0E10),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: _base.copyWith(fontSize: 11, color: const Color(0xFFA1A1AA)),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Align(alignment: Alignment.centerLeft, child: search),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final Widget _search = MeltSearch(
  key: GlobalKey(),
  width: 220,
  color: const Color(0xFFF4F4F5),
  hint: 'Search components',
);

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = _size;
    view.devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset());

  testWidgets('MeltSearch melts open and closed', (tester) async {
    final frames = <ui.Image>[];
    Future<void> shot(String label) async {
      await tester.pumpWidget(_Frame(label: label, search: _search));
      frames.add(await captureBoundary(tester, _boundary));
    }

    await shot('collapsed');
    await tester.tap(find.text('Search'));
    await tester.pump();
    var elapsed = 0;
    for (final t in const [60, 120, 180, 260, 360, 900]) {
      await tester.pump(Duration(milliseconds: t - elapsed));
      elapsed = t;
      await shot('opening, $t ms');
    }
    await tester.enterText(find.byType(EditableText), 'goo');
    await tester.pump(const Duration(milliseconds: 600));
    await shot('typed');

    await tester.enterText(find.byType(EditableText), '');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    elapsed = 0;
    for (final t in const [80, 160, 260, 900]) {
      await tester.pump(Duration(milliseconds: t - elapsed));
      elapsed = t;
      await shot('closing, $t ms');
    }
    await expectSheet(tester, frames, 'melt_search_melt.png', axis: Axis.vertical);
    await tester.pumpWidget(const SizedBox());
  });
}
