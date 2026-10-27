import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// Centres [child] with a plain text style, optionally reducing motion.
class _Host extends StatelessWidget {
  const _Host({required this.child, this.reduceMotion = false});

  final Widget child;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Roboto', fontSize: 40, color: Color(0xFF000000)),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// The numerals and symbols currently on screen, left to right.
String _shown(WidgetTester tester) {
  final texts = [
    for (final e in find.byType(Text).evaluate())
      ((e.renderObject! as RenderBox).localToGlobal(Offset.zero).dx, (e.widget as Text).data!),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  return texts.map((t) => t.$2).join();
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 300 && tester.binding.hasScheduledFrame; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(tester.binding.hasScheduledFrame, isFalse, reason: 'settles');
}

void main() {
  test('formats numbers', () {
    expect(const DigitRollFormat().apply(1284), '1,284');
    expect(const DigitRollFormat(grouping: false).apply(1284), '1284');
    expect(const DigitRollFormat(decimals: 2, prefix: r'$').apply(-1234.5), r'-$1,234.50');
    expect(const DigitRollFormat(minDigits: 2).apply(7), '07');
    expect(const DigitRollFormat(suffix: '%').apply(42.4), '42%');
    expect(
      const DigitRollFormat(
        decimals: 1,
        groupSeparator: '.',
        decimalSeparator: ',',
      ).apply(1234567.89),
      '1.234.567,9',
    );
    // Rounds to zero without a stray minus sign.
    expect(const DigitRollFormat().apply(-0.2), '0');
  });

  testWidgets('shows the value at rest', (tester) async {
    await tester.pumpWidget(const _Host(child: DigitRoll(value: 1284, rollOnMount: false)));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(_shown(tester), '1,284');
    expect(find.bySemanticsLabel('1,284'), findsOneWidget);
  });

  testWidgets('spins once on mount, then rests on the value', (tester) async {
    await tester.pumpWidget(const _Host(child: DigitRoll(value: 42)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await _settle(tester);
    expect(_shown(tester), '42');
  });

  testWidgets('rolls to a new value, showing numerals in between', (tester) async {
    await tester.pumpWidget(const _Host(child: DigitRoll(value: 1284, rollOnMount: false)));
    await tester.pumpWidget(const _Host(child: DigitRoll(value: 1290, rollOnMount: false)));
    await tester.pump(const Duration(milliseconds: 120));
    // Mid-roll, a digit window shows two numerals at once.
    expect(find.byType(Text).evaluate().length, greaterThan(5));
    await _settle(tester);
    expect(_shown(tester), '1,290');
  });

  testWidgets('new places grow in and old ones shrink away', (tester) async {
    await tester.pumpWidget(const _Host(child: DigitRoll(value: 999, rollOnMount: false)));
    final narrow = tester.getSize(find.byType(DigitRoll)).width;
    await tester.pumpWidget(const _Host(child: DigitRoll(value: 1000, rollOnMount: false)));
    await _settle(tester);
    expect(_shown(tester), '1,000');
    expect(tester.getSize(find.byType(DigitRoll)).width, greaterThan(narrow));

    await tester.pumpWidget(const _Host(child: DigitRoll(value: 5, rollOnMount: false)));
    await _settle(tester);
    expect(_shown(tester), '5');
  });

  testWidgets('direction decides which numerals roll past', (tester) async {
    Future<Set<String>> passed(DigitRollDirection direction) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _Host(child: DigitRoll(value: 1, rollOnMount: false, direction: direction)),
      );
      await tester.pumpWidget(
        _Host(child: DigitRoll(value: 2, rollOnMount: false, direction: direction)),
      );
      final seen = <String>{};
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        seen.addAll(tester.widgetList<Text>(find.byType(Text)).map((t) => t.data!));
      }
      return seen;
    }

    expect(await passed(DigitRollDirection.up), isNot(contains('5')));
    expect(await passed(DigitRollDirection.down), containsAll(['0', '9', '5']));
  });

  testWidgets('jumps straight to the value when motion is reduced', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true, child: DigitRoll(value: 10)));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const _Host(reduceMotion: true, child: DigitRoll(value: 12345)));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(_shown(tester), '12,345');
  });

  testWidgets('decorates each digit', (tester) async {
    await tester.pumpWidget(
      const _Host(
        child: DigitRoll(
          value: 7,
          rollOnMount: false,
          format: DigitRollFormat(minDigits: 2),
          digitPadding: EdgeInsets.all(6),
          digitDecoration: BoxDecoration(color: Color(0xFFEEEEEE)),
        ),
      ),
    );
    expect(_shown(tester), '07');
    expect(find.byType(DecoratedBox), findsNWidgets(2));
  });
}
