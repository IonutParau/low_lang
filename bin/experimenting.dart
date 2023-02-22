// This file is just to experiment around with stuff in early development

import 'package:low_lang/low_lang.dart';

void main() {
  final vm = LowVM();
  vm.addExperimentalFlag("compiler"); // Enables experimental compiler to IR

  vm.loadLibraries();

  vm.runCode('''
foreach(element, index in [5, 30, 2]) {
  print([element, index])
}
''', 'test.low');
}
