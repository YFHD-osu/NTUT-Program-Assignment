import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:ntut_program_assignment/core/global.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(final SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class Account {
  int course;
  String username, password;
  String? sessionID, name;

  Account({
    required this.course,
    required this.username,
    required this.password
  });

  static List<String> defaultDomain = [
    "https://140.124.181.25",
    "https://140.124.181.26"
  ];

  String get domain {
    final isEven = int.tryParse(username.substring(username.length-3))?.isEven??false;
    return isEven ? defaultDomain[1] : defaultDomain[0];
  }

  bool get isLogin => sessionID != null;

  Map<String, String> get headers => {
    'Host': domain.replaceAll("https://", ""),
    'Referer': "$domain/upload/Login",
    'Origin': domain,
    'Cookie': sessionID ?? "",
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36'
  };

  late final client = InnerClient(
    account: this
  );

  late DateTime loginTime = DateTime.now();

  Future<void> login() async {    
    sessionID = null;
    late http.Response response;

    response = await client._get("/Login");
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

    response = await client._post("/Login", body: payload, headers: headers);

    loginTime = DateTime.now();
    BeautifulSoup bs = BeautifulSoup(response.body);
    final loginBox = bs.find("div", class_: "login-box");

    // If the login box still exist, means that login failed
    if (loginBox != null) {
      final error = bs.find("h4", class_: "card-title"); 
      throw Exception(error?.text??"");
    }

    response = await client._get("/TopMenu", headers: headers);
    bs = BeautifulSoup(response.body);

    final studentName = bs.find("div", class_: "content");

    if (studentName == null) {
      throw RuntimeError("Cannot fetch Student ID (DNS error suspected)");
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
    final uri = Uri.parse("$domain/upload/HomeworkBoard");

    late final http.Response resp;
    try {
      resp = await http.get(uri, headers: headers);
    } on http.ClientException catch (e) {
      await login();
      logger.e("Perform account redfresh due to: $e");
      return await fetchHomeworkList();
    }
  
    BeautifulSoup bs = BeautifulSoup(resp.body);
    final hwList = bs.find("tbody");

    if (hwList == null) {
      throw Exception("ERROR, Cannot fetch homeworks");
    }

    return hwList.contents
      .map((e) => Homework.fromSoup(e))
      .toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'course': course,
      'username': username,
      'password': password,
      'sessionID': sessionID,
    };
  }

  factory Account.fromMap(Map res) {
    final instance = Account(
      course: res['course'],
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
}

class NetworkError {
  final String message;

  NetworkError(this.message);
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
    return "$output\n" == result?.output.join("\n");
  }

  factory Testcase.parse(String message) {
    final regExp = RegExp(r"輸(入|出).+");

    final arr = message.split(regExp);
    if (arr.length < 3) {
      throw RuntimeError("Cannot parse testcase: $message");
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

  Future<TestResult> exec(File target) async {
    if (!await target.exists()) {
      throw TestException("指定的測試檔案不存在");
    }

    testing = true;
    result = null;

    final process = await Process.start("python", [target.path]);

    for (var line in input.split("\n")) {
      // print("Feeding: $line");
      process.stdin.write(line);
      process.stdin.write(ascii.decode([10]));
    }

    try {
      await process.exitCode
        .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (_) {
      result = TestResult(
        error: ["測試時間超時，已強制結束"],
        output: ["測試時間超時，已強制結束"]
      );
      throw TestException("測試時間超時，已強制結束");
    } on OSError catch (e) {
      result = TestResult(
        error: ["測試檔案無效: ${e.message}"],
        output: ["測試時間超時，已強制結束"]
      );
    } catch (e) {
      logger.e(e);
      return result!;
    } 
    finally {
      process.kill();
    }

    final out = await process.stdout
      .map((e) => utf8.decode(e))
      .toList();

    final err = await process.stderr
      .map((e) => utf8.decode(e))
      .toList();
    
    result = TestResult(
      error: err,
      output: out.firstOrNull
        ?.split("\n")
        .map((e) => e.replaceAll(ascii.decode([13]), ""))
        .toList() ?? []
    );
    testing = false;

    return result!;
  }
}

class Description {
  final String? title;
  final String problem;
  final List<Testcase> testCases;

  Description({
    required this.title,
    required this.problem,
    required this.testCases
  });

  factory Description.fromRaw(String raw, Homework homework) {
    final filtered = raw.split("\n")
      .map((e) => e.trim())
      .join("\n");

    final lines = filtered.split("\n");
    final titleList = lines.where((e) => e .contains(homework.number));
    final title = (titleList.isEmpty ? null : titleList.first)
      ?.replaceAll(homework.number, "")
      .trim();
    
    final desc = filtered.replaceAll(homework.number, "").trim();

    final regExp = RegExp(r"【測試資料.+】");
    final res = desc.split(regExp);

    return Description(
      title: title,
      problem: res.first
        .replaceFirst(title??"", "")
        .trim(),
      testCases: res.sublist(1)
        .map((e) => Testcase.parse(e.trim()))
        .toList()
    );
  }
}

class CheckResult {
  final bool pass;
  final String title;
  final String? message;

  CheckResult(this.pass, this.title, this.message);

  factory CheckResult.fromSoup(Bs4Element soup) {
    final failed = soup.findAll("td");
    
    return CheckResult(
      soup.children.first.className == "positive",
      soup.children.first.text.trim(),
      failed.isEmpty ? "" : failed.last.text.trim()
    );
  }
}

enum HomeworkState {
  notTried,
  notPassed,
  passed,
  checking,
  delete
}

class Homework {
  final int id;
  final String type;
  final String number;
  final DateTime deadline;
  final bool canHandIn;
  final String language;
  String status;

  Description? description;

  bool get isAllTesting =>
    description?.testCases.every((e) => e.testing) ?? false;

  bool _deleting = false;
  bool submitting = false;

  bool get isPass =>
    status == "通過";

  HomeworkState get state {
    if (submitting) {
      return HomeworkState.checking;
    }

    if (_deleting) {
      return HomeworkState.delete;
    }

    if (status == "通過") {
      return HomeworkState.passed;
    }

    if (status == "未通過") {
      return HomeworkState.notPassed;
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
      throw RuntimeError("無法獲取作業詳細資料，猜測作業不存在");
    }

    BeautifulSoup bs = BeautifulSoup(resp.body);
    final hwDesc = bs.find("p");

    description = Description.fromRaw(hwDesc!.text, this);
    return;
  }

  Future<List<String>> fetchPassList() async {
    final resp = await client._get("/success.jsp?HW_ID=$number");

    BeautifulSoup bs = BeautifulSoup(resp.body);

    final table = bs.find("table", class_: "table");
    
    final tr = table?.children.first.children;
    if (tr == null) {
      throw RuntimeError("Cannot fetch success list, not login ?");
    }

    return tr
      .map((e) => e.text.trim())
      .where((e) => e != "學號")
      .toList();
  }

  Future<List<CheckResult>> fetchTestcases() async {
    final account = GlobalSettings.account!;
    final resp = await client._get("/CheckResult?questionID=$number&studentID=${account.username}");

    BeautifulSoup bs = BeautifulSoup(utf8.decode(resp.bodyBytes));

    final table = bs.find("tbody");
    
    if (table == null) {
      // Return empty array means that the homework hasn't been submitted
      return []; 
    }

    // Even student ID doesn't support test case showing,
    // ignore search if the form is empty

    if (table.children.isEmpty) {
      return [];
    }
      
    return table.children
      .map((e) => CheckResult.fromSoup(e))
      .toList();

  }

  Future<void> delete() async {
    _deleting = true;
    final resp = await client._get("/delHw?title=$number&l=$language");

    if (resp.statusCode != 200) {
      throw RuntimeError("Failed to delete homework");
    }

    await _refresh();

    status = "未繳交";
    _deleting = false;

    return;
  }

  Future<void> _refresh() async {
    final result = (await GlobalSettings.account!.fetchHomeworkList())
      .where((e) => e.number == number)
      .first;

    status = result.status;
  }

  Future<void> _prefetch() async {
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

  Future<void> upload(File file) async {
    submitting = true;

    if (!await file.exists()) {
      submitting = false;
      throw RuntimeError("File is not exists");
    }    

    final account = GlobalSettings.account!;


    // This endpoint must be GET before any homework uploaded
    await _prefetch();

    logger.i("Prefetch completed.");

    final headers = account.headers;
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
    http.StreamedResponse response = await request.send();

    logger.d("Upload process completed with status code ${response.statusCode}");

    await _refresh();
    submitting = false;

    if (response.statusCode != 200) {
      throw RuntimeError(response.reasonPhrase.toString());
    }

    return;
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
}

class InnerClient extends http.BaseClient {
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

  Future<void> checkConnect() async {
    late Uri uri;
    
    uri = Uri.parse("https://www.google.com/");
    try {
      await http.head(uri)
        .timeout(const Duration(seconds: 8));
    } on TimeoutException catch (_) {
      throw NetworkError("無法連線到網際網路或網路不穩定");
    } on SocketException catch (_) {
      throw NetworkError("無法連線到網際網路或網路不穩定");
    } catch (e) {
      throw NetworkError(e.toString());
    }

    uri = Uri.parse(account.domain);
    try {
      await http.head(uri)
        .timeout(const Duration(seconds: 8));
    } on TimeoutException catch (_) {
      throw NetworkError("網路不穩定或未使用VPN");
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

    try {
      response = await _copyRequest(request).send();
    } on SocketException catch (_) {
      if (depth > 2) {
        throw RuntimeError("Cannot login");
      }

      await checkConnect();
      logger.e("SocketException occured with ${request.method} ${request.url}");

      if (timestamp.compareTo(account.loginTime) < 0) {
        throw RuntimeError("Login is processing, please resend request");
      }

      account.logout();
      await account.login();

      

      logger.d("Debug depth: ${depth + 1}");
      return _send(_copyRequest(request), depth + 1, timestamp);
    } on HandshakeException catch (_) {
      throw RuntimeError("Unable to locate to the server...");
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