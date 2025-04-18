import 'dart:async';

import 'package:intl/intl.dart';
import 'package:html_character_entities/html_character_entities.dart';
import 'package:beautiful_soup_dart/beautiful_soup.dart';

import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/core/test_server.dart';
import 'package:ntut_program_assignment/core/utils.dart';
import 'package:ntut_program_assignment/main.dart' show MyApp, logger;

class RuntimeError {
  final String message;

  RuntimeError(this.message);

  @override
  String toString() {
    return message;
  }
}

class NetworkError extends RuntimeError {
  NetworkError(super.message);
}

class TestCase {
  final bool pass;
  final String title;
  final String? testResult;
  final String message;

  TestCase(
    this.pass,
    this.title,
    this.message,
    this.testResult
  );

  factory TestCase.fromSoup(Bs4Element soup) {
    final failed = soup.findAll("td");
    
    return TestCase(
      soup.children.first.className == "positive",
      soup.children.first.text.trim(),
      failed.isEmpty ? "" : failed[1].text.trim(),
      failed.isEmpty ? "" : failed.last.text.trim()
    );
  }
}

class CheckResult {
  final List<TestCase> cases;
  final int? _passRate;

  int get failedCount {
    // Even student id cannot fetch all test count, so we need to handle it specially 
    if (GlobalSettings.account!.isEven) {
      return cases.length;
    }

    // Process odd studnet id normally
    return cases.where((e) => !e.pass).length;
  }

  int get passCount {
    // Even student id cannot fetch all test count, so we need to handle it specially 
    if (GlobalSettings.account!.isEven) {
      return ( allCount * passRate / 100).toInt();
    }

    return cases.where((e) => e.pass).length;
  }

  int get failedRate => 100 - passRate;

  int get passRate {
    if (_passRate != null) {
      return _passRate;
    }

    if (cases.isEmpty && GlobalSettings.account!.isEven) {
      // Return 100% pass rate due to even student id system will response a empty list if assignment passed
      return 100;
    }

    if (cases.isEmpty) {
      // Assert that length of test cases is not zero 
      return 0;
    }
    
    return (cases.where((e) => e.pass).length / cases.length * 100).toInt();
  }
    

  int get allCount {
    if (GlobalSettings.account!.isEven) {
      if (failedCount == 0) {
        return 0;
      }

      return ( failedCount * 100 / failedRate ).toInt();
    } 

    return cases.length;
  }

  CheckResult(
    this.cases,
    this._passRate
  );

  factory CheckResult.fromSoup(BeautifulSoup soup) {
    final table = soup.find("tbody");
  
    late final List<TestCase> testcases;

    if (table == null || table.children.isEmpty) {
      // Return empty array means that the homework hasn't been submitted

      // Even student ID doesn't support test case showing,
      // ignore search if the form is empty
      testcases = [];
    } else {
      testcases = table.children
      .where((soup) => soup.children.firstOrNull != null)
      .map((e) => TestCase.fromSoup(e))
      .toList();
    }
    
    final pr = soup.findAll("span").lastOrNull?.text ?? "";
    
    final int? passRate = int.tryParse(
      RegExp(r"\d+")
        .firstMatch(pr)
        ?.group(0) ?? ""
    );

    return CheckResult(testcases, passRate);
  }
}

enum HomeworkState {
  notTried,
  notPassed,
  passed,
  checking,
  delete,
  compileFailed,
  preparing,
  plagiarism,
  other
}

class Homework {
  final int id;
  final String type;
  final String hwId;
  final DateTime deadline;
  final bool canHandIn;
  final String language;

  String? filename;
  List<int>? bytes;

  List<String>? passList;
  CheckResult? testResults;

  String? title;
  late Testcase testCase;
  late List<String> problem;

  String status;

  HomeworkStatus? fileState;

  bool deleting = false;
  bool submitting = false;

  bool get isPass =>
    status == "通過";

  CodeType get codeType {
    switch (type) {
      case "Python":
        return CodeType.python;
      
      case "C":
        return CodeType.c;

      default:
        throw UnimplementedError();
    }
  }

  bool get canUpload {
    if (submitting || deleting) {
      return false;
    }

    return true;
  }

  bool get canDelete {
    switch (state) {
      case HomeworkState.notPassed:
      case HomeworkState.passed:
      case HomeworkState.other:
      case HomeworkState.compileFailed:
      case HomeworkState.plagiarism:
        return DateTime.now().compareTo(deadline) <= 0;

      default:
        return false;
    }
  }

  int? passRate;

  HomeworkState get state {
    if (submitting) {
      return HomeworkState.checking;
    }

    if (deleting) {
      return HomeworkState.delete;
    }

    if (status == "通過") {
      return HomeworkState.passed;
    }

    if (status == "未通過") {
      return HomeworkState.notPassed;
    }

    if (status == "編譯失敗") {
      return HomeworkState.compileFailed;
    }

    if (status == "準備中") {
      return HomeworkState.preparing;
    }

    if (status == "未繳交" || status == "未繳") {
      return HomeworkState.notTried;
    }

    if (status == "作業抄襲") {
      return HomeworkState.plagiarism;
    }

    return HomeworkState.other;
  }

  Homework({
    required this.id, 
    required this.type, 
    required this.hwId, 
    required this.deadline,
    required this.status,
    required this.canHandIn, 
    required this.language,
  });

  Future<void> refreshTestcaseAndPasslist() async {
    final tasks = [refreshPassList(), fetchTestcases()];
    await Future.wait(tasks);
  }

  Future<void> fetchHomeworkDetail() async {
    final ctx = await GlobalSettings.account!.fetchHomeworkDetail(hwId);

    int index = 0;
    int start = 0;

    problem = [];

    while (index < ctx.length) {
      if (problem.isEmpty && ctx[index].trim().replaceAll("\n", "").isEmpty) {
        index++;
        continue;
      }

      // Search for title if the value is not found
      if (title == null && ctx[index].contains(hwId)) {
        title = HtmlCharacterEntities.decode(ctx[index])
          .split(hwId)
          .sublist(1)
          .join("")
          .trim();
        index++;
        continue;
      }

      if (ctx[index].contains(RegExp(r"【測試資料.+】"))) {
        index++;
        start = index;
        break;
      }
      
      problem.add(HtmlCharacterEntities
        .decode(ctx[index].trim())
      );
      
      index++;
    }

    // Clean up for empty lines
    while (problem.last.replaceAll("\n", "").isEmpty) {
      problem.removeLast();
    }
    
    testCase = Testcase.parse(ctx, index, start, codeType);
  }

  Future<void> refreshPassList() async {
    passList = await GlobalSettings.account!.fetchPassList(hwId);
  }

  Future<void> fetchTestcases() async {
    testResults = await GlobalSettings.account!.fetchTestcases(hwId);
  }

  Future<void> delete() async {
    deleting = true;
    
    await GlobalSettings.account!.delete(hwId);

    await _fetchState();

    status = "未繳交";
    deleting = false;

    return;
  }

  // Fetch the homework status on web
  Future<String> _fetchState() async {
    final result = (await GlobalSettings.account!.fetchHomeworkList())
      .where((e) => e.hwId == hwId)
      .first;

    status = result.status;
    return result.status;
  }

  void applyTrashCode() {
    assert (bytes != null, "Bytes variable is null, so the trash code cannot be appiled");

    switch (language) {
      case "C":
        bytes!.addAll("\n".codeUnits);
        bytes!.addAll(Utils.generateTrashCode(CodeType.c).join("\n").codeUnits);

      default:
        throw UnimplementedError("Trash code apply is not implement for $type language");
    }
  }

  void applyDelComment() {
    assert(bytes != null, "Bytes variable is null, so comment cannot be deleted");

    switch (language) {
      case "C":
        final commentExp = RegExp(r'//.*|/\*[\s\S]*?\*/');
        bytes = String.fromCharCodes(bytes!)
          .replaceAll(commentExp, '')
          .codeUnits;

      default:
        throw UnimplementedError("Delete comment is not implement for $type language");
    }
  }

  Future<void> upload(List<int> bytes, String filename) async {
    this.bytes = bytes;
    this.filename = filename;

    int attempts = 1;

    await GlobalSettings.account!.upload(hwId, language, bytes, filename);

    while (attempts > 0) {
      final state = await _fetchState();

      if (state != "批改中") break;
      
      await Future.delayed(const Duration(seconds: 1));
      attempts--;
    }

    submitting = false;

    logger.d("Upload process completed ");

    if (attempts <= 0) {
      throw RuntimeError(MyApp.locale.grading_time_exceeded);
    }

    return;
  }

  static Future<List<Homework>> refreshState(List<Homework> hws) async {
    final map = Map<String, Homework>.fromEntries(hws.map((e) => MapEntry(e.hwId, e)));
    final updated = await GlobalSettings.account!.fetchHomeworkList();
    
    for (var hw in updated.where((e) => map.keys.contains(e.hwId))) {
      map[hw.hwId]!.status = hw.status;
    }

    return map.values.toList();
  }

  static Future<List<Homework>> refreshHandedIn(List<Homework> hws) async {
    final map = Map<String, Homework>.fromEntries(hws.map((e) => MapEntry(e.hwId, e)));
    final updated = await GlobalSettings.account!.fetchHanddedHomeworks();
    
    for (var hw in updated.where((e) => map.keys.contains(e.id))) {
      map[hw.id]!.fileState = hw;
    }

    return map.values.toList();
  }

  factory Homework.fromSoup(Bs4Element e) {
    DateFormat dateFormat = DateFormat("yyyy/MM/dd HH:mm");
    return Homework(
      id: int.parse(e.contents[0].text),
      type: e.contents[5].text.trim(), 
      hwId: e.contents[2].text.trim(),
      deadline: dateFormat.parse(e.contents[3].text), 
      canHandIn: e.contents[4].find("a") != null, 
      language: e.contents[5].text.trim(),
      status: e.contents[6].text.trim()
    );
  }
}

class HomeworkStatus {
  final DateTime date;
  final String id, description, filename, status;

  HomeworkStatus({
    required this.date, 
    required this.id, 
    required this.description, 
    required this.filename, 
    required this.status
  });
  
  static HomeworkStatus? fromList(List<String> a) {
    if (a.length < 5) {
      return null;
    }

    final dateFormat = DateFormat("yyyy/MM/dd HH:mm:ss");
    
    return HomeworkStatus(
      date: dateFormat.parse(a[0]),
      id: a[1],
      description: a[2],
      filename: a[3],
      status: a[4].trim()
    );
  }
}

class UserComment {
  final String author;
  final String metadata;
  final String text;
  final bool canReply;

  final List<UserComment> child;

  UserComment({
    required this.author,
    required this.metadata,
    required this.text,
    required this.canReply,
    required this.child
  });

  factory UserComment.parse(Bs4Element soup) {
    final content = soup.find("div", class_: "content")!;

    final author = content
      .find("a", class_: 'author')!
      .text;

    final metadata = content
      .find("div", class_: "metadata")!
      .find("span")!
      .text;
    
    final text = content
      .find("div", class_: "text")!
      .findAll("p")
      .map((e) => HtmlCharacterEntities.decode(e.text))
      .join("\n")
      .trim();

    final canReply = content
      .find("div", class_: "actions")!
      .children.isNotEmpty;


    final comments = soup
      .findAll("div", class_: "comments");

    List<UserComment> children = comments
      .map((e) => UserComment.parse(e.find("div", class_: "comment")!))
      .toList();

    return UserComment(
      author: author,
      metadata: metadata,
      text: text,
      canReply: canReply,
      child: children,
    );
  }
}