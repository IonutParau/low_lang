import 'package:low_lang/parser/token.dart';
import 'package:low_lang/vm/context.dart';
import 'package:low_lang/vm/errors.dart';

abstract class LowAST {
  final LowTokenPosition position;

  LowAST(this.position);

  String? markForIgnorance();
  Set<String> dependencies(Set<String> toIgnore);

  void rawrun(LowContext context);
  dynamic rawget(LowContext context);
  void rawset(LowContext context, dynamic value);

  Set<String> handleDependencies(Set<String> toIgnore) {
    final ig = markForIgnorance();
    final dep = dependencies(toIgnore);
    if (ig != null) toIgnore.add(ig);
    return dep;
  }

  void run(LowContext context) {
    try {
      rawrun(context);
    } catch (e) {
      if (e is! LowRuntimeError) {
        throw LowRuntimeError(e.toString(), position, context.stackTrace);
      } else {
        rethrow;
      }
    }
  }

  dynamic get(LowContext context) {
    try {
      return rawget(context);
    } catch (e) {
      if (e is! LowRuntimeError) {
        throw LowRuntimeError(e.toString(), position, context.stackTrace);
      } else {
        rethrow;
      }
    }
  }

  void set(LowContext context, dynamic value) {
    try {
      rawset(context, value);
    } catch (e) {
      if (e is! LowRuntimeError) {
        throw LowRuntimeError(e.toString(), position, context.stackTrace);
      } else {
        rethrow;
      }
    }
  }
}
