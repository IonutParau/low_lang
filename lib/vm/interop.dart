import 'dart:typed_data';

import 'package:low_lang/parser/token.dart';
import 'package:low_lang/vm/vm.dart';

import 'context.dart';
import 'errors.dart';

abstract class LowExternalValue {
  String typeName() => "external";

  dynamic invoke(
      List params, LowContext context, LowTokenPosition callerTokenPosition);

  dynamic readField(
      String field, LowContext context, LowTokenPosition getterTokenPosition);

  dynamic writeField(String field, dynamic value, LowContext context,
      LowTokenPosition setterTokenPosition);

  dynamic handleOperator(String opcode, List args, LowContext context,
      LowTokenPosition operatorTokenPosition);

  dynamic iterate(dynamic Function(List args) callback, LowContext context,
      LowTokenPosition iteratorTokenPosition);

  bool truthful(LowContext context, LowTokenPosition callerTokenPosition);

  String convertToString(
      LowContext context, LowTokenPosition callerTokenPosition);

  bool representsTypeOf(
      dynamic value, LowContext context, LowTokenPosition position);
}

class LowInteropHandler {
  static String typeNameOf(
      LowContext context, LowTokenPosition tokenPosition, dynamic value) {
    if (value is String) {
      return "String";
    }

    if (value is int) {
      return "Int";
    }

    if (value is double) {
      return "Double";
    }

    if (value is bool) {
      return "Bool";
    }

    if (value is Map<String, dynamic>) {
      return "Object";
    }

    if (value is Map) {
      return "Map";
    }

    if (value is Uint8List) {
      return "Buffer";
    }

    if (value is List) {
      return "List";
    }

    if (value is LowFunction) {
      return "Function";
    }

    if (value is LowExternalValue) {
      return value.typeName();
    }

    if (value == null) {
      return "Null";
    }

    throw LowRuntimeError("Attempt to get type name of $value", tokenPosition,
        context.stackTrace);
  }

  static dynamic invoke(LowContext context, LowTokenPosition tokenPosition,
      dynamic value, List params) {
    if (value is String) {
      throw LowRuntimeError(
          "Attempt to invoke a string", tokenPosition, context.stackTrace);
    }

    if (value is int) {
      throw LowRuntimeError(
          "Attempt to invoke an int", tokenPosition, context.stackTrace);
    }

    if (value is bool) {
      throw LowRuntimeError(
          "Attempt to invoke a bool", tokenPosition, context.stackTrace);
    }

    if (value is double) {
      throw LowRuntimeError(
          "Attempt to invoke a double", tokenPosition, context.stackTrace);
    }

    if (value is Uint8List) {
      throw LowRuntimeError(
          "Attempt to invoke a buffer", tokenPosition, context.stackTrace);
    }

    if (value is LowObject) {
      if (value['__call'] == null) {
        throw LowRuntimeError(
            "Attempt to invoke an object with no __call metamethod",
            tokenPosition,
            context.stackTrace);
      }
      return invoke(context, tokenPosition, value['__call'], params);
    }

    if (value is Map) {
      throw LowRuntimeError(
          "Attempt to invoke a map", tokenPosition, context.stackTrace);
    }

    if (value is List) {
      throw LowRuntimeError(
          "Attempt to invoke a list", tokenPosition, context.stackTrace);
    }

    if (value is LowFunction) {
      return value(params, context, tokenPosition);
    }

    if (value is LowExternalValue) {
      return value.invoke(params, context, tokenPosition);
    }

    if (value == null) {
      throw LowRuntimeError(
          "Attempt to invoke null", tokenPosition, context.stackTrace);
    }

    throw LowRuntimeError(
        "Attempt to invoke $value", tokenPosition, context.stackTrace);
  }

  static dynamic readField(LowContext context, LowTokenPosition tokenPosition,
      dynamic value, String field) {
    if (value is String) {
      if (field == "isEmpty") return value.isEmpty;
      if (field == "isNotEmpty") return value.isNotEmpty;
      if (field == "split") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          final str = convertToString(context, tokenPosition, args.first);

          return value.split(str);
        };
      }
      if (field == "startsWith") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          final str = convertToString(context, tokenPosition, args.first);

          return value.startsWith(str);
        };
      }
      if (field == "endsWith") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          final str = convertToString(context, tokenPosition, args.first);

          return value.endsWith(str);
        };
      }
      if (field == "contains") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          final str = convertToString(context, tokenPosition, args.first);

          return value.contains(str);
        };
      }
      if (field == "substring") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 2);

          final start = args[0];
          final end = args[1];

          if (start is! int) {
            throw LowRuntimeError(
                "<string>.substring(start, end) expected start to be an int. Instead, we got ${typeNameOf(context, pos, start)}",
                pos,
                context.stackTrace);
          }

          if (end is! int && end != null) {
            throw LowRuntimeError(
                "<string>.substring(start, end) expected end to be an int or null. Instead, we got ${typeNameOf(context, pos, end)}",
                pos,
                context.stackTrace);
          }

          return value.substring(start, end);
        };
      }
      if (field == "upper") {
        return value.toUpperCase();
      }
      if (field == "lower") {
        return value.toLowerCase();
      }
      if (field == "length") {
        return value.length;
      }
      return null;
    }

    if (value is int) {
      if (field == "isEven") return value.isEven;
      if (field == "isOdd") return value.isOdd;
      if (field == "sign") return value.sign;
      if (field == "isFinite") return value.isFinite;
      if (field == "isInfinite") return value.isInfinite;
      if (field == "isNaN") return value.isNaN;
      if (field == "isNegative") return value.isNegative;
      if (field == "isPositive") return !value.isNegative;
      if (field == "toDouble") {
        return (List args, LowContext context, LowTokenPosition pos) {
          return value.toDouble();
        };
      }
      if (field == "toInt") {
        return (List args, LowContext context, LowTokenPosition pos) {
          return value;
        };
      }
      if (field == "abs") {
        return (List args, LowContext context, LowTokenPosition pos) {
          return value.abs();
        };
      }
      if (field == "neg") {
        return (List args, LowContext context, LowTokenPosition pos) {
          return -value.abs();
        };
      }
      if (field == "clamp") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 2);

          final min = args[0];
          final max = args[1];

          if (min is! num) {
            throw LowRuntimeError(
                "<int>.clamp(min, max) expected min to be a number (either double or int). Instead, we got ${typeNameOf(context, pos, min)}",
                pos,
                context.stackTrace);
          }

          if (max is! num) {
            throw LowRuntimeError(
                "<int>.clamp(min, max) expected max to be a number (either double or int). Instead, we got ${typeNameOf(context, pos, max)}",
                pos,
                context.stackTrace);
          }

          final result = value.clamp(min, max);

          if (result % 1 == 0) {
            return result.toInt();
          } else {
            return result.toDouble();
          }
        };
      }
      if (field == "ceil") {
        return (List args, LowContext context, LowTokenPosition pos) {
          return value.ceil();
        };
      }
      if (field == "floor") {
        return (List args, LowContext context, LowTokenPosition pos) {
          return value.floor();
        };
      }
      if (field == "gcd") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          final a = args[0];

          if (a is! int) {
            throw LowRuntimeError(
                "<int>.gcd(other) expected other to be an int. Instead, we got ${typeNameOf(context, pos, a)}",
                pos,
                context.stackTrace);
          }

          return value.gcd(a);
        };
      }
      if (field == "toStringAsExponential") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          final a = args[0];

          if (a is! int && a != null) {
            throw LowRuntimeError(
                "<int>.toStringAsExponential(fractionDigits) expected fractionDigits to be an int or null. Instead, we got ${typeNameOf(context, pos, a)}",
                pos,
                context.stackTrace);
          }

          return value.toStringAsExponential(a);
        };
      }
      if (field == "toStringAsFixed") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          final a = args[0];

          if (a is! int) {
            throw LowRuntimeError(
                "<int>.toStringAsFixed(fractionDigits) expected fractionDigits to be an int. Instead, we got ${typeNameOf(context, pos, a)}",
                pos,
                context.stackTrace);
          }

          return value.toStringAsFixed(a);
        };
      }
      if (field == "toRadixString") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          final radix = args[0];

          if (radix is! int) {
            throw LowRuntimeError(
                "<int>.toRadixString(radix) expected radix to be an int. Instead, we got ${typeNameOf(context, pos, radix)}",
                pos,
                context.stackTrace);
          }

          return value.toStringAsFixed(radix);
        };
      }
      return null;
    }

    if (value is double) {
      if (field == "sign") return value.sign;
      if (field == "isFinite") return value.isFinite;
      if (field == "isInfinite") return value.isInfinite;
      if (field == "isNaN") return value.isNaN;
      if (field == "isNegative") return value.isNegative;
      if (field == "isPositive") return !value.isNegative;
      if (field == "toDouble") {
        return (List args, LowContext context, LowTokenPosition pos) {
          return value.toDouble();
        };
      }
      if (field == "toInt") {
        return (List args, LowContext context, LowTokenPosition pos) {
          return value;
        };
      }
      if (field == "abs") {
        return (List args, LowContext context, LowTokenPosition pos) {
          return value.abs();
        };
      }
      if (field == "neg") {
        return (List args, LowContext context, LowTokenPosition pos) {
          return -value.abs();
        };
      }
      if (field == "clamp") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 2);

          final min = args[0];
          final max = args[1];

          if (min is! num) {
            throw LowRuntimeError(
                "<double>.clamp(min, max) expected min to be a number (either double or int). Instead, we got ${typeNameOf(context, pos, min)}",
                pos,
                context.stackTrace);
          }

          if (max is! num) {
            throw LowRuntimeError(
                "<double>.clamp(min, max) expected max to be a number (either double or int). Instead, we got ${typeNameOf(context, pos, max)}",
                pos,
                context.stackTrace);
          }

          final result = value.clamp(min, max);

          if (result % 1 == 0) {
            return result.toInt();
          } else {
            return result.toDouble();
          }
        };
      }
      if (field == "ceil") {
        return (List args, LowContext context, LowTokenPosition pos) {
          return value.ceil();
        };
      }
      if (field == "floor") {
        return (List args, LowContext context, LowTokenPosition pos) {
          return value.floor();
        };
      }
      if (field == "toStringAsExponential") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          final a = args[0];

          if (a is! int && a != null) {
            throw LowRuntimeError(
              "<double>.toStringAsExponential(fractionDigits) expected fractionDigits to be an int or null. Instead, we got ${typeNameOf(context, pos, a)}",
              pos,
              context.stackTrace,
            );
          }

          return value.toStringAsExponential(a);
        };
      }
      if (field == "toStringAsFixed") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          final a = args[0];

          if (a is! int) {
            throw LowRuntimeError(
                "<double>.toStringAsFixed(fractionDigits) expected fractionDigits to be an int. Instead, we got ${typeNameOf(context, pos, a)}",
                pos,
                context.stackTrace);
          }

          return value.toStringAsFixed(a);
        };
      }
      if (field == "toRadixString") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          final radix = args[0];

          if (radix is! int) {
            throw LowRuntimeError(
                "<double>.toRadixString(radix) expected radix to be an int. Instead, we got ${typeNameOf(context, pos, radix)}",
                pos,
                context.stackTrace);
          }

          return value.toStringAsFixed(radix);
        };
      }
      return null;
    }

    if (value is bool) {
      return null;
    }

    if (value is LowObject) {
      if (value['__getters'] is LowObject) {
        if (value['__getters'][field] != null)
          return invoke(
              context, tokenPosition, value['__getters'][field], [value]);
      }

      return value[field];
    }

    if (value is Map) {
      if (field == "isEmpty") return value.isEmpty;
      if (field == "isNotEmpty") return value.isNotEmpty;
      if (field == "length") return value.length;
      if (field == "clear") {
        return (List args, LowContext context, LowTokenPosition pos) {
          value.clear();
        };
      }
      if (field == "containsKey") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);
          return value.containsKey(args.first);
        };
      }
      if (field == "containsValue") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);
          return value.containsValue(args.first);
        };
      }
      if (field == "keys") {
        return value.keys.toList();
      }
      if (field == "values") {
        return value.values.toList();
      }
      if (field == "remove") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          value.remove(args.first);
        };
      }
      return null;
    }

    if (value is Uint8List) {
      if (field == "isEmpty") return value.isEmpty;
      if (field == "isNotEmpty") return value.isNotEmpty;
      if (field == "length") return value.length;
      if (field == "clear") {
        return (List args, LowContext context, LowTokenPosition pos) {
          value.clear();
        };
      }
      if (field == "contains") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          return value.contains(args.first);
        };
      }
      if (field == "first") {
        if (value.isEmpty) {
          throw LowRuntimeError("<buffer>.first was used on an empty buffer",
              tokenPosition, context.stackTrace);
        }
        return value.first;
      }
      if (field == "last") {
        if (value.isEmpty) {
          throw LowRuntimeError("<buffer>.last was used on an empty buffer",
              tokenPosition, context.stackTrace);
        }
        return value.last;
      }
      if (field == "range") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 2);

          final start = args.first;
          final end = args[1];

          if (end > value.length) {
            throw LowRuntimeError(
                "<buffer>.range(start, end) expected end to be at most the length of the buffer (${value.length}). Instead, we got $end",
                pos,
                context.stackTrace);
          }

          if (start is! int) {
            throw LowRuntimeError(
                "<buffer>.range(start, end) expected start to be an int. Instead, we got ${typeNameOf(context, pos, start)}",
                pos,
                context.stackTrace);
          }
          if (end is! int) {
            throw LowRuntimeError(
                "<buffer>.range(start, end) expected end to be an int. Instead, we got ${typeNameOf(context, pos, end)}",
                pos,
                context.stackTrace);
          }

          final len = end - start;

          return Uint8List.view(
              value.buffer, start * Uint8List.bytesPerElement, len);
        };
      }
      return null;
    }

    if (value is List) {
      if (field == "isEmpty") return value.isEmpty;
      if (field == "isNotEmpty") return value.isNotEmpty;
      if (field == "length") return value.length;
      if (field == "clear") {
        return (List args, LowContext context, LowTokenPosition pos) {
          value.clear();
        };
      }
      if (field == "remove") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          value.remove(args.first);
        };
      }
      if (field == "removeAt") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          final idx = args.first;

          if (idx is! int) {
            throw LowRuntimeError(
                "<list>.removeAt(idx) expected idx to be an int. Instead, we got ${typeNameOf(context, pos, idx)}",
                pos,
                context.stackTrace);
          }

          value.removeAt(idx);
        };
      }
      if (field == "insert") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 2);

          final idx = args.first;
          final val = args[1];

          if (idx is! int) {
            throw LowRuntimeError(
                "<list>.insert(idx, val) expected idx to be an int. Instead, we got ${typeNameOf(context, pos, idx)}",
                pos,
                context.stackTrace);
          }

          value.insert(idx, val);
        };
      }
      if (field == "add") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          value.add(args.first);
        };
      }
      if (field == "contains") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 1);

          return value.contains(args.first);
        };
      }
      if (field == "first") {
        return value.first;
      }
      if (field == "last") {
        return value.last;
      }
      if (field == "range") {
        return (List args, LowContext context, LowTokenPosition pos) {
          minArgLength(args, 2);

          final start = args.first;
          final end = args[1];

          if (start is! int) {
            throw LowRuntimeError(
                "<list>.range(start, end) expected start to be an int. Instead, we got ${typeNameOf(context, pos, start)}",
                pos,
                context.stackTrace);
          }
          if (end is! int) {
            throw LowRuntimeError(
                "<list>.range(start, end) expected end to be an int. Instead, we got ${typeNameOf(context, pos, end)}",
                pos,
                context.stackTrace);
          }

          return value.getRange(start, end).toList();
        };
      }
      return null;
    }

    if (value is LowFunction) {
      if (field == "invoke") {
        return value;
      }
      if (field == "invokeWith") {
        return (List args, LowContext context,
            LowTokenPosition callerPosition) {
          minArgLength(args, 1);
          if (args.first is List) {
            return value(args.first, context, callerPosition);
          } else {
            throw LowRuntimeError(
                "Attempt to invoke a function using invokeWith, but not passing in a list",
                callerPosition,
                context.stackTrace);
          }
        };
      }
      return null;
    }

    if (value is LowExternalValue) {
      return value.readField(field, context, tokenPosition);
    }

    throw LowRuntimeError("Attempt to read field $field of $value",
        tokenPosition, context.stackTrace);
  }

  static dynamic writeField(LowContext context, LowTokenPosition tokenPosition,
      dynamic value, String field, dynamic fieldValue) {
    if (value is int) {
      throw LowRuntimeError("Attempt to mutate the fields of an int",
          tokenPosition, context.stackTrace);
    }

    if (value is String) {
      throw LowRuntimeError("Attempt to mutate the fields of a string",
          tokenPosition, context.stackTrace);
    }

    if (value is double) {
      throw LowRuntimeError("Attempt to mutate the fields of a double",
          tokenPosition, context.stackTrace);
    }

    if (value is Uint8List) {
      throw LowRuntimeError("Attempt to mutate the fields of a buffer",
          tokenPosition, context.stackTrace);
    }

    if (value is List) {
      throw LowRuntimeError("Attempt to mutate the fields of a list",
          tokenPosition, context.stackTrace);
    }

    if (value is LowObject) {
      if (value["__setters"] != null) {
        return value["__setters"]
            [field]([value, fieldValue], context, tokenPosition);
      }
      value[field] = fieldValue;
      return fieldValue;
    }

    if (value is Map) {
      throw LowRuntimeError("Attempt to mutate the fields of a map",
          tokenPosition, context.stackTrace);
    }

    if (value is LowFunction) {
      throw LowRuntimeError("Attempt to mutate the fields of a function",
          tokenPosition, context.stackTrace);
    }

    if (value is LowExternalValue) {
      return value.writeField(field, value, context, tokenPosition);
    }

    throw LowRuntimeError("Attempt to modify field $field of $value",
        tokenPosition, context.stackTrace);
  }

  static dynamic handleOperator(LowContext context,
      LowTokenPosition tokenPosition, dynamic value, String opcode, List args) {
    if (opcode == "is") {
      return LowInteropHandler.matchesType(
        context,
        tokenPosition,
        value,
        args.first,
      );
    }
    if (opcode == "isnt") {
      return !LowInteropHandler.matchesType(
        context,
        tokenPosition,
        value,
        args.first,
      );
    }
    if (opcode == "<=") {
      final less = LowInteropHandler.handleOperator(
          context, tokenPosition, value, "<", args);
      if (LowInteropHandler.truthful(context, tokenPosition, less)) return true;
      return LowInteropHandler.handleOperator(
          context, tokenPosition, value, "==", args);
    }
    if (opcode == ">=") {
      final less = LowInteropHandler.handleOperator(
        context,
        tokenPosition,
        value,
        ">",
        args,
      );
      if (LowInteropHandler.truthful(context, tokenPosition, less)) return true;
      return LowInteropHandler.handleOperator(
        context,
        tokenPosition,
        value,
        "==",
        args,
      );
    }
    if (opcode == "!=") {
      return !LowInteropHandler.truthful(
        context,
        tokenPosition,
        LowInteropHandler.handleOperator(
          context,
          tokenPosition,
          value,
          "==",
          args,
        ),
      );
    }
    if (opcode == "&&") {
      if (!LowInteropHandler.truthful(context, tokenPosition, value)) {
        return false;
      }
      return LowInteropHandler.truthful(context, tokenPosition, args.first);
    }
    if (opcode == "||") {
      if (LowInteropHandler.truthful(context, tokenPosition, value)) {
        return true;
      }
      return LowInteropHandler.truthful(context, tokenPosition, args.first);
    }

    if (value is int) {
      if (opcode == "+") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError("Only ints and doubles can be added to ints",
              tokenPosition, context.stackTrace);
        }

        return value + other;
      }
      if (opcode == "-") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError(
              "Only ints and doubles can be subtracted from ints",
              tokenPosition,
              context.stackTrace);
        }

        return value - other;
      }
      if (opcode == "*") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError("Ints can only multiply with ints and doubles",
              tokenPosition, context.stackTrace);
        }

        return value * other;
      }
      if (opcode == "%") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError(
              "Ints can only take remainder of division with ints and doubles",
              tokenPosition,
              context.stackTrace);
        }

        return value % other;
      }
      if (opcode == "/") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError("Ints can only be divided by ints and doubles",
              tokenPosition, context.stackTrace);
        }

        return value / other;
      }
      if (opcode == "~/") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError(
              "Ints can only be integer divided by ints and doubles",
              tokenPosition,
              context.stackTrace);
        }

        return value ~/ other;
      }
      if (opcode == ">>") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int) {
          throw LowRuntimeError(
              "Ints can only be bit-shifted by integer amounts",
              tokenPosition,
              context.stackTrace);
        }

        return value >> other;
      }
      if (opcode == "<<") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int) {
          throw LowRuntimeError(
              "Ints can only be bit-shifted by integer amounts",
              tokenPosition,
              context.stackTrace);
        }

        return value << other;
      }
      if (opcode == "&") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int) {
          throw LowRuntimeError(
              "Binary AND can only be done on ints against other ints",
              tokenPosition,
              context.stackTrace);
        }

        return value & other;
      }
      if (opcode == "|") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int) {
          throw LowRuntimeError(
              "Binary OR can only be done on ints against other ints",
              tokenPosition,
              context.stackTrace);
        }

        return value | other;
      }
      if (opcode == "^") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int) {
          throw LowRuntimeError(
              "Binary XOR can only be done on ints against other ints",
              tokenPosition,
              context.stackTrace);
        }

        return value ^ other;
      }
      if (opcode == "==") {
        minArgLength(args, 1);

        return value == args[0];
      }
      if (opcode == ">") {
        minArgLength(args, 1);

        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError(
              "Ints can only be compared if greater relative to other ints and doubles",
              tokenPosition,
              context.stackTrace);
        }

        return value > other;
      }
      if (opcode == "<") {
        minArgLength(args, 1);

        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError(
              "Ints can only be compared if less relative to other ints and doubles",
              tokenPosition,
              context.stackTrace);
        }

        return value < other;
      }
      throw LowRuntimeError("Ints do not support the $opcode operator",
          tokenPosition, context.stackTrace);
    }

    if (value is double) {
      if (opcode == "+") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError("Only ints and doubles can be added to doubles",
              tokenPosition, context.stackTrace);
        }

        return value + other;
      }
      if (opcode == "-") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError(
              "Only ints and doubles can be subtracted from doubles",
              tokenPosition,
              context.stackTrace);
        }

        return value - other;
      }
      if (opcode == "*") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError(
              "Doubles can only multiply with ints and doubles",
              tokenPosition,
              context.stackTrace);
        }

        return value * other;
      }
      if (opcode == "/") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError(
              "Doubles can only be divided by ints and doubles",
              tokenPosition,
              context.stackTrace);
        }

        return value / other;
      }
      if (opcode == "%") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError(
              "Doubles can only take remainder of division with ints and doubles",
              tokenPosition,
              context.stackTrace);
        }

        return value % other;
      }
      if (opcode == "~/") {
        minArgLength(args, 1);
        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError(
              "Doubles can only be integer divided by ints and doubles",
              tokenPosition,
              context.stackTrace);
        }

        return value ~/ other;
      }
      if (opcode == "==") {
        minArgLength(args, 1);

        return value == args[0];
      }
      if (opcode == ">") {
        minArgLength(args, 1);

        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError(
              "Doubles can only be compared if greater relative to other ints and doubles",
              tokenPosition,
              context.stackTrace);
        }

        return value > other;
      }
      if (opcode == "<") {
        minArgLength(args, 1);

        final other = args[0];

        if (other is! int && other is! double) {
          throw LowRuntimeError(
              "Doubles can only be compared if less relative to other ints and doubles",
              tokenPosition,
              context.stackTrace);
        }

        return value < other;
      }
      throw LowRuntimeError("Doubles do not support the $opcode operator",
          tokenPosition, context.stackTrace);
    }

    if (value is String) {
      if (opcode == "+") {
        minArgLength(args, 1);

        final str = convertToString(context, tokenPosition, args[0]);

        return value + str;
      }
      if (opcode == "*") {
        minArgLength(args, 1);

        final amount = args[0];

        if (amount is! int) {
          throw LowRuntimeError("Strings can only be multiplied by integers",
              tokenPosition, context.stackTrace);
        }

        return value * amount;
      }
      if (opcode == "==") {
        minArgLength(args, 1);

        return value == args[0];
      }

      throw LowRuntimeError("Strings do not support the $opcode operator",
          tokenPosition, context.stackTrace);
    }

    if (value is LowObject) {
      if (value["__opcodes"] is Map) {
        if (value["__opcodes"][opcode] != null) {
          return value["__opcodes"]
              [opcode]([value, ...args], context, tokenPosition);
        }
      }

      if (opcode == "==") {
        return value == args.first;
      }

      throw LowRuntimeError("Objects do not support the $opcode operator",
          tokenPosition, context.stackTrace);
    }

    if (value is Uint8List) {
      if (opcode == "[]") {
        minArgLength(args, 1);
        final idx = args[0];

        if (idx is! int) {
          throw LowRuntimeError("Buffers can only be indexed by integers",
              tokenPosition, context.stackTrace);
        }

        if (idx < 0 || idx >= value.length) return null;

        return value[idx];
      }
      if (opcode == "[]=") {
        minArgLength(args, 1);
        final idx = args[0];
        final val = args[1];

        if (idx is! int) {
          throw LowRuntimeError("Buffers can only be indexed by integers",
              tokenPosition, context.stackTrace);
        }
        if (idx < 0 || idx >= value.length) return null;

        if (val is! int) {
          throw LowRuntimeError(
              "Buffers can only have their indexes set to integers",
              tokenPosition,
              context.stackTrace);
        }

        value[idx] = val;
        return null;
      }
      if (opcode == "==") {
        return value == args.first;
      }
      throw LowRuntimeError("Buffers do not support the $opcode operator",
          tokenPosition, context.stackTrace);
    }

    if (value is List) {
      if (opcode == "[]") {
        minArgLength(args, 1);
        final idx = args[0];

        if (idx is! int) {
          throw LowRuntimeError("Lists can only be indexed by integers",
              tokenPosition, context.stackTrace);
        }

        if (idx < 0 || idx >= value.length) return null;

        return value[idx];
      }
      if (opcode == "[]=") {
        minArgLength(args, 2);
        final idx = args[0];
        final val = args[1];

        if (idx is! int) {
          throw LowRuntimeError("Lists can only be indexed by integers",
              tokenPosition, context.stackTrace);
        }
        if (idx < 0 || idx >= value.length) return;

        value[idx] = val;
        return null;
      }
      if (opcode == "==") {
        return value == args.first;
      }
      throw LowRuntimeError("Lists do not support the $opcode operator",
          tokenPosition, context.stackTrace);
    }

    if (value is Map) {
      if (opcode == "[]") {
        minArgLength(args, 1);
        final key = args[0];

        return value[key];
      }
      if (opcode == "[]=") {
        minArgLength(args, 1);
        final key = args[0];
        final val = args[1];

        value[key] = val;
        return null;
      }
      if (opcode == "==") {
        return value == args.first;
      }
      throw LowRuntimeError("Maps do not support the $opcode operator",
          tokenPosition, context.stackTrace);
    }

    if (value is LowFunction) {
      if (opcode == "==") {
        return value == args.first;
      }
      throw LowRuntimeError("Functions do not support the $opcode operator",
          tokenPosition, context.stackTrace);
    }

    if (value is LowExternalValue) {
      return value.handleOperator(opcode, args, context, tokenPosition);
    }

    if (value == null) {
      if (opcode == "==") {
        minArgLength(args, 1);
        return args[0] == null;
      }
    }

    throw LowRuntimeError("Attempt to invoke operator $opcode on $value",
        tokenPosition, context.stackTrace);
  }

  static void iterate(LowContext context, LowTokenPosition tokenPosition,
      dynamic value, dynamic Function(List args) callback) {
    if (value is int) {
      throw LowRuntimeError(
          "Attempt to iterate an int", tokenPosition, context.stackTrace);
    }

    if (value is double) {
      throw LowRuntimeError(
          "Attempt to iterate a double", tokenPosition, context.stackTrace);
    }

    if (value is LowFunction) {
      throw LowRuntimeError(
          "Attempt to iterate a function", tokenPosition, context.stackTrace);
    }

    if (value is String) {
      final chars = value.split('');

      for (var char in chars) {
        callback([char]);
        if (context.status.status == LowMemoryStatus.broke) {
          context.status.status = LowMemoryStatus.running;
          break;
        }
        if (context.status.status == LowMemoryStatus.continued) {
          context.status.status = LowMemoryStatus.running;
        }
        if (context.status.status == LowMemoryStatus.returned) return;
      }
      return;
    }

    if (value is Uint8List) {
      int i = -1;
      for (var val in value) {
        i++;
        callback([val, i]);
        if (context.status.status == LowMemoryStatus.broke) {
          context.status.status = LowMemoryStatus.running;
          break;
        }
        if (context.status.status == LowMemoryStatus.continued) {
          context.status.status = LowMemoryStatus.running;
        }
        if (context.status.status == LowMemoryStatus.returned) return;
      }
      return;
    }

    if (value is List) {
      int i = -1;
      for (var val in value) {
        i++;
        callback([val, i]);
        if (context.status.status == LowMemoryStatus.broke) {
          context.status.status = LowMemoryStatus.running;
          break;
        }
        if (context.status.status == LowMemoryStatus.continued) {
          context.status.status = LowMemoryStatus.running;
        }
        if (context.status.status == LowMemoryStatus.returned) return;
      }
      return;
    }

    if (value is LowObject) {
      if (value["__iterate"] != null) {
        value["__iterate"]([value], context, tokenPosition);
        return;
      }
      for (var val in value.entries) {
        callback([val.key, val.value]);
        if (context.status.status == LowMemoryStatus.broke) {
          context.status.status = LowMemoryStatus.running;
          break;
        }
        if (context.status.status == LowMemoryStatus.continued) {
          context.status.status = LowMemoryStatus.running;
        }
        if (context.status.status == LowMemoryStatus.returned) return;
      }
      return;
    }

    if (value is Map) {
      for (var val in value.entries) {
        callback([val.key, val.value]);
        if (context.status.status == LowMemoryStatus.broke) {
          context.status.status = LowMemoryStatus.running;
          break;
        }
        if (context.status.status == LowMemoryStatus.continued) {
          context.status.status = LowMemoryStatus.running;
        }
        if (context.status.status == LowMemoryStatus.returned) return;
      }
      return;
    }

    if (value is LowExternalValue) {
      value.iterate(callback, context, tokenPosition);
      return;
    }

    throw LowRuntimeError(
        "Attempt to iterate $value", tokenPosition, context.stackTrace);
  }

  static bool truthful(
      LowContext context, LowTokenPosition tokenPosition, dynamic value) {
    if (value is int) {
      return value != 0;
    }

    if (value is double) {
      return value != 0;
    }

    if (value is bool) {
      return value;
    }

    if (value is LowFunction) {
      return true;
    }

    if (value is String) {
      return value.isNotEmpty;
    }

    if (value is LowObject) {
      if (value["__tobool"] != null)
        return value["__tobool"]([value], context, tokenPosition);
      return true;
    }

    if (value is List || value is Uint8List || value is Map) {
      return true;
    }

    if (value is LowExternalValue) {
      return value.truthful(context, tokenPosition);
    }

    if (value == null) {
      return false;
    }

    throw LowRuntimeError("Attempt to convert $value to a boolean",
        tokenPosition, context.stackTrace);
  }

  static String convertToString(
      LowContext context, LowTokenPosition tokenPosition, dynamic value) {
    if (value is int) {
      return "$value";
    }

    if (value is double) {
      return "$value";
    }

    if (value is bool) {
      return "$value";
    }

    if (value is Uint8List) {
      return "$value";
    }

    if (value is List) {
      return "$value";
    }

    if (value is LowObject) {
      if (value["__tostr"] != null)
        return convertToString(context, tokenPosition,
            value["__tostr"]([value], context, tokenPosition));
      return "$value";
    }

    if (value is Map) {
      return "$value";
    }

    if (value is LowFunction) {
      return "<function:0x${value.hashCode.toRadixString(16)}>";
    }

    if (value is String) {
      return value;
    }

    if (value is LowExternalValue) {
      return value.convertToString(context, tokenPosition);
    }

    if (value == null) {
      return 'null';
    }

    throw LowRuntimeError("Attempt to convert $value to a string",
        tokenPosition, context.stackTrace);
  }

  static bool matchesType(LowContext context, LowTokenPosition position,
      dynamic value, dynamic type) {
    if (type is LowExternalValue) {
      return type.representsTypeOf(value, context, position);
    }

    if (type is LowFunction) {
      return truthful(context, position, type([value], context, position));
    }

    if (type is String) {
      return typeNameOf(context, position, value) == type;
    }

    if (type == null) {
      return value == null;
    }

    if (type is List) {
      var oneWorked = false;

      for (var subtype in type) {
        if (!matchesType(context, position, value, subtype)) continue;
        oneWorked = true;
        break;
      }

      return oneWorked;
    }

    if (type is LowObject) {
      if (value is! LowObject) return false;

      if (type["__type"] != null) {
        return matchesType(context, position, value, type["__type"]);
      }

      var incorrectField = false;

      for (var pair in type.entries) {
        if (matchesType(context, position, value[pair.key], pair.value))
          continue;
        incorrectField = true;
        break;
      }

      return !incorrectField;
    }

    throw LowRuntimeError(
        "Attempt to treat ${typeNameOf(context, position, type)} as a type",
        position,
        context.stackTrace);
  }
}
