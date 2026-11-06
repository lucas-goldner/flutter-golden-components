import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

/// Playground for [NotchCard].
class NotchCardDemo extends StatefulWidget {
  const NotchCardDemo({super.key});

  @override
  State<NotchCardDemo> createState() => _NotchCardDemoState();
}

class _NotchCardDemoState extends State<NotchCardDemo> {
  late bool _newTag;
  late bool _featured;
  late double _radius;
  late double _height;
  late bool _zoom;
  late bool _wash;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _newTag = true;
    _featured = true;
    _radius = 20;
    _height = 280;
    _zoom = true;
    _wash = true;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: p.text),
              child: NotchCard(
                key: ValueKey(_run),
                color: p.surface,
                child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NotchCardMedia(
                          height: _height,
                          zoom: _zoom ? 1.05 : 1,
                          wash: _wash ? 0.35 : 0,
                          labels: [
                            if (_featured)
                              NotchLabel(
                                corner: NotchCorner.bottomLeft,
                                radius: _radius,
                                child: Text(
                                  'FEATURED',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.1,
                                    color: p.muted,
                                  ),
                                ),
                              ),
                            if (_newTag)
                              NotchLabel(
                                corner: NotchCorner.topRight,
                                radius: _radius * 0.8,
                                color: p.text,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Text(
                                  'New',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: p.surface,
                                  ),
                                ),
                              ),
                          ],
                          child: const _Landscape(),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: NotchCardStagger(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Alpine Adventures',
                                style: GalleryText.heading(p).copyWith(fontSize: 20),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 16),
                                child: Text(
                                  'Discover breathtaking mountain landscapes and experience '
                                  'the serenity of nature at its finest.',
                                  style: GalleryText.body(p),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.only(top: 16),
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide(color: p.border)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFE8C468), Color(0xFFF4A462)],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Sarah Chen',
                                        style: GalleryText.label(p).copyWith(fontSize: 14),
                                      ),
                                    ),
                                    Text('5 min read', style: GalleryText.value(p)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Straddles the bottom edge of the image.
                    Positioned(
                      right: 20,
                      top: _height - 18,
                      child: NotchCardReveal(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: p.text,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Read more',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: p.surface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      onReset: () => _set(() {
        _reset();
        _run++;
      }),
      controls: [
        ControlSection(
          title: 'Labels',
          children: [
            ToggleControl(
              label: '"New" tag (top right)',
              value: _newTag,
              onChanged: (v) => _set(() => _newTag = v),
            ),
            ToggleControl(
              label: '"Featured" label (bottom left)',
              value: _featured,
              onChanged: (v) => _set(() => _featured = v),
            ),
            SliderControl(
              label: 'Notch radius',
              value: _radius,
              min: 8,
              max: 36,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _radius = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Media',
          children: [
            SliderControl(
              label: 'Image height',
              value: _height,
              min: 160,
              max: 360,
              step: 4,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _height = v),
            ),
            ToggleControl(
              label: 'Zoom on hover',
              value: _zoom,
              onChanged: (v) => _set(() => _zoom = v),
            ),
            ToggleControl(
              label: 'Bottom wash',
              value: _wash,
              onChanged: (v) => _set(() => _wash = v),
            ),
            GalleryButton(label: 'Replay entrance', onTap: () => _set(() => _run++)),
          ],
        ),
      ],
    );
  }
}

/// A dusky mountain gradient standing in for a photo.
class _Landscape extends StatelessWidget {
  const _Landscape();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF2CD3D1), Color(0xFF2A6C95), Color(0xFF3B1E6E)],
        ),
      ),
    );
  }
}
