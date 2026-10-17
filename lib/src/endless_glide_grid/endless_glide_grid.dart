import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// An endless, two-dimensional grid of tiles you can drag in any direction,
/// which keeps gliding with momentum after release.
///
/// Mouse wheels and trackpads pan it too (trackpad swipes glide on as well). The [itemCount] tiles repeat
/// forever in a pattern [columns] wide; odd columns can be staggered by half
/// a tile, and tiles shrink and tilt with speed so motion feels physical.
///
/// Tiles are built once per index and reused while panning, so
/// [itemBuilder] runs again only when this widget or its dependencies change.
class EndlessGlideGrid extends StatefulWidget {
  /// Creates an endless glide grid of [itemCount] repeating tiles.
  const EndlessGlideGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.columns = 5,
    this.tileSize = const Size(220, 280),
    this.spacing = 24,
    this.friction = 0.06,
    this.stagger = true,
    this.tilt = 1,
    this.squash = 1,
    this.initialOffset = Offset.zero,
    this.onTileTap,
  }) : assert(itemCount > 0),
       assert(columns > 0),
       assert(friction > 0 && friction < 1),
       assert(tilt >= 0),
       assert(squash >= 0);

  /// Number of distinct tiles before the pattern repeats.
  final int itemCount;

  /// Builds tile `index`, from 0 until [itemCount].
  final IndexedWidgetBuilder itemBuilder;

  /// Number of distinct columns in the repeating pattern.
  final int columns;

  /// Size of each tile.
  final Size tileSize;

  /// Gap between tiles, horizontally and vertically.
  final double spacing;

  /// Fraction of velocity kept after one second of gliding (0-1, exclusive).
  /// Lower values stop sooner.
  final double friction;

  /// Whether odd columns are offset by half a tile.
  final bool stagger;

  /// Strength of the speed-based tilt; 0 disables it, 1 is the default.
  final double tilt;

  /// Strength of the speed-based shrink; 0 disables it, 1 is the default.
  final double squash;

  /// Where the grid starts, relative to tile 0 at the top left corner.
  final Offset initialOffset;

  /// Called with the tile index when a tile is tapped (not dragged).
  final ValueChanged<int>? onTileTap;

  @override
  State<EndlessGlideGrid> createState() => _EndlessGlideGridState();
}

class _EndlessGlideGridState extends State<EndlessGlideGrid> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);

  /// How far the grid has been panned.
  late Offset _offset = widget.initialOffset;

  /// Glide velocity once released, in logical pixels per second.
  Offset _velocity = Offset.zero;

  /// Velocity measured while dragging, used for tilt and trackpad flings.
  Offset _dragVelocity = Offset.zero;

  /// Smoothed velocity that drives tilt and shrink.
  Offset _visualVelocity = Offset.zero;

  Duration _last = Duration.zero;
  bool _dragging = false;

  /// Built tiles by index, reused across frames while panning.
  final Map<int, Widget> _tiles = {};

  @override
  void didUpdateWidget(EndlessGlideGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tiles.clear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tiles.clear();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _ensureTicking() {
    if (_ticker.isActive) return;
    _last = Duration.zero;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    setState(() {
      if (!_dragging) {
        _offset += _velocity * dt;
        _velocity *= math.pow(widget.friction, dt).toDouble();
      }
      _dragVelocity *= math.exp(-dt * 8);
      final target = _dragging ? _dragVelocity : _velocity;
      _visualVelocity += (target - _visualVelocity) * (1 - math.exp(-dt * 10));
    });
    if (!_dragging && _velocity.distance < 4 && _visualVelocity.distance < 4) {
      _velocity = Offset.zero;
      _visualVelocity = Offset.zero;
      _ticker.stop();
    }
  }

  void _startDrag() {
    _dragging = true;
    _velocity = Offset.zero;
    _dragVelocity = Offset.zero;
    _ensureTicking();
  }

  void _dragBy(Offset delta) {
    setState(() => _offset += delta);
    _dragVelocity = delta * 60;
  }

  void _release(Offset velocity) {
    _dragging = false;
    _velocity = velocity;
    _ensureTicking();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      final delta = (event as PointerScrollEvent).scrollDelta;
      setState(() => _offset -= delta);
      _velocity = -delta * 8;
      _ensureTicking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tile = widget.tileSize;
    final cellW = tile.width + widget.spacing;
    final cellH = tile.height + widget.spacing;
    final rows = (widget.itemCount / widget.columns).ceil();
    final speed = _visualVelocity.distance;
    final squash = (speed / 9000 * widget.squash).clamp(0.0, 0.14 * widget.squash);
    final tilt = (_visualVelocity.dx / 30000 * widget.tilt).clamp(
      -0.08 * widget.tilt,
      0.08 * widget.tilt,
    );
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateY(tilt * 3)
      ..rotateZ(tilt)
      ..scaleByDouble(1 - squash, 1 - squash, 1, 1);
    final onTileTap = widget.onTileTap;

    return Listener(
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (_) => _startDrag(),
        onPanUpdate: (d) => _dragBy(d.delta),
        onPanEnd: (d) => _release(d.velocity.pixelsPerSecond),
        onPanCancel: () => _release(Offset.zero),
        child: MouseRegion(
          cursor: _dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cells = _visibleCells(constraints.biggest, cellW, cellH, rows);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final (:col, :row, :index, :rect) in cells)
                      _GlideTile(
                        key: ValueKey((col, row)),
                        rect: rect,
                        transform: transform,
                        index: index,
                        onTap: onTileTap,
                        child: _tiles[index] ??= widget.itemBuilder(context, index),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Every grid cell that overlaps [viewport] (plus a one-cell margin), with
  /// its repeating tile index and on-screen rect.
  Iterable<({int col, int row, int index, Rect rect})> _visibleCells(
    Size viewport,
    double cellW,
    double cellH,
    int rows,
  ) sync* {
    final tile = widget.tileSize;
    final firstCol = (-_offset.dx / cellW).floor() - 1;
    final lastCol = ((viewport.width - _offset.dx) / cellW).ceil();
    for (var col = firstCol; col <= lastCol; col++) {
      final stagger = widget.stagger && col.isOdd ? tile.height / 2 : 0.0;
      final firstRow = ((-_offset.dy - stagger) / cellH).floor() - 1;
      final lastRow = ((viewport.height - _offset.dy - stagger) / cellH).ceil();
      for (var row = firstRow; row <= lastRow; row++) {
        yield (
          col: col,
          row: row,
          index: ((row % rows) * widget.columns + col % widget.columns) % widget.itemCount,
          rect: Rect.fromLTWH(
            col * cellW + _offset.dx,
            row * cellH + _offset.dy + stagger,
            tile.width,
            tile.height,
          ),
        );
      }
    }
  }
}

/// One positioned, speed-transformed tile.
class _GlideTile extends StatelessWidget {
  const _GlideTile({
    super.key,
    required this.rect,
    required this.transform,
    required this.index,
    required this.onTap,
    required this.child,
  });

  final Rect rect;
  final Matrix4 transform;
  final int index;
  final ValueChanged<int>? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onTap = this.onTap;
    return Positioned.fromRect(
      rect: rect,
      child: Transform(
        alignment: Alignment.center,
        transform: transform,
        child: GestureDetector(
          onTap: onTap == null ? null : () => onTap(index),
          child: RepaintBoundary(child: child),
        ),
      ),
    );
  }
}
