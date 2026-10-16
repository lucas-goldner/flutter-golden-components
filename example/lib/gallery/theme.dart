import 'package:flutter/widgets.dart';

/// Colors used throughout the gallery chrome.
@immutable
class GalleryPalette {
  const GalleryPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.onAccent,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color onAccent;

  bool get isDark => brightness == Brightness.dark;

  static const dark = GalleryPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0A0A0C),
    surface: Color(0xFF121216),
    surfaceAlt: Color(0xFF1A1A20),
    border: Color(0x1FFFFFFF),
    text: Color(0xFFF4F4F5),
    muted: Color(0xFF9B9BA6),
    accent: Color(0xFFF5C451),
    onAccent: Color(0xFF1A1405),
  );

  static const light = GalleryPalette(
    brightness: Brightness.light,
    background: Color(0xFFF7F6F2),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEFEEE8),
    border: Color(0x1A000000),
    text: Color(0xFF18181B),
    muted: Color(0xFF6B6B74),
    accent: Color(0xFFB7800A),
    onAccent: Color(0xFFFFFFFF),
  );
}

/// Provides the active [GalleryPalette] and a way to flip it.
class GalleryTheme extends InheritedWidget {
  const GalleryTheme({
    super.key,
    required this.palette,
    required this.onToggleBrightness,
    required super.child,
  });

  final GalleryPalette palette;
  final VoidCallback onToggleBrightness;

  static GalleryTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GalleryTheme>()!;

  static GalleryPalette paletteOf(BuildContext context) => of(context).palette;

  @override
  bool updateShouldNotify(GalleryTheme oldWidget) => palette != oldWidget.palette;
}

/// Shared text styles.
abstract final class GalleryText {
  static TextStyle title(GalleryPalette p) => TextStyle(
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: p.text,
  );

  static TextStyle heading(GalleryPalette p) =>
      TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.1, color: p.text);

  static TextStyle body(GalleryPalette p) => TextStyle(fontSize: 14, height: 1.45, color: p.muted);

  static TextStyle label(GalleryPalette p) =>
      TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: p.text);

  static TextStyle overline(GalleryPalette p) =>
      TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: p.muted);

  static TextStyle value(GalleryPalette p) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: p.muted,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
