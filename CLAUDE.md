# CLAUDE.md

Rules for working in this repo. They take precedence over the vendored
Flutter/Dart skills in `.claude/skills/` whenever the two disagree.

## Project

- `lib/` is the `flutter_golden_components` package: one folder per
  component under `lib/src/<name>/`, exported from
  `lib/flutter_golden_components.dart`.
- `example/` is the gallery app (web, iOS, macOS). Each component has a
  playground in `example/lib/demos/` registered in
  `example/lib/gallery/registry.dart`.
- The web gallery deploys to Vercel via `vercel.json` and
  `scripts/vercel-build.sh`. Every route rewrites to `/index.html`, so do not
  enable `cleanUrls`: it redirects `/index.html` and breaks deep links.

## Hard rules

1. **Widgets library only.** Import `package:flutter/widgets.dart` and lower
   layers (`foundation`, `services`, `rendering`, `painting`, `animation`,
   `physics`, `scheduler`, `gestures`). Never import `material.dart` or
   `cupertino.dart`, in `lib/` or in the gallery.
   (`test/widgets_only_test.dart` enforces this for `lib/`.)
2. **No functions that return widgets.** Never write helper methods or
   functions such as `Widget _buildHeader()`, `Widget _row(String label)` or
   local closures like `Widget tab(...) {}`. Extract a private widget class
   instead (`class _Header extends StatelessWidget`), passing what it needs
   through its constructor. This also applies to tests (use a `_Host`
   widget, not `Widget _host(...)`). The only exceptions are `build`
   methods and builder callbacks the framework asks for (`builder:`,
   `pageBuilder:`, `itemBuilder:` ...), and those should stay small.
   (`test/code_style_test.dart` enforces this.)
3. **New component checklist:**
   - Add its folder to `flutter: assets:` in the root `pubspec.yaml` so the
     gallery's Code tab and Copy button can load the source.
   - Add unit tests (`test/<name>_*_test.dart`) and golden tests
     (`test/goldens/<name>_*_golden_test.dart`) covering its states and its
     animation over time (frame sheets via `golden_utils.dart`). Generate
     with `flutter test --tags golden --update-goldens` and look at every
     image before committing.
   - Regenerate the gallery goldens in `example/` too (they pick the new
     component up from the registry).
   - Add a playground with settings for its behaviour and register it with
     its `sourcePath`.
   (`test/component_checklist_test.dart` enforces assets, tests and goldens.)

## Dart style (Effective Dart)

Follow [Effective Dart](https://dart.dev/effective-dart):

- Naming: `UpperCamelCase` types, `lowerCamelCase` members and variables,
  `lowercase_with_underscores` files. Prefix private members with `_`.
- Prefer `final` locals and fields, `const` constructors and literals where
  possible.
- Document every public API with `///` comments. Start with a one-sentence
  summary. Use `[Name]` to reference identifiers. Don't restate the obvious.
- Prefer small, single-purpose widgets and immutable value classes
  (`@immutable`) for configuration passed between widgets.
- Use pattern matching, switch expressions and records where they make code
  clearer.
- Keep `build` methods free of side effects and expensive work.
- Dispose every controller, focus node, ticker and timer you create.

## Before committing

Run from the repo root and from `example/`:

```sh
dart format --line-length 100 lib test
flutter analyze
flutter test
```

`example/` additionally: `flutter build web --release` must succeed.

Goldens are generated on Linux. Only update them for intentional visual
changes, and say so in the commit message.

## Ports from other libraries

When a component is based on another project, keep its license next to the
code (`lib/src/<name>/LICENSE_*.md`), add a header comment with the source
link, set `credit:` on its gallery entry, and list it under Credits in the
README. Endlessly animating components must hold still when
`MediaQuery.disableAnimations` is set (gallery goldens rely on it).
