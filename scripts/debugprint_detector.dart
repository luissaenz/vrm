// Detection logic for debugPrint guard patterns.
// Used by debugprint_scanner.dart (CLI) and test/debugprint_scanner_test.dart.
//
// Detects when debugPrint is inside a debug-mode-only guard:
//   if (kDebugMode) debugPrint(...)            same line no braces
//   if (kDebugMode)\n  debugPrint(...)          adjacent line no braces
//   if (kDebugMode) { ... debugPrint(...) }     braced block
//   assert(debugPrint(...))                     inside assert
//   kDebugMode ? debugPrint(...) : null         ternary
//
// All functions public — usable by scanner and test.

bool isInsideDebugModeBlock(List<String> lines, int lineIdx) {
  final line = lines[lineIdx];

  if (isSameLineKDebugModeGuard(line)) return true;
  if (isInsideAssert(line)) return true;
  if (isTernaryKDebugModeGuard(line)) return true;
  if (isAdjacentKDebugModeGuard(lines, lineIdx)) return true;
  if (isInsideBracedDebugModeBlock(lines, lineIdx)) return true;

  return false;
}

bool isSameLineKDebugModeGuard(String line) {
  final dpIdx = line.indexOf('debugPrint(');
  if (dpIdx == -1) return false;

  final before = line.substring(0, dpIdx);
  return RegExp(
    r"if\s*\(\s*(kDebugMode|!kReleaseMode)\s*\)\s*$",
  ).hasMatch(before.trimRight());
}

bool isInsideAssert(String line) {
  final dpIdx = line.indexOf('debugPrint(');
  if (dpIdx == -1) return false;

  final before = line.substring(0, dpIdx);

  for (final m in RegExp(r'assert\s*\(').allMatches(before).toList().reversed) {
    final afterParen = before.substring(m.end);
    int depth = 1;
    bool closed = false;
    for (int i = 0; i < afterParen.length; i++) {
      if (afterParen[i] == '(') depth++;
      if (afterParen[i] == ')') {
        depth--;
        if (depth == 0) {
          closed = true;
          break;
        }
      }
    }
    if (!closed) return true;
  }

  return false;
}

bool isTernaryKDebugModeGuard(String line) {
  return RegExp(
    r'(kDebugMode|!kReleaseMode)\s*\?.*debugPrint\(',
  ).hasMatch(line);
}

bool isAdjacentKDebugModeGuard(List<String> lines, int lineIdx) {
  if (lineIdx == 0) return false;
  final prev = lines[lineIdx - 1].trim();
  if (!RegExp(r'^if\s*\(\s*(kDebugMode|!kReleaseMode)\s*\)$').hasMatch(prev)) {
    return false;
  }
  return !prev.endsWith('{');
}

bool isInsideBracedDebugModeBlock(List<String> lines, int lineIdx) {
  int braceDepth = 0;

  for (int i = lineIdx; i >= 0; i--) {
    final cleaned = stripStringsAndComments(lines[i]);

    for (int j = 0; j < cleaned.length; j++) {
      if (cleaned[j] == '{') braceDepth++;
      if (cleaned[j] == '}') braceDepth--;
    }

    if (braceDepth > 0 &&
        (lines[i].contains('kDebugMode') ||
            lines[i].contains('!kReleaseMode'))) {
      return true;
    }
  }

  return false;
}

/// Returns [line] with string literals and comments stripped for brace counting.
///
/// Stops at `//`.  Strips content inside `/* ... */`, `'...'`, `"..."`.
/// Multi-line strings (`'''`, `"""`) not handled — rare in this codebase.
String stripStringsAndComments(String line) {
  final buf = StringBuffer();
  bool inSingleQuote = false;
  bool inDoubleQuote = false;

  int i = 0;
  while (i < line.length) {
    final ch = line[i];

    if (inSingleQuote) {
      if (ch == '\\') {
        i++; // skip escaped char
      } else if (ch == "'") {
        inSingleQuote = false;
      }
      i++;
      continue;
    }

    if (inDoubleQuote) {
      if (ch == '\\') {
        i++; // skip escaped char
      } else if (ch == '"') {
        inDoubleQuote = false;
      }
      i++;
      continue;
    }

    if (ch == '/' && i + 1 < line.length) {
      final next = line[i + 1];
      if (next == '/') break; // rest is line comment

      if (next == '*') {
        i += 2; // skip /*
        while (i < line.length) {
          if (line[i] == '*' && i + 1 < line.length && line[i + 1] == '/') {
            i += 2; // skip */
            break;
          }
          i++;
        }
        continue;
      }
    }

    if (ch == "'") {
      inSingleQuote = true;
      i++;
      continue;
    }

    if (ch == '"') {
      inDoubleQuote = true;
      i++;
      continue;
    }

    buf.write(ch);
    i++;
  }

  return buf.toString();
}
