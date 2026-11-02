import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 200x120 card centred on an 800x600 screen, under an [Overlay].
class _Host extends StatelessWidget {
  const _Host({this.reduceMotion = false, this.onOpenChanged});

  final bool reduceMotion;
  final ValueChanged<bool>? onOpenChanged;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(size: const Size(800, 600), disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 14, color: Color(0xFF111111)),
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Center(
                  child: MorphCard(
                    semanticLabel: 'Lamp',
                    onOpenChanged: onOpenChanged,
                    card: const SizedBox(width: 200, height: 120, child: Text('card face')),
                    dialog: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 300, child: Text('dialog body')),
                        MorphCardReveal(child: Text('more details')),
                        MorphCardClose(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The morphing box: the outer surface around the dialog, once it shows.
Rect _dialogBox(WidgetTester tester) => tester.getRect(
  find.ancestor(of: find.text('dialog body'), matching: find.byType(ClipRRect)).first,
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 200 && tester.binding.hasScheduledFrame; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  // Closing finishes in a microtask after the last frame.
  await tester.pump();
}

void main() {
  testWidgets('tapping the card morphs it into a centred dialog', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(_Host(onOpenChanged: changes.add));
    final card = tester.getRect(find.text('card face'));

    await tester.tap(find.text('card face'));
    await tester.pump(); // measuring pass
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final mid = _dialogBox(tester);
    expect(mid.width, greaterThan(card.width), reason: 'growing');
    expect(mid.width, lessThan(500));

    await _settle(tester);
    final open = _dialogBox(tester);
    expect(open.width, 500);
    expect(open.center.dx, closeTo(400, 0.5));
    expect(open.center.dy, closeTo(300, 0.5));
    expect(find.text('more details'), findsOneWidget);
    expect(changes, [true]);
  });

  testWidgets('the barrier, Escape and the close button each close it', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(_Host(onOpenChanged: changes.add));

    Future<void> open() async {
      await tester.tap(find.text('card face').first);
      await tester.pump();
      await _settle(tester);
      expect(find.text('dialog body'), findsOneWidget);
    }

    await open();
    await tester.tapAt(const Offset(10, 10));
    await _settle(tester);
    expect(find.text('dialog body'), findsNothing);

    await open();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
    expect(find.text('dialog body'), findsNothing);

    await open();
    await tester.tap(find.bySemanticsLabel('Close'));
    await _settle(tester);
    expect(find.text('dialog body'), findsNothing);
    expect(changes, [true, false, true, false, true, false]);
  });

  testWidgets('opens from the keyboard', (tester) async {
    await tester.pumpWidget(const _Host());
    Focus.of(tester.element(find.text('card face'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await _settle(tester);
    expect(find.text('dialog body'), findsOneWidget);
  });

  testWidgets('opens without morphing when motion is reduced', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true));
    await tester.tap(find.text('card face'));
    await tester.pump();
    await tester.pump();
    expect(_dialogBox(tester).width, 500);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('dialog body'), findsNothing);
  });

  testWidgets('the dialog keeps the text style of the card', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.tap(find.text('card face'));
    await tester.pump();
    await _settle(tester);
    final style = DefaultTextStyle.of(tester.element(find.text('dialog body'))).style;
    expect(style.color, const Color(0xFF111111));
  });
}
