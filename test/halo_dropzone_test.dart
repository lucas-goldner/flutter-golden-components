import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_golden_components/flutter_golden_components.dart';
import 'package:flutter_test/flutter_test.dart';

const HaloFile _pdf = HaloFile(name: 'report.pdf', sizeBytes: 2048);
const HaloFile _png = HaloFile(name: 'shot.png', sizeBytes: 3 * 1024 * 1024);

/// A drop zone with a draggable file chip above it, 800x600.
class _Host extends StatelessWidget {
  const _Host({
    this.onFiles,
    this.onBrowse,
    this.multiple = true,
    this.reduceMotion = false,
    this.keep = false,
  });

  final ValueChanged<List<HaloFile>>? onFiles;
  final Future<List<HaloFile>?> Function()? onBrowse;
  final bool multiple;
  final bool reduceMotion;
  final bool keep;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xFF000000)),
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Column(
                  children: [
                    const Draggable<List<HaloFile>>(
                      data: [_pdf, _png],
                      feedback: SizedBox(width: 20, height: 20),
                      child: SizedBox(width: 100, height: 40, child: Text('chip')),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 500,
                      child: HaloDropzone(
                        multiple: multiple,
                        successDuration: keep ? Duration.zero : const Duration(seconds: 2),
                        onFiles: onFiles,
                        onBrowse: onBrowse,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  test('describes files', () {
    expect(_pdf.extension, 'pdf');
    expect(_pdf.sizeLabel, '2.0 KB');
    expect(_png.sizeLabel, '3.0 MB');
    expect(const HaloFile(name: 'README').extension, '');
  });

  testWidgets('dropping files reports them, shows them, then resets', (tester) async {
    final got = <List<HaloFile>>[];
    await tester.pumpWidget(_Host(onFiles: got.add));
    await tester.drag(find.text('chip'), const Offset(0, 120));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(got.single.map((f) => f.name), ['report.pdf', 'shot.png']);
    expect(find.text('Files added'), findsOneWidget);
    expect(find.text('report.pdf'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Drop files here or browse'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('single mode keeps the first file only', (tester) async {
    final got = <List<HaloFile>>[];
    await tester.pumpWidget(_Host(multiple: false, keep: true, onFiles: got.add));
    await tester.drag(find.text('chip'), const Offset(0, 120));
    await tester.pump(const Duration(milliseconds: 600));
    expect(got.single.map((f) => f.name), ['report.pdf']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tap and Enter browse', (tester) async {
    final got = <List<HaloFile>>[];
    var browses = 0;
    await tester.pumpWidget(
      _Host(
        keep: true,
        onFiles: got.add,
        onBrowse: () async {
          browses++;
          return [_pdf];
        },
      ),
    );
    await tester.tap(find.byType(HaloDropzone));
    await tester.pump(const Duration(milliseconds: 600));
    expect(browses, 1);
    expect(got.single.single.name, 'report.pdf');

    Focus.of(tester.element(find.text('report.pdf'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 600));
    expect(browses, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a cancelled browse changes nothing', (tester) async {
    final got = <List<HaloFile>>[];
    await tester.pumpWidget(_Host(onFiles: got.add, onBrowse: () async => null));
    await tester.tap(find.byType(HaloDropzone));
    await tester.pump(const Duration(milliseconds: 600));
    expect(got, isEmpty);
    expect(find.text('Drop files here or browse'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('disabled zones take nothing', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true));
    await tester.drag(find.text('chip'), const Offset(0, 120));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Files added'), findsNothing);
  });

  testWidgets('holds still when motion is reduced', (tester) async {
    await tester.pumpWidget(_Host(reduceMotion: true, onFiles: (_) {}));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
