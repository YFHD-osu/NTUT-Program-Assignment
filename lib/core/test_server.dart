import 'dart:io';

import 'package:ntut_program_assignment/core/diff_matcher.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/main.dart';

const String pythonAlias = "python3";

enum CompilerType {
  environment,
  path
}

class Compiler {
  final String name;
  final String version;

  CompilerType get type {
    switch (name) {
      case "c":
        return GlobalSettings.prefs.gccPath == null ? 
          CompilerType.environment : 
          CompilerType.path;

      case "python":
        return GlobalSettings.prefs.pythonPath == null ? 
          CompilerType.environment : 
          CompilerType.path;
    }

    return CompilerType.environment;
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
  // Raw problem string fetch from website
  // final String original;

  // Splitted input, output string parsed from original
  final String input, output;

  bool testing = false;

  // Store test output and error message
  List<String>? testError, testOutput;

  DifferentMatcher? matcher;

  Testcase({
    required this.input,
    required this.output,
    // required this.original
  });

  bool get hasOutput => 
    testOutput != null;

  bool get isPass {
    return output.trim() == testOutput?.join("\n").trim();
  }

  bool get hasError =>
    testError?.isNotEmpty??false;

  void setOutput({List<String>? error, List<String>? output}) {
    testError = error ?? testError;
    testOutput = output ?? testOutput;
    testing = false;

    if (testOutput != null) {
      matcher = DifferentMatcher.trimAndMatch(this.output.split("\n"), testOutput!);
    }
  }

  void resetTestState() {
    testOutput = null;
    testError = null;
    testing = true;
  }

  factory Testcase.parse(String message) {
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

      return Testcase(
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

    return Testcase(
      input: arr[1]
        .replaceFirst("\n", "")
        .trimRight(),
      output: arr
        .last // There are always some <new lines> mark at the begin of the List 
        .replaceFirst("\n", ""), // Replace the first '\n' to empty string 
      // original: message
    );
  }

  factory Testcase.fromMap(Map res) {
    return Testcase(
      input: res["input"],
      output: res["output"]
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "input": input,
      "output": output
    };
  }

  @override
  String toString() {
    return "${MyApp.locale.input}: \n$input \n\n${MyApp.locale.output}:\n$output";
  }
}