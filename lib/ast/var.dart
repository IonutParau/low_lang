import 'package:low_lang/ast/ast.dart';
import 'package:low_lang/vm/context.dart';

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
}
