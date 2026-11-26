import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

/// Playground for [MeltSearch].
class MeltSearchDemo extends StatefulWidget {
  const MeltSearchDemo({super.key});

  @override
  State<MeltSearchDemo> createState() => _MeltSearchDemoState();
}

class _MeltSearchDemoState extends State<MeltSearchDemo> {
  late double _goo;
  late double _bounce;
  late double _width;
  late double _gap;
  late bool _accent;
  String _status = 'Tap the pill';
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _goo = 7;
    _bounce = 0.5;
    _width = 260;
    _gap = 16;
    _accent = false;
  }

  void _set(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    return Playground(
      preview: DefaultTextStyle.merge(
        style: TextStyle(color: p.text),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  // Room for the open field, so it opens in place.
                  width: 44 + _gap + _width,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: MeltSearch(
                      key: ValueKey(_run),
                      goo: _goo,
                      bounce: _bounce,
                      width: _width,
                      gap: _gap,
                      color: _accent ? p.accent : null,
                      hint: 'Search components…',
                      onExpandedChanged: (open) =>
                          setState(() => _status = open ? 'Open' : 'Closed'),
                      onSubmitted: (text) => setState(() => _status = 'Searched for "$text"'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(_status, style: GalleryText.value(p)),
              ],
            ),
          ),
        ),
      ),
      onReset: () => _set(() {
        _reset();
        _run++;
        _status = 'Tap the pill';
      }),
      controls: [
        ControlSection(
          title: 'Melt',
          children: [
            SliderControl(
              label: 'Goo',
              value: _goo,
              min: 0,
              max: 14,
              step: 0.5,
              format: (v) => v == 0 ? 'off' : '${v.toStringAsFixed(1)} px',
              onChanged: (v) => _set(() => _goo = v),
            ),
            SliderControl(
              label: 'Bounce',
              value: _bounce,
              min: 0,
              max: 1,
              step: 0.05,
              onChanged: (v) => _set(() => _bounce = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Size',
          children: [
            SliderControl(
              label: 'Field width',
              value: _width,
              min: 160,
              max: 420,
              step: 10,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _width = v),
            ),
            SliderControl(
              label: 'Gap',
              value: _gap,
              min: 4,
              max: 40,
              step: 1,
              format: (v) => '${v.round()} px',
              onChanged: (v) => _set(() => _gap = v),
            ),
            ToggleControl(
              label: 'Accent colour',
              value: _accent,
              onChanged: (v) => _set(() => _accent = v),
            ),
          ],
        ),
      ],
    );
  }
}
