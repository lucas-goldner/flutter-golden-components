import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the project rule from CLAUDE.md: UI is split into widget classes,
/// never into functions or methods that return widgets (other than `build`).
void main() {
  test('no functions or methods return widgets', () {
    // `Widget foo(`, `List<Widget> _foo(`, `Widget? _buildBar(` ... except
    // `build(` and function types such as `Widget Function(`.
    final returnsWidget = RegExp(
      r'\b(?:Widget|List<Widget>)\??\s+(?!build\b|Function\b)[A-Za-z_]\w*\s*\(',
    );
    final buildHelper = RegExp(r'\b_build[A-Z]\w*\s*\(');
    final offenders = <String>[];
    for (final dir in ['lib', 'test', 'example/lib', 'example/test']) {
      final root = Directory(dir);
      if (!root.existsSync()) continue;
      for (final file in root.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          if (returnsWidget.hasMatch(line) || buildHelper.hasMatch(line)) {
            offenders.add('${file.path}:${i + 1}: ${line.trim()}');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Use a private widget class instead');
  });
}
