import 'package:flutter/widgets.dart';

import '../demos/aurora_backdrop_demo.dart';
import '../demos/blur_fade_demo.dart';
import '../demos/cylinder_carousel_demo.dart';
import '../demos/digit_roll_demo.dart';
import '../demos/endless_glide_grid_demo.dart';
import '../demos/glide_highlight_demo.dart';
import '../demos/globe_demo.dart';
import '../demos/goo_blobs_demo.dart';
import '../demos/jump_text_demo.dart';
import '../demos/kinetic_line_demo.dart';
import '../demos/live_feed_demo.dart';
import '../demos/magnify_dock_demo.dart';
import '../demos/marquee_demo.dart';
import '../demos/metal_button_demo.dart';
import '../demos/morph_card_demo.dart';
import '../demos/notch_card_demo.dart';
import '../demos/smooth_caret_demo.dart';
import '../demos/step_flow_demo.dart';
import '../demos/stretch_slider_demo.dart';

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
  GalleryComponent(
    number: 8,
    slug: 'digit-roll',
    name: 'Digit Roll',
    description:
        'A number whose digits roll to each new value like an odometer, one spring per digit, '
        'rippling from the right with motion blur. New places grow in, old ones shrink away.',
    tags: const ['text', 'number', 'spring'],
    sourcePath: 'lib/src/digit_roll/digit_roll.dart',
    builder: (context) => const DigitRollDemo(),
  ),
  GalleryComponent(
    number: 9,
    slug: 'stretch-slider',
    name: 'Stretch Slider',
    description:
        'A slider that stretches like rubber when you drag past either end, then snaps back on a '
        'spring. Horizontal or vertical, with steps, a thumb, signed fills and icons inside or out.',
    tags: const ['input', 'slider', 'spring'],
    sourcePath: 'lib/src/stretch_slider/stretch_slider.dart',
    builder: (context) => const StretchSliderDemo(),
  ),
  GalleryComponent(
    number: 10,
    slug: 'step-flow',
    name: 'Step Flow',
    description:
        'A multi-step flow: a numbers, dots or bars indicator (or a side rail), content that '
        'slides in the direction of travel while its height eases, and a Back / Continue footer.',
    tags: const ['navigation', 'form', 'animation'],
    sourcePath: 'lib/src/step_flow/step_flow.dart',
    builder: (context) => const StepFlowDemo(),
  ),
  GalleryComponent(
    number: 11,
    slug: 'jump-text',
    name: 'Jump Text',
    description:
        'Words or letters spring up from below with a tilt, one after another, like story '
        'captions. Spring, stagger, rise and tilt are all adjustable.',
    tags: const ['text', 'spring', 'entrance'],
    sourcePath: 'lib/src/jump_text/jump_text.dart',
    builder: (context) => const JumpTextDemo(),
  ),
  GalleryComponent(
    number: 12,
    slug: 'kinetic-line',
    name: 'Kinetic Line',
    description:
        'A line that builds itself word by word: each word slides in from the right with a soft '
        'blur and pushes the line so it stays centred, holds, then lifts out for the next phrase.',
    tags: const ['text', 'loop', 'blur'],
    sourcePath: 'lib/src/kinetic_line/kinetic_line.dart',
    builder: (context) => const KineticLineDemo(),
  ),
  GalleryComponent(
    number: 13,
    slug: 'glide-highlight',
    name: 'Glide Highlight',
    description:
        'One highlight that glides on a spring behind whichever item is active: tabs, toolbars '
        'or a grid of cards. Activates on tap, keyboard or hover.',
    tags: const ['navigation', 'spring', 'hover'],
    sourcePath: 'lib/src/glide_highlight/glide_highlight.dart',
    builder: (context) => const GlideHighlightDemo(),
  ),
  GalleryComponent(
    number: 14,
    slug: 'magnify-dock',
    name: 'Magnify Dock',
    description:
        'A dock whose icons swell on a spring as the pointer passes over them, with labels '
        'that float up. Works with touch drags and the keyboard too.',
    tags: const ['navigation', 'hover', 'spring'],
    sourcePath: 'lib/src/magnify_dock/magnify_dock.dart',
    builder: (context) => const MagnifyDockDemo(),
  ),
  GalleryComponent(
    number: 15,
    slug: 'morph-card',
    name: 'Morph Card',
    description:
        'A card that morphs on a spring into a centred dialog over a blurred backdrop, and back. '
        'Close by tapping outside, Escape or a close button.',
    tags: const ['dialog', 'spring', 'card'],
    sourcePath: 'lib/src/morph_card/morph_card.dart',
    builder: (context) => const MorphCardDemo(),
  ),
  GalleryComponent(
    number: 16,
    slug: 'cylinder-carousel',
    name: 'Cylinder Carousel',
    description:
        'Cards around a 3D cylinder you spin by dragging: it coasts with the fling and settles '
        'on a card. Arrow keys turn it; tap a card to open it large.',
    tags: const ['carousel', '3d', 'gesture'],
    sourcePath: 'lib/src/cylinder_carousel/cylinder_carousel.dart',
    builder: (context) => const CylinderCarouselDemo(),
  ),
  GalleryComponent(
    number: 17,
    slug: 'aurora-backdrop',
    name: 'Aurora Backdrop',
    description:
        'Soft curtains of aurora light drifting behind your content, gathering in one corner. '
        'Palettes, light and dark skies, speed, intensity and softness.',
    tags: const ['background', 'ambient', 'gradient'],
    sourcePath: 'lib/src/aurora_backdrop/aurora_backdrop.dart',
    builder: (context) => const AuroraBackdropDemo(),
  ),
  GalleryComponent(
    number: 18,
    slug: 'notch-card',
    name: 'Notch Card',
    description:
        'A card whose image has labels notched into its corners with concave fillets. The image '
        'zooms and an action rises in on hover; the text staggers in.',
    tags: const ['card', 'hover', 'layout'],
    sourcePath: 'lib/src/notch_card/notch_card.dart',
    builder: (context) => const NotchCardDemo(),
  ),
  GalleryComponent(
    number: 19,
    slug: 'metal-button',
    name: 'Metal Button',
    description:
        'A button wrapped in a ring of slowly flowing liquid metal, with a rolling glint and a '
        'soft glow. Chromatic, silver or gold, four surface styles, pill or round.',
    tags: const ['button', 'shader', 'ambient'],
    sourcePath: 'lib/src/metal_button/metal_button.dart',
    builder: (context) => const MetalButtonDemo(),
  ),
];

GalleryComponent? componentForRoute(String? route) {
  for (final c in galleryComponents) {
    if (c.route == route) return c;
  }
  return null;
}
