import 'package:low_lang/ast/ast.dart';
import 'package:low_lang/parser/token.dart';
import 'package:low_lang/vm/context.dart';
import 'package:low_lang/vm/interop.dart';

class LowCallValue extends LowAST {
  LowAST value;
  List<LowAST> params;

  LowCallValue(this.value, this.params, super.position);

  @override
  rawget(LowContext context) {
    final fn = value.get(context);
    final List args = params.map((e) => e.get(context)).toList();
    return lowHandleCall(fn, args, position, context);
  }

  @override
  void rawrun(LowContext context) {
    rawget(context);
  }

  @override
  void rawset(LowContext context, value) {
    throw "Can't set result of call to a value";
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) {
    return [value, ...params].fold({}, (curr, ast) => curr..addAll(ast.dependencies(toIgnore)));
  }

  @override
  String? markForIgnorance() {
    return null;
  }
}

dynamic lowHandleCall(dynamic fn, List args, LowTokenPosition position, LowContext context) {
  context.stackTrace.push(position);
  final returned = LowInteropHandler.invoke(context, position, fn, args);
  context.stackTrace.pop();
  return returned;
}
