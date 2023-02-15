import 'package:low_lang/parser/lexer.dart';
import 'package:low_lang/parser/token.dart';
import 'package:low_lang/vm/errors.dart';

class LowPreprocessor {
  List<LowToken> removeComments(List<LowToken> commented) {
    final uncommented = <LowToken>[];

    var commentType = "none";

    for (var token in commented) {
      if (commentType == "one-line") {
        if (token.value == "\n") commentType = "none";
        continue;
      }
      if (commentType == "multi-line") {
        if (token.value.endsWith('*/')) commentType = "none";
        continue;
      }
      if (token.value.startsWith('//')) {
        commentType = "one-line";
        continue;
      }
      if (token.value.startsWith('/*')) {
        commentType = "multi-line";
        continue;
      }
      uncommented.add(token);
    }

    uncommented.removeWhere((token) => token.value.replaceAll(" ", "").replaceAll("\t", "").isEmpty);

    return uncommented;
  }

  List<LowPreprocessedToken> preprocess(List<LowToken> tokens, List<String> lines) {
    final uncommented = removeComments(tokens);
    final processed = <LowPreprocessedToken>[];

    for (var i = 0; i < uncommented.length; i++) {
      final token = uncommented[i];
      final pos = token.position;

      if (token.value == "@") {
        i++;
        if (i >= uncommented.length) throw LowParsingFailure("@ expected to be followed by [ or {, but was instead followed by the end of the file.", pos, lines);
        final next = uncommented[i];
        if (next.value == "\n") throw LowParsingFailure("@ expected to be followed by [ or {, but was instead followed by the end of a line.", pos, lines);

        if (next.value == "[") {
          final pos = next.position;
          final subtokens = <LowToken>[];

          var bias = 1;
          var lastpos = pos;

          while (bias > 0) {
            i++;
            if (uncommented.length <= i) {
              throw LowParsingFailure("Missing end of [] pair defined at $pos", lastpos, lines);
            }
            if (uncommented[i].value == "[") bias++;
            if (uncommented[i].value == "]") bias--;
            if (bias > 0) subtokens.add(uncommented[i]);
            lastpos = uncommented[i].position;
          }

          processed.add(LowPreprocessedToken("@[]", LowPreprocessedTokenType.literal, pos, preprocess(subtokens, lines)));
          continue;
        }

        if (next.value == "{") {
          final pos = next.position;
          final subtokens = <LowToken>[];

          var bias = 1;
          var lastpos = pos;

          while (bias > 0) {
            i++;
            if (uncommented.length <= i) {
              throw LowParsingFailure("Missing end of {} pair defined at $pos", lastpos, lines);
            }
            if (uncommented[i].value == "{") bias++;
            if (uncommented[i].value == "}") bias--;
            if (bias > 0) subtokens.add(uncommented[i]);
            lastpos = uncommented[i].position;
          }

          processed.add(LowPreprocessedToken("@{}", LowPreprocessedTokenType.literal, pos, preprocess(subtokens, lines)));
          continue;
        }

        throw LowParsingFailure("@ expected to be followed by [ or {, but was instead followed by ${next.value}.", pos, lines);
      }

      if (token.value == "(") {
        final subtokens = <LowToken>[];

        var bias = 1;
        var lastpos = pos;

        while (bias > 0) {
          i++;
          if (uncommented.length <= i) {
            throw LowParsingFailure("Missing end of () pair defined at $pos", lastpos, lines);
          }
          if (uncommented[i].value == "(") bias++;
          if (uncommented[i].value == ")") bias--;
          if (bias > 0) subtokens.add(uncommented[i]);
          lastpos = uncommented[i].position;
        }

        processed.add(LowPreprocessedToken("()", LowPreprocessedTokenType.roundPair, pos, preprocess(subtokens, lines)));
        continue;
      }

      if (token.value == "[") {
        final subtokens = <LowToken>[];

        var bias = 1;
        var lastpos = pos;

        while (bias > 0) {
          i++;
          if (uncommented.length <= i) {
            throw LowParsingFailure("Missing end of [] pair defined at $pos", lastpos, lines);
          }
          if (uncommented[i].value == "[") bias++;
          if (uncommented[i].value == "]") bias--;
          if (bias > 0) subtokens.add(uncommented[i]);
          lastpos = uncommented[i].position;
        }

        processed.add(LowPreprocessedToken("[]", LowPreprocessedTokenType.squarePair, pos, preprocess(subtokens, lines)));
        continue;
      }

      if (token.value == "{") {
        final subtokens = <LowToken>[];

        var bias = 1;
        var lastpos = pos;

        while (bias > 0) {
          i++;
          if (uncommented.length <= i) {
            throw LowParsingFailure("Missing end of {} pair defined at $pos", lastpos, lines);
          }
          if (uncommented[i].value == "{") bias++;
          if (uncommented[i].value == "}") bias--;
          if (bias > 0) subtokens.add(uncommented[i]);
          lastpos = uncommented[i].position;
        }

        processed.add(LowPreprocessedToken("{}", LowPreprocessedTokenType.curlyPair, pos, preprocess(subtokens, lines)));
        continue;
      }

      if (token.type == LowTokenType.identifier) {
        processed.add(LowPreprocessedToken(token.value, LowPreprocessedTokenType.identifier, pos, []));
      }
      if (token.type == LowTokenType.keyword) {
        processed.add(LowPreprocessedToken(token.value, LowPreprocessedTokenType.keyword, pos, []));
      }
      if (token.type == LowTokenType.literal) {
        processed.add(LowPreprocessedToken(token.value, LowPreprocessedTokenType.literal, pos, []));
      }
      if (token.type == LowTokenType.operator) {
        processed.add(LowPreprocessedToken(token.value, LowPreprocessedTokenType.operator, pos, []));
      }
      if (token.type == LowTokenType.seperator) {
        processed.add(LowPreprocessedToken(token.value, LowPreprocessedTokenType.seperator, pos, []));
      }
    }

    return handlePreprocessedTypes(processed);
  }

  List<LowPreprocessedToken> handlePreprocessedTypes(List<LowPreprocessedToken> untyped) {
    final helper = LowLexer();

    for (var token in untyped) {
      if (helper.isLiteral(token.value)) {
        token.type = LowPreprocessedTokenType.literal;
      }
      if (helper.isIdentifier(token.value)) {
        token.type = LowPreprocessedTokenType.identifier;
      }
      if (helper.isSeperator(token.value)) {
        token.type = LowPreprocessedTokenType.seperator;
      }
      if (helper.isOperator(token.value)) {
        token.type = LowPreprocessedTokenType.operator;
      }
      if (helper.isKeyword(token.value)) {
        token.type = LowPreprocessedTokenType.keyword;
      }
      if (token.value == "()") {
        token.type = LowPreprocessedTokenType.roundPair;
      }
      if (token.value == "[]") {
        token.type = LowPreprocessedTokenType.squarePair;
      }
      if (token.value == "[]") {
        token.type = LowPreprocessedTokenType.curlyPair;
      }
    }

    return untyped;
  }

  List<List<LowPreprocessedToken>> splitBySeperators(List<LowPreprocessedToken> unseperated, List<String> seperators, {bool removeEmptyLists = false, bool removeNewlines = false}) {
    final l = <List<LowPreprocessedToken>>[[]];

    for (var token in unseperated) {
      if (removeNewlines && "\n" == token.value) continue;
      if (seperators.contains(token.value)) {
        l.add([]);
      } else {
        l.last.add(token);
      }
    }

    if (removeEmptyLists) l.removeWhere((element) => element.isEmpty);

    return l;
  }
}
