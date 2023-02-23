import 'dart:typed_data';

import 'package:low_lang/ast/call.dart';
import 'package:low_lang/parser/token.dart';
import 'package:low_lang/vm/context.dart';
import 'package:low_lang/vm/errors.dart';
import 'package:low_lang/vm/interop.dart';

enum LowInstructionType {
  clone,
  set,
  pop,
  addInt,
  addDouble,
  addString,
  addBool,
  addList,
  addMap,
  addObject,
  addNull,
  addBuffer,
  addFunction,
  call,
  getGlobal,
  setGlobal,
  ifCheck,
  whileLoop,
  forLoop,
  foreachLoop,
  writeField,
  readField,
}

class LowInstruction {
  LowInstructionType type;
  dynamic data;
  LowTokenPosition position;

  LowInstruction(this.type, this.data, this.position);

  @override
  String toString() {
    return '${type.name} $data $position';
  }

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
          final int pairc = instruction.data;

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
            while (context.size > old) {
              context.pop();
            }
          }
          break;
        case LowInstructionType.whileLoop:
          final List<LowInstruction> check = instruction.data[0];
          final List<LowInstruction> body = instruction.data[1];

          while (context.status.status == LowMemoryStatus.running) {
            LowInstruction.runBlock(check, instruction.position, context);
            if (!LowInteropHandler.truthful(
              context,
              instruction.position,
              context.pop(),
            )) break;

            final old = context.size;
            LowInstruction.runBlock(body, instruction.position, context);
            while (context.size > old) {
              context.pop();
            }

            if (context.status.status == LowMemoryStatus.continued) continue;
          }
          break;
        case LowInstructionType.forLoop:
          final List<LowInstruction> startup = instruction.data[0];
          final List<LowInstruction> condition = instruction.data[1];
          final List<LowInstruction> step = instruction.data[2];
          final List<LowInstruction> body = instruction.data[3];

          final old = context.size;

          LowInstruction.runBlock(startup, instruction.position, context);

          while (context.status.status == LowMemoryStatus.running) {
            LowInstruction.runBlock(condition, instruction.position, context);
            if (!LowInteropHandler.truthful(
              context,
              instruction.position,
              context.pop(),
            )) break;

            final old = context.size;
            LowInstruction.runBlock(body, caller, context);
            while (context.size > old) {
              context.pop();
            }

            LowInstruction.runBlock(step, caller, context);
            while (context.size > old) {
              context.pop();
            }

            if (context.status.status == LowMemoryStatus.continued) {
              context.status.status = LowMemoryStatus.running;
            }
          }

          if (context.status.status == LowMemoryStatus.broke) {
            context.status.status = LowMemoryStatus.running;
          }

          while (context.size > old) {
            context.pop();
          }
          break;
        case LowInstructionType.foreachLoop:
          final val = context.pop();
          final top = context.size;
          final int argc = instruction.data[0];
          final List<LowInstruction> body = instruction.data[1];

          LowInteropHandler.iterate(context, instruction.position, val, (args) {
            final top = context.size;

            for (var i = 0; i < argc; i++) {
              if (i < args.length) {
                context.push(args[i]);
              } else {
                context.push(null);
              }
            }

            LowInstruction.runBlock(body, instruction.position, context);

            while (context.size > top) {
              context.pop();
            }
          });
          while (context.size > top) {
            context.pop();
          }
          break;
        case LowInstructionType.addNull:
          context.push(null);
          break;
        case LowInstructionType.addBuffer:
          final int n = instruction.data;
          var l = [];

          for (var i = 0; i < n; i++) {
            l.add(context.pop());
          }

          l = l.reversed.toList();

          context.push(Uint8List.fromList(l.whereType<int>().toList()));
          break;
        case LowInstructionType.addFunction:
          final int argc = instruction.data[0];
          final List<int> upvals = instruction.data[1];
          final List<List<LowInstruction>?> argt = instruction.data[2];
          final List<LowInstruction> body = instruction.data[3];

          final List upvalv = upvals.map(context.getAt).toList();
          final pos = instruction.position;

          context.push(
            (List args, LowContext context, LowTokenPosition caller) {
              final old = context.size;
              upvalv.forEach(context.push);
              final argv = [];
              for (var i = 0; i < argc; i++) {
                if (i < args.length) {
                  context.push(args[i]);
                  argv.add(args[i]);
                } else {
                  context.push(null);
                  argv.add(null);
                }
              }

              for (var i = 0; i < argc; i++) {
                if (argt[i] == null) continue;

                final old = context.size;

                LowInstruction.runBlock(argt[i]!, pos, context);
                if (!LowInteropHandler.matchesType(
                  context,
                  caller,
                  argv[i],
                  context.pop(),
                )) {
                  throw LowRuntimeError(
                    "Argument #${i + 1} does not match type expected by called function",
                    caller,
                    context.stackTrace,
                  );
                }

                while (context.size > old) {
                  context.pop();
                }
              }

              final ctx = context.lexicallyScopedCopy(copyStatus: true);

              LowInstruction.runBlock(body, caller, ctx);

              while (context.size > old) {
                context.pop();
              }
              return ctx.returnedValue;
            },
          );
          break;
        case LowInstructionType.pop:
          final int c = instruction.data;

          for (var i = 0; i < c; i++) {
            context.pop();
          }
          break;
        case LowInstructionType.writeField:
          final owner = context.pop();
          final value = context.pop();

          final String field = instruction.data;

          LowInteropHandler.writeField(
            context,
            instruction.position,
            owner,
            field,
            value,
          );

          break;
        case LowInstructionType.readField:
          final owner = context.pop();
          final String field = instruction.data;

          context.push(LowInteropHandler.readField(
            context,
            instruction.position,
            owner,
            field,
          ));
          break;
      }

      if (context.status.status == LowMemoryStatus.returned) {
        return context.returnedValue;
      }
      if (context.status.status != LowMemoryStatus.running) {
        break;
      }
    }

    return context.returnedValue;
  }
}
