import 'dart:math';

import 'package:low_lang/parser/token.dart';

class LowStackTrace {
  final _stack = <LowTokenPosition>[];
  final int limit;
  final int printMaximum;

  LowStackTrace({this.limit = 16384, this.printMaximum = 16});

  void push(LowTokenPosition position) {
    _stack.add(position);
    if (_stack.length > limit) {
      throw "$position: Stack Overflow\n$this";
    }
  }

  void pop() {
    _stack.removeLast();
  }

  bool isEmpty() => _stack.isEmpty;
  bool isNotEmpty() => _stack.isNotEmpty;

  T scoped<T>(LowTokenPosition position, T Function() toRun) {
    push(position);
    late T v;
    try {
      v = toRun();
    } catch (e) {
      pop();
      rethrow;
    }
    pop();
    return v;
  }

  @override
  String toString() {
    return _stack.sublist(0, min(_stack.length, printMaximum)).map((e) => "$e").join("\n");
  }
}
