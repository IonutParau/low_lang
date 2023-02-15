import 'dart:io';
import 'dart:math';

import 'package:low_lang/parser/token.dart';
import 'package:low_lang/vm/context.dart';
import 'package:low_lang/vm/errors.dart';
import 'package:low_lang/vm/interop.dart';
import 'package:low_lang/vm/vm.dart';

Map<String, dynamic> lowCoreAPI(LowVM vm) {
  final rng = Random();

  final types = <String, dynamic>{
    "string": "String",
    "int": "Int",
    "double": "Double",
    "number": ["Int", "Double"],
    "function": "Function",
    "object": "Object",
    "list": "List",
    "map": "Map",
    "buffer": "Buffer",
    "listOf": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      return (List subargs, LowContext context, LowTokenPosition position) {
        minArgLength(subargs, 1);

        final l = subargs[0];
        if (l is! List) return false;

        for (var val in l) {
          if (!LowInteropHandler.matchesType(context, position, val, args[0])) return false;
        }

        return true;
      };
    },
    "equalsTo": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      return (List subargs, LowContext context, LowTokenPosition position) {
        minArgLength(subargs, 1);

        return LowInteropHandler.handleOperator(context, position, subargs[0], "==", [args[0]]);
      };
    },
  };

  return {
    "not": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      return !LowInteropHandler.truthful(context, LowTokenPosition("core.low", 1, 1), args[0]);
    },
    "toString": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      return LowInteropHandler.convertToString(context, LowTokenPosition("core.low", 1, 1), args[0]);
    },
    "char": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      final v = args[0];

      if (v is int) {
        return String.fromCharCode(v);
      } else if (v is String) {
        return v.codeUnits.first;
      }

      return null;
    },
    "toInt": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      final str = LowInteropHandler.convertToString(context, LowTokenPosition("core.low", 1, 1), args[0]);

      return int.tryParse(str);
    },
    "toDouble": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      final str = LowInteropHandler.convertToString(context, LowTokenPosition("core.low", 1, 1), args[0]);

      return double.tryParse(str);
    },
    "timeMS": (List args, LowContext context, LowTokenPosition position) {
      return DateTime.now().millisecondsSinceEpoch;
    },
    "timeMicro": (List args, LowContext context, LowTokenPosition position) {
      return DateTime.now().microsecondsSinceEpoch;
    },
    "randBool": (List args, LowContext context, LowTokenPosition position) {
      return rng.nextBool();
    },
    "randInt": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 2);
      final min = args[0];
      final max = args[1];

      if (min is! int) {
        throw LowRuntimeError("randInt(min, max) expects min to be an int", position, context.stackTrace);
      }

      if (max is! int) {
        throw LowRuntimeError("randInt(min, max) expects max to be an int", position, context.stackTrace);
      }

      return rng.nextInt(max - min) + min;
    },
    "randDouble": (List args, LowContext context, LowTokenPosition position) {
      return rng.nextDouble();
    },
    "print": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      final str = LowInteropHandler.convertToString(context, LowTokenPosition("core.low", 1, 1), args[0]);

      print(str);
    },
    "write": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      final str = LowInteropHandler.convertToString(context, LowTokenPosition("core.low", 1, 1), args[0]);

      stdout.write(str);
    },
    "error": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      final str = LowInteropHandler.convertToString(context, LowTokenPosition("core.low", 1, 1), args[0]);

      throw LowRuntimeError(str, position, context.stackTrace);
    },
    "assert": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 3);

      final v = LowInteropHandler.truthful(context, LowTokenPosition("core.low", 1, 1), args[0]);
      final str = LowInteropHandler.convertToString(context, LowTokenPosition("core.low", 1, 1), args[1]);

      if (!v) throw LowRuntimeError(str, position, context.stackTrace);
      if (args[2] != null) {
        final out = LowInteropHandler.convertToString(context, LowTokenPosition("core.low", 1, 1), args[2]);
        print(out);
        return out;
      }
    },
    "read": (List args, LowContext context, LowTokenPosition position) {
      return stdin.readLineSync();
    },
    "prompt": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);
      stdout.write(LowInteropHandler.convertToString(context, LowTokenPosition("core.low", 1, 1), args[0]));
      return stdin.readLineSync();
    },
    "typeOf": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      return LowInteropHandler.typeNameOf(context, position, args[0]);
    },
    "exit": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      exit(args[0] is int ? args[0] : 0);
    },
    ...types,
  };
}
