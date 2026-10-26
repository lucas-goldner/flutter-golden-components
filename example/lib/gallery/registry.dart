import 'package:flutter/widgets.dart';

import '../demos/blur_fade_demo.dart';
import '../demos/endless_glide_grid_demo.dart';
import '../demos/globe_demo.dart';
import '../demos/goo_blobs_demo.dart';
import '../demos/live_feed_demo.dart';
import '../demos/marquee_demo.dart';
import '../demos/smooth_caret_demo.dart';

/// One component listed in the gallery.
@immutable
class GalleryComponent {
  const GalleryComponent({
    required this.number,
    required this.slug,
    required this.name,
    required this.description,
    required this.tags,
    required this.sourcePath,
    required this.builder,
  });

  /// Running number, shown as a badge (001, 002, ...).
  final int number;

  /// URL segment, e.g. `/smooth-caret`.
  final String slug;
  final String name;
  final String description;
  final List<String> tags;

  /// Path of the component's source inside the package, e.g.
  /// `lib/src/smooth_caret/smooth_caret_field.dart`. Its folder must be
  /// listed under `flutter: assets:` in the package's pubspec.yaml.
  final String sourcePath;

  /// Builds the playground (preview + settings) for this component.
  final WidgetBuilder builder;

  String get route => '/$slug';

  /// Asset key the gallery loads [sourcePath] from.
  String get sourceAsset => 'packages/flutter_golden_components/$sourcePath';
  String get badge => number.toString().padLeft(3, '0');
}

/// Every component in the gallery, in display order.
final List<GalleryComponent> galleryComponents = [
  GalleryComponent(
    number: 1,
    slug: 'smooth-caret',
    name: 'Smooth Caret',
    description:
        'A text input whose caret glides to each new cursor position on a spring, '
        'leaving a soft motion trail as it travels and blinking with a soft fade at rest.',
    tags: const ['input', 'text', 'spring'],
    sourcePath: 'lib/src/smooth_caret/smooth_caret_field.dart',
    builder: (context) => const SmoothCaretDemo(),
  ),
  GalleryComponent(
    number: 2,
    slug: 'endless-glide-grid',
    name: 'Endless Glide Grid',
    description:
        'An endless, staggered grid you can drag, fling and wheel-scroll in any direction. '
        'It glides on with friction after release, and tiles tilt and shrink with speed.',
    tags: const ['gesture', 'scroll', 'physics'],
    sourcePath: 'lib/src/endless_glide_grid/endless_glide_grid.dart',
    builder: (context) => const EndlessGlideGridDemo(),
  ),
  GalleryComponent(
    number: 3,
    slug: 'marquee',
    name: 'Marquee',
    description:
        'An endless scrolling strip of any widgets, horizontal or vertical. It runs at a '
        'constant speed, fills any width, fades at the edges and eases to a stop on hover.',
    tags: const ['animation', 'carousel', 'loop'],
    sourcePath: 'lib/src/marquee/marquee.dart',
    builder: (context) => const MarqueeDemo(),
  ),
  GalleryComponent(
    number: 4,
    slug: 'blur-fade',
    name: 'Blur Fade',
    description:
        'Reveals any widget by fading it in from a soft blur while it slides into place, '
        'on mount or as it scrolls into view. Stagger a group for a cascading entrance.',
    tags: const ['animation', 'scroll', 'reveal'],
    sourcePath: 'lib/src/blur_fade/blur_fade.dart',
    builder: (context) => const BlurFadeDemo(),
  ),
  GalleryComponent(
    number: 5,
    slug: 'live-feed',
    name: 'Live Feed',
    description:
        'A feed that reveals items one at a time, newest on top. Each one springs in and '
        'pushes the rest down, like incoming notifications. Loops, caps and pauses.',
    tags: const ['list', 'animation', 'spring'],
    sourcePath: 'lib/src/live_feed/live_feed.dart',
    builder: (context) => const LiveFeedDemo(),
  ),
  GalleryComponent(
    number: 6,
    slug: 'globe',
    name: 'Globe',
    description:
        'An interactive dotted globe. Highlight countries or continents, draw flight routes '
        'that animate from start to end with a plane, pin pulsing markers, and spin it.',
    tags: const ['map', 'canvas', 'animation'],
    sourcePath: 'lib/src/globe/globe.dart',
    builder: (context) => const GlobeDemo(),
  ),
  GalleryComponent(
    number: 7,
    slug: 'goo-blobs',
    name: 'Goo Blobs',
    description:
        'Glowing blobs of goo that drift like wax in a lava lamp: they heat up, rise, cool, '
        'sink, and melt into each other on the way. One follows your pointer.',
    tags: const ['animation', 'canvas', 'ambient'],
    sourcePath: 'lib/src/goo_blobs/goo_blobs.dart',
    builder: (context) => const GooBlobsDemo(),
  ),
];

GalleryComponent? componentForRoute(String? route) {
  for (final c in galleryComponents) {
    if (c.route == route) return c;
  }
  return null;
}
