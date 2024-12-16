import 'dart:io';

class TestServer {
  static bool gccState = false;
  static bool pythonState = false;

  static Future<bool> findPython() async {
    final result = await Process.run("python", ["--version"]);

    if (result.stderr.toString().isNotEmpty) {
      return false;
    }

    final exp = RegExp(r"Python \d\.\d+\.\d+");
    return pythonState = exp.hasMatch(result.stdout);
  }

  static Future<bool> findGCC() async {
    final result = await Process.run("gcc", ["--version"]);

    if (result.stderr.toString().isNotEmpty) {
      return false;
    }

    final exp = RegExp(r"clang version \d+\.\d+\.\d+");
    return gccState = exp.hasMatch(result.stdout);
  }
}