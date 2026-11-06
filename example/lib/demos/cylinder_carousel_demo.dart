import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';

const List<String> _words = [
  'night',
  'city',
  'sky',
  'sunset',
  'sunrise',
  'winter',
  'skyscraper',
  'building',
  'cityscape',
  'architecture',
  'street',
  'lights',
  'downtown',
  'bridge',
];

const List<List<Color>> _gradients = [
  [Color(0xFFFF8A8A), Color(0xFFFF5F7E)],
  [Color(0xFF7FB2FF), Color(0xFFD9B8FF)],
  [Color(0xFF3DE07A), Color(0xFF34F5D6)],
  [Color(0xFFFF6F91), Color(0xFFFFE04D)],
  [Color(0xFFFFB86B), Color(0xFFFF6FA3)],
  [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
  [Color(0xFF4FACFE), Color(0xFF00F2FE)],
  [Color(0xFFF6D365), Color(0xFFFDA085)],
  [Color(0xFF5EE7DF), Color(0xFFB490CA)],
  [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
  [Color(0xFF43E97B), Color(0xFF38F9D7)],
  [Color(0xFFFA709A), Color(0xFFFEE140)],
  [Color(0xFF30CFD0), Color(0xFF330867)],
  [Color(0xFFFF9A8B), Color(0xFFFF6A88)],
];

/// Playground for [CylinderCarousel].
class CylinderCarouselDemo extends StatefulWidget {
  const CylinderCarouselDemo({super.key});

  @override
  State<CylinderCarouselDemo> createState() => _CylinderCarouselDemoState();
}

class _CylinderCarouselDemoState extends State<CylinderCarouselDemo> {
  late double _circumference;
  late double _perspective;
  late double _cards;
  late bool _snap;
  late bool _lightbox;
  String _status = 'Drag to spin, tap a card to open it';

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _circumference = 1800;
    _perspective = 1;
    _cards = 14;
    _snap = true;
    _lightbox = true;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final count = _cards.round();
    return Playground(
      preview: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            Expanded(
              child: CylinderCarousel(
                height: constraints.maxHeight - 44,
                circumference: constraints.maxWidth < 640 ? _circumference * 0.6 : _circumference,
                perspective: _perspective / 1000,
                snap: _snap,
                lightbox: _lightbox,
                onCardTap: (i) => setState(() => _status = 'Opened ${_words[i]}'),
                onFrontChanged: (i) => setState(() => _status = 'In front: ${_words[i]}'),
                cards: [for (var i = 0; i < count; i++) _Card(index: i)],
              ),
            ),
            SizedBox(
              height: 44,
              child: Center(
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9B9BA6)),
                ),
              ),
            ),
          ],
        ),
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Cylinder',
          children: [
            SliderControl(
              label: 'Cards',
              value: _cards,
              min: 6,
              max: 14,
              step: 1,
              onChanged: (v) => _set(() => _cards = v),
            ),
            SliderControl(
              label: 'Circumference',
              value: _circumference,
              min: 900,
              max: 2600,
              step: 50,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _circumference = v),
            ),
            SliderControl(
              label: 'Perspective',
              value: _perspective,
              min: 0,
              max: 2,
              step: 0.05,
              onChanged: (v) => _set(() => _perspective = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Behaviour',
          children: [
            ToggleControl(
              label: 'Snap to a card',
              value: _snap,
              onChanged: (v) => _set(() => _snap = v),
            ),
            ToggleControl(
              label: 'Open cards in a lightbox',
              value: _lightbox,
              onChanged: (v) => _set(() => _lightbox = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// A gradient card with its word in the corner.
class _Card extends StatelessWidget {
  const _Card({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradients[index % _gradients.length],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _words[index % _words.length],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
