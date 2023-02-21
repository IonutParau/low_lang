// This file is just to experiment around with stuff in early development

import 'package:low_lang/low_lang.dart';
import 'package:low_lang/parser/token.dart';
import 'package:low_lang/vm/ir.dart';

void main() {
  final pos = LowTokenPosition("experiment.low", 1, 1);

  final vm = LowVM()..loadLibraries();

  final context = vm.context;

  LowInstruction.runBlock(
    [
      LowInstruction(LowInstructionType.getGlobal, "print", pos),
      LowInstruction(LowInstructionType.addString, "Hello, world!", pos),
      LowInstruction(LowInstructionType.call, [1, false], pos),
    ],
    pos,
    context,
  );
}