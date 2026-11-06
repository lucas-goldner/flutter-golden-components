## Unreleased

- `PillSelect`: a pill field that opens a frosted, blurred list of
  options, aligned so the chosen one sits over the field (or dropping
  below); icons, disabled options, placeholder and list label; hover and
  arrow-key highlighting, Enter/Space to choose, Escape or an outside tap
  to close; screen reader labels; light/dark aware; reduced-motion
  support.
- `MetalButton`: a ring of flowing metal (chromatic, silver, gold or a
  custom palette) with a counter-rotating glint and soft glow around a
  filled, outline, soft or ghost surface; any height, width and radius
  (pill or round); hover, press and keyboard focus (brightens the ring);
  strength, ring width, speed, pause and reduced-motion support.
- `NotchCard`: a card surface with hover state (pointer, or tap on
  touch) and a deepening shadow; `NotchCardMedia` with `NotchLabel`s set
  into any corner by concave fillets and a hover zoom;
  `NotchCardReveal` for hover-revealed actions; `NotchCardStagger` for a
  rising, un-blurring text entrance; reduced-motion support.
- `AuroraBackdrop`: two layers of slanted bands drifting past each other,
  blurred and faded out from a focus point, behind any child. Palette,
  light or dark sky, speed, intensity, softness, tilt and focus; holds
  still when motion is reduced.
- `CylinderCarousel`: cards on a 3D cylinder spun by dragging (the front
  card tracks the finger), coasting with the fling and snapping to a
  card, arrow-key turns, an optional lightbox, configurable circumference
  and perspective, and reduced-motion support.
- `MorphCard`: a card whose box morphs on a spring into a centred dialog
  (corner radius, cross-fading content) over a tinted, blurred backdrop,
  and back. `MorphCardReveal` for content that drifts in after the morph,
  `MorphCardClose` and `MorphCard.close`, barrier tap and Escape to close,
  keyboard opening, focus moved into the dialog and back to the card,
  inherits the card's text style and icon theme, and reduced-motion
  support.
- `MagnifyDock`: icons swell on a spring as the pointer passes over them
  (configurable base and magnified size, reach and falloff curve), the
  dock rises to fit, and the hovered icon's label floats up. Touch drags,
  keyboard focus (magnifies like a hover) with Enter/Space activation,
  and reduced-motion support.
- `GlideHighlight`: a single highlight that glides on a spring behind the
  active item of any layout (row, wrap, grid), fading in and out when the
  selection is set or cleared. Tap, Enter/Space or hover activation,
  controlled or uncontrolled selection, custom decoration and spring,
  follows layout changes, and reduced-motion support.
- `KineticLine`: cycles phrases that build word by word around the
  centre (blurred entries from the right that push the line along, hold,
  lift-out exit). Configurable timing, distances, blur and easing, speed
  multiplier, loop, and reduced-motion support.
- `JumpText`: words or characters spring up from below with a tilt, one
  after another. Word or character units (words never break), spring,
  stagger, delay, rise, tilt, `onComplete`, and reduced-motion support.
- `StepFlow`: a multi-step flow. Numbers (with a gliding ring and
  self-drawing checks), dots or bars indicator, or a vertical rail with
  titles and subtitles; slide / fade / no transition in the direction of
  travel with the height easing between steps; Back / Continue / Complete
  footer that folds away on completion; tappable indicator with a linear
  mode, `canContinue` gating, keyboard and screen reader support, and
  reduced-motion support.
- `StretchSlider`: a slider whose track stretches like rubber when dragged
  past either end and snaps back on a spring. Spring-eased fill, thickens
  while active, horizontal or vertical, divisions with ticks, thumb, fill
  from an origin, leading/trailing widgets beside or inside the track
  (recolored where the fill covers them), relative drags, keyboard and
  screen reader support, and reduced-motion support.
- `DigitRoll`: an odometer-style number. Each digit rolls on its own spring
  with a stagger from the right, by an auto/up/down/shortest direction,
  with motion blur and soft edges. New places grow in and old ones shrink
  away. Built-in `DigitRollFormat` (decimals, min digits, grouping,
  separators, prefix/suffix), per-digit decoration, tabular figures and
  reduced-motion support.
- `GooBlobs`: lava-lamp metaballs (blur + alpha threshold goo with a glow
  layer), heat-driven rise and fall, wax pool, pointer blob, palettes,
  gooeyness, glow and reduced-motion support.
  `lightColor` publishes the light the goo gives off (blend of the hottest
  blobs' colors) to light its surroundings.
- `Globe`: dotted globe with country/continent highlights (242 countries,
  ISO codes, continents, centres), animated great-circle flight arcs with
  planes, pulsing markers, drag with momentum, auto-rotation, tap to get
  a country, `GlobeController.focus`, and reduced-motion support. Map
  data is generated by `scripts/globe/generate_globe_data.py`.
- `LiveFeed`: reveals children one per interval, newest on top, each
  springing in; loop, maxVisible cap, pause, custom spring and
  reduced-motion support.
- `BlurFade`: blur + fade + slide reveal on mount or when scrolled into
  view, with delay/stagger, direction, start scale, replay on re-entry and
  reduced-motion support.
- `Marquee`: an endless scrolling strip with px/s speed, automatic copies to fill any width, edge fade, eased
  pause on hover, vertical mode and reduced-motion support.
- `EndlessGlideGrid`: an endless 2D grid of repeating tiles with drag, fling,
  wheel and trackpad panning, friction-based momentum, staggered columns and
  speed tilt/shrink. Tiles are built once per index and reused while panning.

## 0.1.0

- `SmoothCaretField`: a text input whose caret glides to each new cursor
  position on a spring.
- Gallery app for web, iOS and macOS with live settings per component.
