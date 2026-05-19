import 'package:flutter_test/flutter_test.dart';

import '../scripts/debugprint_detector.dart';

void main() {
  group('isSameLineKDebugModeGuard', () {
    test('TP-1: misma linea con kDebugMode sin llaves → true', () {
      expect(
        isSameLineKDebugModeGuard("if (kDebugMode) debugPrint('test');"),
        isTrue,
      );
    });

    test('TP-1b: misma linea con !kReleaseMode sin llaves → true', () {
      expect(
        isSameLineKDebugModeGuard("if (!kReleaseMode) debugPrint('test');"),
        isTrue,
      );
    });

    test('sin guard debug → false', () {
      expect(isSameLineKDebugModeGuard("debugPrint('test');"), isFalse);
    });

    test('con llaves en misma linea → false (braced block)', () {
      expect(
        isSameLineKDebugModeGuard("if (kDebugMode) { debugPrint('test'); }"),
        isFalse,
      );
    });
  });

  group('isInsideAssert', () {
    test('TP-5: assert(debugPrint()) → true', () {
      expect(isInsideAssert("assert(debugPrint('test'));"), isTrue);
    });

    test('sin assert → false', () {
      expect(isInsideAssert("debugPrint('test');"), isFalse);
    });

    test('assert con expression antes de debugPrint → true', () {
      expect(isInsideAssert("assert(x != null && debugPrint('msg'));"), isTrue);
    });
  });

  group('isTernaryKDebugModeGuard', () {
    test('TP-6: kDebugMode ? debugPrint() : null → true', () {
      expect(
        isTernaryKDebugModeGuard("kDebugMode ? debugPrint('test') : null;"),
        isTrue,
      );
    });

    test('sin ternario → false', () {
      expect(isTernaryKDebugModeGuard("debugPrint('test');"), isFalse);
    });

    test('!kReleaseMode ternario → true', () {
      expect(
        isTernaryKDebugModeGuard("!kReleaseMode ? debugPrint('test') : null;"),
        isTrue,
      );
    });
  });

  group('isAdjacentKDebugModeGuard', () {
    test('TP-3: línea adyacente sin llaves → true', () {
      final lines = ['if (kDebugMode)', "  debugPrint('test');"];
      expect(isAdjacentKDebugModeGuard(lines, 1), isTrue);
    });

    test('!kReleaseMode adyacente → true', () {
      final lines = ['if (!kReleaseMode)', "  debugPrint('test');"];
      expect(isAdjacentKDebugModeGuard(lines, 1), isTrue);
    });

    test('línea anterior no es guard → false', () {
      final lines = ['// comment', "debugPrint('test');"];
      expect(isAdjacentKDebugModeGuard(lines, 1), isFalse);
    });

    test('guard con llave → false (braced block)', () {
      final lines = ['if (kDebugMode) {', "  debugPrint('test');"];
      expect(isAdjacentKDebugModeGuard(lines, 1), isFalse);
    });
  });

  group('isInsideBracedDebugModeBlock', () {
    test('TP-1: multilinea con llaves → true', () {
      final lines = ['if (kDebugMode) {', "  debugPrint('test');", '}'];
      expect(isInsideBracedDebugModeBlock(lines, 1), isTrue);
    });

    test('sin guard → false', () {
      final lines = ["debugPrint('test');"];
      expect(isInsideBracedDebugModeBlock(lines, 0), isFalse);
    });

    test('!kReleaseMode multilinea → true', () {
      final lines = ['if (!kReleaseMode) {', "  debugPrint('test');", '}'];
      expect(isInsideBracedDebugModeBlock(lines, 1), isTrue);
    });

    test('TP-7: string con braces no altera braceDepth', () {
      final lines = [
        "if (kDebugMode) {",
        "  final x = '{test}';",
        "  debugPrint(x);",
        '}',
      ];
      expect(isInsideBracedDebugModeBlock(lines, 2), isTrue);
    });

    test('TP-8: comentario con braces no altera braceDepth', () {
      final lines = [
        'if (kDebugMode) {',
        '  // {comment with braces}',
        "  debugPrint('real');",
        '}',
      ];
      expect(isInsideBracedDebugModeBlock(lines, 2), isTrue);
    });

    test('comentario con braces sin guard real → false', () {
      final lines = ["// if (kDebugMode) {", "debugPrint('real');"];
      expect(isInsideBracedDebugModeBlock(lines, 1), isFalse);
    });
  });

  group('stripStringsAndComments', () {
    test('stripa string con braces', () {
      final result = stripStringsAndComments("final x = '{test}';");
      expect(result, equals('final x = ;'));
    });

    test('stripa comentario //', () {
      final result = stripStringsAndComments('x = 1; // {comment}');
      expect(result, equals('x = 1; '));
    });

    test('stripa comentario /* */', () {
      final result = stripStringsAndComments('x /*{bloque}*/ = 1;');
      expect(result, equals('x  = 1;'));
    });

    test('stripa bloque /* */ en una línea', () {
      final result = stripStringsAndComments('/* comment */ int x = 1;');
      expect(result, equals(' int x = 1;'));
    });

    test('conserva código sin strings ni comentarios', () {
      final result = stripStringsAndComments('if (kDebugMode) {');
      expect(result, equals('if (kDebugMode) {'));
    });
  });

  group('isInsideDebugModeBlock (orquestador)', () {
    test('TP-4: sin guard → false', () {
      final lines = ["debugPrint('test');"];
      expect(isInsideDebugModeBlock(lines, 0), isFalse);
    });

    test('TP-2: misma linea sin llaves → true', () {
      final lines = ["if (kDebugMode) debugPrint('test');"];
      expect(isInsideDebugModeBlock(lines, 0), isTrue);
    });

    test('TP-3: línea adyacente sin llaves → true', () {
      final lines = ['if (kDebugMode)', "  debugPrint('test');"];
      expect(isInsideDebugModeBlock(lines, 1), isTrue);
    });

    test('TP-5: assert wrapper → true', () {
      final lines = ["assert(debugPrint('test'));"];
      expect(isInsideDebugModeBlock(lines, 0), isTrue);
    });

    test('TP-6: ternario → true', () {
      final lines = ["kDebugMode ? debugPrint('test') : null;"];
      expect(isInsideDebugModeBlock(lines, 0), isTrue);
    });

    test('TP-1: multilinea con llaves → true', () {
      final lines = [
        'void foo() {',
        '  if (kDebugMode) {',
        "    debugPrint('test');",
        '  }',
        '}',
      ];
      expect(isInsideDebugModeBlock(lines, 2), isTrue);
    });
  });

  group('multi-line debugPrint', () {
    test('TP-M1: findClosingParenMultiLine detects closing ) across lines', () {
      final lines = [
        '  debugPrint(',
        "    '[Pipeline] Stage 1: Fetching idea...',",
        '  );',
      ];

      final dpIdx = lines[0].indexOf('debugPrint(');
      final result = findClosingParenMultiLine(
        lines,
        0,
        dpIdx + 'debugPrint('.length,
      );
      expect(result.$1, equals(2));
      expect(result.$2, equals(2));
    });

    test(
      'TP-M2: extractMultiLineArg extracts argument from multi-line call',
      () {
        final lines = [
          '  debugPrint(',
          "    '[Pipeline] Stage 1: Fetching idea...',",
          '  );',
        ];

        final dpIdx = lines[0].indexOf('debugPrint(');
        final openParenCol = dpIdx + 'debugPrint('.length - 1;
        final arg = extractMultiLineArg(lines, 0, openParenCol, 2, 2);
        expect(arg, equals("'[Pipeline] Stage 1: Fetching idea...',"));
      },
    );

    test('TP-M3: extractMultiLineArg handles interpolation', () {
      final lines = [
        '  debugPrint(',
        "    'Processing \${widget.name}...',",
        '  );',
      ];

      final dpIdx = lines[0].indexOf('debugPrint(');
      final openParenCol = dpIdx + 'debugPrint('.length - 1;
      final arg = extractMultiLineArg(lines, 0, openParenCol, 2, 2);
      expect(arg, equals("'Processing \${widget.name}...',"));
    });

    test(
      'TP-M4: parens inside string do not break findClosingParenMultiLine',
      () {
        final lines = ['  debugPrint(', "    'func(x) result: y',", '  );'];

        final dpIdx = lines[0].indexOf('debugPrint(');
        final result = findClosingParenMultiLine(
          lines,
          0,
          dpIdx + 'debugPrint('.length,
        );
        expect(result.$1, equals(2));
        expect(result.$2, equals(2));
      },
    );

    test(
      'TP-M5: multi-line debugPrint inside kDebugMode guard is detected',
      () {
        final lines = [
          'if (kDebugMode) {',
          '  debugPrint(',
          "    'should not fix',",
          '  );',
          '}',
        ];

        expect(isInsideDebugModeBlock(lines, 1), isTrue);
      },
    );

    test(
      'TP-M6: findClosingParenMultiLine handles multiple multi-line calls',
      () {
        final lines = [
          '  debugPrint(',
          "    'first call',",
          '  );',
          "  debugPrint('single line');",
          '  debugPrint(',
          "    'second call',",
          '  );',
        ];

        final dpIdx0 = lines[0].indexOf('debugPrint(');
        final r1 = findClosingParenMultiLine(
          lines,
          0,
          dpIdx0 + 'debugPrint('.length,
        );
        expect(r1.$1, equals(2));
        expect(r1.$2, equals(2));

        final dpIdx4 = lines[4].indexOf('debugPrint(');
        final r2 = findClosingParenMultiLine(
          lines,
          4,
          dpIdx4 + 'debugPrint('.length,
        );
        expect(r2.$1, equals(6));
        expect(r2.$2, equals(2));
      },
    );

    test('TP-M7: findClosingParenMultiLine returns (-1, -1) for malformed', () {
      final lines = ['  debugPrint(', "    'no closing paren',"];

      final dpIdx = lines[0].indexOf('debugPrint(');
      final result = findClosingParenMultiLine(
        lines,
        0,
        dpIdx + 'debugPrint('.length,
      );
      expect(result.$1, equals(-1));
      expect(result.$2, equals(-1));
    });
  });
}
