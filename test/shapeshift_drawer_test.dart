import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the drawer.
class _Trigger extends StatelessWidget {
  const _Trigger();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ShapeshiftDrawer.of(context).open(),
      child: const Text('Open'),
    );
  }
}

/// The first view: two links.
class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    final drawer = ShapeshiftDrawer.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ShapeshiftDrawerHeader(title: 'Options'),
        ShapeshiftDrawerTile(label: 'Details', onTap: () => drawer.show('details')),
      ],
    );
  }
}

/// A taller view with a back action.
class _Details extends StatelessWidget {
  const _Details();

  @override
  Widget build(BuildContext context) {
    final drawer = ShapeshiftDrawer.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ShapeshiftDrawerHeader(
          title: 'Details',
          description: 'A longer view, so the sheet grows to fit it.',
        ),
        const SizedBox(height: 200),
        ShapeshiftDrawerAction(label: 'Back', onTap: drawer.back),
      ],
    );
  }
}

/// A drawer under an [Overlay] on an 800x600 screen.
class _Host extends StatelessWidget {
  const _Host({this.reduceMotion = false, this.onOpen, this.onView});

  final bool reduceMotion;
  final ValueChanged<bool>? onOpen;
  final ValueChanged<String>? onView;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(size: const Size(800, 600), disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xFF0A0A0A)),
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Center(
                  child: ShapeshiftDrawer(
                    onOpenChanged: onOpen,
                    onViewChanged: onView,
                    views: {
                      'default': (context) => const _Home(),
                      'details': (context) => const _Details(),
                    },
                    child: const _Trigger(),
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

Rect _sheet(WidgetTester tester) => tester.getRect(
  find.ancestor(of: find.byType(ShapeshiftDrawerHeader), matching: find.byType(ClipRRect)).first,
);

void main() {
  testWidgets('opens from the trigger and slides up', (tester) async {
    final opens = <bool>[];
    await tester.pumpWidget(_Host(onOpen: opens.add));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final rising = _sheet(tester).top;
    await tester.pumpAndSettle();
    expect(_sheet(tester).top, lessThan(rising));
    expect(_sheet(tester).bottom, closeTo(584, 1), reason: '16 px above the bottom');
    expect(find.text('Options'), findsOneWidget);
    expect(opens, [true]);
  });

  testWidgets('morphs between views, growing to fit, and goes back', (tester) async {
    final views = <String>[];
    await tester.pumpWidget(_Host(onView: views.add));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final small = _sheet(tester).height;

    await tester.tap(find.text('Details'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Options'), findsOneWidget, reason: 'cross-fading out');
    await tester.pumpAndSettle();
    expect(find.text('Options'), findsNothing);
    expect(_sheet(tester).height, greaterThan(small + 150));

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Options'), findsOneWidget);
    expect(_sheet(tester).height, closeTo(small, 1));
    expect(views, ['details', 'default']);
  });

  testWidgets('the backdrop, Escape and a drag down close it', (tester) async {
    final opens = <bool>[];
    await tester.pumpWidget(_Host(onOpen: opens.add));

    Future<void> open() async {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Options'), findsOneWidget);
    }

    await open();
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('Options'), findsNothing);

    await open();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Options'), findsNothing);

    await open();
    await tester.drag(find.text('Options'), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(find.text('Options'), findsNothing);
    expect(opens, [true, false, true, false, true, false]);
  });

  testWidgets('a short drag springs back', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final top = _sheet(tester).top;
    await tester.timedDrag(find.text('Options'), const Offset(0, 20), const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(_sheet(tester).top, closeTo(top, 1));
  });

  testWidgets('reopens on the first view', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Options'), findsOneWidget);
  });

  testWidgets('no animation when motion is reduced', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Options'), findsOneWidget);
    await tester.tap(find.text('Details'));
    await tester.pump();
    expect(find.text('Options'), findsNothing);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
