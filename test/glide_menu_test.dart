import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

const Key _narrow = Key('narrow');
const Key _wide = Key('wide');

const List<GlideMenuItem> _items = [
  GlideMenuItem(
    label: 'Products',
    content: SizedBox(key: _narrow, width: 160, height: 100, child: Text('Startup')),
  ),
  GlideMenuItem(
    label: 'Pricing',
    content: SizedBox(key: _wide, width: 320, height: 60, child: Text('Plans')),
  ),
  GlideMenuItem(
    label: 'Blog',
    content: SizedBox(width: 200, height: 140, child: Text('Posts')),
  ),
];

/// A menu at the top centre of an 800x600 screen, inside an overlay.
class _Host extends StatelessWidget {
  const _Host({
    this.reduceMotion = false,
    this.onChanged,
    this.screen = const Size(800, 600),
    this.fontSize = 14,
  });

  final bool reduceMotion;
  final Size screen;
  final double fontSize;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(size: screen, disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: TextStyle(color: const Color(0xFF0A0A0A), fontSize: fontSize),
          child: TapRegionSurface(
            // Opaque, so taps on empty space count as taps outside the menu.
            child: Listener(
              behavior: HitTestBehavior.opaque,
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => Align(
                      alignment: const Alignment(0, -0.9),
                      child: GlideMenu(items: _items, onChanged: onChanged),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<TestGesture> _mouse(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: const Offset(790, 590));
  addTearDown(gesture.removePointer);
  return gesture;
}

void main() {
  testWidgets('hovering a tab opens its panel below it', (tester) async {
    final changes = <int?>[];
    await tester.pumpWidget(_Host(onChanged: changes.add));
    expect(find.text('Startup'), findsNothing);

    final mouse = await _mouse(tester);
    await mouse.moveTo(tester.getCenter(find.text('Products')));
    await tester.pumpAndSettle();
    expect(find.text('Startup'), findsOneWidget);
    final tab = tester.getRect(find.text('Products'));
    final panel = tester.getRect(find.byKey(_narrow));
    expect(panel.center.dx, closeTo(tab.center.dx + 10, 12), reason: 'centred under the tab');
    expect(panel.top, greaterThan(tab.bottom));
    expect(changes, [0]);
  });

  testWidgets('moving to another tab glides and resizes the same panel', (tester) async {
    await tester.pumpWidget(const _Host());
    final mouse = await _mouse(tester);
    await mouse.moveTo(tester.getCenter(find.text('Products')));
    await tester.pumpAndSettle();
    final productsX = tester.getCenter(find.byKey(_narrow)).dx;

    await mouse.moveTo(tester.getCenter(find.text('Pricing')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    // Mid-glide both contents are on screen.
    expect(find.text('Startup'), findsOneWidget);
    expect(find.text('Plans'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Startup'), findsNothing);
    final wide = tester.getRect(find.byKey(_wide));
    expect(wide.width, 320);
    expect(wide.center.dx, greaterThan(productsX), reason: 'moved right with the tab');
    expect(
      wide.center.dx,
      closeTo(tester.getCenter(find.text('Pricing')).dx + 10, 12),
      reason: 'centred under Pricing (label plus chevron)',
    );
  });

  testWidgets('leaving closes after a moment; crossing the gap does not', (tester) async {
    final changes = <int?>[];
    await tester.pumpWidget(_Host(onChanged: changes.add));
    final mouse = await _mouse(tester);
    await mouse.moveTo(tester.getCenter(find.text('Products')));
    await tester.pumpAndSettle();

    // Down through the gap and into the panel.
    await mouse.moveTo(tester.getCenter(find.text('Startup')));
    await tester.pumpAndSettle();
    expect(find.text('Startup'), findsOneWidget);

    await mouse.moveTo(const Offset(790, 590));
    await tester.pump(const Duration(milliseconds: 100));
    expect(changes, [0], reason: 'not closed yet');
    await tester.pumpAndSettle();
    expect(find.text('Startup'), findsNothing);
    expect(changes, [0, null]);
  });

  testWidgets('taps toggle; tapping outside and Escape close', (tester) async {
    final changes = <int?>[];
    await tester.pumpWidget(_Host(onChanged: changes.add));
    await tester.tap(find.text('Blog'));
    await tester.pumpAndSettle();
    expect(find.text('Posts'), findsOneWidget);
    await tester.tap(find.text('Blog'));
    await tester.pumpAndSettle();
    expect(find.text('Posts'), findsNothing);

    await tester.tap(find.text('Blog'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 580));
    await tester.pumpAndSettle();
    expect(find.text('Posts'), findsNothing);

    Focus.of(tester.element(find.text('Pricing'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('Plans'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Plans'), findsNothing);
    expect(changes, [2, null, 2, null, 1, null]);
  });

  testWidgets('reduced motion: opens and swaps at once', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true));
    final mouse = await _mouse(tester);
    await mouse.moveTo(tester.getCenter(find.text('Products')));
    await tester.pump();
    expect(find.text('Startup'), findsOneWidget);
    await mouse.moveTo(tester.getCenter(find.text('Pricing')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Startup'), findsNothing);
    expect(find.text('Plans'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('tabs tell screen readers whether they are open', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const _Host());
    await tester.tap(find.text('Pricing'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Pricing')),
      matchesSemantics(
        label: 'Pricing',
        isButton: true,
        hasExpandedState: true,
        isExpanded: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('content wider than the screen is scaled down to fit', (tester) async {
    tester.view.physicalSize = const Size(300, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Small tab text, so only the panel is too wide (test glyphs are square).
    await tester.pumpWidget(const _Host(screen: Size(300, 600), fontSize: 6));
    await tester.tap(find.text('Pricing'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final panel = tester.getRect(find.byKey(_wide));
    expect(panel.width, lessThanOrEqualTo(276.5), reason: '320 px scaled into 300 - 24');
    expect(panel.left, greaterThanOrEqualTo(-0.5));
    expect(panel.right, lessThanOrEqualTo(300.5));
  });
}
