import 'dart:math';

import 'package:ntut_program_assignment/core/test_server.dart';

class Utils {
  static var rng = Random();

  static const String legalHead = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  static const String legalBody = "${legalHead}0123456789";

  static String _randVarName(int length) {
    String result = "";

    int index = rng.nextInt(legalHead.length);
    result += legalHead[index];

    length--;

    while (length > 0) {
      index = rng.nextInt(legalHead.length);
      result += legalBody[index];
      length--;
    }

    return result;
  }

  static List<String> generateTrashCode(CodeType type, {int? lines}) {
    lines ??= rng.nextInt(20) + 80;

    switch (type) {
      case CodeType.c:
        return _genCodeC(lines);

      case CodeType.python:
        throw UnimplementedError();
    }
  }

  static List<String> _genCodeC(int lines) {
    final List<String> result = [];

    final List<String> varName = [];

    int index = 0;

    while (index < lines) {
      String newName = _randVarName(16);

      if (varName.contains(newName)) {
        continue;
      }
      
      varName.add(newName);

      index++;
    }

    index = 1;

    final randInt = rng.nextInt(1000);

    result.add("int ${varName.first} = $randInt;");
    
    while (index < lines) {
      result.add(
        "int ${'*'*index}${varName[index]} = &${varName[index-1]};"
      );
      index++;
    }

    return result;
  }
}