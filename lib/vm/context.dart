import 'package:low_lang/vm/stack_trace.dart';
import 'package:low_lang/vm/vm.dart';

enum LowMemoryStatus {
  running,
  returned,
  broke,
  continued,
}

class LowVar {
  String name;
  dynamic value;

  LowVar(this.name, this.value);
}

class LowCommonStatus {
  LowMemoryStatus status;
  dynamic returned;

  LowCommonStatus(this.status);
}

class LowContext {
  Map<String, dynamic> _globals = {};
  Map<String, LowVar> _locals = {};
  List _stack = [];
  var status = LowCommonStatus(LowMemoryStatus.running);
  LowStackTrace stackTrace;
  LowVM vm;
  String filePath;

  LowContext(this.stackTrace, this.vm, this.filePath);

  void returnValue(dynamic value) {
    status.status = LowMemoryStatus.returned;
    status.returned = value;
  }

  void breakLoop() {
    status.status = LowMemoryStatus.broke;
  }

  void skipLoop() {
    status.status = LowMemoryStatus.continued;
  }

  dynamic get returnedValue => status.returned;

  void setGlobal(String name, dynamic val) {
    _globals[name] = val;
  }

  dynamic getGlobal(String name) {
    return _globals[name];
  }

  void defineLocal(String name, dynamic val) {
    _locals[name] = LowVar(name, val);
  }

  dynamic readLocal(String name) => _locals[name]?.value;

  void setLocal(String name, value) => _locals[name]?.value = value;

  dynamic get(String name) {
    if (_locals.containsKey(name)) return readLocal(name);
    if (_globals.containsKey(name)) return getGlobal(name);
  }

  void set(String name, dynamic v) {
    if (_locals.containsKey(name)) return setLocal(name, v);
    if (_globals.containsKey(name)) return setGlobal(name, v);
    _globals[name] = v;
  }

  LowContext lexicallyScopedCopy({List<String>? onlyPassThrough, bool copyStatus = false, String? filePath}) {
    final lm = LowContext(stackTrace, vm, filePath ?? this.filePath);

    lm._stack = [..._stack];
    lm._globals = _globals;
    if (onlyPassThrough == null) {
      lm._locals = {..._locals};
    } else {
      for (var name in onlyPassThrough) {
        if (_locals.containsKey(name)) lm._locals[name] = _locals[name]!;
      }
    }
    lm.status = status;
    if (copyStatus) {
      lm.status = LowCommonStatus(status.status);
      lm.status.returned = status.returned;
    }

    return lm;
  }

  void push(dynamic value) => _stack.add(value);
  dynamic pop() => _stack.removeLast();
  dynamic remove(int i) {
    if (_stack.isEmpty) return;
    return _stack.removeAt(i % _stack.length);
  }

  dynamic getAt(int i) {
    if (_stack.isEmpty) return;
    return _stack[i % _stack.length];
  }

  void setAt(int i, dynamic value) {
    if (_stack.isEmpty) return;
    _stack[i % _stack.length] = value;
  }
}

// TODO: Implement a compiler to some form of IR or bytecode
class LowCompilerContext {
  List<String> _stackMirror = [];

  void push() => _stackMirror.add("");
  void define(String name) => _stackMirror.add(name);
  void name(String name) => _stackMirror.last = name;
  bool isLocal(String name) => _stackMirror.contains(name);
  int stackIndex(String name) => _stackMirror.indexOf(name) - _stackMirror.length;

  LowCompilerContext linkedCopy([List<String>? startingLocals]) {
    final copy = LowCompilerContext();

    copy._stackMirror = startingLocals == null ? [..._stackMirror] : [...startingLocals];

    return copy;
  }
}
