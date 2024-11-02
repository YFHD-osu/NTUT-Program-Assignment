import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

import 'package:ntut_program_assignment/core/api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ntut_program_assignment/core/global.dart';

var logger = Logger(
  printer: PrettyPrinter()
);

void main() async {
  await dotenv.load(fileName: ".env");
  String username = dotenv.env['USERNAME']!;
  String password = dotenv.env['PASSWORD']!;

  // Accept bad certificate
  HttpOverrides.global = DevHttpOverrides();
  
  final account = Account(
    course: 1,
    username: username,
    password: password
  );

  test('Account fetch courses test', () async {
    final resp = await Account.fetchCourse(false);
    expect(resp, ["113PD01", "computerprogramming"]);
  });
  
  test('Account success login test', () async {
    await GlobalSettings.login(account);
    expect(account.isLogin, true);
  });

  GlobalSettings.account = account;

  test('Account wrong username test', () async {
    final acc = Account(
      course: 1,
      username: "112334456",
      password: "1234567812345678912345678" 
    );

    String errMsg = "";
    
    try {
      await acc.login();
    } catch (e) {
      errMsg = e.toString();
    }

    expect(acc.isLogin, false);
    expect(errMsg.contains("查無此人"), true);
  });

  test('Account wrong password test', () async {
    final acc = Account(
      course: 1,
      username: username,
      password: "1234567812345678912345678" 
    );
    
    String errMsg = "";

    try {
      await acc.login();
    } catch (e) {
      errMsg = e.toString();
    }
    
    expect(acc.isLogin, false);
    expect(errMsg.contains("密碼錯誤"), true);
  });

  List<Homework> hws = [];
  test('Fetch homework list', () async {
    hws = await account.fetchHomeworkList();
    expect(hws.length, 15);
  });

  test('Fetch homework details', () async {
    await hws.first.fetchHomeworkDetail();
    logger.i(hws.first.description);

    expect(hws.first.description != null, true);
  });

  test('Fetch success list', () async {
    final success = await hws.first.fetchPassList();
  
    expect(success.runtimeType, List<String>);
  });

  test('Fetch test case result', () async {
    final success = await hws.first.fetchTestcases();
  
    expect(success.runtimeType, List<CheckResult>);
  });

  test('Delete homework', () async {
    await hws.last.delete();
  });

}