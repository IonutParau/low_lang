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
  Map<String, dynamic> _extern = {};
  Map<String, LowVar> _locals = {};
  var status = LowCommonStatus(LowMemoryStatus.running);
  LowStackTrace stackTrace;
  LowVM vm;

  LowContext(this.stackTrace, this.vm);

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

  void setExtern(String name, dynamic val) {
    _extern[name] = val;
  }

  dynamic getExtern(String name) {
    return _extern[name];
  }

  void defineLocal(String name, dynamic val) {
    _locals[name] = LowVar(name, val);
  }

  dynamic readLocal(String name) => _locals[name]?.value;

  void setLocal(String name, value) => _locals[name]?.value = value;

  dynamic get(String name) {
    if (_locals.containsKey(name)) return readLocal(name);
    if (_globals.containsKey(name)) return getGlobal(name);
    if (_extern.containsKey(name)) return getExtern(name);
  }

  void set(String name, dynamic v) {
    if (_locals.containsKey(name)) return setLocal(name, v);
    if (_globals.containsKey(name)) return setGlobal(name, v);
    if (_extern.containsKey(name)) return setExtern(name, v);
    _globals[name] = v;
  }

  LowContext lexicallyScopedCopy({List<String>? onlyPassThrough, bool copyStatus = false}) {
    final lm = LowContext(stackTrace, vm);

    lm._extern = _extern;
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
}
