import 'package:low_lang/parser/token.dart';
import 'package:low_lang/vm/errors.dart';

class LowLexer {
  List<LowToken> lex(String str, String fileName) {
    final chars = str.split("");
    var inString = false;
    var escaping = false;
    final currPos = LowTokenPosition(fileName, 1, 0);
    final l = <LowToken>[LowToken("", LowTokenType.identifier, LowTokenPosition(fileName, 1, 1))];

    for (var i = 0; i < chars.length; i++) {
      final char = chars[i];

      if (char == "\n") {
        currPos.lineNumber++;
        currPos.charNumber = 0;
      } else {
        currPos.charNumber++;
      }

      if (char == " " && !inString) {
        l.add(LowToken("", LowTokenType.seperator, currPos.copy));
        continue;
      } else if (char == "\t" && !inString) {
        l.add(LowToken("", LowTokenType.seperator, currPos.copy));
        continue;
      } else if (char == "\r") {
        continue;
      } else if (char == '"' && !escaping) {
        inString = !inString;
      } else if (char == "\\" && !escaping) {
        escaping = true;
        if (inString) {
          l.last.value += char;
        }
        continue;
      }

      if (isSeperator(char) && !inString) {
        l.add(LowToken(char, LowTokenType.seperator, currPos.copy));
      } else if (isOperator(char) && !inString) {
        if (isOperator(l.last.value)) {
          l.last.value += char;
        } else {
          l.add(LowToken(char, LowTokenType.operator, currPos.copy));
        }
      } else if (isText(char) || inString) {
        if (isText(l.last.value)) {
          l.last.value += char;
        } else {
          l.add(LowToken(char, LowTokenType.identifier, currPos.copy));
        }
      }
      escaping = false;
    }

    if (escaping) {
      throw LowParsingFailure("Lexer: Unable to escape End Of File", l.last.position, str.split('\n'));
    }

    if (inString) {
      throw LowParsingFailure("Lexer: Missing end of string", l.last.position, str.split('\n'));
    }

    l.removeWhere((token) => token.value.replaceAll(" ", "").replaceAll("\t", "").isEmpty);

    return handleTypes(handleEdgeCases(l), str.split("\n"));
  }

  List<LowToken> handleEdgeCases(List<LowToken> faulty) {
    final fixed = <LowToken>[];

    for (var i = 0; i < faulty.length; i++) {
      final token = faulty[i];

      LowToken last(int n) {
        final idx = i - n;

        if (idx < 0) {
          return LowToken("", LowTokenType.identifier, LowTokenPosition("out-of-bounds", 0, 0));
        } else {
          return faulty[idx];
        }
      }

      LowToken next(int n) {
        final idx = i + n;

        if (idx >= faulty.length) {
          return LowToken("", LowTokenType.identifier, LowTokenPosition("out-of-bounds", 0, 0));
        } else {
          return faulty[idx];
        }
      }

      if ((isSeperator(last(1).value) && last(1).value != ']') || isOperator(last(1).value)) {
        if (token.value == "-" && int.tryParse(next(1).value) != null && next(2).value == "." && int.tryParse(next(3).value) != null) {
          fixed.add(LowToken("-${next(1).value}.${next(3).value}", LowTokenType.literal, token.position));
          i += 3;
          continue;
        }

        if (token.value == "-" && int.tryParse(next(1).value) != null) {
          fixed.add(LowToken("-${next(1).value}", LowTokenType.literal, token.position));
          i++;
          continue;
        }
      }

      if (int.tryParse(token.value) != null && next(1).value == "." && int.tryParse(next(2).value) != null) {
        fixed.add(LowToken("${token.value}.${next(2).value}", LowTokenType.literal, token.position));
        i += 2;
        continue;
      }

      fixed.add(token);
    }

    return fixed;
  }

  List<LowToken> handleTypes(List<LowToken> untyped, List<String> lines) {
    for (var token in untyped) {
      if (isLiteral(token.value)) {
        token.type = LowTokenType.literal;
      } else if (isIdentifier(token.value)) {
        token.type = LowTokenType.identifier;
      } else if (isOperator(token.value)) {
        token.type = LowTokenType.operator;
      } else if (isSeperator(token.value)) {
        token.type = LowTokenType.seperator;
      } else if (isKeyword(token.value)) {
        token.type = LowTokenType.keyword;
      } else {
        throw LowParsingFailure("Lexer can't figure out the type of ${token.value}", token.position, lines);
      }
    }

    return untyped;
  }

  bool isOperator(String str) {
    if (str.isEmpty) return false;
    final ops = "./=-*%!+^:&|<>";

    for (var char in str.split("")) {
      if (!ops.contains(char)) return false;
    }

    return true;
  }

  bool isText(String str) {
    if (str.isEmpty) return false;
    return !isOperator(str) && !isSeperator(str);
  }

  bool isSeperator(String char) {
    if (char.isEmpty) return false;
    return ",()[]{}@;\n".contains(char);
  }

  bool isKeyword(String str) {
    final keywords = <String>[
      "var",
      "fn",
      "if",
      "else",
      "include",
      "return",
      "continue",
      "break",
      "for",
      "while",
      "foreach",
      "as",
      "globally",
      "is",
      "isnt",
      "static",
    ];

    return keywords.contains(str);
  }

  bool isLiteral(String str) {
    if (str.startsWith('"')) return true;
    if (num.tryParse(str) != null) return true;
    if (str == "true" || str == "false") return true;
    if (str == "@[]") return true;
    if (str == "@{}") return true;
    if (str == "null") return true;
    return false;
  }

  bool isIdentifier(String str) {
    if (isLiteral(str)) return false;
    if (isKeyword(str)) return false;

    final allowed = "abcdefghijklmnopqrstuvwxyz1234567890_";

    for (var char in str.split("")) {
      if (!allowed.contains(char.toLowerCase())) return false;
    }

    return true;
  }
}
