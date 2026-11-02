@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _size = Size(320, 120);

const TextStyle _base = TextStyle(fontFamily: 'Roboto', color: Color(0xFFF4F4F5));

const List<String> _tabs = ['Day', 'Week', 'Month', 'Year'];

/// Dark segmented tabs with a gliding highlight.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.value, this.decoration});

  final String value;
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: GlideHighlight<String>(
        items: _tabs,
        value: value,
        decoration:
            decoration ??
            BoxDecoration(color: const Color(0xFF2A2A31), borderRadius: BorderRadius.circular(7)),
        itemBuilder: (context, item, active) => SizedBox(
          width: 68,
          height: 30,
          child: Center(
            child: Text(
              item,
              style: _base.copyWith(
                fontSize: 13,
                color: active ? const Color(0xFFF4F4F5) : const Color(0xFF8A8A93),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A dark, labelled frame.
class _Frame extends StatelessWidget {
  const _Frame({required this.boundary, required this.label, required this.child});

  final Key boundary;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
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

  testWidgets('GlideHighlight glides from Day to Year', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _Frame(
        boundary: key,
        label: 'Day',
        child: const _Tabs(value: 'Day'),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(
      _Frame(
        boundary: key,
        label: 'Day to Year',
        child: const _Tabs(value: 'Year'),
      ),
    );
    final frames = <ui.Image>[];
    var elapsed = 0;
    for (final t in const [0, 40, 80, 130, 200, 400]) {
      await advance(tester, Duration(milliseconds: t - elapsed));
      elapsed = t;
      await tester.pumpWidget(
        _Frame(
          boundary: key,
          label: 'Day to Year, $t ms',
          child: const _Tabs(value: 'Year'),
        ),
      );
      frames.add(await captureBoundary(tester, key));
    }
    await expectSheet(tester, frames, 'glide_highlight_glide.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('GlideHighlight looks', (tester) async {
    final images = <ui.Image>[];
    for (final (label, decoration) in <(String, Decoration)>[
      (
        'soft',
        BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(7)),
      ),
      (
        'accent outline',
        BoxDecoration(
          color: const Color(0x2EF5C451),
          border: Border.all(color: const Color(0x99F5C451)),
          borderRadius: BorderRadius.circular(7),
        ),
      ),
      (
        'underline',
        const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF5C451), width: 2)),
        ),
      ),
    ]) {
      final key = GlobalKey();
      await tester.pumpWidget(
        _Frame(
          boundary: key,
          label: label,
          child: _Tabs(value: 'Month', decoration: decoration),
        ),
      );
      await tester.pump();
      images.add(await captureBoundary(tester, key));
    }
    await expectSheet(tester, images, 'glide_highlight_looks.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
