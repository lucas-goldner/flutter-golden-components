import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the project rule: components may only depend on the `widgets`
/// layer of Flutter (and the layers below it), never Material or Cupertino.
void main() {
  test('lib/ never imports Material or Cupertino', () {
    final banned = RegExp(
      r'''(import|export)\s+['"]package:flutter/(material|cupertino)\.dart['"]''',
    );
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      if (banned.hasMatch(file.readAsStringSync())) offenders.add(file.path);
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Only package:flutter/widgets.dart (and lower layers) is allowed',
    );
  });
}
