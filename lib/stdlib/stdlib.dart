import 'dart:io';

import 'package:low_lang/vm/vm.dart';

export 'core_api.dart';
export 'math_api.dart';

typedef LowLibrary = dynamic Function(LowVM vm);

ProcessResult lowRunCommand(String cmd) {
  if (Platform.isWindows) {
    return Process.runSync(
      r"C:\Windows\System32\cmd.exe",
      ["/c", cmd],
      workingDirectory: Directory.current.path,
    );
  } else {
    return Process.runSync(
      "/bin/sh",
      ["-c", cmd],
      workingDirectory: Directory.current.path,
    );
  }
}
