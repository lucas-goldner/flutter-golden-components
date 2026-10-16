import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal widgets-only host for a field under test.
class _Host extends StatelessWidget {
  const _Host({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 300, child: child),
          ),
        ),
      ),
    );
  }
}

/// The caret head: the solid box. (The motion trail is a gradient box.)
Finder _caret() => find.descendant(
  of: find.byType(SmoothCaretField),
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).color != null,
  ),
);

void main() {
  testWidgets('caret only shows while focused', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(_Host(child: SmoothCaretField(focusNode: focus)));
    await tester.pump();
    expect(_caret(), findsNothing);

    focus.requestFocus();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(_caret(), findsOneWidget);

    focus.unfocus();
    await tester.pump();
    await tester.pump();
    expect(_caret(), findsNothing);
  });

  testWidgets('caret springs to the new cursor position', (tester) async {
    final controller = TextEditingController(text: 'hello world');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _Host(
        child: SmoothCaretField(controller: controller, focusNode: focus, blink: false),
      ),
    );
    focus.requestFocus();
    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();
    await tester.pump();
    final start = tester.getTopLeft(_caret()).dx;

    controller.selection = const TextSelection.collapsed(offset: 11);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final mid = tester.getTopLeft(_caret()).dx;

    await tester.pumpAndSettle();
    final end = tester.getTopLeft(_caret()).dx;

    expect(end, greaterThan(start));
    // Mid-flight it has not arrived yet (it is animating, not jumping).
    expect(mid, lessThan(end));
  });

  testWidgets('typing updates text and hides the placeholder', (tester) async {
    String? changed;
    await tester.pumpWidget(
      _Host(
        child: SmoothCaretField(placeholder: 'Type here', onChanged: (v) => changed = v),
      ),
    );
    expect(find.text('Type here'), findsOneWidget);
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'abc');
    await tester.pump();
    expect(changed, 'abc');
    expect(find.text('Type here'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('caret hides while a range is selected', (tester) async {
    final controller = TextEditingController(text: 'hello');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _Host(
        child: SmoothCaretField(controller: controller, focusNode: focus, blink: false),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();
    await tester.pump();
    expect(_caret(), findsNothing);
  });
}
