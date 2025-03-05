import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:html_character_entities/html_character_entities.dart';

import 'package:http/http.dart' as http;
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/core/test_server.dart';
import 'package:ntut_program_assignment/main.dart' show MyApp, logger;
import 'package:path_provider/path_provider.dart';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(final SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class Account {
  int course;
  String courseName;
  String username, password;
  String? sessionID, name;

  Account({
    required this.course,
    required this.courseName,
    required this.username,
    required this.password
  });

  static List<String> defaultDomain = [
    "https://140.124.181.25",
    "https://140.124.181.26"
  ];

  bool get isEven => 
    int.tryParse(username.substring(username.length-3))?.isEven??false;

  String get domain {
    return isEven ? defaultDomain[1] : defaultDomain[0];
  }
  
  bool get isLogin => sessionID != null;

  late final client = InnerClient(
    account: this
  );

  late DateTime loginTime = DateTime.now();

  Future<void> login() async {

    sessionID = null;
    late http.Response response;

    Uri url = Uri.parse("$domain/upload/Login");
    response = await http.get(url, headers: client._headers);

    sessionID = response.headers['set-cookie']
      .toString()
      .split(" ")
      .first
      .replaceAll(";", "");

    final payload = {
      "name": username,
      "passwd": password,
      "rdoCourse": course.toString()
    };
    
    url = Uri.parse("$domain/upload/Login");
    response = await http.post(url, body: payload, headers: client._headers);

    loginTime = DateTime.now();
    BeautifulSoup bs = BeautifulSoup(response.body);
    final loginBox = bs.find("div", class_: "login-box");

    // If the login box still exist, means that login failed
    if (loginBox != null) {
      final error = bs.find("h4", class_: "card-title"); 
      throw Exception(error?.text??"");
    }

    url = Uri.parse("$domain/upload/TopMenu");
    response = await http.get(url, headers: client._headers);

    bs = BeautifulSoup(response.body);
    final studentName = bs.find("div", class_: "content");

    if (studentName == null) {
      logger.e("Cannot fetch Student ID (DNS error suspected)");
      throw RuntimeError(MyApp.locale.runtime_error_student_id_not_found);
    }
    name = studentName.text.replaceAll(" ", "").split("\n")[1];
  }

  void logout() => sessionID = null;

  static Future<List<String>> fetchCourse(bool isOdd) async {
    final uri = Uri.parse("${isOdd ? defaultDomain[0]: defaultDomain[1]}/upload/Login");
    final response = await http.get(uri, headers: {
      "origin": isOdd ? defaultDomain[0]: defaultDomain[1]
    });
    BeautifulSoup bs = BeautifulSoup(response.body);
    final menu = bs.find("select", id: "inputGroupSelect01");
    if (menu?.contents == null) {
      throw Exception("Cannot fetch class");
    }
    return menu!.contents
      .map((e) => e.text.trim())
      .toList();
  }

  Future<List<Homework>> fetchHomeworkList() async {
    late final http.Response resp;
    try {
      resp = await client._get("/HomeworkBoard");
    } on http.ClientException catch (e) {
      await login();
      logger.e("Perform account refresh due to: $e");
      return await fetchHomeworkList();
    }

    BeautifulSoup bs = BeautifulSoup(resp.body);
    final hwList = bs.find("tbody");

    if (hwList == null) {
      logger.e("Cannot fetch homeworks list element");
      throw RuntimeError(MyApp.locale.runtime_error_element_not_found);
    }

    return hwList.contents
      .map((e) => Homework.fromSoup(e))
      .toList();
  }

  Future<List<HomeworkStatus>> fetchHanddedHomeworks() async {
    final response = await client._get("/HwQuery");

    BeautifulSoup bs = BeautifulSoup(utf8.decode(response.bodyBytes));
    final menu = bs.find("tbody");

    if (menu == null) {
      logger.e("Cannot find the main table element");
      throw RuntimeError(MyApp.locale.runtime_error_element_not_found);
    }

    final List<HomeworkStatus> result = [];

    for (var item in menu.children) {
      final res = HomeworkStatus.fromList(item.text.split("\n"));
      if (res != null) {
        result.add(res);
      }
    }
    return result;
  }

  Future<void> changePasswd(String pass) async {
    final data = {
      "pass": pass,
      "submit": "sumit"
    };
    final resp = await client._post("/changePasswd", body: data);

    if (resp.statusCode != 200) {
      logger.e("Unable to change password (Status: ${resp.statusCode})");
      throw RuntimeError("${MyApp.locale.runtime_error_abnormal_status_code} (${resp.statusCode})");
    }

  }

  Future<void> addMsgBoard(String content) async {
    final data = {
      "body": content
    };

    final resp = await client._post("/AddMsgBoard", body: data);

    if (resp.statusCode != 302) {
      logger.e("Unable to add message (Status: ${resp.statusCode})");
      throw RuntimeError("${MyApp.locale.runtime_error_abnormal_status_code} (${resp.statusCode})");
    }
  }

  Future<void> replyMsgBoard(String metadata, String content) async {
    final data = {
      "masterTime": metadata,
      "replyContent": content
    };

    final header = {
      "Referer": "https://$domain/upload/MessageBoard"
    };

    final resp = await client._post("/MessageAjax?case=replySomeone", body: data, headers: header);

    if (resp.statusCode != 200) {
      logger.e("Unable to reply (Status: ${resp.statusCode})");
      throw RuntimeError("${MyApp.locale.runtime_error_abnormal_status_code} (${resp.statusCode})");
    }

  }

  Future<List<Comment>> fetchMsgBoard() async {
    final response = await client._get("/MessageBoard");

    BeautifulSoup bs = BeautifulSoup(response.body);
    final comemnts = bs.find("div", class_: "ui comments");

    return comemnts!.children
      .where((e) => e.className == "comment")
      .map((e) => Comment.parse(e))
      .toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'course': course,
      'courseName': courseName,
      'username': username,
      'password': password,
      'sessionID': sessionID,
    };
  }

  factory Account.fromMap(Map res) {
    final instance = Account(
      course: res['course'],
      courseName: res['courseName'] ?? "NULL",
      username: res['username'],
      password: res['password']
    );
    instance.sessionID = res['sessionID'];
    instance.name = res['name'];
    return instance;
  }
}

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

class TestException {
  final String message;

  TestException(this.message);
}

class TestResult {
  final List<String> error, output;

  TestResult({
    required this.error,
    required this.output
  });
}

class Testcase {
  final String input, output;
  final String original;

  bool testing = false;
  TestResult? result;

  Testcase({
    required this.input,
    required this.output,
    required this.original
  });

  bool get hasOutput {
    return result != null && result!.output.isNotEmpty;
  }

  bool get isPass {
    return output.trim() == result?.output.join("\n").trim();
  }

  factory Testcase.parse(String message) {
    final regExp = RegExp(r"輸(入|出).+");

    final arr = message.split(regExp);
    if (arr.length < 3) {
      logger.e("Cannot parse testcase: $message");
      throw RuntimeError(MyApp.locale.runtime_error_testcase_parse_failed);
    }

    return Testcase(
      input: arr[1]
        .replaceFirst("\n", "")
        .trimRight(),
      output: arr
        .last // There are always some <new lines> mark at the begin of the List 
        .replaceFirst("\n", ""), // Replace the first '\n' to empty string 
      original: message
    );
  }

  @override
  String toString() {
    return "${MyApp.locale.input}: \n$input \n\n${MyApp.locale.output}:\n$output";
  }
}

class TestCase {
  final bool pass;
  final String title;
  final String? message;

  TestCase(
    this.pass,
    this.title,
    this.message
  );

  factory TestCase.fromSoup(Bs4Element soup) {
    final failed = soup.findAll("td");
    
    return TestCase(
      soup.children.first.className == "positive",
      soup.children.first.text.trim(),
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
  preparing
}

class Homework {
  final int id;
  final String type;
  final String number;
  final DateTime deadline;
  final bool canHandIn;
  final String language;

  String? title;
  List<String> problem = [];
  List<Testcase> testCases = [];

  String status;

  HomeworkStatus? fileState;

  bool get isAllTesting =>
    testCases.every((e) => e.testing);

  bool deleting = false;
  bool submitting = false;

  File? testFile;

  bool get isPass =>
    status == "通過";

  int? passRate;

  List<String> get allowedExtensions {

    if (language == "C") {
      return ["c"];
    }

    if (language == "Python") {
      return ["py"];
    }
    return ['*'];
  }

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

    return HomeworkState.notTried;
  }

  final client = InnerClient(
    account: GlobalSettings.account!
  );

  Homework({
    required this.id, 
    required this.type, 
    required this.number, 
    required this.deadline,
    required this.status,
    required this.canHandIn, 
    required this.language,
  });

  Future<void> fetchHomeworkDetail() async {
    final resp = await client._get("/showHomework?hwId=$number");

    if (resp.statusCode == 500) {
      logger.e("Cannot fetch homework details, status code :${resp.statusCode}");
      throw RuntimeError(MyApp.locale.runtime_error_homework_not_found);
    }

    BeautifulSoup bs = BeautifulSoup(resp.body);
    final hwDesc = bs.find("span")!;

    final ctx = hwDesc.innerHtml.split("<br>");

    int index = 0;
    int start = 0;

    while (index < ctx.length) {
      if (problem.isEmpty && ctx[index].trim().replaceAll("\n", "").isEmpty) {
        index++;
        continue;
      }

      if (title == null && ctx[index].contains(number)) {
        title = HtmlCharacterEntities.decode(ctx[index])
          .split(number)
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

    while (problem.last.replaceAll("\n", "").isEmpty) {
      problem.removeLast();
    }
    
    while (index < ctx.length) {
      if (!ctx[index].contains(RegExp(r"【測試資料.+】"))) {
        index++;
        continue;
      }

      try {
        final data = Testcase.parse(
          ctx.sublist(start, index)
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .join("\n")
        );
        testCases.add(data);
      } on RuntimeError catch (e) {
        logger.d(e);
        continue;
      } finally {
        start = index + 1;
      }

      index++;
    }

    try {
      final data = Testcase.parse(
        ctx.sublist(start, index)
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .join("\n")
      );
      testCases.add(data);
    } on RuntimeError catch (e) {
      logger.d(e);
    }

    return;
  }

  Future<List<String>> fetchPassList() async {
    final resp = await client._get("/success.jsp?HW_ID=$number");

    BeautifulSoup bs = BeautifulSoup(resp.body);

    final table = bs.find("table", class_: "table");
    
    final tr = table?.children.first.children;

    if (tr == null) {
      // If account being logout, the table will not shown
      // So try re-login and try again

      await Future.doWhile(() => GlobalSettings.isLoggingIn);

      return await fetchPassList();

      // throw RuntimeError("Cannot fetch success list, not login ?");
    }

    return tr
      .map((e) => e.text.trim())
      .where((e) => e != "學號")
      .toList();
  }

  Future<CheckResult> fetchTestcases() async {
    final account = GlobalSettings.account!;
    final resp = await client._get("/CheckResult?questionID=$number&studentID=${account.username}");

    BeautifulSoup bs = BeautifulSoup(utf8.decode(resp.bodyBytes));

    return CheckResult.fromSoup(bs);
  }

  Future<void> delete() async {
    deleting = true;
    final resp = await client._get("/delHw?title=$number&l=$language");

    if (resp.statusCode != 200) {
      throw RuntimeError("Failed to delete homework");
    }

    await _fetchState();

    status = "未繳交";
    deleting = false;

    return;
  }

  // Fetch the homework status on web
  Future<String> _fetchState() async {
    final result = (await GlobalSettings.account!.fetchHomeworkList())
      .where((e) => e.number == number)
      .first;

    status = result.status;
    return result.status;
  }

  Future<void> upload(File file) async {
    Future<void> prefetch() async {
      final account = GlobalSettings.account!;

      /*
      Login (Ref: "https://140.124.181.25/upload/Login")
        -> MainMenu
          -> DownMenu, TopMenu
            -> HomeworkBoard (TopMenu)
              -> ${account.domain}/upload/upLoadHw?hwId=$number&l=$language
                -> Final UPLOAD 
      */

      logger.d("Upload prefetching with session: ${account.sessionID}");

      await client._get("/MainMenu", headers: {
        "Referer": "${account.domain}/upload/Login"
      });
      
      await client._get("/DownMenu", headers: {
        "Referer": "${account.domain}/upload/MainMenu"
      });

      await client._get("/TopMenu", headers: {
        "Referer": "${account.domain}/upload/MainMenu"
      });

      await client._get("/HomeworkBoard", headers: {
        "Referer": "${account.domain}/upload/TopMenu"
      });

      await client._get("/upLoadHw?hwId=$number&l=$language", headers: {
        "Referer": "${account.domain}/upload/HomeworkBoard"
      });

      return;
    }

    if (!await file.exists()) {
      submitting = false;
      throw RuntimeError(MyApp.locale.file_not_found);
    }    

    final account = GlobalSettings.account!;

    // This endpoint must be GET before any homework uploaded
    await prefetch();

    logger.i("Upload homework prefetch completed.");

    final headers = client._headers;
    headers.addAll({
      "Referer": "${account.domain}/upload/upLoadHw?hwId=$number&l=$language",
      'Content-Type': 'multipart/form-data',
    });

    var request = http.MultipartRequest(
      'POST', Uri.parse('${account.domain}/upload/upLoadFile')
    );

    request.files.add(await http.MultipartFile.fromPath('hwFile', file.path));
    // request.headers.addAll(account.headers);
    request.headers.addAll(headers);

    logger.d("Start uploading file to server");

    int attempts = 1;

    try {
      await request
        .send()
        .timeout(const Duration(seconds: 15));
    } on TimeoutException catch (_) {
      attempts = 90;
    }
    
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
    final map = Map<String, Homework>.fromEntries(hws.map((e) => MapEntry(e.number, e)));
    final updated = await GlobalSettings.account!.fetchHomeworkList();
    
    for (var hw in updated.where((e) => map.keys.contains(e.number))) {
      map[hw.number]!.status = hw.status;
    }

    return map.values.toList();
  }

  static Future<List<Homework>> refreshHandedIn(List<Homework> hws) async {
    final map = Map<String, Homework>.fromEntries(hws.map((e) => MapEntry(e.number, e)));
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
      type: e.contents[1].text.trim(), 
      number: e.contents[2].text.trim(),
      deadline: dateFormat.parse(e.contents[3].text), 
      canHandIn: e.contents[4].find("a") != null, 
      language: e.contents[5].text.trim(),
      status: e.contents[6].text.trim()
    );
  }

  Future<void> testAll(File target) async {
    for (int i=0; i<testCases.length; i++) {
      await test(target, i);
    }
  }

  Future<TestResult> test(File target, int index) async {
    if (!await target.exists()) {
      throw TestException(MyApp.locale.file_not_found);
    }

    switch (language) {
      case "Python":
        await _testPython(target, index);


      case "C":
        await _testC(target, index);
        

      default: 
        testCases[index].testing = false;
        throw TestException("${MyApp.locale.testcase_unsupported_lang} $language");
    }
    testCases[index].testing = false;

    return testCases[index].result!;
  }

  Future<void> _testPython(File target, int index) async {
    if (!TestServer.pythonOK) {
      throw RuntimeError("Python ${MyApp.locale.testcase_environment_not_setup}");
    }

    late final Process process;

    try {
      process = await Process.start(GlobalSettings.prefs.pythonPath ?? "python", [target.path]);
    } catch (e) {
      testCases[index].result = TestResult(
        error: ["${MyApp.locale.testcase_file_failed_to_execute} $e"],
        output: ["${MyApp.locale.testcase_file_failed_to_execute} $e"]
      );
      return;
    }    

    for (var line in testCases[index].input.split("\n")) {
      // print("Feeding: $line");
      process.stdin.write(line);
      process.stdin.write(ascii.decode([10]));
    }

    await process.exitCode
      .timeout(const Duration(seconds: 10))
      .onError((error, trace) => _onTestError(error, trace, index, process));

    if (await process.exitCode != 0) {
      testCases[index].testing = false;
      return;
    }

    process.kill();

    final out = await process.stdout
      .map((e) => utf8.decode(e))
      .toList();

    final err = await process.stderr
      .map((e) => utf8.decode(e))
      .toList();
    
    testCases[index].result = TestResult(
      error: err,
      output: out.firstOrNull
        ?.split("\n")
        .map((e) => e.replaceAll(ascii.decode([13]), ""))
        .toList() ?? []
    );

    testCases[index].testing = false;

    return;
  }

  Future<void> _testC(File target, int index) async {
    if (!TestServer.gccOK) {
      throw RuntimeError("C ${MyApp.locale.testcase_environment_not_setup}");
    }

    late final Process compile;

    final compileDir = "${(await getApplicationSupportDirectory()).path}/build";

    if (! (await Directory(compileDir).exists())) {
      await Directory(compileDir).create(recursive: true);
    }

    try {
      compile = await Process.start(
        GlobalSettings.prefs.gccPath ?? "gcc",
        [target.path, '-o', '$compileDir/$id']
      );
      
    } catch (e) {
      testCases[index].result = TestResult(
        error: ["${MyApp.locale.testcase_compile_failed} $e"],
        output: ["${MyApp.locale.testcase_compile_failed} $e"]
      );
      return;
    }
    
    await compile.exitCode
      .timeout(const Duration(seconds: 10))
      .onError((error, trace) => _onTestError(error, trace, index, compile));
    
    final exitCode = await compile.exitCode;
    if (exitCode != 0) {
      final err = await compile.stderr
        .map((e) => utf8.decode(e))
        .toList();

      testCases[index].testing = false;
      testCases[index].result = TestResult(
        error: ["${MyApp.locale.testcase_program_error_with} $exitCode \n$err"],
        output: ["${MyApp.locale.testcase_program_error_with} $exitCode \n$err"]
      );
      logger.e("failed to compile: ${target.path} \n$err");

      return;
    } 

    compile.kill();

    final process = await Process.start("$compileDir/$id", []);

    for (var line in testCases[index].input.split("\n")) {
      // print("Feeding: $line");
      process.stdin.write(line);
      process.stdin.write(ascii.decode([10]));
    }

    await process.exitCode
      .timeout(const Duration(seconds: 10))
      .onError((error, trace) => _onTestError(error, trace, index, process));

    process.kill();

    final out = await process.stdout
      .map((e) => utf8.decode(e))
      .toList();

    final err = await process.stderr
      .map((e) => utf8.decode(e))
      .toList();
    
    testCases[index].result = TestResult(
      error: err,
      output: out.firstOrNull
        ?.split("\n")
        .map((e) => e.replaceAll(ascii.decode([13]), ""))
        .toList() ?? []
    );

    testCases[index].testing = false;

    return;
  }

  Future<int> _onTestError(Object? error, StackTrace trace, int index, Process process) async {
    process.kill();
    switch (error.runtimeType) {
      case TimeoutException _:
        testCases[index].result = TestResult(
          error: [MyApp.locale.testcase_timeout],
          output: [MyApp.locale.testcase_timeout]
        );
        throw TestException(MyApp.locale.testcase_timeout);
      
      case OSError _:
        testCases[index].result = TestResult(
          error: ["${MyApp.locale.testcase_invalid_test_file} ${(error as OSError).message}"],
          output: [MyApp.locale.testcase_timeout]
        );

      default:
        throw TestException(error.toString());
    }

    return 0;
  }
}

class InnerClient extends http.BaseClient {
  static bool _loginBlock = false;
  final Account account;

  InnerClient({
    required this.account
  });

  Map<String, String> get _headers => {
    'Host': account.domain.replaceAll("https://", ""),
    'Referer': "${account.domain}/upload/Login",
    'Origin': account.domain,
    'Cookie': account.sessionID ?? "",
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
  };

  Map<String, String> get headers => {
    'Host': account.domain.replaceAll("https://", ""),
    'Origin': account.domain,
    'Cookie': account.sessionID ?? "",
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36'
  };

  Future<void> checkConnect() async {
    late Uri uri;
    
    uri = Uri.parse("https://www.google.com/");
    try {
      await http.head(uri)
        .timeout(const Duration(seconds: 8));
    } on TimeoutException catch (_) {
      throw NetworkError(MyApp.locale.internet_not_stable);
    } on SocketException catch (_) {
      throw NetworkError(MyApp.locale.internet_not_stable);
    } catch (e) {
      throw NetworkError(e.toString());
    }

    uri = Uri.parse(account.domain);
    try {
      await http.head(uri)
        .timeout(const Duration(seconds: 8));
    } on TimeoutException catch (_) {
      throw NetworkError(MyApp.locale.vpn_not_connect);
    } catch (e) {
      throw NetworkError(e.toString());
    }
  }

  http.BaseRequest _copyRequest(http.BaseRequest request) {
    http.BaseRequest requestCopy;

    if(request is http.Request) {
      requestCopy = http.Request(request.method, request.url)
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes;
    }
    else if(request is http.MultipartRequest) {
      requestCopy = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    }
    else if(request is http.StreamedRequest) {
      throw Exception('copying streamed requests is not supported');
    }
    else {
      throw Exception('request type is unknown, cannot copy');
    }

    requestCopy
      ..persistentConnection = request.persistentConnection
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..headers.addAll(request.headers);

    return requestCopy;
  }
  Future<http.StreamedResponse> _send(http.BaseRequest request, int depth, DateTime timestamp) async {
    late final http.StreamedResponse response;
    
    if (_loginBlock) {
      await Future.doWhile(() async {
        await Future.delayed(Duration(milliseconds: 500));
        return _loginBlock;
      });
      return _send(request, depth, timestamp);
    }

    try {
      response = await _copyRequest(request).send();
    } on SocketException catch (_) {
      

      if (depth > 1) {
        throw RuntimeError(MyApp.locale.cannot_login);
      }

      await checkConnect();
      logger.e("SocketException occured with ${request.method} ${request.url} ($depth)");

      // if (timestamp.compareTo(account.loginTime) < 0) {
      //   throw LoginProcessingError("Login is processing, please resend request");
      // }

      _loginBlock = true;

      account.logout();
      await account.login();

      _loginBlock = false;

      // Update requests header with new cookies
      final newReq = _copyRequest(request);
      newReq.headers.addAll(headers);

      logger.d("Debug depth: ${depth + 1}");
      return _send(newReq, depth + 1, timestamp);
    } on HandshakeException catch (_) {
      throw RuntimeError(MyApp.locale.uable_to_locale_server);
    } on http.ClientException catch (_) {
      throw RuntimeError(MyApp.locale.internet_not_stable);
    }

    return response;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return await _send(request, 0, DateTime.now());
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final newHeader = _headers;
    newHeader.addAll(headers??{});
    
    return await super.get(url, headers: newHeader);
  }

  Future<http.Response> _get(String endpoints, {Map<String, String>? headers}) async {
    final newHeader = _headers;
    newHeader.addAll(headers??{});
    
    final uri = Uri.parse("${account.domain}/upload$endpoints");
    return await get(uri, headers: newHeader);
  }

  @override
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final newHeader = _headers;
    newHeader.addAll(headers??{});
    
    return await super.post(url, headers: newHeader, body: body, encoding: encoding);
  }

  Future<http.Response> _post(String endpoints, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final newHeader = _headers;
    newHeader.addAll(headers??{});
    
    final uri = Uri.parse("${account.domain}/upload$endpoints");
    return await post(uri, headers: newHeader, body: body, encoding: encoding);
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

class Comment {
  final String author;
  final String metadata;
  final String text;
  final bool canReply;

  final List<Comment> child;

  Comment({
    required this.author,
    required this.metadata,
    required this.text,
    required this.canReply,
    required this.child
  });

  factory Comment.parse(Bs4Element soup) {
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

    List<Comment> children = comments
      .map((e) => Comment.parse(e.find("div", class_: "comment")!))
      .toList();

    return Comment(
      author: author,
      metadata: metadata,
      text: text,
      canReply: canReply,
      child: children,
    );
  }
}