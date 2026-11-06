import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';

import '../gallery/controls.dart';
import '../gallery/playground.dart';
import '../gallery/theme.dart';

const Map<String, List<List<Color>>> _palettes = {
  'Brand': HaloDropzone.defaultColors,
  'Mint': [
    [Color(0xFF047857), Color(0xFF10B981), Color(0xFF14B8A6)],
    [Color(0xFF34D399), Color(0xFF6EE7B7), Color(0xFF2DD4BF)],
    [Color(0xFF0EA5E9), Color(0xFF22D3EE), Color(0xFF10B981)],
  ],
  'Sunset': [
    [Color(0xFFF97316), Color(0xFFF43F5E), Color(0xFFEC4899)],
    [Color(0xFFFBBF24), Color(0xFFF97316), Color(0xFFF43F5E)],
    [Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFFFB7185)],
  ],
};

/// A warm gradient standing in for an image preview.
class _Shot extends StatelessWidget {
  const _Shot();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6F91), Color(0xFFFFC75F)],
        ),
      ),
    );
  }
}

const List<HaloFile> _chips = [
  HaloFile(name: 'quarterly-report.pdf', sizeBytes: 240000),
  HaloFile(name: 'hero-shot.png', sizeBytes: 1800000, preview: _Shot()),
  HaloFile(name: 'budget.xlsx', sizeBytes: 52000),
];

const List<HaloFile> _browsed = [
  HaloFile(name: 'notes.md', sizeBytes: 1800),
  HaloFile(name: 'config.json', sizeBytes: 640),
  HaloFile(name: 'pitch.pptx', sizeBytes: 4200000),
];

/// Playground for [HaloDropzone].
class HaloDropzoneDemo extends StatefulWidget {
  const HaloDropzoneDemo({super.key});

  @override
  State<HaloDropzoneDemo> createState() => _HaloDropzoneDemoState();
}

class _HaloDropzoneDemoState extends State<HaloDropzoneDemo> {
  late bool _multiple;
  late bool _keep;
  late String _palette;
  List<HaloFile> _last = const [];

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _multiple = true;
    _keep = false;
    _palette = 'Brand';
    _last = const [];
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
            constraints: const BoxConstraints(maxWidth: 560),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: p.text),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Animated dropzone', style: GalleryText.heading(p).copyWith(fontSize: 20)),
                  const SizedBox(height: 6),
                  Text(
                    'Tap to browse, or drag a file chip into the zone.',
                    style: GalleryText.body(p),
                  ),
                  const SizedBox(height: 18),
                  HaloDropzone(
                    multiple: _multiple,
                    hint: 'Try images plus PDF, Office, JSON, Markdown…',
                    colors: _palettes[_palette]!,
                    successDuration: _keep ? Duration.zero : const Duration(milliseconds: 2400),
                    onBrowse: () async => _browsed,
                    onFiles: (files) => setState(() => _last = files),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final file in _chips) _Chip(file: file)],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _last.isEmpty
                        ? 'Nothing received yet'
                        : 'Last received: ${_last.map((f) => '${f.name} (${f.sizeLabel})').join(', ')}',
                    textAlign: TextAlign.center,
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
          title: 'Files',
          children: [
            ToggleControl(
              label: 'Accept several at once',
              value: _multiple,
              onChanged: (v) => _set(() => _multiple = v),
            ),
            ToggleControl(
              label: 'Keep the files shown',
              value: _keep,
              onChanged: (v) => _set(() => _keep = v),
            ),
          ],
        ),
        ControlSection(
          title: 'Halo',
          children: [
            SegmentedControl<String>(
              label: 'Palette',
              value: _palette,
              options: {for (final k in _palettes.keys) k: k},
              onChanged: (v) => _set(() => _palette = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// A draggable file chip.
class _Chip extends StatelessWidget {
  const _Chip({required this.file});

  final HaloFile file;

  @override
  Widget build(BuildContext context) {
    final p = GalleryTheme.paletteOf(context);
    final chip = Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HaloFileIcon(file: file, size: 22),
          const SizedBox(width: 8),
          Text(file.name, style: TextStyle(fontSize: 12.5, color: p.text)),
        ],
      ),
    );
    return Draggable<HaloFile>(
      data: file,
      feedback: DefaultTextStyle(
        style: TextStyle(color: p.text),
        child: Transform.rotate(angle: -0.04, child: chip),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: chip),
      child: MouseRegion(cursor: SystemMouseCursors.grab, child: chip),
    );
  }
}
