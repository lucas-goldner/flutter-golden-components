import 'package:flutter/widgets.dart';

import '../demos/endless_glide_grid_demo.dart';
import '../demos/marquee_demo.dart';
import '../demos/smooth_caret_demo.dart';

/// Attribution for a component based on another project.
@immutable
class GalleryCredit {
  const GalleryCredit({required this.label, required this.url});

  /// Shown on the component page, e.g. "Based on Magic UI's Marquee (MIT)".
  final String label;
  final String url;
}

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
    this.credit,
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

  /// Attribution when the component is based on someone else's work.
  final GalleryCredit? credit;

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
    credit: GalleryCredit(
      label: "Based on Magic UI's Marquee (MIT)",
      url: 'https://magicui.design/docs/components/marquee',
    ),
    builder: (context) => const MarqueeDemo(),
  ),
];

GalleryComponent? componentForRoute(String? route) {
  for (final c in galleryComponents) {
    if (c.route == route) return c;
  }
  return null;
}
