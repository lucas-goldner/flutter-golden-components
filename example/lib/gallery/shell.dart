import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'code_view.dart';
import 'controls.dart';
import 'registry.dart';
import 'theme.dart';

/// Width above which the sidebar is shown next to the content.
const double kSidebarBreakpoint = 900;

/// Page frame: sidebar on wide screens, plain content on narrow ones.
class GalleryShell extends StatelessWidget {
  const GalleryShell({super.key, required this.selected, required this.child});

  /// Route of the selected component, or `null` on the home page.
  final String? selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final wide = MediaQuery.sizeOf(context).width >= kSidebarBreakpoint;
    return ColoredBox(
      color: p.background,
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 260, child: _Sidebar(selected: selected)),
                Container(width: 1, color: p.border),
                Expanded(child: child),
              ],
            )
          : child,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return ColoredBox(
      color: p.surface,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 16, 18),
              child: Pressable(
                onTap: () => openRoute(context, '/'),
                builder: (context, hover, pressed) => const _Logo(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text('COMPONENTS', style: GalleryText.overline(p)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (final c in galleryComponents)
                    _SidebarItem(component: c, selected: c.route == selected),
                ],
              ),
            ),
            Container(height: 1, color: p.border),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(child: Text('widgets library only', style: GalleryText.value(p))),
                  const ThemeToggle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.component, required this.selected});

  final GalleryComponent component;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        onTap: () => openRoute(context, component.route),
        builder: (context, hover, pressed) => AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? p.accent.withValues(alpha: 0.14) : (hover ? p.surfaceAlt : null),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                component.badge,
                style: GalleryText.value(p).copyWith(color: selected ? p.accent : p.muted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  component.name,
                  style: GalleryText.label(
                    p,
                  ).copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Row(
      children: [
        const SizedBox.square(dimension: 28, child: CustomPaint(painter: _LogoMarkPainter())),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'Golden Components',
            overflow: TextOverflow.ellipsis,
            style: GalleryText.heading(p),
          ),
        ),
      ],
    );
  }
}

/// The Golden Components mark: a gold chevron on a dark tile. Same shape as
/// `scripts/og/icon.js`, which renders the favicon and app icons.
class _LogoMarkPainter extends CustomPainter {
  const _LogoMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64);
    const tile = Rect.fromLTWH(0, 0, 64, 64);
    final rrect = RRect.fromRectAndRadius(tile, const Radius.circular(14));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1C1A16), Color(0xFF0A0A0C)],
        ).createShader(tile),
    );
    canvas.drawRRect(
      rrect.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0x38F5C451),
    );
    // Mark, scaled 0.86 around (32, 33) like the SVG.
    canvas
      ..translate(32, 33)
      ..scale(0.86)
      ..translate(-32, -33);
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFDE68A), Color(0xFFF5C451), Color(0xFFC98A12)],
      ).createShader(const Rect.fromLTWH(19, 13, 22, 40));
    canvas
      ..drawLine(const Offset(41, 13), const Offset(19, 35), gold)
      ..drawPath(
        Path()
          ..moveTo(41, 31)
          ..lineTo(29.5, 42.5)
          ..lineTo(40, 53),
        gold,
      );
  }

  @override
  bool shouldRepaint(_LogoMarkPainter oldDelegate) => false;
}

/// Switches between light and dark.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = GalleryTheme.of(context);
    final p = theme.palette;
    return GalleryButton(
      label: p.isDark ? 'Light' : 'Dark',
      onTap: theme.onToggleBrightness,
      leading: CustomPaint(size: const Size.square(12), painter: _HalfMoonPainter(p.text)),
    );
  }
}

class _HalfMoonPainter extends CustomPainter {
  _HalfMoonPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    canvas.drawCircle(
      c,
      r - 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 0.75),
      -math.pi / 2,
      math.pi,
      true,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_HalfMoonPainter oldDelegate) => oldDelegate.color != color;
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.65, size.height * 0.2)
      ..lineTo(size.width * 0.3, size.height * 0.5)
      ..lineTo(size.width * 0.65, size.height * 0.8);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) => oldDelegate.color != color;
}

/// Navigates to [route], replacing the current page on wide layouts so the
/// sidebar acts like tabs, and pushing on narrow ones so "back" works.
void openRoute(BuildContext context, String route) {
  final nav = Navigator.of(context);
  if (ModalRoute.of(context)?.settings.name == route) return;
  final wide = MediaQuery.sizeOf(context).width >= kSidebarBreakpoint;
  if (wide || route == '/') {
    nav.pushNamedAndRemoveUntil(route, (_) => false);
  } else {
    nav.pushNamed(route);
  }
}

/// Landing page: intro and a card per component.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final wide = MediaQuery.sizeOf(context).width >= kSidebarBreakpoint;
    return GalleryShell(
      selected: null,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          children: [
            if (!wide)
              Row(
                children: [
                  const Expanded(child: _Logo()),
                  const ThemeToggle(),
                ],
              ),
            if (!wide) const SizedBox(height: 32),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('A collection of golden\nFlutter components', style: GalleryText.title(p)),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Text(
                        'Polished, animated components built with nothing but '
                        "Flutter's widgets library: no Material, no Cupertino. "
                        'Pick one to play with its settings live.',
                        style: GalleryText.body(p).copyWith(fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 28),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = math.max(1, (constraints.maxWidth / 280).floor());
                        final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            for (final c in galleryComponents)
                              SizedBox(
                                width: width,
                                child: _ComponentCard(component: c),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComponentCard extends StatelessWidget {
  const _ComponentCard({required this.component});

  final GalleryComponent component;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Semantics(
      button: true,
      child: Pressable(
        onTap: () => openRoute(context, component.route),
        builder: (context, hover, pressed) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(18),
          transform: Matrix4.translationValues(0, hover ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: hover ? p.accent.withValues(alpha: 0.6) : p.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(component.badge, style: GalleryText.value(p).copyWith(color: p.accent)),
              const SizedBox(height: 8),
              Text(component.name, style: GalleryText.heading(p)),
              const SizedBox(height: 6),
              Text(
                component.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GalleryText.body(p).copyWith(fontSize: 13),
              ),
              const SizedBox(height: 12),
              _Tags(tags: component.tags),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tags extends StatelessWidget {
  const _Tags({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final t in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(6)),
            child: Text(t, style: GalleryText.value(p).copyWith(fontSize: 11)),
          ),
      ],
    );
  }
}

/// A component's page: header plus its playground.
class ComponentPage extends StatefulWidget {
  const ComponentPage({super.key, required this.component});

  final GalleryComponent component;

  @override
  State<ComponentPage> createState() => _ComponentPageState();
}

class _ComponentPageState extends State<ComponentPage> {
  bool _showCode = false;

  GalleryComponent get component => widget.component;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final wide = MediaQuery.sizeOf(context).width >= kSidebarBreakpoint;
    return GalleryShell(
      selected: component.route,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(wide ? 24 : 12, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!wide) ...[
                    Semantics(
                      button: true,
                      label: 'Back',
                      child: Pressable(
                        onTap: () {
                          final nav = Navigator.of(context);
                          if (nav.canPop()) {
                            nav.pop();
                          } else {
                            openRoute(context, '/');
                          }
                        },
                        builder: (context, hover, pressed) => Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: hover || pressed ? p.surfaceAlt : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomPaint(painter: _ChevronPainter(p.text)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              component.badge,
                              style: GalleryText.value(p).copyWith(color: p.accent),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                component.name,
                                style: GalleryText.title(p).copyWith(fontSize: 22),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(component.description, style: GalleryText.body(p)),
                      ],
                    ),
                  ),
                  if (!wide) ...[const SizedBox(width: 8), const ThemeToggle()],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 0, 16, 14),
              child: Row(
                children: [
                  _ViewTabs(showCode: _showCode, onChanged: (v) => setState(() => _showCode = v)),
                  const Spacer(),
                  CopyCodeButton(component: component, compact: !wide),
                ],
              ),
            ),
            Container(height: 1, color: p.border),
            Expanded(
              // IndexedStack keeps the playground's settings while the code
              // is shown.
              child: IndexedStack(
                index: _showCode ? 1 : 0,
                sizing: StackFit.expand,
                children: [
                  component.builder(context),
                  CodeView(component: component),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview / Code switch in the component header.
class _ViewTabs extends StatelessWidget {
  const _ViewTabs({required this.showCode, required this.onChanged});

  final bool showCode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(9)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewTab(label: 'Preview', selected: !showCode, onTap: () => onChanged(false)),
          _ViewTab(label: 'Code', selected: showCode, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _ViewTab extends StatelessWidget {
  const _ViewTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        onTap: onTap,
        builder: (context, hover, pressed) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? p.surface : (hover ? p.surface.withValues(alpha: 0.4) : null),
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? p.text : p.muted,
            ),
          ),
        ),
      ),
    );
  }
}
