import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import 'package:ntut_program_assignment/main.dart' show logger;
import 'package:ntut_program_assignment/core/test_server.dart';

class LocalProblem {
  final String uuid;
  final String title;
  final List<String> problem;
  final DateTime createDate;
  final DateTime importDate;

  final List<String> collections;

  final Testcase testCase;

  final List<String>? sampleCode;

  final CodeType codeType;

  LocalProblem({
    required this.uuid,
    required this.problem,
    required this.title,
    required this.createDate,
    required this.importDate,
    required this.testCase,
    required this.collections,
    required this.sampleCode,
    required this.codeType
  });

  factory LocalProblem.fromMap(Map res) {
    final uuid = Uuid();
    final now = DateTime.now();

    return LocalProblem(
      uuid: res["uuid"] ?? uuid.v4(),
      title: res["title"],
      importDate: now,
      createDate: DateTime
        .fromMillisecondsSinceEpoch(res["createDate"]),
      problem: List<String>
        .from(res["problem"]),
      testCase: Testcase
        .fromMap(res["testcase"]),
      collections: List<String>
        .from(res["collections"]),
      sampleCode: res["sampleCode"]==null ? null : List<String>
        .from(res["sampleCode"]),
      codeType: CodeType.values[res["testcase"]["codeType"]],

    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uuid": uuid,
      "title": title,
      "createDate": createDate.millisecondsSinceEpoch,
      "problem": problem,
      "testCase": testCase.toMap(),
      "collections": collections,
      "sampleCode": sampleCode,
      "codeType": codeType.index
    };
  }
}

class ProblemCollection {
  final String uuid;
  final String name;
  final String description;

  final List<String> problemIDs;

  bool isInitialized = false;
  final List<LocalProblem> problems = [];

  ProblemCollection({
    required this.uuid,
    required this.name,
    required this.description,
    required this.problemIDs
  });

  Future<void> fetchProblems() async {
    if (isInitialized) return;

    problems.clear();
    
    final tasks = problemIDs
      .map((e) => OnlineProblemAPI.fetchProblem(e));
    
    late final List<LocalProblem> results;
    try {
      results = await Future.wait(tasks);
    } catch (e) {
      logger.e("Cannot parse problem: $e");
    }
    
    for (var item in results) {
        problems.add(item);
    }

    isInitialized = true; 
  }

  factory ProblemCollection.fromMap(Map res) {
    final uuid = Uuid();

    return ProblemCollection(
      uuid: res["uuid"] ?? uuid.v4(),
      name: res["name"],
      description: res["description"],
      problemIDs: List<String>.from(res["problems"])
    );
  }
}

class OnlineProblemAPI {
  static const String domian = "https://yfhd-osu.github.io/NTUT-Problem-Repo";

  static Future<List<ProblemCollection>> fetchCollections() async {
    final url = Uri.parse("$domian/index.json");
    final map = await _parseJson(url);

    final collectionsID = List<String>.from(map["collections"]);

    Future<ProblemCollection> fetch(String collectionID) async {
      final url = Uri.parse("$domian/collections/$collectionID.json");
      final map = await _parseJson(url);
      
      return ProblemCollection.fromMap(map);
    }

    final tasks = collectionsID.map((e) => fetch(e));

    return await Future.wait<ProblemCollection>(tasks);

  }

  static Future<LocalProblem> fetchProblem(String problemID) async {
    final url = Uri.parse("$domian/problems/$problemID.json");
    final map = await _parseJson(url);

    return LocalProblem.fromMap(map);
  }

  static Future<dynamic> _parseJson(Uri url) async {
    final response = await http.get(url);

    return json.decode(response.body);
  }
}