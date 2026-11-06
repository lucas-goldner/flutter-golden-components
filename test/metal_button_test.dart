import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// A centred button, optionally reducing motion.
class _Host extends StatelessWidget {
  const _Host({required this.button, this.reduceMotion = false});

  final MetalButton button;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xFF000000)),
          child: Center(child: button),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('taps and the keyboard press it', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      _Host(
        button: MetalButton(onPressed: () => presses++, child: const Text('Continue')),
      ),
    );
    await tester.tap(find.text('Continue'));
    expect(presses, 1);
    Focus.of(tester.element(find.text('Continue'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(presses, 3);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('hugs its label and keeps the height', (tester) async {
    await tester.pumpWidget(
      _Host(
        reduceMotion: true,
        button: MetalButton(height: 44, onPressed: () {}, child: const Text('Go')),
      ),
    );
    final size = tester.getSize(find.byType(MetalButton));
    expect(size.height, 44);
    expect(size.width, lessThan(200));
  });

  testWidgets('a disabled button ignores taps', (tester) async {
    await tester.pumpWidget(
      const _Host(reduceMotion: true, button: MetalButton(onPressed: null, child: Text('Off'))),
    );
    await tester.tap(find.text('Off'));
    expect(
      tester.getSemantics(find.byType(MetalButton)),
      matchesSemantics(isButton: true, hasEnabledState: true, isFocusable: false, label: 'Off'),
    );
  });

  testWidgets('the ring flows, and holds still when paused or reduced', (tester) async {
    await tester.pumpWidget(
      _Host(
        button: MetalButton(onPressed: () {}, child: const Text('A')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pumpWidget(
      _Host(
        button: MetalButton(paused: true, onPressed: () {}, child: const Text('A')),
      ),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(
      _Host(
        reduceMotion: true,
        button: MetalButton(onPressed: () {}, child: const Text('A')),
      ),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
