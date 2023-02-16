import 'dart:io';
import 'dart:typed_data';

import 'package:low_lang/parser/token.dart';
import 'package:low_lang/vm/context.dart';
import 'package:low_lang/vm/errors.dart';
import 'package:low_lang/vm/interop.dart';
import 'package:low_lang/vm/vm.dart';

LowObject lowFileSysAPI(LowVM vm) {
  return {
    "read": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      var path = LowInteropHandler.convertToString(context, position, args[0]);
      if (Platform.isWindows) {
        path = path.split("/").join("\\");
      }

      final f = File(path);
      if (!f.existsSync()) return null;
      if (f.statSync().type == FileSystemEntityType.directory) {
        return null;
      }

      return f.readAsStringSync();
    },
    "readBytes": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      var path = LowInteropHandler.convertToString(context, position, args[0]);
      if (Platform.isWindows) {
        path = path.split("/").join("\\");
      }

      final f = File(path);
      if (!f.existsSync()) return null;
      if (f.statSync().type == FileSystemEntityType.directory) {
        return null;
      }

      return f.readAsBytesSync();
    },
    "write": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 2);

      var path = LowInteropHandler.convertToString(context, position, args[0]);
      final content = LowInteropHandler.convertToString(
        context,
        position,
        args[1],
      );
      if (Platform.isWindows) {
        path = path.split("/").join("\\");
      }

      final f = File(path);
      if (f.statSync().type == FileSystemEntityType.directory) {
        return;
      }

      f.writeAsStringSync(content, flush: true);
    },
    "writeBytes": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 2);

      var path = LowInteropHandler.convertToString(context, position, args[0]);
      final content = args[1];

      if (content is! Uint8List) {
        throw LowRuntimeError(
          "fs.writeBytes(path, bytes) expects bytes to be a buffer",
          position,
          context.stackTrace,
        );
      }

      if (Platform.isWindows) {
        path = path.split("/").join("\\");
      }

      final f = File(path);
      if (f.statSync().type == FileSystemEntityType.directory) {
        return;
      }

      f.writeAsBytesSync(content, flush: true);
    },
    "append": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 2);

      var path = LowInteropHandler.convertToString(context, position, args[0]);
      final content = LowInteropHandler.convertToString(
        context,
        position,
        args[1],
      );
      if (Platform.isWindows) {
        path = path.split("/").join("\\");
      }

      final f = File(path);
      if (!f.existsSync()) f.createSync();
      if (f.statSync().type == FileSystemEntityType.directory) {
        return;
      }

      f.writeAsStringSync(content, mode: FileMode.append, flush: true);
    },
    "appendBytes": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 2);

      var path = LowInteropHandler.convertToString(context, position, args[0]);
      final content = args[1];

      if (content is! Uint8List) {
        throw LowRuntimeError(
          "fs.appendBytes(path, bytes) expects bytes to be a buffer",
          position,
          context.stackTrace,
        );
      }

      if (Platform.isWindows) {
        path = path.split("/").join("\\");
      }

      final f = File(path);
      if (!f.existsSync()) f.createSync();
      if (f.statSync().type == FileSystemEntityType.directory) {
        return;
      }

      f.writeAsBytesSync(content, mode: FileMode.append, flush: true);
    },
    "list": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      var path = LowInteropHandler.convertToString(context, position, args[0]);

      if (Platform.isWindows) {
        path = path.split("/").join("\\");
      }

      final f = Directory(path);
      if (!f.existsSync()) return null;
      if (f.statSync().type != FileSystemEntityType.directory) {
        return null;
      }

      return f
          .listSync()
          .map(
            (e) => Platform.isWindows ? e.path.split('\\').join('/') : e.path,
          )
          .toList();
    },
    "listRecursive": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      var path = LowInteropHandler.convertToString(context, position, args[0]);

      if (Platform.isWindows) {
        path = path.split("/").join("\\");
      }

      final f = Directory(path);
      if (!f.existsSync()) return null;
      if (f.statSync().type != FileSystemEntityType.directory) {
        return null;
      }

      return f
          .listSync(recursive: true)
          .map(
            (e) => Platform.isWindows ? e.path.split('\\').join('/') : e.path,
          )
          .toList();
    },
    "isFile": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      var path = LowInteropHandler.convertToString(context, position, args[0]);

      if (Platform.isWindows) {
        path = path.split("/").join("\\");
      }

      final f = File(path);
      if (!f.existsSync()) return null;
      return f.statSync().type != FileSystemEntityType.directory;
    },
    "isDirectory": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      var path = LowInteropHandler.convertToString(context, position, args[0]);

      if (Platform.isWindows) {
        path = path.split("/").join("\\");
      }

      final f = File(path);
      if (!f.existsSync()) return null;
      return f.statSync().type == FileSystemEntityType.directory;
    },
    "makeDirectory": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      var path = LowInteropHandler.convertToString(context, position, args[0]);

      if (Platform.isWindows) {
        path = path.split("/").join("\\");
      }

      Directory(path).createSync();
    },
    "delete": (List args, LowContext context, LowTokenPosition position) {
      minArgLength(args, 1);

      var path = LowInteropHandler.convertToString(context, position, args[0]);

      if (Platform.isWindows) {
        path = path.split("/").join("\\");
      }

      File(path).deleteSync();
    },
  };
}
