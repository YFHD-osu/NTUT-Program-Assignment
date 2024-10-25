import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:beautiful_soup_dart/beautiful_soup.dart';

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

enum GlobalEvent {
  accountSwitch
}

class GlobalSettings {
  // The account that current using
  static Account? account;

  static final update = StreamController<GlobalEvent>();
  static final stream = update.stream.asBroadcastStream();

  static bool get isLogin =>
    account != null ;

  static Future<void> login(Account acc) async {
    await acc.login();
    logger.d("Logged in with session: ${acc.sessionID}");
    account = acc;
    update.sink.add(GlobalEvent.accountSwitch);
  }

  static void logout() {
    account = null;
    update.sink.add(GlobalEvent.accountSwitch);
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
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
  };

  Future<void> login() async {
    final payload = {
      "name": username,
      "passwd": password,
      "rdoCourse": course.toString()
    };
    final uri = Uri.parse("$domain/upload/Login");

    final headResp = await http.get(uri);
    sessionID = headResp.headers['set-cookie']
      .toString()
      .split(" ")
      .first
      .replaceAll(";", "");

    final response = await http.post(uri, body: payload, headers: headers);

    BeautifulSoup bs = BeautifulSoup(response.body);
    final loginBox = bs.find("div", class_: "login-box");
    
    // If the login box still exist, means that login failed
    if (loginBox != null) {
      final error = bs.find("h4", class_: "card-title"); 
      throw Exception(error?.text??"");
    }

    late final http.Response menuResp;

    final menuUri = Uri.parse("$domain/upload/TopMenu");

    try { // TODO: Cencer here
      menuResp = await http.get(menuUri, headers: headers);
    } on http.ClientException catch (_) {
      return;
    }

    bs = BeautifulSoup(menuResp.body);
    final studentName = bs.find("div", class_: "content");
    name = studentName!.text.replaceAll(" ", "").split("\n")[1];    
  }

  void logout() => sessionID = null;

  static Future<List<String>> fetchCourse(bool isOdd) async {
    final uri = Uri.parse("${isOdd ? defaultDomain[0]: defaultDomain[1]}/upload/Login");
    final response = await http.get(uri);
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

class HomeworkRuntimeError {
  final String message;

  HomeworkRuntimeError(this.message);
}

class Testcase {
  final String input, output;
  final String original;

  Testcase({
    required this.input,
    required this.output,
    required this.original
  });

  factory Testcase.parse(String message) {
    final regExp = RegExp(r"輸(入|出).+");

    final arr = message.split(regExp);
    if (arr.length < 3) {
      throw HomeworkRuntimeError("Cannot parse testcase: $message");
    }

    return Testcase(
      input: arr[1].trim(),
      output: arr[2].trim(), 
      original: message
    );
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

  bool _deleting = false;
  bool _submitting = false;

  bool get isPass =>
    status == "通過";

  HomeworkState get state {
    if (_submitting) {
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
      throw HomeworkRuntimeError("無法獲取作業詳細資料，猜測作業不存在");
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
      throw HomeworkRuntimeError("Cannot fetch success list, not login ?");
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
      throw HomeworkRuntimeError("Failed to delete homework");
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
    if (!await file.exists()) {
      throw HomeworkRuntimeError("File is not exists");
    }

    final account = GlobalSettings.account!;

    _submitting = true;

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
    _submitting = false;

    if (response.statusCode != 200) {
      throw HomeworkRuntimeError(response.reasonPhrase.toString());
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

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    late final http.StreamedResponse response;
    try {
      response = await _copyRequest(request).send();
    } on SocketException catch (_) {
      GlobalSettings.account?.sessionID = "";
      await GlobalSettings.account?.login();
      return await send(request);
    } on HandshakeException catch (_) {
      throw HomeworkRuntimeError("Unable to locate to the server...");
    }

    return response;
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final newHeader = _headers;
    newHeader.addAll(headers??{});
    
    return await super.get(url, headers: newHeader);
  }

  Future<http.Response> _get(String url, {Map<String, String>? headers}) async {
    final newHeader = _headers;
    newHeader.addAll(headers??{});
    
    final uri = Uri.parse("${account.domain}/upload$url");
    return await super.get(uri, headers: newHeader);
  }

  @override
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final newHeader = _headers;
    newHeader.addAll(headers??{});
    
    return await super.get(url, headers: newHeader);
  }

}