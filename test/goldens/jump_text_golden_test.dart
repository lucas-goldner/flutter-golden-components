@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(300, 110);

const TextStyle _base = TextStyle(fontFamily: 'Roboto', color: Color(0xFFF4F4F5));

/// A dark, labelled frame with the text centred in it.
class _Frame extends StatelessWidget {
  const _Frame({required this.boundary, required this.label, required this.child});

  final Key boundary;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: _base.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: boundary,
            child: Container(
              width: _size.width,
              height: _size.height,
              color: const Color(0xFF0E0E10),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: _base.copyWith(fontSize: 11, color: const Color(0xFFA1A1AA))),
                  Expanded(child: Center(child: child)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Captures [text] at each of [ms] after it is first shown.
Future<List<ui.Image>> _timeline(
  WidgetTester tester, {
  required String name,
  required JumpText text,
  required List<int> ms,
}) async {
  final key = GlobalKey();
  final frames = <ui.Image>[];
  var elapsed = 0;
  for (final t in ms) {
    if (t == 0) {
      await tester.pumpWidget(_Frame(boundary: key, label: '$name, 0 ms', child: text));
    }
    await advance(tester, Duration(milliseconds: t - elapsed));
    elapsed = t;
    await tester.pumpWidget(_Frame(boundary: key, label: '$name, $t ms', child: text));
    frames.add(await captureBoundary(tester, key));
  }
  return frames;
}

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = _size;
    view.devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset());

  testWidgets('JumpText words jump in one after another', (tester) async {
    final frames = await _timeline(
      tester,
      name: 'words',
      text: const JumpText('Jump into place now'),
      ms: const [0, 60, 120, 200, 320, 520, 1600],
    );
    await expectSheet(tester, frames, 'jump_text_words.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('JumpText characters ripple in', (tester) async {
    final frames = await _timeline(
      tester,
      name: 'characters',
      text: const JumpText('Character wave', unit: JumpTextUnit.character),
      ms: const [0, 40, 100, 180, 300, 1600],
    );
    await expectSheet(tester, frames, 'jump_text_characters.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
