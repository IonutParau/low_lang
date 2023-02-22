import 'package:low_lang/ast/ast.dart';
import 'package:low_lang/parser/token.dart';
import 'package:low_lang/vm/context.dart';
import 'package:low_lang/vm/errors.dart';
import 'package:low_lang/vm/interop.dart';
import 'package:low_lang/vm/ir.dart';
import 'package:low_lang/vm/vm.dart';

class LowDefineVariable extends LowAST {
  String name;
  LowAST value;
  bool static;

  LowDefineVariable(this.name, this.value, this.static, super.position);

  @override
  rawget(LowContext context) {
    final val = value.get(context);
    static ? context.setGlobal(name, val) : context.defineLocal(name, val);
    return val;
  }

  @override
  void rawrun(LowContext context) {
    rawget(context);
  }

  @override
  void rawset(LowContext context, value) {
    throw "Can't set variable definition to a specific value";
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) {
    return value.dependencies(toIgnore);
  }

  @override
  String? markForIgnorance() {
    return static ? null : name;
  }

  @override
  List<LowInstruction> compile(
      LowCompilerContext context, LowCompilationMode mode) {
    if (mode != LowCompilationMode.run) {
      throw "Invalid AST";
    }

    if (static) {
      return [
        ...value.compile(context, LowCompilationMode.data),
        LowInstruction(LowInstructionType.setGlobal, name, position)
      ];
    }

    final inst = value.compile(context, LowCompilationMode.data);

    context.name(name);

    return inst;
  }
}

class LowDefineFunction extends LowAST {
  String name;
  List<String> params;
  List<LowAST?> types;
  LowAST? returnType;
  LowAST body;
  bool static;

  LowDefineFunction(this.name, this.static, this.body, this.params, this.types,
      this.returnType, super.position);

  @override
  rawget(LowContext context) {
    final val = createLowFunction(context, position, params, types, returnType,
        body, dependencies({}).toList());

    static ? context.setGlobal(name, val) : context.defineLocal(name, val);
    return val;
  }

  @override
  void rawrun(LowContext context) {
    rawget(context);
  }

  @override
  void rawset(LowContext context, value) {
    throw "Can't set function definition to a specific value";
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) {
    return {
      ...body.dependencies({...toIgnore, ...params}),
      ...types.fold<Set<String>>(
          {},
          (current, type) => current
            ..addAll(type?.dependencies({...toIgnore, ...params}) ?? {})),
      ...(returnType?.dependencies(toIgnore) ?? {}),
    };
  }

  @override
  String? markForIgnorance() {
    return static ? null : name;
  }

  @override
  List<LowInstruction> compile(
      LowCompilerContext context, LowCompilationMode mode) {
    if (mode != LowCompilationMode.run) throw "Invalid AST";
    final ctx = LowCompilerContext();

    final dep = dependencies({});
    dep.where(context.isLocal).forEach(ctx.define);
    final argc = params.length;
    for (var i = 0; i < argc; i++) {
      ctx.define(params[i]);
    }
    final List<List<LowInstruction>> argt = types.map((type) {
      if (type == null) {
        return [
          LowInstruction(LowInstructionType.addBool, true, position),
        ];
      }

      return type.compile(ctx.copy(), LowCompilationMode.data);
    }).toList();
    final upvals = dep.where(ctx.isLocal).map(ctx.stackIndex).toList();

    final inst = [
      LowInstruction(
        LowInstructionType.addFunction,
        [argc, upvals, argt, body.compile(ctx, LowCompilationMode.run)],
        position,
      ),
      if (static) LowInstruction(LowInstructionType.setGlobal, name, position),
    ];
    if (!static) context.define(name);
    return inst;
  }
}

LowFunction createLowFunction(
    LowContext oldCtx,
    LowTokenPosition position,
    List<String> params,
    List<LowAST?> types,
    LowAST? returnType,
    LowAST body,
    List<String> dependencies) {
  return (List args, LowContext context, LowTokenPosition callerPosition) {
    final context = oldCtx.lexicallyScopedCopy(
        copyStatus: true, onlyPassThrough: dependencies);

    for (var i = 0; i < params.length; i++) {
      final param = params[i];
      final val = i < args.length ? args[i] : null;
      context.defineLocal(param, val);
    }

    for (var i = 0; i < params.length; i++) {
      final typeAST = types[i];
      final val = i < args.length ? args[i] : null;

      if (typeAST != null &&
          !LowInteropHandler.matchesType(
              context, position, val, typeAST.get(context))) {
        throw LowRuntimeError(
          "Argument #${i + 1} does not match type expected by called function",
          callerPosition,
          context.stackTrace,
        );
      }
    }

    body.run(context);

    final rv = context.returnedValue;

    if (returnType != null) {
      if (!LowInteropHandler.matchesType(
          context, position, rv, returnType.get(context)))
        throw LowRuntimeError(
            "Return Value of function is not what was expected",
            position,
            context.stackTrace);
    }

    return rv;
  };
}
