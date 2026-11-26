import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// A search at the left of an 800x600 screen, with a second focusable
/// widget to move focus to.
class _Host extends StatelessWidget {
  const _Host({
    this.reduceMotion = false,
    this.onSubmitted,
    this.onExpandedChanged,
    this.controller,
  });

  final bool reduceMotion;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<bool>? onExpandedChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xFF18181B), fontSize: 14),
          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MeltSearch(
                  controller: controller,
                  onSubmitted: onSubmitted,
                  onExpandedChanged: onExpandedChanged,
                ),
                const Focus(child: SizedBox(key: Key('elsewhere'), width: 10, height: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('tapping the pill opens and focuses the field', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(_Host(onExpandedChanged: changes.add));
    expect(tester.getSize(find.byType(MeltSearch)), const Size(120, 44));
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(changes, [true]);
    expect(tester.getSize(find.byType(MeltSearch)), const Size(44 + 16 + 260, 44));
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);
    expect(find.text('Search'), findsNothing, reason: 'the label fades away');
  });

  testWidgets('the field keeps its state while the label leaves', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.tap(find.text('Search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final before = tester.state<EditableTextState>(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(tester.state<EditableTextState>(find.byType(EditableText)), same(before));
    expect(tester.testTextInput.hasAnyClients, isTrue);
  });

  testWidgets('submits with Enter or the button; the empty button closes', (tester) async {
    final submitted = <String>[];
    final changes = <bool>[];
    await tester.pumpWidget(_Host(onSubmitted: submitted.add, onExpandedChanged: changes.add));
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'goo');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(submitted, ['goo']);

    await tester.tapAt(const Offset(22, 22));
    await tester.pump();
    expect(submitted, ['goo', 'goo']);

    await tester.enterText(find.byType(EditableText), '');
    await tester.tapAt(const Offset(22, 22));
    await tester.pumpAndSettle();
    expect(changes, [true, false]);
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('losing focus closes it only when empty', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(_Host(onExpandedChanged: changes.add));
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'kept');
    Focus.of(tester.element(find.byKey(const Key('elsewhere')))).requestFocus();
    await tester.pumpAndSettle();
    expect(changes, [true], reason: 'text keeps it open');

    await tester.tap(find.byType(EditableText));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), '');
    Focus.of(tester.element(find.byKey(const Key('elsewhere')))).requestFocus();
    await tester.pumpAndSettle();
    expect(changes, [true, false]);
  });

  testWidgets('Escape clears and closes', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_Host(controller: controller));
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'oops');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect(tester.getSize(find.byType(MeltSearch)).width, 120);
  });

  testWidgets('the keyboard opens it from the button', (tester) async {
    await tester.pumpWidget(const _Host());
    Focus.of(tester.element(find.byType(CustomPaint).last)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MeltSearch)).width, 320);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue, reason: 'focus moves on to the field');
  });

  testWidgets('reduced motion: opens at once', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true));
    await tester.tap(find.text('Search'));
    await tester.pump();
    expect(tester.getSize(find.byType(MeltSearch)).width, 320);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('describes itself to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const _Host());
    expect(find.bySemanticsLabel('Search'), findsOneWidget);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Submit search'), findsOneWidget);
    handle.dispose();
  });
}
