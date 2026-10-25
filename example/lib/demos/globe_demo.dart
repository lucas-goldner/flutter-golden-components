import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

enum _Style { light, dark, gold }

enum _Routes { hub, atlantic, tour, none }

/// Cities used for routes, markers and focus buttons.
const _cities = <String, GlobeLatLng>{
  'Tokyo': GlobeLatLng(35.68, 139.69),
  'San Francisco': GlobeLatLng(37.77, -122.42),
  'London': GlobeLatLng(51.51, -0.13),
  'Sydney': GlobeLatLng(-33.87, 151.21),
  'Singapore': GlobeLatLng(1.35, 103.82),
  'Dubai': GlobeLatLng(25.20, 55.27),
  'New York': GlobeLatLng(40.71, -74.01),
  'Paris': GlobeLatLng(48.86, 2.35),
  'Rio': GlobeLatLng(-22.91, -43.17),
  'Madrid': GlobeLatLng(40.42, -3.70),
  'Mexico City': GlobeLatLng(19.43, -99.13),
  'Lisbon': GlobeLatLng(38.72, -9.14),
  'Toronto': GlobeLatLng(43.65, -79.38),
  'Los Angeles': GlobeLatLng(34.05, -118.24),
  'Cape Town': GlobeLatLng(-33.92, 18.42),
};

const _routes = <_Routes, List<(String, String)>>{
  _Routes.hub: [
    ('Tokyo', 'San Francisco'),
    ('Tokyo', 'London'),
    ('Tokyo', 'Sydney'),
    ('Tokyo', 'Singapore'),
    ('Tokyo', 'Dubai'),
  ],
  _Routes.atlantic: [
    ('London', 'New York'),
    ('Paris', 'Rio'),
    ('Madrid', 'Mexico City'),
    ('Lisbon', 'Toronto'),
    ('London', 'Cape Town'),
  ],
  _Routes.tour: [
    ('New York', 'London'),
    ('London', 'Dubai'),
    ('Dubai', 'Singapore'),
    ('Singapore', 'Sydney'),
    ('Sydney', 'Los Angeles'),
    ('Los Angeles', 'New York'),
  ],
  _Routes.none: [],
};

const _routeColors = [
  Color(0xFFE3A008),
  Color(0xFF3B82F6),
  Color(0xFFEC4899),
  Color(0xFF10B981),
  Color(0xFF8B5CF6),
  Color(0xFFF97316),
];

const _continentNames = {
  GlobeContinent.africa: 'Africa',
  GlobeContinent.antarctica: 'Antarctica',
  GlobeContinent.asia: 'Asia',
  GlobeContinent.europe: 'Europe',
  GlobeContinent.northAmerica: 'N. America',
  GlobeContinent.oceania: 'Oceania',
  GlobeContinent.southAmerica: 'S. America',
};

/// Colors for one look of the globe.
@immutable
class _Look {
  const _Look({
    required this.sphere,
    required this.shade,
    required this.dots,
    required this.glow,
    required this.highlight,
  });

  final Color sphere;
  final Color shade;
  final Color dots;
  final Color glow;
  final Color highlight;
}

const _looks = {
  _Style.light: _Look(
    sphere: Color(0xFFF8F8FA),
    shade: Color(0xFFDCDDE2),
    dots: Color(0xFF8E9099),
    glow: Color(0x00000000),
    highlight: Color(0xFFE3A008),
  ),
  _Style.dark: _Look(
    sphere: Color(0xFF1C1C22),
    shade: Color(0xFF09090B),
    dots: Color(0xFFD4D4D8),
    glow: Color(0x33FFFFFF),
    highlight: Color(0xFFF5C451),
  ),
  _Style.gold: _Look(
    sphere: Color(0xFF241B08),
    shade: Color(0xFF0A0802),
    dots: Color(0xFFF5C451),
    glow: Color(0x66F5C451),
    highlight: Color(0xFFFFFFFF),
  ),
};

/// Playground for [Globe].
class GlobeDemo extends StatefulWidget {
  const GlobeDemo({super.key});

  @override
  State<GlobeDemo> createState() => _GlobeDemoState();
}

class _GlobeDemoState extends State<GlobeDemo> {
  final _controller = GlobeController();

  late _Style _style;
  late double _dotSize;
  late Set<GlobeContinent> _continents;
  late Set<String> _countries;
  late _Routes _route;
  late bool _planes;
  late bool _loop;
  late bool _markers;
  late double _arcSeconds;
  late double _staggerSeconds;
  late double _height;
  late double _spin;
  GlobeCountry? _tapped;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reset() {
    _style = _Style.light;
    _dotSize = 1.6;
    _continents = {};
    _countries = {'JPN'};
    _route = _Routes.hub;
    _planes = true;
    _loop = true;
    _markers = true;
    _arcSeconds = 1.8;
    _staggerSeconds = 0.5;
    _height = 0.35;
    _spin = 6;
    _tapped = null;
  }

  void _set(VoidCallback fn) => setState(fn);

  void _onCountryTap(GlobeCountry country) => setState(() {
    _tapped = country;
    if (!_countries.remove(country.code)) _countries.add(country.code);
  });

  @override
  Widget build(BuildContext context) {
    final look = _looks[_style]!;
    final routes = _routes[_route]!;
    final ends = {
      for (final (a, b) in routes) ...[a, b],
    };
    return Playground(
      preview: _Preview(
        tapped: _tapped,
        tappedHighlighted: _tapped != null && _countries.contains(_tapped!.code),
        globe: Globe(
          controller: _controller,
          initialFocus: const GlobeLatLng(30, 100),
          autoRotateSpeed: _spin,
          onCountryTap: _onCountryTap,
          sphereColor: look.sphere,
          shadeColor: look.shade,
          dotColor: look.dots,
          glowColor: look.glow,
          highlightColor: look.highlight,
          dotSize: _dotSize,
          showPlanes: _planes,
          loopArcs: _loop,
          arcDuration: Duration(milliseconds: (_arcSeconds * 1000).round()),
          arcStagger: Duration(milliseconds: (_staggerSeconds * 1000).round()),
          highlights: [
            for (final c in _continents) GlobeHighlight.continent(c),
            for (final code in _countries) GlobeHighlight.country(code),
          ],
          arcs: [
            for (var i = 0; i < routes.length; i++)
              GlobeArc(
                from: _cities[routes[i].$1]!,
                to: _cities[routes[i].$2]!,
                color: _style == _Style.gold
                    ? const Color(0xFFFFFFFF)
                    : _routeColors[i % _routeColors.length],
                height: _height,
              ),
          ],
          markers: [
            if (_markers)
              for (final city in ends) GlobeMarker(at: _cities[city]!, size: 3.5),
          ],
        ),
      ),
      onReset: () => _set(_reset),
      controls: [
        ControlSection(
          title: 'Look',
          children: [
            SegmentedControl<_Style>(
              label: 'Style',
              value: _style,
              options: const {_Style.light: 'Light', _Style.dark: 'Dark', _Style.gold: 'Gold'},
              onChanged: (v) => _set(() => _style = v),
            ),
            SliderControl(
              label: 'Dot size',
              value: _dotSize,
              min: 0.8,
              max: 3.2,
              step: 0.1,
              format: (v) => v.toStringAsFixed(1),
              onChanged: (v) => _set(() => _dotSize = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Highlights',
          children: [
            ChipsControl<GlobeContinent>(
              label: 'Continents',
              options: _continentNames,
              selected: _continents,
              onChanged: (v) => _set(() => _continents = v),
            ),
            _Hint(
              text: _countries.isEmpty
                  ? 'Tap a country on the globe to highlight it.'
                  : 'Countries: ${_countries.map((c) => GlobeCountry.byCode(c)?.name ?? c).join(', ')}. '
                        'Tap the globe to add or remove.',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: GalleryButton(
                label: 'Clear highlights',
                onTap: () => _set(() {
                  _continents = {};
                  _countries = {};
                }),
              ),
            ),
          ],
        ),
        ControlSection(
          title: 'Routes',
          children: [
            SegmentedControl<_Routes>(
              label: 'Arcs',
              value: _route,
              options: const {
                _Routes.hub: 'Tokyo hub',
                _Routes.atlantic: 'Atlantic',
                _Routes.tour: 'World tour',
                _Routes.none: 'None',
              },
              onChanged: (v) => _set(() => _route = v),
            ),
            ToggleControl(
              label: 'Planes',
              value: _planes,
              onChanged: (v) => _set(() => _planes = v),
            ),
            ToggleControl(label: 'Loop', value: _loop, onChanged: (v) => _set(() => _loop = v)),
            ToggleControl(
              label: 'City markers',
              value: _markers,
              onChanged: (v) => _set(() => _markers = v),
            ),
            SliderControl(
              label: 'Flight time',
              value: _arcSeconds,
              min: 0.4,
              max: 5,
              step: 0.1,
              format: (v) => '${v.toStringAsFixed(1)} s',
              onChanged: (v) => _set(() => _arcSeconds = v),
            ),
            SliderControl(
              label: 'Stagger',
              value: _staggerSeconds,
              min: 0,
              max: 2,
              step: 0.1,
              format: (v) => '${v.toStringAsFixed(1)} s',
              onChanged: (v) => _set(() => _staggerSeconds = v),
            ),
            SliderControl(
              label: 'Arc height',
              value: _height,
              min: 0,
              max: 1,
              step: 0.05,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => _set(() => _height = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Motion',
          children: [
            SliderControl(
              label: 'Auto-rotate',
              value: _spin,
              min: 0,
              max: 40,
              step: 1,
              format: (v) => v == 0 ? 'off' : '${v.round()}°/s',
              onChanged: (v) => _set(() => _spin = v),
            ),
            ChipsControl<String>(
              label: 'Focus on',
              multiple: false,
              options: const {
                'Tokyo': 'Tokyo',
                'Paris': 'Paris',
                'New York': 'New York',
                'Sydney': 'Sydney',
                'Rio': 'Rio',
              },
              selected: const {},
              onChanged: (v) {
                _set(() => _spin = 0);
                _controller.focus(_cities[v.single]!);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Text(text, style: GalleryText.body(p).copyWith(fontSize: 12));
  }
}

/// The globe centered on the stage, with a pill naming the tapped country.
class _Preview extends StatelessWidget {
  const _Preview({required this.globe, required this.tapped, required this.tappedHighlighted});

  final Globe globe;
  final GlobeCountry? tapped;
  final bool tappedHighlighted;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final country = tapped;
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(padding: const EdgeInsets.all(20), child: globe),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: p.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.border),
                ),
                child: Text(
                  country == null
                      ? 'Drag to spin. Tap a country to highlight it.'
                      : '${country.name} · ${_continentNames[country.continent]}'
                            '${tappedHighlighted ? '  (highlighted)' : ''}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.text),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
