import 'package:flutter_test/flutter_test.dart';
import 'package:ntut_program_assignment/core/test.dart';

void main() async {
  final server = TestServer();
  
  test('Account fetch courses test', () async {
    final resp = await TestServer.fetchAllPython();
    expect(resp, ["113PD01", "computerprogramming"]);
  });
  
}