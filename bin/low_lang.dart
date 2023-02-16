import 'dart:io';

import 'package:low_lang/low_lang.dart';
import 'package:low_lang/vm/errors.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print("Usage: ${Platform.executable} (path) <args>");
    return;
  }

  final f = File(arguments.first);

  if (f.path == "__repl__") {
    final vm = LowVM();

    vm.loadLibraries();

    vm.defineGlobal("EXEC", Platform.executable);
    vm.defineGlobal("ARGS", arguments.sublist(1));

    while (true) {
      stdout.write("Low REPL > ");
      final line = stdin.readLineSync();

      if (line == null) return;

      vm.runCode(line, "repl");
    }
  }

  if (!f.existsSync()) {
    print("File ${f.path} does not exist.");
    return;
  }

  final vm = LowVM();

  vm.loadLibraries();

  vm.defineGlobal("EXEC", Platform.executable);
  vm.defineGlobal("ARGS", arguments.sublist(1));

  try {
    vm.runCode(f.readAsStringSync(), f.path);
  } catch (e) {
    if (e is LowRuntimeError || e is LowParsingFailure) {
      print(e);
      return;
    }
    rethrow;
  }
}
