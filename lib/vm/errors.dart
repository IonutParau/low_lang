import 'dart:math';

import 'package:low_lang/parser/token.dart';
import 'package:low_lang/vm/stack_trace.dart';

class LowRuntimeError {
  String msg;
  LowTokenPosition source;
  LowStackTrace stackTrace;

  LowRuntimeError(this.msg, this.source, this.stackTrace);

  @override
  String toString() {
    if (stackTrace.isEmpty()) {
      return "$source: $msg";
    }
    return "$source: $msg\n--Low Stack Trace--\n$stackTrace\n---End of Trace----";
  }
}

class LowParsingFailure {
  String msg;
  String? example;
  LowTokenPosition source;
  List<String> lines;

  LowParsingFailure(this.msg, this.source, this.lines);

  @override
  String toString() {
    final errorPosition = source;
    final lineNumber = errorPosition.lineNumber;
    final charNumber = errorPosition.charNumber;

    var hasExtra = false;
    var extraLine = "";
    var extraArrow = "";
    var extraHeader = "";
    final msgHeader = '$errorPosition: ';

    if (msg.contains('Missing end of') && msg.contains('pair')) {
      final position = LowTokenPosition.fromString(msg.split(' ').last);

      hasExtra = true;
      extraLine = lines[position.lineNumber - 1];
      extraHeader = "${position.lineNumber}. ";

      extraArrow = List.generate(max(msg.length + msgHeader.length, extraHeader.length + extraLine.length), (i) => (i - extraHeader.length) == position.charNumber ? "^" : " ").join();
    }

    var line = lines[lineNumber - 1];
    final header = '$lineNumber. ';

    final topAndBottom = List.filled(max(msg.length + msgHeader.length, max(header.length + line.length, extraHeader.length + extraLine.length)), '=').join();
    final littleArrow = List.generate(
      max(msg.length + msgHeader.length, max(header.length + line.length, extraHeader.length + extraLine.length)),
      (i) => (i - header.length) == charNumber ? "^" : " ",
    ).join().substring(1);

    return "$topAndBottom\n${hasExtra ? "$extraHeader$extraLine\n$extraArrow" : ""}\n$header$line\n$littleArrow\n$msgHeader$msg\n${example == null ? "" : "$example\n"}$topAndBottom";
  }
}
