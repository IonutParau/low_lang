import 'dart:typed_data';

import 'package:low_lang/ast/ast.dart';
import 'package:low_lang/ast/define.dart';
import 'package:low_lang/vm/context.dart';
import 'package:low_lang/vm/interop.dart';

class LowIntegerNode extends LowAST {
  int i;

  LowIntegerNode(this.i, super.position);

  @override
  rawget(LowContext context) {
    return i;
  }

  @override
  void rawrun(LowContext context) {}

  @override
  void rawset(LowContext context, value) {}

  @override
  Set<String> dependencies(Set<String> toIgnore) => {};
  @override
  String? markForIgnorance() => null;
}

class LowDoubleNode extends LowAST {
  double d;

  LowDoubleNode(this.d, super.position);

  @override
  rawget(LowContext context) {
    return d;
  }

  @override
  void rawrun(LowContext context) {}

  @override
  void rawset(LowContext context, value) {}

  @override
  Set<String> dependencies(Set<String> toIgnore) => {};
  @override
  String? markForIgnorance() => null;
}

class LowBoolNode extends LowAST {
  bool b;

  LowBoolNode(this.b, super.position);

  @override
  rawget(LowContext context) {
    return b;
  }

  @override
  void rawrun(LowContext context) {
    return;
  }

  @override
  void rawset(LowContext context, value) {
    return;
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) => {};
  @override
  String? markForIgnorance() => null;
}

class LowStringNode extends LowAST {
  String str;

  LowStringNode(this.str, super.position);

  @override
  rawget(LowContext context) {
    return str;
  }

  @override
  void rawrun(LowContext context) {}

  @override
  void rawset(LowContext context, value) {}

  @override
  Set<String> dependencies(Set<String> toIgnore) => {};
  @override
  String? markForIgnorance() => null;
}

class LowLambdaFunction extends LowAST {
  List<String> params;
  List<LowAST?> types;
  LowAST? returnType;
  LowAST body;

  LowLambdaFunction(this.body, this.params, this.types, this.returnType, super.position);

  @override
  rawget(LowContext context) {
    return createLowFunction(context, position, params, types, returnType, body, dependencies({}).toList());
  }

  @override
  void rawrun(LowContext context) {
    return;
  }

  @override
  void rawset(LowContext context, value) {
    throw "Can't set function definition to a specific value";
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) => {
        ...body.dependencies({...toIgnore, ...params}),
        ...types.fold<Set<String>>({}, (current, type) => current..addAll(type?.dependencies({...toIgnore, ...params}) ?? {})),
        ...(returnType?.dependencies(toIgnore) ?? {}),
      };
  @override
  String? markForIgnorance() => null;
}

class LowListNode extends LowAST {
  List<LowAST> subnodes;

  LowListNode(this.subnodes, super.position);

  @override
  rawget(LowContext context) {
    return subnodes.map((subnode) => subnode.get(context)).toList();
  }

  @override
  void rawrun(LowContext context) {
    return;
  }

  @override
  void rawset(LowContext context, value) {
    return;
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) => subnodes.fold({}, (curr, node) => curr..addAll(node.dependencies(toIgnore)));
  @override
  String? markForIgnorance() => null;
}

class LowBufferNode extends LowAST {
  List<LowAST> subnodes;

  LowBufferNode(this.subnodes, super.position);

  @override
  rawget(LowContext context) {
    final List l = subnodes.map((subnode) => subnode.get(context)).toList();

    for (var i = 0; i < l.length; i++) {
      if (l[i] is! int) {
        throw "Buffer element MUST be an integer in order to be converted to a byte. The wrong type was ${LowInteropHandler.typeNameOf(context, position, l[i])} and defined in ${subnodes[i].position}";
      }
    }

    return Uint8List.fromList(l.whereType<int>().toList());
  }

  @override
  void rawrun(LowContext context) {
    return;
  }

  @override
  void rawset(LowContext context, value) {
    return;
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) => subnodes.fold({}, (curr, node) => curr..addAll(node.dependencies(toIgnore)));
  @override
  String? markForIgnorance() => null;
}

class LowMapNode extends LowAST {
  Map<LowAST, LowAST> map;

  LowMapNode(this.map, super.position);

  @override
  rawget(LowContext context) {
    final Map m = {};

    map.forEach((key, value) {
      m[key.get(context)] = value.get(context);
    });

    return m;
  }

  @override
  void rawrun(LowContext context) {
    return;
  }

  @override
  void rawset(LowContext context, value) {
    return;
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) => [...map.keys, ...map.values].fold({}, (curr, ast) => curr..addAll(ast.dependencies(toIgnore)));
  @override
  String? markForIgnorance() => null;
}

class LowObjectNode extends LowAST {
  Map<String, LowAST> obj;

  LowObjectNode(this.obj, super.position);

  @override
  rawget(LowContext context) {
    final Map<String, dynamic> o = {};

    obj.forEach((key, value) {
      o[key] = value.get(context);
    });

    return o;
  }

  @override
  void rawrun(LowContext context) {
    return;
  }

  @override
  void rawset(LowContext context, value) {
    return;
  }

  @override
  Set<String> dependencies(Set<String> toIgnore) => obj.values.fold({}, (curr, ast) => curr..addAll(ast.dependencies(toIgnore)));
  @override
  String? markForIgnorance() => null;
}

class LowNullNode extends LowAST {
  LowNullNode(super.position);

  @override
  rawget(LowContext context) {
    return null;
  }

  @override
  void rawrun(LowContext context) {}

  @override
  void rawset(LowContext context, value) {}

  @override
  Set<String> dependencies(Set<String> toIgnore) => {};
  @override
  String? markForIgnorance() => null;
}
