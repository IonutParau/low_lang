class LowTokenPosition {
  String fileName;
  int lineNumber;
  int charNumber;

  LowTokenPosition(this.fileName, this.lineNumber, this.charNumber);

  LowTokenPosition get copy => LowTokenPosition(fileName, lineNumber, charNumber);

  @override
  String toString() {
    return "$fileName:$lineNumber:$charNumber";
  }

  factory LowTokenPosition.fromString(String str) {
    final parts = str.split(':');

    return LowTokenPosition(parts.first, int.parse(parts[1]), int.parse(parts[2]));
  }
}

enum LowTokenType {
  identifier,
  keyword,
  seperator,
  operator,
  literal,
}

class LowToken {
  String value;
  LowTokenType type;
  LowTokenPosition position;

  LowToken(this.value, this.type, this.position);
}

enum LowPreprocessedTokenType {
  identifier,
  keyword,
  seperator,
  operator,
  literal,
  roundPair,
  squarePair,
  curlyPair,
}

class LowPreprocessedToken {
  String value;
  LowPreprocessedTokenType type;
  LowTokenPosition position;
  List<LowPreprocessedToken> subtokens;

  LowPreprocessedToken(this.value, this.type, this.position, this.subtokens);
}
