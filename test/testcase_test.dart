import 'package:flutter_test/flutter_test.dart';
import 'package:ntut_program_assignment/core/test_server.dart';

void main() async {
  test('Check python is in environment', () async {
    await TestServer.findPython();
    expect(TestServer.pythonOK, true);
  });
  
}