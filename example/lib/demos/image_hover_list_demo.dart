import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

const List<(String, String, List<Color>)> _links = [
  ('About', 'Learn what we do here', [Color(0xFF6366F1), Color(0xFFEC4899)]),
  ('Clients', 'We work with great people', [Color(0xFF10B981), Color(0xFF3B82F6)]),
  ('Portfolio', 'Our work speaks for itself', [Color(0xFFF59E0B), Color(0xFFEF4444)]),
  ('Careers', 'We are always hiring', [Color(0xFF22D3EE), Color(0xFF8B5CF6)]),
  ('Fun', 'Incase you are bored', [Color(0xFFF472B6), Color(0xFFFBBF24)]),
];

/// Playground for [ImageHoverList].
class ImageHoverListDemo extends StatefulWidget {
  const ImageHoverListDemo({super.key});

  @override
  State<ImageHoverListDemo> createState() => _ImageHoverListDemoState();
}

class _ImageHoverListDemoState extends State<ImageHoverListDemo> {
  late double _imageWidth;
  late double _stiffness;
  late double _fontSize;
  late bool _subtitles;
  late bool _accent;
  String? _opened;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _imageWidth = 200;
    _stiffness = 12;
    _fontSize = 44;
    _subtitles = true;
    _accent = true;
    _opened = null;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: p.text),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ImageHoverList(
                    imageSize: Size(_imageWidth, _imageWidth * 0.68),
                    stiffness: _stiffness,
                    titleStyle: TextStyle(fontSize: _fontSize),
                    highlight: _accent ? p.accent : null,
                    onTap: (i) => setState(() => _opened = _links[i].$1),
                    items: [
                      for (final (title, subtitle, colors) in _links)
                        ImageHoverItem(
                          title: title,
                          subtitle: _subtitles ? subtitle : null,
                          image: _Photo(colors: colors, label: title),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _opened == null ? 'Hover a link, then click it' : 'Opened $_opened',
                    style: GalleryText.value(p),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Image',
          children: [
            SliderControl(
              label: 'Width',
              value: _imageWidth,
              min: 100,
              max: 320,
              step: 4,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _imageWidth = v),
            ),
            SliderControl(
              label: 'Follow',
              value: _stiffness,
              min: 3,
              max: 30,
              step: 1,
              format: (v) => v < 8 ? 'lazy' : (v > 20 ? 'snappy' : 'soft'),
              onChanged: (v) => _set(() => _stiffness = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Links',
          children: [
            SliderControl(
              label: 'Title size',
              value: _fontSize,
              min: 24,
              max: 64,
              step: 2,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _fontSize = v),
            ),
            ToggleControl(
              label: 'Subtitles',
              value: _subtitles,
              onChanged: (v) => _set(() => _subtitles = v),
            ),
            ToggleControl(
              label: 'Accent on hover',
              value: _accent,
              onChanged: (v) => _set(() => _accent = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// A gradient "photo" with a small caption.
class _Photo extends StatelessWidget {
  const _Photo({required this.colors, required this.label});

  final List<Color> colors;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            label.toLowerCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              color: Color(0xE6FFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}
