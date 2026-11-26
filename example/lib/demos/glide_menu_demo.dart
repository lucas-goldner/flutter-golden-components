import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

/// Playground for [GlideMenu].
class GlideMenuDemo extends StatefulWidget {
  const GlideMenuDemo({super.key});

  @override
  State<GlideMenuDemo> createState() => _GlideMenuDemoState();
}

class _GlideMenuDemoState extends State<GlideMenuDemo> {
  late double _duration;
  late double _closeDelay;
  late double _gap;
  late double _radius;
  late bool _surface;
  String _status = 'Hover the menu';

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _duration = 320;
    _closeDelay = 160;
    _gap = 10;
    _radius = 14;
    _surface = true;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: DefaultTextStyle.merge(
        style: TextStyle(color: p.text, fontSize: 14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            children: [
              // Scrolls sideways on screens narrower than the tabs.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: GlideMenu(
                  duration: Duration(milliseconds: _duration.round()),
                  closeDelay: Duration(milliseconds: _closeDelay.round()),
                  gap: _gap,
                  radius: _radius,
                  panelColor: _surface ? p.surface : null,
                  borderColor: _surface ? p.border : null,
                  onChanged: (i) =>
                      setState(() => _status = i == null ? 'Closed' : 'Open: ${_labels[i]}'),
                  items: const [
                    GlideMenuItem(label: 'Products', content: _Products()),
                    GlideMenuItem(label: 'Pricing', content: _Pricing()),
                    GlideMenuItem(label: 'Blog', content: _Blog()),
                  ],
                ),
              ),
              const Spacer(),
              Text(_status, style: GalleryText.value(p)),
            ],
          ),
        ),
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Motion',
          children: [
            SliderControl(
              label: 'Glide',
              value: _duration,
              min: 100,
              max: 900,
              step: 20,
              format: (v) => '${v.round()} ms',
              onChanged: (v) => _set(() => _duration = v),
            ),
            SliderControl(
              label: 'Close after',
              value: _closeDelay,
              min: 0,
              max: 600,
              step: 20,
              format: (v) => '${v.round()} ms',
              onChanged: (v) => _set(() => _closeDelay = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Panel',
          children: [
            ToggleControl(
              label: 'Match the page surface',
              value: _surface,
              onChanged: (v) => _set(() => _surface = v),
            ),
            SliderControl(
              label: 'Gap',
              value: _gap,
              min: 0,
              max: 32,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _gap = v),
            ),
            SliderControl(
              label: 'Radius',
              value: _radius,
              min: 0,
              max: 28,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _radius = v),
            ),
          ],
        ),
      ],
    );
  }
}

const List<String> _labels = ['Products', 'Pricing', 'Blog'];

/// A heading over a few links.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.links});

  final String title;
  final List<String> links;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: p.muted)),
        const SizedBox(height: 8),
        for (final link in links) ...[
          Text(link, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _Products extends StatelessWidget {
  const _Products();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Group(title: 'Startup', links: ['Bookkeeping', 'Invoicing']),
          SizedBox(width: 32),
          _Group(title: 'Scaleup', links: ['Live coaching', 'Reviews', 'Tax and VAT']),
          SizedBox(width: 32),
          _Group(title: 'Enterprise', links: ['White glove', 'SOX compliance', 'Audit']),
        ],
      ),
    );
  }
}

class _Pricing extends StatelessWidget {
  const _Pricing();

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (name, price) in const [('Free', r'$0'), ('Team', r'$12'), ('Pro', r'$29')])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(price, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(name, style: TextStyle(fontSize: 12, color: p.muted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Blog extends StatelessWidget {
  const _Blog();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Post(colors: [Color(0xFF6366F1), Color(0xFFEC4899)], title: 'Shipping faster'),
          SizedBox(width: 14),
          _Post(colors: [Color(0xFF10B981), Color(0xFF3B82F6)], title: 'Our 2026 roadmap'),
        ],
      ),
    );
  }
}

/// A post card: a gradient thumbnail and a title.
class _Post extends StatelessWidget {
  const _Post({required this.colors, required this.title});

  final List<Color> colors;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 150,
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(colors: colors),
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
