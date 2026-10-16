import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads Roboto (instead of the Ahem test font) so goldens are readable, and
/// installs a comparator that tolerates tiny anti-aliasing differences.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader('Roboto');
  for (final f in ['Regular', 'Medium', 'Bold', 'Italic']) {
    loader.addFont(_read('test/fonts/Roboto-$f.ttf'));
  }
  await loader.load();
  if (goldenFileComparator is LocalFileComparator) {
    final base = (goldenFileComparator as LocalFileComparator).basedir;
    goldenFileComparator = TolerantGoldenComparator(base.resolve('placeholder'));
  }
  await testMain();
}

Future<ByteData> _read(String path) async => ByteData.sublistView(File(path).readAsBytesSync());

/// Passes when at most [tolerance] of pixels differ, so goldens generated on
/// Linux (CI) survive minor rasterisation differences on other machines.
class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile);

  /// Fraction of pixels allowed to differ.
  static const double tolerance = 0.005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
