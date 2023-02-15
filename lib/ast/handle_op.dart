import 'package:low_lang/ast/call.dart';
import 'package:low_lang/ast/var.dart';
import 'package:low_lang/vm/context.dart';
import 'package:low_lang/vm/interop.dart';

import 'ast.dart';

class LowHandleOp extends LowAST {
  LowAST left;
  List<LowAST> params;
  String opcode;

  LowHandleOp(this.opcode, this.left, this.params, super.position);

  @override
  rawget(LowContext context) {
    if (opcode == "is") {
      final v = left.get(context);
      final t = params.first.get(context);

      return LowInteropHandler.matchesType(context, position, v, t);
    }
    if (opcode == "isnt") {
      final v = left.get(context);
      final t = params.first.get(context);

      return !LowInteropHandler.matchesType(context, position, v, t);
    }
    if (opcode == "->") {
      final v = left.get(context);
      final l = params.first;

      if (l is LowCallValue) {
        final fn = l.value.get(context);
        final args = l.params.map((v) => v.get(context)).toList();
        return lowHandleCall(fn, [v, ...args], position, context);
      } else {
        return lowHandleCall(l.get(context), [v], position, context);
      }
    }
    if (opcode == ".") {
      final v = left.get(context);
      final fieldToken = params.first as LowVariableNode;

      return LowInteropHandler.readField(context, position, v, fieldToken.name);
    }
    if (opcode == "=") {
      final v = params.first.get(context);
      left.set(context, v);
      return v;
    }
    final v = left.get(context);
    final args = params.map((ast) => ast.get(context)).toList();
    if (opcode == "<=") {
      final less = LowInteropHandler.handleOperator(context, position, v, "<", args);
      if (LowInteropHandler.truthful(context, position, less)) return true;
      return LowInteropHandler.handleOperator(context, position, v, "==", args);
    }
    if (opcode == ">=") {
      final less = LowInteropHandler.handleOperator(context, position, v, ">", args);
      if (LowInteropHandler.truthful(context, position, less)) return true;
      return LowInteropHandler.handleOperator(context, position, v, "==", args);
    }
    if (opcode == "!=") {
      return !LowInteropHandler.truthful(context, position, LowInteropHandler.handleOperator(context, position, v, "==", args));
    }
    if (opcode == "&&") {
      if (!LowInteropHandler.truthful(context, position, v)) return false;
      return LowInteropHandler.truthful(context, position, args.first);
    }
    if (opcode == "||") {
      if (LowInteropHandler.truthful(context, position, v)) return true;
      return LowInteropHandler.truthful(context, position, args.first);
    }

    return LowInteropHandler.handleOperator(context, position, left.get(context), opcode, args);
  }

  @override
  void rawrun(LowContext context) {
    rawget(context);
  }

  @override
  void rawset(LowContext context, value) {
    if (opcode == "[]") {
      LowInteropHandler.handleOperator(context, position, left.get(context), "[]=", [...params.map((p) => p.get(context)), value]);
      return;
    }
    throw UnsupportedError("You can not set the result of $opcode to a value");
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) {
    return {...left.dependencies(toIgnore), ...params.fold<Set<String>>(<String>{}, (current, param) => current..addAll(param.dependencies(toIgnore)))};
  }

  @override
  String? markForIgnorance() {
    return null;
  }
}
