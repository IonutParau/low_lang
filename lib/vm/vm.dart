import 'package:low_lang/parser/parser.dart';
import 'package:low_lang/parser/token.dart';
import 'package:low_lang/stdlib/fs_api.dart';
import 'package:low_lang/vm/stack_trace.dart';
import 'package:low_lang/stdlib/stdlib.dart';

import 'context.dart';

typedef LowObject = Map<String, dynamic>;

typedef LowFunction = dynamic Function(
    List args, LowContext context, LowTokenPosition callerPosition);

void minArgLength(List args, int min) {
  while (args.length < min) {
    args.add(null);
  }
}

class LowVM {
  late LowContext _rootContext;
  final _parser = LowParser();
  final Map<String, LowLibrary> libraries = {};

  LowVM() {
    _init();
  }

  void _init() {
    _rootContext = LowContext(LowStackTrace(), this, "");
    _rootContext.setGlobal("EXEC", null);
    _rootContext.setGlobal("ARGS", []);
  }

  LowContext get context => _rootContext;

  dynamic runCode(String code, String filename) {
    final parsed = _parser.parseCode(code, filename);
    final context = _rootContext.lexicallyScopedCopy(filePath: filename);

    parsed.run(context);

    return context.returnedValue;
  }

  void defineGlobal(String name, dynamic value) {
    _rootContext.setGlobal(name, value);
  }

  void defineFunction(String name, LowFunction function) {
    _rootContext.setGlobal(name, function);
  }

  void defineLibrary(String name, LowLibrary library) {
    libraries[name] = library;
  }

  void loadLibraries() {
    // Define libraries
    defineLibrary("low:core", lowCoreAPI);
    defineLibrary("low:math", lowMathAPI);
    defineLibrary("low:fs", lowFileSysAPI);

    // Load core
    lowCoreAPI(this).forEach(defineGlobal);
    defineGlobal("fs", lowFileSysAPI(this));
  }
}
