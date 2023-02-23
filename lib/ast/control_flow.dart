import 'package:low_lang/ast/ast.dart';
import 'package:low_lang/ast/literals.dart';
import 'package:low_lang/vm/context.dart';
import 'package:low_lang/vm/interop.dart';
import 'package:low_lang/vm/ir.dart';

class LowReturnNode extends LowAST {
  LowAST value;

  LowReturnNode(this.value, super.position);

  @override
  rawget(LowContext context) {
    return;
  }

  @override
  void rawrun(LowContext context) {
    final v = value.get(context);
    context.returnValue(v);
  }

  @override
  void rawset(LowContext context, value) {
    return;
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) {
    return value.dependencies(toIgnore);
  }

  @override
  String? markForIgnorance() {
    return null;
  }

  @override
  List<LowInstruction> compile(
      LowCompilerContext context, LowCompilationMode mode) {
    if (mode != LowCompilationMode.run) throw "Invalid AST";

    final v = value.compile(context, LowCompilationMode.data);
    context.pop();

    return [
      ...v,
      LowInstruction(LowInstructionType.returnValue, null, position)
    ];
  }
}

class LowIfNode extends LowAST {
  LowAST condition;
  LowAST body;
  LowAST? fallback;

  LowIfNode(this.condition, this.body, this.fallback, super.position);

  @override
  rawget(LowContext context) {
    return;
  }

  @override
  void rawrun(LowContext context) {
    final shouldRun =
        LowInteropHandler.truthful(context, position, condition.get(context));

    if (shouldRun) {
      body.rawrun(context);
    } else {
      fallback?.rawrun(context);
    }
  }

  @override
  void rawset(LowContext context, value) {
    return;
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) {
    return {
      ...condition.dependencies(toIgnore),
      ...body.dependencies(toIgnore),
      if (fallback != null) ...fallback!.dependencies(toIgnore),
    };
  }

  @override
  String? markForIgnorance() {
    return null;
  }

  @override
  List<LowInstruction> compile(
      LowCompilerContext context, LowCompilationMode mode) {
    if (mode != LowCompilationMode.run) throw "Invalid AST";
    final inst = [...condition.compile(context, LowCompilationMode.data)];
    context.pop();
    inst.add(LowInstruction(
        LowInstructionType.ifCheck,
        [
          body.compile(context.copy(), LowCompilationMode.run),
          fallback?.compile(context.copy(), LowCompilationMode.run)
        ],
        position));

    return inst;
  }
}

class LowContinueNode extends LowAST {
  LowContinueNode(super.position);

  @override
  rawget(LowContext context) {
    return;
  }

  @override
  void rawrun(LowContext context) {
    context.skipLoop();
  }

  @override
  void rawset(LowContext context, value) {
    return;
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) {
    return {};
  }

  @override
  String? markForIgnorance() {
    return null;
  }

  @override
  List<LowInstruction> compile(
      LowCompilerContext context, LowCompilationMode mode) {
    if (mode != LowCompilationMode.run) throw "Invalid AST";

    return [LowInstruction(LowInstructionType.skipLoop, null, position)];
  }
}

class LowBreakNode extends LowAST {
  LowBreakNode(super.position);

  @override
  rawget(LowContext context) {
    return;
  }

  @override
  void rawrun(LowContext context) {
    context.breakLoop();
  }

  @override
  void rawset(LowContext context, value) {
    return;
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) {
    return {};
  }

  @override
  String? markForIgnorance() {
    return null;
  }

  @override
  List<LowInstruction> compile(
      LowCompilerContext context, LowCompilationMode mode) {
    if (mode != LowCompilationMode.run) throw "Invalid AST";

    return [LowInstruction(LowInstructionType.breakLoop, null, position)];
  }
}
