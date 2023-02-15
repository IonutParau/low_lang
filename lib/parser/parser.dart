import 'package:low_lang/ast/ast.dart';
import 'package:low_lang/ast/body.dart';
import 'package:low_lang/ast/call.dart';
import 'package:low_lang/ast/control_flow.dart';
import 'package:low_lang/ast/define.dart';
import 'package:low_lang/ast/handle_op.dart';
import 'package:low_lang/ast/include.dart';
import 'package:low_lang/ast/literals.dart';
import 'package:low_lang/ast/loops.dart';
import 'package:low_lang/ast/var.dart';
import 'package:low_lang/parser/lexer.dart';
import 'package:low_lang/parser/preprocessor.dart';
import 'package:low_lang/parser/token.dart';
import 'package:low_lang/vm/errors.dart';

class LowParser {
  final lexer = LowLexer();
  final preprocessor = LowPreprocessor();

  LowAST parseCode(String code, String filename) {
    final sourceLines = code.split('\n');

    final lexed = lexer.lex(code, filename);
    final preprocessed = preprocessor.preprocess(lexed, sourceLines);
    final lines = splitByLines(preprocessed);

    return LowCodeBody(lines.map((line) => parseLine(line, sourceLines, LowParserMode.topLevel)).toList(), LowTokenPosition(filename, 1, 1));
  }

  List<List<LowPreprocessedToken>> splitByLines(List<LowPreprocessedToken> tokens) {
    return preprocessor.splitBySeperators(tokens, [';', '\n'], removeEmptyLists: true);
  }

  LowAST parseLine(List<LowPreprocessedToken> tokens, List<String> lines, LowParserMode mode) {
    if (tokens.length == 1) {
      final token = tokens.first;

      if (token.value == "true" || token.value == "false") {
        return LowBoolNode(token.value == "true", token.position);
      }

      if (int.tryParse(token.value) != null) {
        return LowIntegerNode(int.parse(token.value), token.position);
      }

      if (double.tryParse(token.value) != null) {
        return LowDoubleNode(double.parse(token.value), token.position);
      }

      if (token.value == "null") return LowNullNode(token.position);

      if (token.value == "continue") {
        return LowContinueNode(token.position);
      }

      if (token.value == "break") {
        return LowBreakNode(token.position);
      }

      if (token.value == "[]") {
        final subnodes = preprocessor.splitBySeperators(token.subtokens, [','], removeNewlines: true);

        if (subnodes.isNotEmpty) {
          if (subnodes.last.isEmpty) subnodes.removeLast();
        }

        var i = 0;
        for (var subnode in subnodes) {
          i++;
          if (subnode.isEmpty) {
            throw LowParsingFailure("List Element #$i is an empty segment (unparsable)", token.position, lines);
          }
        }

        return LowListNode(
          subnodes.map((line) {
            return parseLine(line, lines, LowParserMode.data);
          }).toList(),
          token.position,
        );
      }

      if (token.value == "@[]") {
        final subnodes = preprocessor.splitBySeperators(token.subtokens, [','], removeNewlines: true);

        if (subnodes.isNotEmpty) {
          if (subnodes.last.isEmpty) subnodes.removeLast();
        }

        var i = 0;
        for (var subnode in subnodes) {
          i++;
          if (subnode.isEmpty) {
            throw LowParsingFailure("Buffer Element #$i is an empty segment (unparsable)", token.position, lines);
          }
        }

        return LowBufferNode(subnodes.map((line) => parseLine(line, lines, LowParserMode.data)).toList(), token.position);
      }

      if (token.value == "{}") {
        if (mode == LowParserMode.data) {
          final subnodes = preprocessor.splitBySeperators(token.subtokens, [','], removeNewlines: true);

          if (subnodes.isNotEmpty) {
            if (subnodes.last.isEmpty) subnodes.removeLast();
          }

          final o = <String, LowAST>{};
          var i = 0;

          for (var subnode in subnodes) {
            i++;

            if (subnode.isEmpty) {
              throw LowParsingFailure("Object Pair #$i is an empty segment (unparsable)", token.position, lines);
            }

            if (subnode.length < 3) {
              throw LowParsingFailure("Object Pair #$i is invalid", token.position, lines);
            }

            var isStringField = subnode[0].value.startsWith('"') && subnode[0].value.endsWith('"');

            if (subnode[0].type != LowPreprocessedTokenType.identifier && !isStringField) {
              throw LowParsingFailure("Object Pair #$i's key is not an identifier or string field", token.position, lines);
            }

            if (subnode[1].value != ":") {
              throw LowParsingFailure("Object Pair #$i's key should end with an : and then specify the value", token.position, lines);
            }

            o[isStringField ? parseStringLiteral(subnode[0], lines) : subnode[0].value] = parseLine(subnode.sublist(2), lines, LowParserMode.data);
          }

          return LowObjectNode(o, token.position);
        } else if (mode == LowParserMode.topLevel) {
          final sublines = splitByLines(token.subtokens);

          return LowCodeBody(sublines.map((line) => parseLine(line, lines, LowParserMode.topLevel)).toList(), token.position);
        }
      }

      if (token.value == "@{}") {
        final subnodes = preprocessor.splitBySeperators(token.subtokens, [','], removeNewlines: true);

        if (subnodes.isNotEmpty) {
          if (subnodes.last.isEmpty) subnodes.removeLast();
        }

        final m = <LowAST, LowAST>{};
        var i = 0;

        for (var subnode in subnodes) {
          i++;
          if (subnode.isEmpty) {
            throw LowParsingFailure("Map Pair #$i is an empty segment (unparsable)", token.position, lines);
          }

          var readingKey = true;

          final keySegs = <LowPreprocessedToken>[];
          final valSegs = <LowPreprocessedToken>[];

          for (var token in subnode) {
            if (token.value == ":" && readingKey) {
              readingKey = false;
            } else {
              if (readingKey) {
                keySegs.add(token);
              } else {
                valSegs.add(token);
              }
            }
          }

          if (readingKey) {
            throw LowParsingFailure("Map Pair #$i's value is not defined. Please make sure you ended the key signature with :", token.position, lines);
          }

          if (keySegs.isEmpty) {
            throw LowParsingFailure("Map Pair #$i's key is an empty segment (unparsable)", token.position, lines);
          }

          if (valSegs.isEmpty) {
            throw LowParsingFailure("Map Pair #$i's value is an empty segment (unparsable)", token.position, lines);
          }

          m[parseLine(keySegs, lines, LowParserMode.data)] = parseLine(valSegs, lines, LowParserMode.data);
        }

        return LowMapNode(m, token.position);
      }

      if (token.value == "()") {
        return parseLine(token.subtokens, lines, LowParserMode.data);
      }

      if (token.value.startsWith('"') && token.value.endsWith('"')) {
        final str = parseStringLiteral(token, lines);

        return LowStringNode(str, token.position);
      }

      if (token.type == LowPreprocessedTokenType.identifier) {
        return LowVariableNode(token.value, token.position);
      }
    }

    if (tokens.length >= 4 && tokens[0].value == "var" && tokens[1].type == LowPreprocessedTokenType.identifier && tokens[2].value == "=") {
      final name = tokens[1].value;
      final value = parseLine(tokens.sublist(3), lines, LowParserMode.data);

      return LowDefineVariable(name, value, false, tokens.first.position);
    }

    if (tokens.length >= 4 && tokens[0].value == "static" && tokens[1].type == LowPreprocessedTokenType.identifier && tokens[2].value == "=") {
      final name = tokens[1].value;
      final value = parseLine(tokens.sublist(3), lines, LowParserMode.data);

      return LowDefineVariable(name, value, true, tokens.first.position);
    }

    if (tokens.length == 4 && tokens[0].value == "fn" && tokens[1].type == LowPreprocessedTokenType.identifier && tokens[2].value == "()" && tokens[3].value == "{}") {
      final name = tokens[1].value;

      final argtokens = preprocessor.splitBySeperators(tokens[2].subtokens, [',']);
      final argnames = <String>[];
      final argtypes = <LowAST?>[];

      var i = 0;
      for (var argtoken in argtokens) {
        i++;
        if (argtoken.isEmpty) {
          if (argtokens.length == 1) break;
          throw LowParsingFailure("Parameter #$i is an empty segment (unparsable)", tokens[2].position, lines);
        }
        if (argtoken.length > 1) {
          if (argtoken[1].value != ":") throw LowParsingFailure("Please separate argument name and argument type by a :", argtoken[1].position, lines);
          if (argtoken.length == 2) throw LowParsingFailure("Please separate argument name and argument type by a :", argtoken[1].position, lines);

          argtypes.add(parseLine(argtoken.sublist(2), lines, LowParserMode.data));
        } else {
          argtypes.add(null);
        }

        argnames.add(argtoken.first.value);
      }

      final body = parseLine([tokens[3]], lines, LowParserMode.topLevel);

      return LowDefineFunction(name, false, body, argnames, argtypes, null, tokens.first.position);
    }

    if (tokens.length == 4 && tokens[0].value == "static" && tokens[1].type == LowPreprocessedTokenType.identifier && tokens[2].value == "()" && tokens[3].value == "{}") {
      final name = tokens[1].value;

      final argtokens = preprocessor.splitBySeperators(tokens[2].subtokens, [',']);
      final argnames = <String>[];
      final argtypes = <LowAST?>[];

      var i = 0;
      for (var argtoken in argtokens) {
        i++;
        if (argtoken.isEmpty) {
          if (argtokens.length == 1) break;
          throw LowParsingFailure("Parameter #$i is an empty segment (unparsable)", tokens[2].position, lines);
        }
        if (argtoken.length > 1) {
          if (argtoken[1].value != ":") throw LowParsingFailure("Please separate argument name and argument type by a :", argtoken[1].position, lines);
          if (argtoken.length == 2) throw LowParsingFailure("Please separate argument name and argument type by a :", argtoken[1].position, lines);

          argtypes.add(parseLine(argtoken.sublist(2), lines, LowParserMode.data));
        } else {
          argtypes.add(null);
        }

        argnames.add(argtoken.first.value);
      }

      final body = parseLine([tokens[3]], lines, LowParserMode.topLevel);

      return LowDefineFunction(name, true, body, argnames, argtypes, null, tokens.first.position);
    }

    if (tokens.length > 4 && tokens[0].value == "fn" && tokens[1].type == LowPreprocessedTokenType.identifier && tokens[2].value == "()" && tokens[3].value == ":" && tokens.last.value == "{}") {
      if (tokens.length == 5) {
        throw LowParsingFailure("Expected a type", tokens.last.position, lines);
      }

      final name = tokens[1].value;

      final argtokens = preprocessor.splitBySeperators(tokens[2].subtokens, [',']);
      final argnames = <String>[];
      final argtypes = <LowAST?>[];

      var i = 0;
      for (var argtoken in argtokens) {
        i++;
        if (argtoken.isEmpty) {
          if (argtokens.length == 1) break;
          throw LowParsingFailure("Parameter #$i is an empty segment (unparsable)", tokens[2].position, lines);
        }
        if (argtoken.length > 1) {
          if (argtoken[1].value != ":") throw LowParsingFailure("Please separate argument name and argument type by a :", argtoken[1].position, lines);
          if (argtoken.length == 2) throw LowParsingFailure("Please separate argument name and argument type by a :", argtoken[1].position, lines);

          argtypes.add(parseLine(argtoken.sublist(2), lines, LowParserMode.data));
        } else {
          argtypes.add(null);
        }

        argnames.add(argtoken.first.value);
      }

      final body = parseLine([tokens.last], lines, LowParserMode.topLevel);

      final returnType = parseLine(tokens.sublist(4, tokens.length - 1), lines, LowParserMode.data);

      return LowDefineFunction(name, false, body, argnames, argtypes, returnType, tokens.first.position);
    }

    if (tokens.length > 4 && tokens[0].value == "static" && tokens[1].type == LowPreprocessedTokenType.identifier && tokens[2].value == "()" && tokens[3].value == ":" && tokens.last.value == "{}") {
      if (tokens.length == 5) {
        throw LowParsingFailure("Expected a type", tokens.last.position, lines);
      }

      final name = tokens[1].value;

      final argtokens = preprocessor.splitBySeperators(tokens[2].subtokens, [',']);
      final argnames = <String>[];
      final argtypes = <LowAST?>[];

      var i = 0;
      for (var argtoken in argtokens) {
        i++;
        if (argtoken.isEmpty) {
          if (argtokens.length == 1) break;
          throw LowParsingFailure("Parameter #$i is an empty segment (unparsable)", tokens[2].position, lines);
        }
        if (argtoken.length > 1) {
          if (argtoken[1].value != ":") throw LowParsingFailure("Please separate argument name and argument type by a :", argtoken[1].position, lines);
          if (argtoken.length == 2) throw LowParsingFailure("Please separate argument name and argument type by a :", argtoken[1].position, lines);

          argtypes.add(parseLine(argtoken.sublist(2), lines, LowParserMode.data));
        } else {
          argtypes.add(null);
        }

        argnames.add(argtoken.first.value);
      }

      final body = parseLine([tokens.last], lines, LowParserMode.topLevel);

      final returnType = parseLine(tokens.sublist(4, tokens.length - 1), lines, LowParserMode.data);

      return LowDefineFunction(name, true, body, argnames, argtypes, returnType, tokens.first.position);
    }

    if (tokens.length == 3 && tokens[0].value == "fn" && tokens[1].value == "()" && tokens[2].value == "{}") {
      final argtokens = preprocessor.splitBySeperators(tokens[1].subtokens, [',']);
      final argnames = <String>[];
      final argtypes = <LowAST?>[];

      var i = 0;
      for (var argtoken in argtokens) {
        i++;
        if (argtoken.isEmpty) {
          if (argtokens.length == 1) break;
          throw LowParsingFailure("Parameter #$i is an empty segment (unparsable)", tokens[2].position, lines);
        }
        if (argtoken.length > 1) {
          if (argtoken[1].value != ":") throw LowParsingFailure("Please separate argument name and argument type by a :", argtoken[1].position, lines);
          if (argtoken.length == 2) throw LowParsingFailure("Please separate argument name and argument type by a :", argtoken[1].position, lines);

          argtypes.add(parseLine(argtoken.sublist(2), lines, LowParserMode.data));
        } else {
          argtypes.add(null);
        }

        argnames.add(argtoken.first.value);
      }

      final body = parseLine([tokens[2]], lines, LowParserMode.topLevel);

      return LowLambdaFunction(body, argnames, argtypes, null, tokens.first.position);
    }

    if (tokens.length > 3 && tokens[0].value == "fn" && tokens[1].value == "()" && tokens.last.value == "{}") {
      if (tokens.length == 4) throw LowParsingFailure("Expected a type", tokens.last.position, lines);

      final argtokens = preprocessor.splitBySeperators(tokens[1].subtokens, [',']);
      final argnames = <String>[];
      final argtypes = <LowAST?>[];

      var i = 0;
      for (var argtoken in argtokens) {
        i++;
        if (argtoken.isEmpty) {
          if (argtokens.length == 1) break;
          throw LowParsingFailure("Parameter #$i is an empty segment (unparsable)", tokens[2].position, lines);
        }
        if (argtoken.length > 1) {
          if (argtoken[1].value != ":") throw LowParsingFailure("Please separate argument name and argument type by a :", argtoken[1].position, lines);
          if (argtoken.length == 2) throw LowParsingFailure("Please separate argument name and argument type by a :", argtoken[1].position, lines);

          argtypes.add(parseLine(argtoken.sublist(2), lines, LowParserMode.data));
        } else {
          argtypes.add(null);
        }

        argnames.add(argtoken.first.value);
      }

      final body = parseLine([tokens.last], lines, LowParserMode.topLevel);
      final returnType = parseLine(tokens.sublist(2, tokens.length - 1), lines, LowParserMode.data);

      return LowLambdaFunction(body, argnames, argtypes, returnType, tokens.first.position);
    }

    if (tokens.length >= 2 && tokens[0].value == "return") {
      final value = parseLine(tokens.sublist(1), lines, LowParserMode.data);

      return LowReturnNode(value, tokens.first.position);
    }

    if (tokens.length == 3) {
      if (tokens[0].value == "if" && tokens[1].value == "()" && tokens[2].value == "{}") {
        final condition = parseLine(tokens[1].subtokens, lines, LowParserMode.data);
        final body = parseLine([tokens[2]], lines, LowParserMode.topLevel);

        return LowIfNode(condition, body, null, tokens[0].position);
      }
    }

    if (tokens.length > 1 && tokens[0].value == "include") {
      var mode = LowIncludeMode.returned;
      final pathTokens = <LowPreprocessedToken>[];
      String? identifier;

      var i = 0;
      final l = tokens.sublist(1);
      for (var token in l) {
        i++;
        if (mode == LowIncludeMode.returned) {
          if (token.value == "globally" && i == l.length) {
            identifier = null;
            mode = LowIncludeMode.globals;
          } else if (token.value == "as" && i == l.length - 1) {
            if (l.last.type != LowPreprocessedTokenType.identifier) throw LowParsingFailure("Global library message must be an identifier", l.last.position, lines);
            identifier = l.last.value;
            mode = LowIncludeMode.globals;
          } else {
            pathTokens.add(token);
          }
        }
      }

      return LowIncludeNode(parseLine(pathTokens, lines, LowParserMode.data), mode, identifier, tokens.first.position);
    }

    if (tokens.length == 3 && tokens[0].value == "for" && tokens[1].value == "()" && tokens[2].value == "{}") {
      final parts = splitByLines(tokens[1].subtokens);
      if (parts.length != 3) {
        throw LowParsingFailure("For loops need 3 lines in their first parenthesis: A startup line, a condition, and an afterwards", tokens[1].position, lines);
      }
      final startup = parseLine(parts[0], lines, LowParserMode.topLevel);
      final condition = parseLine(parts[1], lines, LowParserMode.data);
      final afterwards = parseLine(parts[2], lines, LowParserMode.topLevel);
      final body = parseLine([tokens[2]], lines, LowParserMode.topLevel);

      return LowForNode(startup, condition, body, afterwards, tokens.first.position);
    }

    if (tokens.length == 3 && tokens[0].value == "while" && tokens[1].value == "()" && tokens[2].value == "{}") {
      final condition = parseLine(tokens[1].subtokens, lines, LowParserMode.data);
      final body = parseLine([tokens[2]], lines, LowParserMode.topLevel);

      return LowWhileNode(condition, body, tokens.first.position);
    }

    if (tokens.length == 3 && tokens[0].value == "foreach" && tokens[1].value == "()" && tokens[2].value == "{}") {
      final vars = <String>[];
      final data = <LowPreprocessedToken>[];

      var i = 0;
      final definition = tokens[1].subtokens;
      var finishedVars = false;
      while (true) {
        if (i >= definition.length) {
          if (!finishedVars) {
            throw LowParsingFailure("Expected to reach in", tokens[1].position, lines);
          }
          break;
        }
        var token = definition[i];

        if (finishedVars) {
          data.add(token);
        } else {
          vars.add(token.value);
          if (i < definition.length - 1) {
            final next = definition[i + 1];
            if (next.value != "in" && next.value != ",") throw LowParsingFailure("Expected in or ,", next.position, lines);
            if (next.value == ",") i++;
            if (next.value == "in") {
              i++;
              finishedVars = true;
            }
          } else {
            throw "Expected to reach , or in";
          }
        }
        i++;
      }
      final body = parseLine([tokens[2]], lines, LowParserMode.topLevel);

      return LowForeachNode(vars, parseLine(data, lines, LowParserMode.data), body, tokens.first.position);
    }

    if (tokens.length >= 5) {
      if (tokens[0].value == "if" && tokens[1].value == "()" && tokens[2].value == "{}" && tokens[3].value == "else") {
        final condition = parseLine(tokens[1].subtokens, lines, LowParserMode.data);
        final body = parseLine([tokens[2]], lines, LowParserMode.topLevel);
        final fallback = parseLine(tokens.sublist(4), lines, LowParserMode.topLevel);

        return LowIfNode(condition, body, fallback, tokens[0].position);
      }
    }

    if (tokens.last.value == "[]") {
      final owner = parseLine(tokens.sublist(0, tokens.length - 1), lines, LowParserMode.data);
      final args = parseLine(tokens.last.subtokens, lines, LowParserMode.data);

      return LowHandleOp("[]", owner, [args], tokens.last.position);
    }

    var op = handleOperators(tokens, lines);

    if (op is LowHandleOp) {
      return op;
    }

    if (tokens.length >= 2 && tokens.last.value == "()" && tokens[tokens.length - 2].type != LowPreprocessedTokenType.operator) {
      final toCall = tokens.sublist(0, tokens.length - 1);
      if (!containsOperators(toCall, except: ['.'])) {
        final params = preprocessor.splitBySeperators(tokens.last.subtokens, [',']);

        var i = 0;
        for (var param in params) {
          i++;
          if (param.isEmpty) {
            if (params.length == 1) break;
            throw LowParsingFailure("Parameter #$i is an empty segment (unparsable)", tokens.last.position, lines);
          }
        }

        final paramsAST = (params.length == 1 && params.first.isEmpty) ? <LowAST>[] : params.map((line) => parseLine(line, lines, LowParserMode.data)).toList();

        final call = parseLine(toCall, lines, LowParserMode.data);

        return LowCallValue(call, paramsAST, tokens.last.position);
      }
    }

    var indexing = handleIndexing(tokens, lines);

    if (indexing is LowHandleOp) {
      return indexing;
    }

    throw LowParsingFailure("Unable to parse line / instruction.", tokens.first.position, lines);
  }

  String parseStringLiteral(LowPreprocessedToken token, List<String> lines) {
    final chars = token.value.substring(1, token.value.length - 1);
    var escaping = false;
    var str = "";
    for (var i = 0; i < chars.length; i++) {
      final char = chars[i];
      final left = chars.length - i - 1;
      if (char == "\\" && !escaping) {
        escaping = true;
        continue;
      } else if (char == "n" && escaping) {
        str += "\n";
      } else if (char == "r" && escaping) {
        str += "\r";
      } else if (char == "v" && escaping) {
        str += "\v";
      } else if (char == "b" && escaping) {
        str += "\b";
      } else if (char == "f" && escaping) {
        str += "\f";
      } else if (char == "t" && escaping) {
        str += "\t";
      } else if (char == "x" && escaping) {
        if (left < 2) throw LowParsingFailure("Escape sequence \\x must be followed by 2 other hex digits", token.position, lines);
        final digits = '${chars[i + 1]}${chars[i + 2]}';
        final codeunit = int.tryParse(digits, radix: 16);
        if (codeunit == null) throw LowParsingFailure("Escape sequence \\x must be followed by 2 other hex digits", token.position, lines);
        str += String.fromCharCode(codeunit);
      }
      str += char;
      escaping = false;
    }
    return str;
  }

  var opOrder = <List<String>>[
    ["*", "/", "~/", "%"],
    ["+", "-"],
    ["<<", ">>", "&", "|", "^"],
    ["==", ">", "<", ">=", "<=", "!="],
    ["is", "isnt"],
    ["&&", "||"],
    ["->"],
    ["="],
  ];
  late List<String> allOps = opOrder.fold<List<String>>([], (a, b) => [...a, ...b]);

  late List<String> indexes = ["."];

  bool containsOperators(List<LowPreprocessedToken> tokens, {List<String> except = const []}) {
    for (var token in tokens) {
      if (allOps.contains(token.value) && !except.contains(token.value)) return true;
    }

    return false;
  }

  LowAST? handleIndexing(List<LowPreprocessedToken> tokens, List<String> lines) {
    // List of either indexing or LowASTs
    var l = [];
    {
      var tmp = <LowPreprocessedToken>[];

      for (var token in tokens) {
        if (indexes.contains(token.value)) {
          l.add(parseLine(tmp, lines, LowParserMode.data));
          tmp.clear();
          l.add(token.value);
        } else {
          tmp.add(token);
        }
      }

      // This means there is only one element
      if (l.isEmpty) return null;

      l.add(parseLine(tmp, lines, LowParserMode.data));
    }

    var nl = [];

    for (var i = 0; i < l.length; i++) {
      final thing = l[i];

      if (indexes.contains(thing)) {
        final String op = thing;

        final LowAST last = nl.removeLast();
        final LowAST next = l[i + 1];
        if (next is! LowVariableNode) {
          throw LowParsingFailure("Field name should be identifier", next.position, lines);
        }
        i++; // Skip next
        nl.add(LowHandleOp(op, last, [next], last.position));
      } else {
        nl.add(thing);
      }
    }

    l = nl;
    if (l.length == 1) return l.first is LowAST ? l.first : null;

    return null;
  }

  LowAST? handleOperators(List<LowPreprocessedToken> tokens, List<String> lines) {
    // List of either operators or LowASTs
    var l = [];
    {
      var tmp = <LowPreprocessedToken>[];

      for (var token in tokens) {
        if (allOps.contains(token.value)) {
          l.add(parseLine(tmp, lines, LowParserMode.data));
          tmp.clear();
          l.add(token.value);
        } else {
          tmp.add(token);
        }
      }

      // This means there is only one element
      if (l.isEmpty) return null;

      l.add(parseLine(tmp, lines, LowParserMode.data));
    }

    while (true) {
      var didSomething = false;
      for (var ops in opOrder) {
        var nl = [];

        for (var i = l.length - 1; i >= 0; i--) {
          final thing = l[i];

          if (ops.contains(thing)) {
            final String op = thing;

            final LowAST next = l[i - 1];
            final LowAST last = nl.removeAt(0);
            i--; // Skip next
            nl.insert(0, LowHandleOp(op, next, [last], last.position));
            didSomething = true;
          } else {
            nl.insert(0, thing);
          }
        }

        l = nl;
        if (l.length == 1) return l.first is LowAST ? l.first : null;
      }
      if (didSomething) break;
    }

    return null;
  }
}

enum LowParserMode {
  topLevel,
  data,
}
