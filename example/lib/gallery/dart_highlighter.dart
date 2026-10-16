import 'package:flutter/widgets.dart';

/// Colors for highlighted Dart code (GitHub-like).
@immutable
class CodePalette {
  const CodePalette({
    required this.background,
    required this.gutter,
    required this.lineNumber,
    required this.plain,
    required this.keyword,
    required this.type,
    required this.function,
    required this.string,
    required this.number,
    required this.comment,
    required this.annotation,
  });

  final Color background;
  final Color gutter;
  final Color lineNumber;
  final Color plain;
  final Color keyword;
  final Color type;
  final Color function;
  final Color string;
  final Color number;
  final Color comment;
  final Color annotation;

  static const dark = CodePalette(
    background: Color(0xFF0D1117),
    gutter: Color(0xFF0D1117),
    lineNumber: Color(0xFF4B535D),
    plain: Color(0xFFE6EDF3),
    keyword: Color(0xFFFF7B72),
    type: Color(0xFFFFA657),
    function: Color(0xFFD2A8FF),
    string: Color(0xFFA5D6FF),
    number: Color(0xFF79C0FF),
    comment: Color(0xFF8B949E),
    annotation: Color(0xFFF5C451),
  );

  static const light = CodePalette(
    background: Color(0xFFFFFFFF),
    gutter: Color(0xFFFFFFFF),
    lineNumber: Color(0xFFAFB8C1),
    plain: Color(0xFF1F2328),
    keyword: Color(0xFFCF222E),
    type: Color(0xFF953800),
    function: Color(0xFF8250DF),
    string: Color(0xFF0A3069),
    number: Color(0xFF0550AE),
    comment: Color(0xFF6E7781),
    annotation: Color(0xFF9A6700),
  );
}

/// Kind of a highlighted token.
enum DartToken { plain, keyword, type, function, string, number, comment, annotation }

const Set<String> _keywords = {
  'abstract', 'as', 'assert', 'async', 'await', 'base', 'break', 'case', //
  'catch', 'class', 'const', 'continue', 'covariant', 'default', 'deferred',
  'do', 'dynamic', 'else', 'enum', 'export', 'extends', 'extension',
  'external', 'factory', 'false', 'final', 'finally', 'for', 'Function', 'get',
  'hide', 'if', 'implements', 'import', 'in', 'interface', 'is', 'late',
  'library', 'mixin', 'new', 'null', 'on', 'operator', 'part', 'required',
  'rethrow', 'return', 'sealed', 'set', 'show', 'static', 'super', 'switch',
  'sync', 'this', 'throw', 'true', 'try', 'typedef', 'var', 'void', 'when',
  'while', 'with', 'yield',
};

/// Built-in types that start lowercase.
const Set<String> _builtinTypes = {'int', 'double', 'num', 'bool'};

final RegExp _token = RegExp(
  r'(?<comment>//[^\n]*|/\*[\s\S]*?\*/)'
  r'|(?<string>r?"""[\s\S]*?"""|'
  r"r?'''[\s\S]*?'''|"
  r'''r?"(?:[^"\\\n]|\\.)*"|r?'(?:[^'\\\n]|\\.)*')'''
  r'|(?<annotation>@[A-Za-z_]\w*)'
  r'|(?<number>\b(?:0x[0-9A-Fa-f]+|\d+(?:\.\d+)?(?:e[+-]?\d+)?)\b)'
  r'|(?<word>[A-Za-z_$][\w$]*)(?<call>\s*(?:<[\w<>, ?]*>)?\()?',
);

final RegExp _typeName = RegExp(r'^_?[A-Z]');

/// Splits Dart source into `(text, kind)` runs. Pure, so it is easy to test.
List<(String, DartToken)> tokenizeDart(String code) {
  final out = <(String, DartToken)>[];
  var last = 0;
  for (final m in _token.allMatches(code)) {
    if (m.start > last) out.add((code.substring(last, m.start), DartToken.plain));
    final DartToken kind;
    var text = m[0]!;
    if (m.namedGroup('comment') != null) {
      kind = DartToken.comment;
    } else if (m.namedGroup('string') != null) {
      kind = DartToken.string;
    } else if (m.namedGroup('annotation') != null) {
      kind = DartToken.annotation;
    } else if (m.namedGroup('number') != null) {
      kind = DartToken.number;
    } else {
      // Only color the identifier; the trailing `(` / type args stay plain.
      final word = m.namedGroup('word')!;
      final isCall = m.namedGroup('call') != null;
      text = word;
      if (_keywords.contains(word)) {
        kind = DartToken.keyword;
      } else if (_typeName.hasMatch(word) || _builtinTypes.contains(word)) {
        kind = DartToken.type;
      } else if (isCall) {
        kind = DartToken.function;
      } else {
        kind = DartToken.plain;
      }
      out.add((text, kind));
      if (isCall) out.add((m.namedGroup('call')!, DartToken.plain));
      last = m.end;
      continue;
    }
    out.add((text, kind));
    last = m.end;
  }
  if (last < code.length) out.add((code.substring(last), DartToken.plain));
  return out;
}

/// Highlights Dart source as [TextSpan]s colored with [palette].
List<TextSpan> highlightDart(String code, CodePalette palette) {
  return [
    for (final (text, kind) in tokenizeDart(code))
      TextSpan(
        text: text,
        style: switch (kind) {
          DartToken.plain => null,
          DartToken.keyword => TextStyle(color: palette.keyword),
          DartToken.type => TextStyle(color: palette.type),
          DartToken.function => TextStyle(color: palette.function),
          DartToken.string => TextStyle(color: palette.string),
          DartToken.number => TextStyle(color: palette.number),
          DartToken.annotation => TextStyle(color: palette.annotation),
          DartToken.comment => TextStyle(color: palette.comment, fontStyle: FontStyle.italic),
        },
      ),
  ];
}
