import 'dart:io';

import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class FileOutput extends LogOutput {
  FileOutput();

  late final File file;

  @override
  void output(OutputEvent event) async {
    for (var line in event.lines) {
      debugPrint(line.toString());
      await file.writeAsString("${line.toString()}\n", mode: FileMode.writeOnlyAppend);
    }
  }

  Future<void> initialize(String path) async {
    final filename = DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now());
    File newfile = File("$path/$filename.log");

    int index = 0;
    while (await newfile.exists()) {
      index ++;
      newfile = File("$path/$filename-$index.log");
    }

    file = await newfile.create(recursive: true);
  }
}