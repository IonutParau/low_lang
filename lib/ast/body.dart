import 'package:low_lang/ast/ast.dart';
import 'package:low_lang/vm/context.dart';

class LowCodeBody extends LowAST {
  List<LowAST> body;

  LowCodeBody(this.body, super.position);

  @override
  rawget(LowContext context) {
    throw "Can't read a function body";
  }

  @override
  void rawrun(LowContext context) {
    final ctx = context.lexicallyScopedCopy();

    for (var node in body) {
      node.rawrun(ctx);

      if (ctx.status.status != LowMemoryStatus.running) break;
    }
  }

  @override
  void rawset(LowContext context, value) {
    throw "Can't set a function body result to a value";
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) {
    final scoped = {...toIgnore};
    return body.fold({}, (current, node) => current..addAll(node.handleDependencies(scoped)));
  }

  @override
  String? markForIgnorance() {
    return null;
  }
}
