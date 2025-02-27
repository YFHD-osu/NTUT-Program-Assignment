import 'dart:io';

import 'dart:async';
import 'package:intl/intl.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class LogToFile {
  static File? _logFile;
  static IOSink? _sink;

  static Future<File> _createFile() async {

    final directory = (await getApplicationSupportDirectory()).path;
    // print(directory);
    final filename = DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now());

    File newfile = File("$directory/logs/$filename.log");

    int index = 0;

    while (await newfile.exists()) {
      index ++;
      newfile = File("$directory/$filename-$index.log");
    }
    
    await newfile.create(recursive: true);
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
      String log = '[ERROR] ${DateTime.now()}: ${details.exceptionAsString()}';
      if (details.stack != null) {
        log += "\n${details.stack.toString()}";
      }
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
      final trace = prettyPrinter.formatStackTrace(StackTrace.current, 6);

      if (trace != null) {
        messages.addAll(
          trace
          .split("\n")
        );
      }
      
    }
    return messages;
  }

}

class FileLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      // debugPrint(line); // 輸出到 Console
      LogToFile._writeLog(line);
    }
  }
}

class AlwaysLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
  
}