import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controls.dart';
import 'theme.dart';

/// Kind of external link, which picks its icon.
enum LinkKind { repo, star, x, website }

/// An external link shown in the gallery.
@immutable
class GalleryLink {
  const GalleryLink({required this.kind, required this.label, required this.url});

  final LinkKind kind;
  final String label;
  final String url;
}

const String kRepoUrl = 'https://github.com/lucas-goldner/flutter-golden-components';

/// Project and author links, in display order.
const List<GalleryLink> galleryLinks = [
  GalleryLink(kind: LinkKind.repo, label: 'GitHub', url: kRepoUrl),
  // GitHub has no direct "star" URL; the button is on the repo page.
  GalleryLink(kind: LinkKind.star, label: 'Star on GitHub', url: kRepoUrl),
  GalleryLink(kind: LinkKind.x, label: '@LucasGoldner', url: 'https://x.com/LucasGoldner'),
  GalleryLink(kind: LinkKind.website, label: 'lucas-goldner.com', url: 'https://lucas-goldner.com'),
];

/// Opens [url] outside the app (a new tab on the web).
Future<void> openExternal(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');

/// "About" card for the home page: what the project is, who made it, links.
class InfoSection extends StatelessWidget {
  const InfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ABOUT', style: GalleryText.overline(p)),
          const SizedBox(height: 10),
          Text('Open source, MIT licensed', style: GalleryText.heading(p)),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Made by '),
                TextSpan(
                  text: 'Lucas Goldner',
                  style: TextStyle(color: p.text, fontWeight: FontWeight.w600),
                ),
                const TextSpan(
                  text:
                      '. Every component is free to use and copy. If you like them, '
                      'a star on GitHub helps a lot.',
                ),
              ],
            ),
            style: GalleryText.body(p),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final link in galleryLinks)
                _LinkButton(link: link, highlighted: link.kind == LinkKind.star),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact icon-only links for the sidebar footer.
class SidebarLinks extends StatelessWidget {
  const SidebarLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final link in galleryLinks)
          if (link.kind != LinkKind.repo) _IconLink(link: link),
      ],
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.link, this.highlighted = false});

  final GalleryLink link;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final fg = highlighted ? p.onAccent : p.text;
    return Semantics(
      link: true,
      label: link.label,
      excludeSemantics: true,
      child: Pressable(
        onTap: () => openExternal(link.url),
        builder: (context, hover, pressed) => AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: highlighted
                ? (hover ? p.accent.withValues(alpha: 0.85) : p.accent)
                : (hover || pressed ? p.surfaceAlt : p.background),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: highlighted ? p.accent : p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LinkIcon(kind: link.kind, color: fg, size: 14),
              const SizedBox(width: 7),
              Text(
                link.label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconLink extends StatelessWidget {
  const _IconLink({required this.link});

  final GalleryLink link;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Semantics(
      link: true,
      label: link.label,
      excludeSemantics: true,
      child: Pressable(
        onTap: () => openExternal(link.url),
        builder: (context, hover, pressed) => AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hover || pressed ? p.surfaceAlt : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _LinkIcon(
            kind: link.kind,
            color: link.kind == LinkKind.star ? p.accent : (hover ? p.text : p.muted),
            size: 14,
          ),
        ),
      ),
    );
  }
}

class _LinkIcon extends StatelessWidget {
  const _LinkIcon({required this.kind, required this.color, required this.size});

  final LinkKind kind;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _LinkIconPainter(kind, color)),
    );
  }
}

/// Small line icons drawn on a 16x16 grid.
class _LinkIconPainter extends CustomPainter {
  _LinkIconPainter(this.kind, this.color);

  final LinkKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 16);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    switch (kind) {
      case LinkKind.repo:
        // </>
        canvas
          ..drawPath(
            Path()
              ..moveTo(5, 4)
              ..lineTo(1.5, 8)
              ..lineTo(5, 12),
            stroke,
          )
          ..drawPath(
            Path()
              ..moveTo(11, 4)
              ..lineTo(14.5, 8)
              ..lineTo(11, 12),
            stroke,
          )
          ..drawLine(const Offset(9.2, 2.8), const Offset(6.8, 13.2), stroke);
      case LinkKind.star:
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final r = i.isEven ? 7.4 : 3.2;
          final a = -math.pi / 2 + i * math.pi / 5;
          final point = Offset(8 + r * math.cos(a), 8.4 + r * math.sin(a));
          i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path..close(), Paint()..color = color);
      case LinkKind.x:
        canvas
          ..drawLine(const Offset(2.5, 2.5), const Offset(13.5, 13.5), stroke..strokeWidth = 1.9)
          ..drawLine(const Offset(13.5, 2.5), const Offset(2.5, 13.5), stroke..strokeWidth = 1.2);
      case LinkKind.website:
        const c = Offset(8, 8);
        canvas
          ..drawCircle(c, 6.4, stroke..strokeWidth = 1.4)
          ..drawOval(Rect.fromCenter(center: c, width: 5.6, height: 12.8), stroke)
          ..drawLine(const Offset(1.8, 8), const Offset(14.2, 8), stroke);
    }
  }

  @override
  bool shouldRepaint(_LinkIconPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

/// A small underlined text link, used for credits.
class CreditLink extends StatelessWidget {
  const CreditLink({super.key, required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Semantics(
      link: true,
      child: Pressable(
        onTap: () => openExternal(url),
        builder: (context, hover, pressed) => Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: hover ? p.text : p.muted,
            decoration: TextDecoration.underline,
            decorationColor: p.muted.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
