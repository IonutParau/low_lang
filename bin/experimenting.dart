// This file is just to experiment around with stuff in early development

import 'package:low_lang/low_lang.dart';

void main() {
  final vm = LowVM();
  vm.addExperimentalFlag("compiler"); // Enables experimental compiler to IR

  vm.loadLibraries();

  vm.runCode('''
fn F(x, y, z) {
  print(x)
  print(y)
  print(z)
}
F(50, 20, 10)
''', 'test.low');
}
