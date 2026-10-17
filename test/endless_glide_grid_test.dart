import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 400x300 viewport around the grid.
class _Host extends StatelessWidget {
  const _Host({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: SizedBox(width: 400, height: 300, child: child)),
    );
  }
}

/// A plain numbered tile.
class _Tile extends StatelessWidget {
  const _Tile(this.index);

  final int index;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF334155),
      child: Center(child: Text('$index', key: ValueKey('tile-$index'))),
    );
  }
}

/// The grid under test: 6 tiles, 3 columns, 100 px tiles on a 110 px pitch.
class _Grid extends StatelessWidget {
  const _Grid({this.onTileTap, this.onBuild, this.friction = 0.06, this.stagger = false});

  final ValueChanged<int>? onTileTap;
  final ValueChanged<int>? onBuild;
  final double friction;
  final bool stagger;

  @override
  Widget build(BuildContext context) {
    return EndlessGlideGrid(
      itemCount: 6,
      columns: 3,
      tileSize: const Size(100, 100),
      spacing: 10,
      friction: friction,
      stagger: stagger,
      onTileTap: onTileTap,
      itemBuilder: (context, i) {
        onBuild?.call(i);
        return _Tile(i);
      },
    );
  }
}

/// The tile in grid cell ([col], [row]); a cell keeps its key while visible.
Finder _cell(int col, int row) =>
    find.descendant(of: find.byKey(ValueKey((col, row))), matching: find.byType(_Tile));

void main() {
  testWidgets('fills the viewport with repeating tiles', (tester) async {
    await tester.pumpWidget(const _Host(child: _Grid()));
    for (var i = 0; i < 6; i++) {
      expect(find.byKey(ValueKey('tile-$i')), findsWidgets);
    }
    // 6 distinct tiles cover more than 6 cells, so some repeat.
    expect(find.byType(_Tile).evaluate().length, greaterThan(6));
  });

  testWidgets('drags follow the pointer', (tester) async {
    await tester.pumpWidget(const _Host(child: _Grid()));
    final before = tester.getTopLeft(_cell(1, 1));
    final gesture = await tester.startGesture(tester.getCenter(find.byType(EndlessGlideGrid)));
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(-15, -10));
      await tester.pump();
    }
    final during = tester.getTopLeft(_cell(1, 1));
    // Moved by the drag (-60, -40), less the touch slop.
    expect(during.dx, lessThan(before.dx - 30));
    expect(during.dy, lessThan(before.dy - 20));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('flings keep gliding after release, then stop', (tester) async {
    await tester.pumpWidget(const _Host(child: _Grid()));
    await tester.fling(find.byType(EndlessGlideGrid), const Offset(-60, 0), 1500);
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'momentum animates on');

    final a = tester.getTopLeft(_cell(3, 1));
    await tester.pump(const Duration(milliseconds: 50));
    final b = tester.getTopLeft(_cell(3, 1));
    expect(b.dx, lessThan(a.dx), reason: 'still moving left after release');

    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'friction brings it to rest');
  });

  testWidgets('lower friction stops sooner', (tester) async {
    Future<Duration> glideTime(double friction) async {
      await tester.pumpWidget(
        _Host(
          key: UniqueKey(),
          child: _Grid(friction: friction),
        ),
      );
      await tester.fling(find.byType(EndlessGlideGrid), const Offset(-100, 0), 1500);
      var elapsed = Duration.zero;
      while (tester.binding.hasScheduledFrame) {
        await tester.pump(const Duration(milliseconds: 16));
        elapsed += const Duration(milliseconds: 16);
      }
      return elapsed;
    }

    final slippery = await glideTime(0.5);
    final sticky = await glideTime(0.01);
    expect(sticky, lessThan(slippery));
  });

  testWidgets('taps report the tile index, drags do not', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(_Host(child: _Grid(onTileTap: taps.add)));
    final tile4 = find.byKey(const ValueKey('tile-4')).hitTestable().first;
    await tester.tap(tile4);
    expect(taps, [4]);

    await tester.drag(tile4, const Offset(-80, 0));
    await tester.pumpAndSettle();
    expect(taps, [4]);
  });

  testWidgets('mouse wheel pans the grid', (tester) async {
    await tester.pumpWidget(const _Host(child: _Grid()));
    final before = tester.getTopLeft(_cell(1, 1));
    final mouse = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(mouse.hover(tester.getCenter(find.byType(EndlessGlideGrid))));
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, 40)));
    await tester.pump();
    expect(tester.getTopLeft(_cell(1, 1)).dy, closeTo(before.dy - 40, 8));
    await tester.pumpAndSettle();
  });

  testWidgets('builds each tile once and reuses it while panning', (tester) async {
    final built = <int>[];
    await tester.pumpWidget(_Host(child: _Grid(onBuild: built.add)));
    expect(built..sort(), [0, 1, 2, 3, 4, 5]);
    await tester.fling(find.byType(EndlessGlideGrid), const Offset(-200, -100), 1500);
    await tester.pumpAndSettle();
    expect(built.length, 6, reason: 'panning reuses the built tiles');
  });

  testWidgets('stagger offsets odd columns by half a tile', (tester) async {
    await tester.pumpWidget(const _Host(child: _Grid(stagger: true)));
    final origin = tester.getTopLeft(find.byType(EndlessGlideGrid)).dy;
    final tops = {
      for (final e in find.byType(_Tile).evaluate())
        (((e.renderObject! as RenderBox).localToGlobal(Offset.zero).dy - origin) % 110).round(),
    };
    // Rows sit on a 110 px pitch; staggered columns are 50 px off it.
    expect(tops, {0, 50});
  });

  testWidgets('initialOffset positions the grid', (tester) async {
    await tester.pumpWidget(
      _Host(
        child: EndlessGlideGrid(
          itemCount: 6,
          columns: 3,
          tileSize: const Size(100, 100),
          spacing: 10,
          stagger: false,
          initialOffset: const Offset(-30, -40),
          itemBuilder: (context, i) => _Tile(i),
        ),
      ),
    );
    final origin = tester.getTopLeft(find.byType(EndlessGlideGrid));
    expect(tester.getTopLeft(_cell(0, 0)) - origin, const Offset(-30, -40));
  });
}
