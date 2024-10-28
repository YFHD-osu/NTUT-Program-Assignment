import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TestException {
  final String message;

  TestException(this.message);
}

class TestResult {
  final List<String> error, output;

  TestResult({
    required this.error,
    required this.output
  });

}

class ProgramTest {
  final File target;
  final String input;
  final Duration timeout;

  ProgramTest({
    required this.target,
    required this.input,
    this.timeout = const Duration(seconds: 10)
  });

  Future<TestResult> exec() async {
    if (!await target.exists()) {
      throw TestException("指定的測試檔案不存在");
    }

    final process = await Process.start("python", [target.path]);

    for (var line in input.split("\n")) {
      process.stdin.write(line);
      process.stdin.write(ascii.decode([10]));
    }

    try {
      await process.exitCode
        .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (_) {
      process.kill();
      throw TestException("測試時間超時，已強制結束");
    }

    final out = await process.stdout
      .map((e) => utf8.decode(e).trim())
      .toList();

    final err = await process.stderr
      .map((e) => utf8.decode(e).trim())
      .toList();
      
    return TestResult(
      error: err,
      output: out,
    );
  }
}

void main() async {

  final code = File(r"path_to_file");
  final test = ProgramTest(
    target: code,
    input: "3 6 1 5 8\n9"
  );

  final result = await test.exec();
  
  (result.error);
  (result.output);
}