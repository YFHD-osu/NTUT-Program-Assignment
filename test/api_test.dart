import 'dart:io';
import 'package:logger/logger.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/main.dart' show logger;

void main() async {
  logger = Logger(
    printer: PrettyPrinter()
  );

  // await dotenv.load(fileName: "./.env");
  String username = const String.fromEnvironment('USERNAME');
  String password = const String.fromEnvironment('PASSWORD');

  // Accept bad certificate
  HttpOverrides.global = DevHttpOverrides();
  
  final account = Account(
    course: 1,
    username: username,
    password: password
  );

  test('Account fetch courses test', () async {
    final resp = await Account.fetchCourse(false);
    expect(resp, ["113PD01", "PD_summer2024"]);
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
      logger.e(errMsg);
    }

    // expect(acc.isLogin, false);
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
    
    // expect(acc.isLogin, false);
    expect(errMsg.contains("密碼錯誤"), true);
  });

  List<Homework> hws = [];
  test('Fetch homework list', () async {
    hws = await account.fetchHomeworkList();
    expect(hws.length, 20);
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
  }, skip: true);

  test('Fetch handded in homework', () async {
    final resp = await account.fetchHanddedHomeworks();
    logger.i(resp.first.id);
    expect(resp.runtimeType, List<HomeworkStatus>);
  });

  test('Fetch handded in homework', () async {
    // final resp = await account.fetchScores();
    // expect(resp.runtimeType, List);
  });

  

}