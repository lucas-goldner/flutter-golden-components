import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'gallery/registry.dart';
import 'gallery/shell.dart';
import 'gallery/theme.dart';

void main() {
  // Clean URLs on the web (/smooth-caret instead of /#/smooth-caret).
  usePathUrlStrategy();
  runApp(const GalleryApp());
}

/// The component gallery, built with the widgets library only.
class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key, this.fontFamily});

  /// Overrides the platform's default font. Golden tests set this so text
  /// renders with a real, bundled font instead of the test font.
  final String? fontFamily;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> with WidgetsBindingObserver {
  /// User override of the platform brightness, if any.
  Brightness? _brightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  Brightness get _effective =>
      _brightness ?? WidgetsBinding.instance.platformDispatcher.platformBrightness;

  void _toggle() => setState(() {
    _brightness = _effective == Brightness.dark ? Brightness.light : Brightness.dark;
  });

  Route<void> _route(RouteSettings settings) {
    final component = componentForRoute(settings.name);
    final page = component == null ? const HomePage() : ComponentPage(component: component);
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: component?.route ?? '/'),
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondary) => page,
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _effective == Brightness.dark ? GalleryPalette.dark : GalleryPalette.light;
    return GalleryTheme(
      palette: palette,
      onToggleBrightness: _toggle,
      child: WidgetsApp(
        title: 'Golden Components',
        color: palette.accent,
        debugShowCheckedModeBanner: false,
        textStyle: TextStyle(fontFamily: widget.fontFamily, fontSize: 14, color: palette.text),
        onGenerateRoute: _route,
        // Deep links like /smooth-caret open that component directly
        // instead of stacking it on top of the home page.
        onGenerateInitialRoutes: (initial) => [_route(RouteSettings(name: initial))],
      ),
    );
  }
}
