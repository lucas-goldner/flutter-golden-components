import 'package:flutter/widgets.dart';

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
];

GalleryComponent? componentForRoute(String? route) {
  for (final c in galleryComponents) {
    if (c.route == route) return c;
  }
  return null;
}
