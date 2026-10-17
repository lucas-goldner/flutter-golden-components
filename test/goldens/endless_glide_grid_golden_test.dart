@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const Size _viewport = Size(480, 300);

const List<List<Color>> _gradients = [
  [Color(0xFFF5C451), Color(0xFFB7800A)],
  [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
  [Color(0xFFF472B6), Color(0xFFBE185D)],
  [Color(0xFF34D399), Color(0xFF047857)],
  [Color(0xFFFB923C), Color(0xFFC2410C)],
  [Color(0xFFA78BFA), Color(0xFF6D28D9)],
];

/// A numbered gradient tile.
class _Tile extends StatelessWidget {
  const _Tile(this.index);

  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradients[index % _gradients.length],
        ),
      ),
      child: Center(
        child: Text(
          (index + 1).toString().padLeft(2, '0'),
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
  }
}

/// A labelled dark viewport around one grid configuration.
class _Frame extends StatelessWidget {
  const _Frame({required this.boundary, required this.label, required this.grid});

  final Key boundary;
  final String label;
  final Widget grid;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: boundary,
          child: Container(
            width: _viewport.width,
            color: const Color(0xFF0E0E10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                ),
                SizedBox(height: _viewport.height, child: grid),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One static configuration for the layouts sheet.
@immutable
class _Layout {
  const _Layout(this.label, {this.columns = 4, this.stagger = true, this.spacing = 14});

  final String label;
  final int columns;
  final bool stagger;
  final double spacing;
}

const List<_Layout> _layouts = [
  _Layout('Default: staggered columns'),
  _Layout('stagger: false', stagger: false),
  _Layout('columns: 3, spacing: 6', columns: 3, spacing: 6),
];

/// A grid configured from a [_Layout].
class _LayoutGrid extends StatelessWidget {
  const _LayoutGrid(this.layout);

  final _Layout layout;

  @override
  Widget build(BuildContext context) => EndlessGlideGrid(
    itemCount: 12,
    columns: layout.columns,
    tileSize: const Size(90, 110),
    spacing: layout.spacing,
    stagger: layout.stagger,
    itemBuilder: (context, i) => _Tile(i),
  );
}

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = Size(_viewport.width, _viewport.height + 40);
    view.devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset());

  testWidgets('EndlessGlideGrid layouts', (tester) async {
    final images = <ui.Image>[];
    for (final layout in _layouts) {
      final key = GlobalKey();
      await tester.pumpWidget(
        _Frame(boundary: key, label: layout.label, grid: _LayoutGrid(layout)),
      );
      // Pan a little so the grid isn't aligned to the viewport corner.
      await tester.dragFrom(const Offset(240, 170), const Offset(-35, -45));
      await tester.pumpAndSettle();
      images.add(await captureBoundary(tester, key));
    }
    await expectSheet(tester, images, 'endless_glide_grid_layouts.png');
  });

  testWidgets('EndlessGlideGrid fling: tilt, shrink and friction', (tester) async {
    final key = GlobalKey();
    const grid = _LayoutGrid(_Layout('fling'));
    await tester.pumpWidget(_Frame(boundary: key, label: 'Fling', grid: grid));
    await tester.flingFrom(const Offset(360, 170), const Offset(-120, -20), 2400);

    final frames = <ui.Image>[];
    var elapsed = Duration.zero;
    for (final ms in const [0, 80, 200, 400, 800, 2000]) {
      final at = Duration(milliseconds: ms);
      await advance(tester, at - elapsed);
      elapsed = at;
      // Same widget types in the same places, so the grid keeps its state.
      await tester.pumpWidget(
        _Frame(boundary: key, label: 'Fling left at 2400 px/s, t = $ms ms', grid: grid),
      );
      frames.add(await captureBoundary(tester, key));
    }
    await expectSheet(tester, frames, 'endless_glide_grid_fling.png');
    await tester.pumpAndSettle();
  });
}
