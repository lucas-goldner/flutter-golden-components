import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

const List<PillSelectItem<String>> _fruit = [
  PillSelectItem(value: 'apple', label: 'Apple'),
  PillSelectItem(value: 'banana', label: 'Banana'),
  PillSelectItem(value: 'blueberry', label: 'Blueberry'),
  PillSelectItem(value: 'grape', label: 'Grape', enabled: false),
  PillSelectItem(value: 'pear', label: 'Pear'),
];

/// A select that keeps its own value, under an [Overlay].
class _Host extends StatefulWidget {
  const _Host({this.initial, this.reduceMotion = false, this.align = true});

  final String? initial;
  final bool reduceMotion;
  final bool align;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String? _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(size: const Size(800, 600), disableAnimations: widget.reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xFF0A0A0A)),
          // WidgetsApp provides this in an app; tap-outside needs it.
          child: TapRegionSurface(
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  // A page background, so taps outside the select hit something.
                  builder: (context) => ColoredBox(
                    color: const Color(0xFFFAFAFA),
                    child: Center(
                      child: PillSelect<String>(
                        items: _fruit,
                        value: _value,
                        label: 'Fruit',
                        alignToSelected: widget.align,
                        onChanged: (v) => setState(() => _value = v),
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
  testWidgets('shows the placeholder, then the chosen option', (tester) async {
    await tester.pumpWidget(const _Host());
    expect(find.text('Select…'), findsOneWidget);
    await tester.tap(find.text('Select…'));
    await tester.pumpAndSettle();
    expect(find.text('Pear'), findsOneWidget);
    await tester.tap(find.text('Pear'));
    await tester.pumpAndSettle();
    expect(find.text('Pear'), findsOneWidget, reason: 'now in the field');
    expect(find.text('Apple'), findsNothing, reason: 'list closed');
  });

  testWidgets('opens with the selected option over the field', (tester) async {
    await tester.pumpWidget(const _Host(initial: 'blueberry'));
    final field = tester.getCenter(find.text('Blueberry'));
    await tester.tap(find.text('Blueberry'));
    await tester.pumpAndSettle();
    // Two "Blueberry" texts: the field's and the list row lying over it.
    final rows = find.text('Blueberry');
    expect(rows, findsNWidgets(2));
    expect(tester.getCenter(rows.last).dy, closeTo(field.dy, 1));
  });

  testWidgets('disabled options cannot be chosen', (tester) async {
    await tester.pumpWidget(const _Host(initial: 'apple'));
    await tester.tap(find.text('Apple'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grape'));
    await tester.pumpAndSettle();
    expect(find.text('Grape'), findsOneWidget, reason: 'still open');
  });

  testWidgets('keyboard: open, move, skip disabled, choose, escape', (tester) async {
    await tester.pumpWidget(const _Host(initial: 'banana'));
    Focus.of(tester.element(find.text('Banana'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // open on Banana
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // Blueberry
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // skips Grape to Pear
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Pear'), findsOneWidget);
    expect(find.text('Banana'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('Apple'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Apple'), findsNothing);
  });

  testWidgets('a tap outside closes it', (tester) async {
    await tester.pumpWidget(const _Host(align: false));
    await tester.tap(find.text('Select…'));
    await tester.pumpAndSettle();
    expect(find.text('Apple'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Apple'), findsNothing);
  });

  testWidgets('opens instantly when motion is reduced', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true));
    await tester.tap(find.text('Select…'));
    await tester.pump();
    // One more frame for the focus change; then nothing keeps animating.
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.text('Apple'), findsOneWidget);
  });
}
