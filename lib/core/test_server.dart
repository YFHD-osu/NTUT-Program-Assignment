import 'dart:io';

class TestServer {
  static Future<bool> findPython() async {
    final result = await Process.run("python", ["--version"]);

    if (result.stderr.toString().isNotEmpty) {
      return false;
    }

    final exp = RegExp(r"Python \d\.\d+\.\d+");
    return exp.hasMatch(result.stdout);

  }  
}