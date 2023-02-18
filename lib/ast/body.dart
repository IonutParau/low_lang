import 'package:low_lang/ast/ast.dart';
import 'package:low_lang/ast/control_flow.dart';
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
    final d = <String>{};

    for (final node in body) {
      d.addAll(node.handleDependencies(scoped));

      // In all of these, the block would always end there, thus anything after that is not a dependency.
      if (node is LowContinueNode || node is LowBreakNode || node is LowReturnNode) {
        break;
      }

      // Bodies might also house these, so we need to check for that
      if (node is LowCodeBody && node.alwaysEnd()) {
        break;
      }
    }

    return d;
  }

  bool alwaysEnd() {
    for (final node in body) {
      // In all of these, the block would always end there, thus anything after that is not a dependency.
      if (node is LowContinueNode || node is LowBreakNode || node is LowReturnNode) {
        return true;
      }
    }

    return false;
  }

  @override
  String? markForIgnorance() {
    return null;
  }
}
