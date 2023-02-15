import 'dart:io';
import 'package:low_lang/ast/ast.dart';
import 'package:low_lang/vm/context.dart';
import 'package:low_lang/vm/errors.dart';
import 'package:low_lang/vm/interop.dart';
import 'package:low_lang/vm/vm.dart';
import 'package:path/path.dart' as path;

enum LowIncludeMode {
  returned,
  globals,
}

class LowIncludeNode extends LowAST {
  LowAST value;
  String? identifier;
  LowIncludeMode mode;

  LowIncludeNode(this.value, this.mode, this.identifier, super.position);

  dynamic getLibrary(LowContext context) {
    var val = LowInteropHandler.convertToString(context, position, value.get(context));
    if (context.vm.libraries[val] != null) {
      return context.vm.libraries[val]?.call(context.vm);
    }

    if (Platform.isWindows) val = val.replaceAll('/', '\\');

    final f = File(path.isAbsolute(val) ? val : path.join(path.dirname(context.filePath), val));

    if (!f.existsSync()) throw LowRuntimeError("Included file path $val does not exist", position, context.stackTrace);

    return context.vm.runCode(f.readAsStringSync(), f.path);
  }

  @override
  rawget(LowContext context) {
    final lib = getLibrary(context);

    if (mode == LowIncludeMode.returned) {
      return lib;
    } else {
      if (identifier == null) {
        if (lib is LowObject) {
          lib.forEach(context.setGlobal);
        } else {
          throw LowRuntimeError("Unable to globalize included library, as it did not return an object", position, context.stackTrace);
        }
      } else {
        context.setGlobal(identifier!, lib);
      }
      return lib;
    }
  }

  @override
  void rawrun(LowContext context) {
    rawget(context);
  }

  @override
  void rawset(LowContext context, value) {
    rawget(context);
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) {
    return value.dependencies(toIgnore);
  }

  @override
  String? markForIgnorance() {
    return null;
  }
}
