import 'package:low_lang/ast/ast.dart';
import 'package:low_lang/vm/context.dart';
import 'package:low_lang/vm/interop.dart';
import 'package:low_lang/vm/ir.dart';

class LowForNode extends LowAST {
  LowAST startup;
  LowAST condition;
  LowAST body;
  LowAST afterwards;

  LowForNode(
      this.startup, this.condition, this.body, this.afterwards, super.position);

  @override
  rawget(LowContext context) {
    rawrun(context);
  }

  @override
  void rawrun(LowContext context) {
    final ctx = context.lexicallyScopedCopy();

    startup.run(ctx);

    while (ctx.status.status == LowMemoryStatus.running) {
      if (!LowInteropHandler.truthful(ctx, position, condition.get(ctx))) break;
      body.run(ctx);
      afterwards.run(ctx);
      if (ctx.status.status == LowMemoryStatus.continued)
        ctx.status.status = LowMemoryStatus.running;
    }

    if (ctx.status.status == LowMemoryStatus.broke) {
      ctx.status.status = LowMemoryStatus.running;
    }
  }

  @override
  void rawset(LowContext context, value) {
    rawrun(context);
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) {
    final scoped = {...toIgnore};
    return {
      ...startup.handleDependencies(scoped),
      ...condition.dependencies(scoped),
      ...body.dependencies(scoped),
      ...afterwards.dependencies(scoped)
    };
  }

  @override
  String? markForIgnorance() => null;

  @override
  List<LowInstruction> compile(
      LowCompilerContext context, LowCompilationMode mode) {
    if (mode != LowCompilationMode.run) throw "Invalid AST";

    final ctx = context.copy();

    final startupIR = startup.compile(ctx, mode);
    final conditionIR = condition.compile(ctx.copy(), LowCompilationMode.data);
    final bodyIR = body.compile(ctx.copy(), mode);
    final stepIR = afterwards.compile(ctx.copy(), LowCompilationMode.run);

    return [
      LowInstruction(
        LowInstructionType.forLoop,
        [
          startupIR,
          conditionIR,
          stepIR,
          bodyIR,
        ],
        position,
      ),
    ];
  }
}

class LowWhileNode extends LowAST {
  LowAST condition;
  LowAST body;

  LowWhileNode(this.condition, this.body, super.position);

  @override
  rawget(LowContext context) {
    rawrun(context);
  }

  @override
  void rawrun(LowContext context) {
    final ctx = context.lexicallyScopedCopy();

    while (ctx.status.status == LowMemoryStatus.running) {
      if (!LowInteropHandler.truthful(ctx, position, condition.get(ctx))) break;
      body.run(ctx);
      if (ctx.status.status == LowMemoryStatus.continued) {
        ctx.status.status = LowMemoryStatus.running;
      }
    }

    if (ctx.status.status == LowMemoryStatus.broke) {
      ctx.status.status = LowMemoryStatus.running;
    }
  }

  @override
  void rawset(LowContext context, value) {
    rawrun(context);
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) {
    final scoped = {...toIgnore};
    return {...condition.dependencies(scoped), ...body.dependencies(scoped)};
  }

  @override
  String? markForIgnorance() => null;

  @override
  List<LowInstruction> compile(
      LowCompilerContext context, LowCompilationMode mode) {
    if (mode != LowCompilationMode.run) throw "Invalid AST";

    final checkIR = condition.compile(context.copy(), LowCompilationMode.data);
    final bodyIR = body.compile(context.copy(), LowCompilationMode.run);

    return [
      LowInstruction(LowInstructionType.whileLoop, [checkIR, bodyIR], position)
    ];
  }
}

class LowForeachNode extends LowAST {
  LowAST body;
  LowAST value;
  List<String> vars;

  LowForeachNode(this.vars, this.value, this.body, super.position);

  @override
  rawget(LowContext context) {
    rawrun(context);
  }

  @override
  void rawrun(LowContext context) {
    final ctx = context.lexicallyScopedCopy();

    LowInteropHandler.iterate(ctx, position, value.get(ctx), (args) {
      final c = ctx.lexicallyScopedCopy();
      for (var i = 0; i < vars.length; i++) {
        if (i >= args.length) {
          c.defineLocal(vars[i], null);
        } else {
          c.defineLocal(vars[i], args[i]);
        }
      }
      body.run(c);
    });
  }

  @override
  void rawset(LowContext context, value) {
    rawrun(context);
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) {
    final scoped = {...toIgnore};
    return {...body.dependencies(scoped), ...value.dependencies(scoped)};
  }

  @override
  String? markForIgnorance() => null;

  @override
  List<LowInstruction> compile(
      LowCompilerContext context, LowCompilationMode mode) {
    if (mode != LowCompilationMode.run) throw "Invalid AST";

    final ctx = context.copy();

    final inst = value.compile(ctx, LowCompilationMode.data);
    ctx.pop();
    final argc = vars.length;
    vars.forEach(ctx.define);
    final bodyIR = body.compile(ctx, mode);

    inst.add(LowInstruction(
        LowInstructionType.foreachLoop, [argc, bodyIR], position));
    return inst;
  }
}
