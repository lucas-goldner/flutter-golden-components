import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads real fonts (instead of the Ahem test font) so goldens are readable,
/// and installs a comparator that tolerates tiny anti-aliasing differences.
///
/// Roboto comes from the package's `test/fonts/`; the code font is the one
/// the gallery bundles.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final roboto = FontLoader('Roboto');
  for (final f in ['Regular', 'Medium', 'Bold', 'Italic']) {
    roboto.addFont(_read('../test/fonts/Roboto-$f.ttf'));
  }
  await roboto.load();
  await (FontLoader('GalleryMono')..addFont(_read('assets/fonts/DejaVuSansMono.ttf'))).load();
  if (goldenFileComparator is LocalFileComparator) {
    final base = (goldenFileComparator as LocalFileComparator).basedir;
    goldenFileComparator = _TolerantComparator(base.resolve('placeholder'));
  }
  await testMain();
}

Future<ByteData> _read(String path) async => ByteData.sublistView(File(path).readAsBytesSync());

/// Passes when at most 0.5 % of pixels differ, so goldens generated on Linux
/// (CI) survive minor rasterisation differences on other machines.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  static const double _tolerance = 0.005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
