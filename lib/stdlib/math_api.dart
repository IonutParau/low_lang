import 'dart:math';

import 'package:low_lang/parser/token.dart';
import 'package:low_lang/vm/context.dart';
import 'package:low_lang/vm/errors.dart';
import 'package:low_lang/vm/vm.dart';

Map<String, dynamic> lowMathAPI(LowVM vm) {
  return {
    "abs": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      final m = args[0];

      if (m is! int && m is! double) {
        throw LowRuntimeError("abs(x) expects x to be an int or double", position, context.stackTrace);
      }

      return (m as num).abs();
    },
    "neg": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      final m = args[0];

      if (m is! int && m is! double) {
        throw LowRuntimeError("neg(x) expects x to be an int or double", position, context.stackTrace);
      }

      return -((m as num).abs());
    },
    "pow": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 2);

      final x = args[0];
      final y = args[1];

      if (x is! int && x is! double) {
        throw LowRuntimeError("pow(x, y) expects x to be an int or double", position, context.stackTrace);
      }
      if (y is! int && y is! double) {
        throw LowRuntimeError("pow(x, y) expects y to be an int or double", position, context.stackTrace);
      }

      return pow(x, y);
    },
    "log": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      final x = args[0];

      if (x is! int && x is! double) {
        throw LowRuntimeError("log(x) expects x to be an int or double", position, context.stackTrace);
      }

      return log(x);
    },
    "logn": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 2);

      final x = args[0];
      final n = args[1];

      if (x is! int && x is! double) {
        throw LowRuntimeError("logn(x, n) expects x to be an int or double", position, context.stackTrace);
      }
      if (n is! int && n is! double) {
        throw LowRuntimeError("logn(x, n) expects n to be an int or double", position, context.stackTrace);
      }

      return log(x) / log(n);
    },
    "mapWithin": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 5);

      final x = args[0];
      final a = args[1];
      final b = args[2];
      final c = args[3];
      final d = args[4];

      if (x is! int && x is! double) {
        throw LowRuntimeError("mapWithin(x, a, b, c, d) expects x to be an int or double", position, context.stackTrace);
      }
      if (a is! int && a is! double) {
        throw LowRuntimeError("mapWithin(x, a, b, c, d) expects a to be an int or double", position, context.stackTrace);
      }
      if (b is! int && b is! double) {
        throw LowRuntimeError("mapWithin(x, a, b, c, d) expects b to be an int or double", position, context.stackTrace);
      }
      if (c is! int && c is! double) {
        throw LowRuntimeError("mapWithin(x, a, b, c, d) expects c to be an int or double", position, context.stackTrace);
      }
      if (d is! int && d is! double) {
        throw LowRuntimeError("mapWithin(x, a, b, c, d) expects d to be an int or double", position, context.stackTrace);
      }

      return ((x - a) / (b - a)) * (d - c) + c;
    },
    "sqrt": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      final x = args[0];

      if (x is! int && x is! double) {
        throw LowRuntimeError("sqrt(x) expects x to be an int or double", position, context.stackTrace);
      }

      return sqrt(x);
    },
    "floor": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      final x = args[0];

      if (x is! int && x is! double) {
        throw LowRuntimeError("floor(x) expects x to be an int or double", position, context.stackTrace);
      }

      return (x as num).floor();
    },
    "ceil": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      final x = args[0];

      if (x is! int && x is! double) {
        throw LowRuntimeError("ceil(x) expects x to be an int or double", position, context.stackTrace);
      }

      return (x as num).ceil();
    },
    "clamp": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 3);

      final x = args[0];
      final a = args[1];
      final b = args[2];

      if (x is! int && x is! double) {
        throw LowRuntimeError("clamp(x, a, b) expects x to be an int or double", position, context.stackTrace);
      }
      if (a is! int && a is! double) {
        throw LowRuntimeError("clamp(x, a, b) expects a to be an int or double", position, context.stackTrace);
      }
      if (b is! int && b is! double) {
        throw LowRuntimeError("clamp(x, a, b) expects b to be an int or double", position, context.stackTrace);
      }

      return (x as num).clamp(a, b);
    },
    "min": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 2);

      final a = args[0];
      final b = args[1];

      if (a is! int && a is! double) {
        throw LowRuntimeError("min(a, b) expects a to be an int or double", position, context.stackTrace);
      }
      if (b is! int && b is! double) {
        throw LowRuntimeError("min(a, b) expects b to be an int or double", position, context.stackTrace);
      }

      return min<num>(a, b);
    },
    "max": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 2);

      final a = args[0];
      final b = args[1];

      if (a is! int && a is! double) {
        throw LowRuntimeError("max(a, b) expects a to be an int or double", position, context.stackTrace);
      }
      if (b is! int && b is! double) {
        throw LowRuntimeError("max(a, b) expects b to be an int or double", position, context.stackTrace);
      }

      return max<num>(a, b);
    },
  };
}
