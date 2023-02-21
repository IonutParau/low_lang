import 'package:low_lang/ast/call.dart';
import 'package:low_lang/parser/token.dart';
import 'package:low_lang/vm/context.dart';
import 'package:low_lang/vm/interop.dart';

enum LowInstructionType {
  clone,
  set,
  addInt,
  addDouble,
  addString,
  addBool,
  addList,
  addMap,
  addObject,
  call,
  getGlobal,
  setGlobal,
  ifCheck,
}

class LowInstruction {
  LowInstructionType type;
  dynamic data;
  LowTokenPosition position;

  LowInstruction(this.type, this.data, this.position);

  static dynamic runBlock(List<LowInstruction> instructions,
      LowTokenPosition caller, LowContext context) {
    for (var i = 0; i < instructions.length; i++) {
      final instruction = instructions[i];

      switch (instruction.type) {
        case LowInstructionType.addInt:
          context.push(instruction.data as int);
          break;
        case LowInstructionType.addDouble:
          context.push(instruction.data as double);
          break;
        case LowInstructionType.addString:
          context.push(instruction.data as String);
          break;
        case LowInstructionType.addBool:
          context.push(instruction.data as bool);
          break;
        case LowInstructionType.clone:
          context.push(context.getAt(instruction.data as int));
          break;
        case LowInstructionType.set:
          final v = context.pop();
          final i = instruction.data as int;
          context.setAt(i, v);
          break;
        case LowInstructionType.call:
          final int argc = instruction.data[0];
          final bool shouldPush = instruction.data[1];

          var argv = [];

          for (var i = 0; i < argc; i++) {
            argv.add(context.pop());
          }
          argv = argv.reversed.toList();

          final v = lowHandleCall(
            context.pop(),
            argv,
            instruction.position,
            context,
          );
          if (shouldPush) {
            context.push(v);
          }
          break;
        case LowInstructionType.addList:
          final n = instruction.data;

          var l = [];

          for (var i = 0; i < n; i++) {
            l.add(context.pop());
          }
          l = l.reversed.toList();
          context.push(l);
          break;
        case LowInstructionType.addMap:
          final pairc = instruction.data;

          final m = <dynamic, dynamic>{};

          for (var i = 0; i < pairc; i++) {
            final val = context.pop();
            final key = context.pop();
            m[key] = val;
          }
          context.push(m);
          break;
        case LowInstructionType.addObject:
          final List<String> fields = instruction.data;

          final o = <String, dynamic>{};
          for (var field in fields) {
            o[field] = context.pop();
          }
          context.push(o);
          break;
        case LowInstructionType.getGlobal:
          final String name = instruction.data;

          context.push(context.getGlobal(name));
          break;
        case LowInstructionType.setGlobal:
          final String name = instruction.data;
          final val = context.pop();
          context.setGlobal(name, val);
          break;
        case LowInstructionType.ifCheck:
          final toCheck = context.pop();
          final List<LowInstruction> body = instruction.data[0];
          final List<LowInstruction>? fallback = instruction.data[1];

          if (LowInteropHandler.truthful(
              context, instruction.position, toCheck)) {
            final old = context.size;
            LowInstruction.runBlock(body, instruction.position, context);
            while (old > context.size) {
              context.pop();
            }
          } else if (fallback != null) {
            final old = context.size;
            LowInstruction.runBlock(fallback, instruction.position, context);
            while (old > context.size) {
              context.pop();
            }
          }
          break;
      }

      if (context.status.status == LowMemoryStatus.returned) {
        return context.returnedValue;
      }
    }

    return context.returnedValue;
  }
}
