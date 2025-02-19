import 'dart:io';

import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/main.dart';

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
        GlobalSettings.prefs.pythonPath ?? "python", ["--version"],
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
    final result = await Process.run(GlobalSettings.prefs.gccPath ?? "gcc", ["--version"]);

    if (result.stderr.toString().isNotEmpty) {
      gccState = null;
      return;
    }

    final exp = RegExp(r"gcc (.+) \d+.\d+.\d+");

    if (!exp.hasMatch(result.stdout)) {
      gccState = null;
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