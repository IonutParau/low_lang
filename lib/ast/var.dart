import 'package:low_lang/ast/ast.dart';
import 'package:low_lang/vm/context.dart';
import 'package:low_lang/vm/ir.dart';

class LowVariableNode extends LowAST {
  String name;

  LowVariableNode(this.name, super.position);

  @override
  rawget(LowContext context) {
    return context.get(name);
  }

  @override
  void rawrun(LowContext context) {
    return;
  }

  @override
  void rawset(LowContext context, value) {
    context.set(name, value);
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) {
    if (toIgnore.contains(name)) return {};
    return {name};
  }

  @override
  String? markForIgnorance() {
    return null;
  }

  @override
  List<LowInstruction> compile(LowCompilerContext context, LowCompilationMode mode) {
    if (mode == LowCompilationMode.run) return [];

    if (mode == LowCompilationMode.data) {
      final inst = context.isLocal(name)
          ? [
              LowInstruction(
                LowInstructionType.clone,
                context.stackIndex(name),
                position,
              ),
            ]
          : [
              LowInstruction(
                LowInstructionType.getGlobal,
                name,
                position,
              ),
            ];
      context.push();
      return inst;
    } else {
      final inst = context.isLocal(name)
          ? [
              LowInstruction(
                LowInstructionType.set,
                context.stackIndex(name),
                position,
              ),
            ]
          : [
              LowInstruction(
                LowInstructionType.setGlobal,
                name,
                position,
              ),
            ];
      context.push();
      return inst;
    }
  }
}
