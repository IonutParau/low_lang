// This file is just to experiment around with stuff in early development

import 'package:low_lang/low_lang.dart';

void main() {
  final vm = LowVM();
  vm.addExperimentalFlag("compiler"); // Enables experimental compiler to IR

  vm.loadLibraries();

  vm.runCode('''
var l = [50, 30, 20]

static D(v) {
  print(v)
  return v
}

for(var i = 0; i < D(l).length; i = i + 1) {
  var c = l[i]
}
''', 'test.low');
}
