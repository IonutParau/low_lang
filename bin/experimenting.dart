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
      LowInstruction(LowInstructionType.addInt, 1, pos),
      LowInstruction(LowInstructionType.addInt, 2, pos),
      LowInstruction(LowInstructionType.addInt, 3, pos),
      LowInstruction(LowInstructionType.addInt, 4, pos),
      LowInstruction(LowInstructionType.addInt, 5, pos),
      LowInstruction(LowInstructionType.addList, 5, pos),
      LowInstruction(
        LowInstructionType.foreachLoop,
        [
          1,
          [
            LowInstruction(LowInstructionType.getGlobal, "print", pos),
            LowInstruction(LowInstructionType.clone, -2, pos),
            LowInstruction(LowInstructionType.call, [1, false], pos),
          ],
        ],
        pos,
      ),
    ],
    pos,
    context,
  );
}
