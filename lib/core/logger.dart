import 'dart:io';

import 'dart:async';
import 'package:intl/intl.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:logger/logger.dart';

class LogToFile {
  static File? _logFile;
  static IOSink? _sink;

  static Future<File> _createFile() async {
    final directory = Directory.current.path;
    final filename = DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now());

    File newfile = File("$directory/logs/$filename.log");

    int index = 0;

    while (await newfile.exists()) {
      index ++;
      newfile = File("$directory/$filename-$index.log");
    }

    return newfile;
  }

  static Future<void> initialize() async {
    _logFile = await _createFile();
    _sink = _logFile!.openWrite(mode: FileMode.append);

    // 攔截 `print()`，讓 `print` 也能寫入檔案
    debugPrint = (String? message, {int? wrapWidth}) {
      final log = '$message';
      _writeLog(log);
    };

    // 攔截 Flutter 內部的錯誤
    FlutterError.onError = (FlutterErrorDetails details) {
      final log = '[ERROR] ${DateTime.now()}: ${details.exceptionAsString()}\n${details.stack}';
      _writeLog(log);
    };

    // // 攔截所有未捕獲的異常（例如 `throw Exception()`）
    // runZonedGuarded(() {
    //   ;
    // }, _onException);
  }

  // static void _onException(Object error, StackTrace stackTrace) {
  //   final log = '[ZONE ERROR] ${DateTime.now()}: $error\n$stackTrace';
  //   _writeLog(log);
  // }

  static void _writeLog(String message) {
    _sink?.writeln(message);
    stdout.writeln(message); // 仍然顯示在 console
  }

  static Future<void> close() async {
    await _sink?.flush();
    await _sink?.close();
  }
}

class Printer extends LogPrinter {
  final Map<Level, String> map = {
    Level.debug: "DEBUG",
    Level.error: "ERROR",
    Level.fatal: "FETAL",
    Level.info: "INFO",
    Level.warning: "WARNNING"
  };

  static const List<Level> logTrace = [
    Level.debug,
    Level.error,
    Level.fatal
  ];

  final prettyPrinter = PrettyPrinter();

  @override
  List<String> log(LogEvent event) {
    final prefix = map[event.level];
    final ts = DateFormat('HH:mm:ss').format(event.time);

    final messages = ["[$prefix] [$ts] ${event.message}"];


    if (logTrace.contains(event.level)) {
      messages.addAll(
        prettyPrinter.formatStackTrace(StackTrace.current, 6)
        .toString()
        .split("\n")
      );
    }
    return messages;
  }

}

class DebugPrintOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      debugPrint(line); // 用 debugPrint() 而非 print()
    }
  }
}