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
}
