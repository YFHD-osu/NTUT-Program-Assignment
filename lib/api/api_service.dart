import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart'; // For HTML parsing
import 'package:html/dom.dart'; // For working with the DOM structure
import 'package:beautiful_soup_dart/beautiful_soup.dart';

import 'package:ntut_program_assignment/main.dart' show MyApp, logger;
import 'package:ntut_program_assignment/models/api_model.dart';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(final SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
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

class Account {
  int course;
  String courseName;
  String username, password;
  String? sessionID, name;

  bool isLoggingIn = false;

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

  Future<void> _login() async {
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

  Future<void> login() async {
    isLoggingIn = true;

    try {
      await _login();
    } catch (e) {
      isLoggingIn = false;
      rethrow;
    }

    isLoggingIn = false;
  }

  void logout() => 
    sessionID = null;

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

  Future<List<UserComment>> fetchMsgBoard() async {
    final response = await client._get("/MessageBoard");

    BeautifulSoup bs = BeautifulSoup(response.body);
    final comemnts = bs.find("div", class_: "ui comments");

    return comemnts!.children
      .where((e) => e.className == "comment")
      .map((e) => UserComment.parse(e))
      .toList();
  }

  String _htmlToPlainText(String html) {
    // Parse the HTML string
    Document document = parse(html);

    // Initialize an empty result string
    String result = '';

    // Traverse all child nodes in <body>
    for (Node node in document.body!.nodes) {
      if (node is Element) {
        if (node.localName == 'img') {
          // If the tag is named <img>, fetch it's url
          String? imgUrl = node.attributes['src'];
          if (imgUrl != null) {
            result += "<img src='$imgUrl'>";
          }
        } else {
          // Parse other tags as plain text
          result += node.text;
        }
      } else if (node is Text) {
        // For plain text, append them to the end of the result
        result += node.text;
      }
    }

    return result;
  }

  Future<List<String>> fetchHomeworkDetail(String hwId) async {
    final resp = await client._get("/showHomework?hwId=$hwId");

    if (resp.statusCode == 500) {
      logger.e("Cannot fetch homework details, status code :${resp.statusCode}");
      throw RuntimeError(MyApp.locale.runtime_error_homework_not_found);
    }

    BeautifulSoup bs = BeautifulSoup(resp.body);
    final hwDesc = bs.find("span")!;

    // print(number);
    return _htmlToPlainText(hwDesc.innerHtml).split("\n");
  }

  Future<List<String>> fetchPassList(String hwId) async {
    final resp = await client._get("/success.jsp?HW_ID=$hwId");

    BeautifulSoup bs = BeautifulSoup(resp.body);

    final table = bs.find("table", class_: "table");
    
    final tr = table?.children.first.children;

    if (tr == null) {
      // If account being logout, the table will not shown
      // So try re-login and try again

      if (isLoggingIn) {
        await Future
          .doWhile(() => isLoggingIn)
          .timeout(Duration(seconds: 15));
      } else {
        await login();
      }

      return await fetchPassList(hwId);
    }

    return tr
      .map((e) => e.text.trim())
      .where((e) => e != "學號")
      .toList();
  }

  Future<CheckResult> fetchTestcases(String hwId) async {
    final resp = await client._get("/CheckResult?questionID=$hwId&studentID=$username");

    BeautifulSoup bs = BeautifulSoup(utf8.decode(resp.bodyBytes));

    return CheckResult.fromSoup(bs);
  }

  Future<void> delete(String hwId) async {
    // Orign upload endpoints: /delHw?title=$hwId&l=$language
    final resp = await client._get("/delHw?title=$hwId");

    if (resp.statusCode != 200) {
      throw RuntimeError("Failed to delete homework");
    }
  }

  // 
  Future<void> _prefetch(String hwId, String language) async {
    /*
    Login (Ref: "https://140.124.181.25/upload/Login")
      -> MainMenu
        -> DownMenu, TopMenu
          -> HomeworkBoard (TopMenu)
            -> ${account.domain}/upload/upLoadHw?hwId=$number&l=$language
              -> Final UPLOAD 
    */
    await client._get("/MainMenu", headers: {
      "Referer": "$domain/upload/Login"
    });
    
    await client._get("/DownMenu", headers: {
      "Referer": "$domain/upload/MainMenu"
    });

    await client._get("/TopMenu", headers: {
      "Referer": "$domain/upload/MainMenu"
    });

    await client._get("/HomeworkBoard", headers: {
      "Referer": "$domain/upload/TopMenu"
    });

    await client._get("/upLoadHw?hwId=$hwId&l=$language", headers: {
      "Referer": "$domain/upload/HomeworkBoard"
    });

    return;
  }

  // Ensure each character in filename is legal
  String _convertToLegalFilename(String filename, String defaultName) {
    final extension = filename.split(".").last;

    String result = filename.replaceAll(RegExp(r'[^A-Za-z0-9_.]'), '');
    if (result.isEmpty) {
      return "$defaultName.$extension";
    }

    return result;
  }

  Future<void> upload(String hwId, String language, List<int> bytes, String filename) async {
    logger.d("Upload prefetching with session: $sessionID");

    // This endpoint must be GET before any homework upload
    await _prefetch(hwId, language);
    
    logger.d("Upload homework prefetch completed.");

    final headers = client._headers;
    headers.addAll({
      "Referer": "$domain/upload/upLoadHw?hwId=$hwId&l=$language",
      'Content-Type': 'multipart/form-data',
    });

    var request = http.MultipartRequest(
      'POST', Uri.parse('$domain/upload/upLoadFile')
    );

    request.files.add(http.MultipartFile.fromBytes(
      'hwFile',
      bytes, 
      filename: _convertToLegalFilename(filename, hwId))
    );

    // request.headers.addAll(account.headers);
    request.headers.addAll(headers);

    logger.d("Start uploading file to server");

    await request
      .send()
      .timeout(const Duration(seconds: 15));

    logger.d("Upload process ends");
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