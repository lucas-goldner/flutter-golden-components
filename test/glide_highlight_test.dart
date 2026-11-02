import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

const BoxDecoration _look = BoxDecoration(color: Color(0xFF123456));

/// Four 80x40 tabs centred on an 800x600 screen.
class _Host extends StatelessWidget {
  const _Host({
    this.value,
    this.initialValue,
    this.hover = false,
    this.reduceMotion = false,
    this.onChanged,
  });

  final String? value;
  final String? initialValue;
  final bool hover;
  final bool reduceMotion;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: GlideHighlight<String>(
            items: const ['Day', 'Week', 'Month', 'Year'],
            value: value,
            initialValue: initialValue,
            hover: hover,
            onChanged: onChanged,
            decoration: _look,
            itemBuilder: (context, item, active) => SizedBox(
              width: 80,
              height: 40,
              child: Center(child: Text(item, style: const TextStyle(fontSize: 12))),
            ),
          ),
        ),
      ),
    );
  }
}

/// The highlight's rectangle, or null when hidden.
Rect? _highlight(WidgetTester tester) {
  final box = find.byWidgetPredicate((w) => w is DecoratedBox && w.decoration == _look);
  return box.evaluate().isEmpty ? null : tester.getRect(box);
}

Rect _tab(WidgetTester tester, String name) =>
    tester.getRect(find.ancestor(of: find.text(name), matching: find.byType(SizedBox)).first);

void main() {
  testWidgets('starts on the initial item', (tester) async {
    await tester.pumpWidget(const _Host(initialValue: 'Week'));
    await tester.pump();
    expect(_highlight(tester), _tab(tester, 'Week'));
  });

  testWidgets('glides to a tapped item', (tester) async {
    final changes = <String?>[];
    await tester.pumpWidget(_Host(initialValue: 'Day', onChanged: changes.add));
    await tester.pump();
    await tester.tap(find.text('Month'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final mid = _highlight(tester)!;
    expect(mid.left, greaterThan(_tab(tester, 'Day').left));
    expect(mid.left, lessThan(_tab(tester, 'Month').left), reason: 'still on its way');
    await tester.pumpAndSettle();
    expect(_highlight(tester), _tab(tester, 'Month'));
    expect(changes, ['Month']);
  });

  testWidgets('hover mode follows the pointer and clears on exit', (tester) async {
    final changes = <String?>[];
    await tester.pumpWidget(_Host(hover: true, onChanged: changes.add));
    await tester.pump();
    expect(_highlight(tester), isNull);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Week')));
    await tester.pumpAndSettle();
    expect(_highlight(tester), _tab(tester, 'Week'));
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(_highlight(tester), isNull);
    expect(changes, ['Week', null]);
    await mouse.removePointer();
  });

  testWidgets('a controlled value moves the highlight without reporting', (tester) async {
    final changes = <String?>[];
    await tester.pumpWidget(_Host(value: 'Day', onChanged: changes.add));
    await tester.pump();
    await tester.pumpWidget(_Host(value: 'Year', onChanged: changes.add));
    await tester.pumpAndSettle();
    expect(_highlight(tester), _tab(tester, 'Year'));
    expect(changes, isEmpty);
  });

  testWidgets('keyboard activates the focused item', (tester) async {
    final changes = <String?>[];
    await tester.pumpWidget(_Host(onChanged: changes.add));
    Focus.of(tester.element(find.text('Week'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(changes, ['Week']);
  });

  testWidgets('jumps when motion is reduced', (tester) async {
    await tester.pumpWidget(const _Host(initialValue: 'Day', reduceMotion: true));
    await tester.pump();
    await tester.tap(find.text('Year'));
    await tester.pump();
    expect(_highlight(tester), _tab(tester, 'Year'));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('marks the active item for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const _Host(initialValue: 'Month'));
    expect(
      tester.getSemantics(find.text('Month')),
      matchesSemantics(
        label: 'Month',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });
}
