import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every component folder in `lib/src/` must ship its source as an asset
/// (for the gallery's Code tab), and have unit tests and golden tests.
void main() {
  final components = Directory('lib/src').listSync().whereType<Directory>().map(
    (d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last,
  );
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final tests = Directory('test').listSync().whereType<File>().map((f) => f.uri.pathSegments.last);
  final goldens = Directory(
    'test/goldens',
  ).listSync().whereType<File>().map((f) => f.uri.pathSegments.last);

  for (final name in components) {
    group(name, () {
      test('is listed under flutter: assets:', () {
        expect(pubspec, contains('- lib/src/$name/'));
      });
      test('has unit tests in test/${name}_*_test.dart', () {
        expect(tests.where((f) => f.startsWith(name) && f.endsWith('_test.dart')), isNotEmpty);
      });
      test('has golden tests in test/goldens/${name}_*_golden_test.dart', () {
        expect(
          goldens.where((f) => f.startsWith(name) && f.endsWith('_golden_test.dart')),
          isNotEmpty,
        );
        expect(goldens.where((f) => f.startsWith(name) && f.endsWith('.png')), isNotEmpty);
      });
    });
  }
}
