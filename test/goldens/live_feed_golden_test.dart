@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

@immutable
class _Note {
  const _Note(this.title, this.subtitle, this.time, this.color);

  final String title;
  final String subtitle;
  final String time;
  final Color color;
}

const List<_Note> _notes = [
  _Note('Payment received', 'Invoice #1042', '15m', Color(0xFF00C9A7)),
  _Note('New sign-up', 'mia@example.com', '10m', Color(0xFFFFB800)),
  _Note('New message', 'Can we ship today?', '5m', Color(0xFFFF3D71)),
  _Note('Deploy finished', 'production · 42s', '2m', Color(0xFF1E86FF)),
];

const TextStyle _base = TextStyle(fontFamily: 'Roboto', color: Color(0xFFF4F4F5));

/// A notification card.
class _Card extends StatelessWidget {
  const _Card(this.note);

  final _Note note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: note.color, borderRadius: BorderRadius.circular(11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title, style: _base.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  note.subtitle,
                  style: _base.copyWith(fontSize: 11, color: const Color(0xFFA1A1AA)),
                ),
              ],
            ),
          ),
          Text(note.time, style: _base.copyWith(fontSize: 11, color: const Color(0xFF71717A))),
        ],
      ),
    );
  }
}

/// A labelled, clipped frame around the feed.
class _Frame extends StatelessWidget {
  const _Frame({required this.boundary, required this.label, required this.feed});

  final Key boundary;
  final String label;
  final Widget feed;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: boundary,
          child: Container(
            width: 300,
            height: 300,
            color: const Color(0xFF0E0E10),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _base.copyWith(fontSize: 11, color: const Color(0xFFA1A1AA))),
                const SizedBox(height: 10),
                Expanded(
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: double.infinity,
                      child: feed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The feed under test: one card per second, looping.
class _Feed extends StatelessWidget {
  const _Feed();

  @override
  Widget build(BuildContext context) {
    return LiveFeed(
      interval: const Duration(seconds: 1),
      gap: 10,
      loop: true,
      maxVisible: 5,
      children: [for (final note in _notes) _Card(note)],
    );
  }
}

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(300, 300);
    view.devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset());

  testWidgets('LiveFeed: a new item springs in and pushes the rest down', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(_Frame(boundary: key, label: 'start', feed: const _Feed()));
    // Let three items arrive and settle: t = 2.6 s.
    await advance(tester, const Duration(milliseconds: 2600));

    // The fourth arrives at t = 3 s; capture its spring.
    final frames = <ui.Image>[];
    var elapsed = 2600;
    for (final t in const [2600, 3016, 3064, 3128, 3224, 3600]) {
      await advance(tester, Duration(milliseconds: t - elapsed));
      elapsed = t;
      final since = t - 3000;
      await tester.pumpWidget(
        _Frame(
          boundary: key,
          label: since < 0 ? 'before, 3 items' : 'arrival + $since ms',
          feed: const _Feed(),
        ),
      );
      frames.add(await captureBoundary(tester, key));
    }
    await expectSheet(tester, frames, 'live_feed_arrival.png', axis: Axis.horizontal);
    await tester.pumpWidget(const SizedBox());
  });
}
