import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';

import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/main.dart' show MyApp, logger;
import 'package:ntut_program_assignment/models/api_model.dart';
import 'package:ntut_program_assignment/models/diff_model.dart';

const String pythonAlias = "python3";

enum CompilerSource {
  environment,
  path
}

enum CodeType {
  python,
  c
}

class Compiler {
  final String name;
  final String version;

  CompilerSource get type {
    switch (name) {
      case "c":
        return GlobalSettings.prefs.gccPath == null ? 
          CompilerSource.environment : 
          CompilerSource.path;

      case "python":
        return GlobalSettings.prefs.pythonPath == null ? 
          CompilerSource.environment : 
          CompilerSource.path;
    }

    return CompilerSource.environment;
  }

  Compiler({
    required this.name,
    required this.version
  });
}

class TestServer {
  static Compiler? gccState;
  static Compiler? pythonState;

  static bool get gccOK => gccState != null;
  static bool get pythonOK => pythonState != null;

  static Future<void> initialize() async {
    await findGCC();
    await findPython();
  }

  static Future<void> findPython() async {
    late final ProcessResult result;

    try {
      result = await Process.run(
        GlobalSettings.prefs.pythonPath ?? pythonAlias, ["--version"],
      );
    } catch (e) {
      logger.e(e.toString());
      return;
    }

    if (result.stderr.toString().isNotEmpty) {
      pythonState = null;
      return;
    }

    final exp = RegExp(r"Python \d\.\d+\.\d+");

    if (!exp.hasMatch(result.stdout)) {
      pythonState = null;
      return;
    }

    pythonState = Compiler(
      name: "python",
      version: exp.firstMatch(result.stdout)!.group(0)!
    );

    return; 
  }

  static Future<void> findGCC() async {
    late final ProcessResult result;
    
    final path = GlobalSettings.prefs.gccPath ?? "gcc";
    try {
      result = await Process.run(path, ["--version"]);
    } catch (e) {
      logger.e("Failed to find GCC compiler in path: $path \n $e");
      gccState = null;
      return;
    }

    if (result.stderr.toString().isNotEmpty) {
      gccState = null;
      logger.e("GCC output a error message; ${result.stderr.toString()}");
      return;
    }

    final exp = RegExp(r"(gcc|Apple clang)(.+) \d+.\d+.\d+");

    if (!exp.hasMatch(result.stdout)) {
      gccState = null;
      logger.e(result.stdout);
      return;
    }
    
    gccState = Compiler(
      name: "c",
      version: exp.firstMatch(result.stdout)!.group(0)!
    );
  }

  static Future<bool> checkGCCAvailable(File compiler) async {
    if (! await compiler.exists() ) {
      return false;
    }
    
    final origPath = GlobalSettings.prefs.gccPath;

    GlobalSettings.prefs.gccPath = compiler.path;
    await findGCC();

    if (gccOK) {
      return true;
    }

    GlobalSettings.prefs.gccPath = origPath; 
    return false;
  }

  static Future<bool> checkPythonAvailable(File compiler) async {
    if (! await compiler.exists() ) {
      return false;
    }

    final origPath = GlobalSettings.prefs.pythonPath;

    GlobalSettings.prefs.pythonPath = compiler.path;
    await findPython();

    if (pythonOK) {
      return true;
    }

    GlobalSettings.prefs.pythonPath = origPath; 
    return false;
  }
}

class Testcase {
  final List<Case> cases;
  final CodeType codeType;

  File? testFile;

  Testcase({
    required this.cases,
    required this.codeType
  });

  List<String> get allowedExtensions {
    switch (codeType) {
      case CodeType.c:
        return ["c"];

      case CodeType.python:
        return ["py"];
    }
  }

  bool get anyTestRunning =>
    cases.any((e) => e.testing);

  bool get isAllTesting =>
    cases.every((e) => e.testing);

  Future<void> testAll(File target, CodeType type) async {
    late final File exec;

    try {
      exec = await compile(target, type);

      for (int i=0; i<cases.length; i++) {
        await test(exec, i, type);
      }
    } catch (e) {
      _writeErrorToTestcase(e, 0);
      rethrow;
    }
  }

  Future<File> compile(File target, CodeType type) async {
    if (!await target.exists()) {
      throw TestException(MyApp.locale.file_not_found);
    }

    switch (type) {
      case CodeType.python:
        // Pyton don't need to compile, return source code as the executable 
        return target;

      case CodeType.c:
        return await _compileC(target);
    }
  }

  Future<void> compileAndTest(File target, int index, CodeType type) async {
    try {
      final exec = await compile(target, type);
      logger.i("Compile complete. (${exec.path})");
      await test(exec, index, type);
    } catch (e) {
      _writeErrorToTestcase(e, index);
    }
  }

  Future<void> test(File target, int index, CodeType type) async {
    // if (!await target.exists()) {
    //   throw TestException(MyApp.locale.file_not_found);
    // }

    switch (type) {
      case CodeType.python:
        await _testPython(target, index);

      case CodeType.c:
        await _testC(target, index);
    }

  }

  Future<void> _testPython(File target, int index) async {
    if (!TestServer.pythonOK) {
      throw RuntimeError("Python ${MyApp.locale.testcase_environment_not_setup}");
    }

    late final Process process;

    try {
      process = await Process.start(GlobalSettings.prefs.pythonPath ?? "python", [target.path]);
    } catch (e) {
      cases[index].testError = ["${MyApp.locale.testcase_file_failed_to_execute} $e"];
      return;
    }    

    for (var line in cases[index].input.split("\n")) {
      // print("Feeding: $line");
      process.stdin.write(line);
      process.stdin.write(ascii.decode([10]));
    }

    await process.exitCode
      .timeout(const Duration(seconds: 10));

    if (await process.exitCode != 0) {
      cases[index].testing = false;
      return;
    }

    process.kill();

    final out = await process.stdout
      .map((e) => utf8.decode(e))
      .toList();

    final err = await process.stderr
      .map((e) => utf8.decode(e))
      .toList();

    cases[index].setOutput(
      error: err,
      output: out.firstOrNull
        ?.split("\n")
        .map((e) => e.replaceAll(ascii.decode([13]), ""))
        .toList() ?? []
    );

    return;
  }

  Future<File> _compileC(File target) async {
    late final Process compile;

    final filename = target.uri.pathSegments.last.split(".").first;

    final compileDir = "${(await getApplicationSupportDirectory()).path}/build";

    logger.d("Start compiling ${target.path}");

    compile = await Process.start(
      GlobalSettings.prefs.gccPath ?? "gcc",
      [target.path, '-o', '$compileDir/$filename']
    );

    // Listen to the stream to prevent compile timeout while gcc throw warning
    // (Make no sense, and linux works without listening them) 
    compile.stdout.asBroadcastStream().listen((data) {
      logger.d("[Compile STDOUT] ${utf8.decode(data)}");
    });

    compile.stderr.asBroadcastStream().listen((data) {
      logger.d("[Compile STDERR] ${utf8.decode(data)}");
    });

    await compile.exitCode
      .timeout(const Duration(seconds: 10));
    
    logger.d("Compile complete (${target.path})");
    final exitCode = await compile.exitCode;
    compile.kill();

    if (exitCode != 0) {
      final err = await compile.stderr
        .map((e) => utf8.decode(e))
        .toList();

      logger.e("failed to compile: ${target.path} \n$err");
      throw RuntimeError(
        "${MyApp.locale.testcase_program_error_with}\n"
        "${err.join('\n')}\n"
        "The program exited with code $exitCode"
      );
    } 

    return File('$compileDir/$filename');
  }

  Future<void> _testC(File target, int index) async {
    if (!TestServer.gccOK) {
      throw RuntimeError("C ${MyApp.locale.testcase_environment_not_setup}");
    }
    
    final process = await Process.start(target.path, []);

    for (var line in cases[index].input.split("\n")) {
      process.stdin.write(line);
      process.stdin.write(ascii.decode([10]));
    }

    Future<int> killAndExit(Object? e, StackTrace s) async {
      process.kill();
      return 0;
    }

    late final List<String> out, err;

    try {
      out = await process.stdout
        .timeout(const Duration(seconds: 10))
        .map((e) => utf8.decode(e))
        .toList();

      err = await process.stderr
        .timeout(const Duration(seconds: 10))
        .map((e) => utf8.decode(e))
        .toList();

    } catch (e) {
      process.kill();
      rethrow;
    }

    process.kill();

    await process.exitCode
      .timeout(const Duration(seconds: 10))
      .onError(killAndExit);
    
    cases[index].setOutput(
      error: err,
      output: out.firstOrNull
        ?.split("\n")
        .map((e) => e.replaceAll(ascii.decode([13]), ""))
        .toList() ?? []
    );

    return;
  }

  void _writeErrorToTestcase(Object? error, int index) {
    switch (error) {
      case TimeoutException():
        cases[index].setOutput(
          error: [MyApp.locale.testcase_timeout]
        );
        throw TestException(MyApp.locale.testcase_timeout);
      
      case OSError():
        cases[index].setOutput(
          error: ["${MyApp.locale.testcase_invalid_test_file} ${error.message}"]
        );

      case Exception():
        cases[index].setOutput(
          error: ["$error"]
        );

      case TestException():
        cases[index].setOutput(
          error: [error.message]
        );

      default:
        cases[index].setOutput(
          error: ["${MyApp.locale.testcase_file_failed_to_execute} $error"]
        );
    }
  }

  factory Testcase.parse(List<String> ctx, int index, int start, CodeType codeType) {
    late String message;
    bool parseError = false;

    final List<Case> testCases = [];

    while (index < ctx.length) {
      if (!ctx[index].contains(RegExp(r"【測試資料.+】"))) {
        index++;
        continue;
      }

      message = ctx.sublist(start, index)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join("\n");

      try {
        final data = Case.parse(
          ctx.sublist(start, index)
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .join("\n")
        );
        testCases.add(data);
      } on RuntimeError catch (e) {
        logger.d(e);
        continue;
      } catch (e) {
        logger.e("Cannot parse testcase for homework, message:\n$message");
        parseError = true;
      } finally {
        start = index + 1;
        index++;
      }
    }

    message = ctx.sublist(start, index)
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .join("\n");

    try {
      final data = Case.parse(
        message
      );
      testCases.add(data);
    } on RuntimeError catch (e) {
      logger.d(e);
    } catch (e) {
      logger.e("Cannot parse testcase for homework, message:\n$message");
      parseError = true;
    }

    if (parseError) {
      throw RuntimeError("Failed to parse some testcase(s)");
    }

    return Testcase(
      cases: testCases,
      codeType: codeType
    );
  }

  factory Testcase.fromMap(Map res) {
    return Testcase(
      cases: List<Map>
        .from(res["cases"])
        .map((e) => Case.fromMap(e))
        .toList(),
      codeType: CodeType.values[res["codeType"]]
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "cases": cases
        .map((e) => e.toMap())
        .toList(),
      "codeType": codeType.index
    };
  }
}

class Case {
  // Raw problem string fetch from website
  // final String original;

  // Splitted input, output string parsed from original
  final String input, output;

  bool testing = false;

  // Store test output and error message
  List<String>? testError, testOutput;

  DifferentMatcher? matcher;

  Case({
    required this.input,
    required this.output
    // required this.original
  });

  bool _isPassCheck(List<String> output, List<String> answer) {
    if (output.length != answer.length) {
      return false;
    }

    return List
      .generate(output.length, (e) => e)
      .every((i) => output[i].trimRight() == answer[i].trimRight());
  }

  bool get hasOutput => 
    testOutput != null;

  bool isPass = false;

  bool get hasError =>
    testError?.isNotEmpty??false;

  void setOutput({List<String>? error, List<String>? output}) {
    testError = error ?? testError;
    testOutput = output ?? testOutput;
    testing = false;

    if (testOutput != null) {
      matcher = DifferentMatcher.trimAndMatch(this.output.split("\n"), testOutput!);
    }

    isPass = _isPassCheck(
      this.output.split("\n"),
      testOutput??[]
    );
  }

  void resetTestState() {
    testOutput = null;
    testError = null;
    testing = true;
  }

  factory Case.parse(String message) {
    // Handle the case that the message doesn't contains the input and output title
    // These conditions only happened while TA froget to type those word ;D
    if (!message.contains("輸入") || !message.contains("輸出")) {
      final arr = message.split("\n");

      int index = 0; 
      int start = 0;

      // Fetch the input data, skip the 
      while (index < arr.length) {
        if (arr[index].trim().isNotEmpty && !arr[index].contains("輸出")) {
          index++;
          continue;
        }

        break;
      }

      final input = arr.sublist(start, index);

      index ++;
      start = index;

      // Fetch the input data, skip the 
      while (index < arr.length) {
        if (arr[index].trim().isNotEmpty) {
          index++;
          continue;
        }

        start = index;
        break;
      }

      final output = arr.sublist(start, index);

      return Case(
        input: input.join("\n"),
        output: output.join("\n"),
        // original: message
      );
    }

    final regExp = RegExp(r"輸(入|出).+");

    final arr = message.split(regExp);
    if (arr.length < 3) {
      logger.e("Cannot parse testcase: $message");
      throw Exception(MyApp.locale.runtime_error_testcase_parse_failed);
    }

    return Case(
      input: arr[1]
        .replaceFirst("\n", "")
        .trimRight(),
      output: arr
        .last // There are always some <new lines> mark at the begin of the List 
        .replaceFirst("\n", ""), // Replace the first '\n' to empty string 
      // original: message
    );
  }

  factory Case.fromMap(Map res) {
    return Case(
      input: List<String>
        .from(res["input"])
        .join("\n"),
      output: List<String>
        .from(res["output"])
        .join("\n")
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "input": input.split("\n"),
      "output": output.split("\n")
    };
  }

  @override
  String toString() {
    return "${MyApp.locale.input}: \n$input \n\n${MyApp.locale.output}:\n$output";
  }
}

class TestException {
  final String message;

  TestException(this.message);

  @override
  String toString() => message;
}