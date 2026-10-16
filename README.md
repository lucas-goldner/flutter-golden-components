# Flutter Golden Components

A growing collection of high quality, animated Flutter components, each with a
live playground where you can tune every setting.

**The rule:** every component is built with Flutter's `widgets` library only
(plus the layers below it: `rendering`, `painting`, `animation`, `physics`,
`services`, `foundation`). No Material, no Cupertino. That keeps them
design-system agnostic and drop-in for any app. A test
(`test/widgets_only_test.dart`) enforces it.

UI is also always split into widget classes, never into functions or methods
that return widgets (`test/code_style_test.dart`). See [CLAUDE.md](CLAUDE.md)
for the full contributor rules.

## Components

| #   | Component        | Description |
| --- | ---------------- | ----------- |
| 001 | `SmoothCaretField` | A text input whose caret glides to each new cursor position on a spring, stretching while it travels and blinking with a soft fade at rest. |

## Usage

```yaml
dependencies:
  flutter_golden_components:
    git: https://github.com/lucas-goldner/flutter-golden-components
```

```dart
import 'package:flutter_golden_components/flutter_golden_components.dart';

SmoothCaretField(
  placeholder: 'Type something...',
  caretColor: const Color(0xFFF5C451),
  spring: const SpringDescription(mass: 1, stiffness: 520, damping: 34),
)
```

`SmoothCaretField` wraps `EditableText`, so it brings no decoration of its own:
wrap it in whatever padding, border or background fits your design.

## Gallery

`example/` is the gallery app. It runs on **web, iOS and macOS**, and every
component has a settings panel (sliders, toggles, presets, colors) to adjust
its behaviour live, plus a **Code** tab showing its syntax-highlighted Dart
source and a **Copy code** button. The gallery chrome itself is also widgets-only.

```sh
cd example
flutter run -d chrome   # or: -d macos, or an iOS simulator
```

Deep links work on the web, e.g. `/smooth-caret`.

### Deploying to Vercel

`vercel.json` is set up so importing this repo in Vercel deploys the gallery
with no extra configuration:

- `scripts/vercel-build.sh` downloads a pinned Flutter SDK (override with the
  `FLUTTER_VERSION` env var) and runs `flutter build web --release` in
  `example/`.
- The output directory is `example/build/web`, and every path is rewritten to
  `index.html` so deep links resolve.

Every push to the production branch redeploys automatically once the repo is
connected in Vercel.

### Social card and icons

`example/web/og.png` (the Open Graph / Twitter image), the favicon, the web
app icons and the iOS/macOS app icons are all rendered from `scripts/og/`:
`og.html` for the card and `icon.js` for the mark. After changing either, run:

```sh
NODE_PATH=$(npm root -g) node scripts/og/render.js   # needs playwright
```

## Adding a component

1. Put the widget in `lib/src/<name>/` and export it from
   `lib/flutter_golden_components.dart`. Import only
   `package:flutter/widgets.dart` (or lower layers).
2. List `lib/src/<name>/` under `flutter: assets:` in `pubspec.yaml`, so the
   gallery can show and copy its source.
3. Add tests in `test/`.
4. Add a playground in `example/lib/demos/` using the controls in
   `example/lib/gallery/controls.dart`, and register it (with its
   `sourcePath`) in `example/lib/gallery/registry.dart`.

## License

MIT, see [LICENSE](LICENSE).
