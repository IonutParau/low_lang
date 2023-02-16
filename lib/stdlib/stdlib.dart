import 'dart:io';

import 'package:low_lang/vm/vm.dart';

export 'core_api.dart';
export 'math_api.dart';

typedef LowLibrary = dynamic Function(LowVM vm);

ProcessResult lowRunCommand(String cmd) {
  // TODO: Make it somehow handle stdout
  if (Platform.isWindows) {
    return Process.runSync(
      r"C:\Windows\System32\cmd.exe",
      ["/c", cmd],
      runInShell: true,
    );
  } else {
    return Process.runSync(
      "/bin/sh",
      ["sh", "-c", cmd],
      runInShell: true,
    );
  }
}
