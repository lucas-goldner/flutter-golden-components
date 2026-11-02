@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(360, 300);

const TextStyle _base = TextStyle(fontFamily: 'Roboto', color: Color(0xFFF4F4F5));

final GlobalKey _boundary = GlobalKey();

/// A gradient block standing in for a photo.
class _Art extends StatelessWidget {
  const _Art();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFFF9177), Color(0xFFF4D25A)]),
      ),
    );
  }
}

/// A dark page with a card at its top left, under an [Overlay].
class _Page extends StatelessWidget {
  const _Page({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(size: _size),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: _base.copyWith(fontSize: 12),
          child: RepaintBoundary(
            key: _boundary,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => Container(
                    color: const Color(0xFF0E0E10),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: _base.copyWith(fontSize: 11, color: const Color(0xFFA1A1AA)),
                        ),
                        const SizedBox(height: 10),
                        MorphCard(
                          color: const Color(0xFF1C1C21),
                          barrierColor: const Color(0x660E0E10),
                          dialogMaxWidth: 300,
                          card: const SizedBox(
                            width: 120,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: 70, child: _Art()),
                                Padding(padding: EdgeInsets.all(8), child: Text('EB27')),
                              ],
                            ),
                          ),
                          dialog: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: 110, child: _Art()),
                              Padding(
                                padding: EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('EB27', style: TextStyle(fontSize: 18)),
                                    MorphCardReveal(
                                      child: Text('Details drift in after the morph.'),
                                    ),
                                  ],
                                ),
                              ),
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

  testWidgets('MorphCard morphs open and back', (tester) async {
    await tester.pumpWidget(const _Page(label: 'card'));
    final frames = <ui.Image>[await captureBoundary(tester, _boundary)];
    await tester.tap(find.text('EB27'));
    await tester.pump(); // measuring pass
    var elapsed = 0;
    for (final t in const [40, 90, 160, 400]) {
      await advance(tester, Duration(milliseconds: t - elapsed));
      elapsed = t;
      await tester.pumpWidget(_Page(label: 'opening, $t ms'));
      frames.add(await captureBoundary(tester, _boundary));
    }
    await tester.tapAt(const Offset(350, 290));
    elapsed = 0;
    for (final t in const [60, 140]) {
      await advance(tester, Duration(milliseconds: t - elapsed));
      elapsed = t;
      await tester.pumpWidget(_Page(label: 'closing, $t ms'));
      frames.add(await captureBoundary(tester, _boundary));
    }
    await advance(tester, const Duration(milliseconds: 600));
    await tester.pump();
    await tester.pumpWidget(const _Page(label: 'closed'));
    frames.add(await captureBoundary(tester, _boundary));
    await expectSheet(tester, frames, 'morph_card_morph.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
