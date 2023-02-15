import 'package:low_lang/ast/ast.dart';
import 'package:low_lang/vm/context.dart';
import 'package:low_lang/vm/interop.dart';

class LowForNode extends LowAST {
  LowAST startup;
  LowAST condition;
  LowAST body;
  LowAST afterwards;

  LowForNode(this.startup, this.condition, this.body, this.afterwards, super.position);

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
      if (ctx.status.status == LowMemoryStatus.continued) ctx.status.status = LowMemoryStatus.running;
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
    return {...startup.handleDependencies(scoped), ...condition.dependencies(scoped), ...body.dependencies(scoped), ...afterwards.dependencies(scoped)};
  }

  @override
  String? markForIgnorance() => null;
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
      if (ctx.status.status == LowMemoryStatus.continued) ctx.status.status = LowMemoryStatus.running;
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
}
