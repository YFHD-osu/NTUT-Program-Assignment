import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:ntut_program_assignment/core/test_server.dart';

class LocalProblem {

  final String uuid;
  final List<String> problem;
  final DateTime createDate;
  final DateTime importDate;

  final List<Testcase> testCase;

  LocalProblem({
    required this.uuid,
    required this.problem,
    required this.createDate,
    required this.importDate,
    required this.testCase
  });

  factory LocalProblem.fromMap(Map res) {
    final now = DateTime.now();
    final problemContext = List<String>
      .from(res["problem"])
      .join()
      .codeUnits;

    final uuid = sha256.convert(problemContext + "${now.millisecondsSinceEpoch}".codeUnits);

    return LocalProblem(
      uuid: uuid.toString(),
      importDate: now,
      createDate: DateTime
        .fromMillisecondsSinceEpoch(res["createDate"]),
      problem: List<String>
        .from(res["problem"]),
      testCase: List<Map>
        .from(res["testCase"])
        .map((e) => Testcase.fromMap(e))
        .toList()

    );
  }

  Map<String, dynamic> toMap() {
    return {
      "createDate": createDate.millisecondsSinceEpoch,
      "problem": problem,
      "testCase": testCase
        .map((e) => e.toMap())
        .toList()
    };
  }
}