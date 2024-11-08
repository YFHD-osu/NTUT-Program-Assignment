import 'dart:async';

import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/core/database.dart';
import 'package:ntut_program_assignment/main.dart' show logger;

enum GlobalEvent {
  accountSwitch
}

class GlobalSettings {
  // The account that current using
  static Account? account;

  static final update = StreamController<GlobalEvent>();
  static final stream = update.stream.asBroadcastStream();

  static final prefs = Preferences();

  static bool get isLogin =>
    account != null ;

  static Future<void> login(Account acc) async {
    await acc.login();
    logger.d("Logged in with session: ${acc.username}");
    account = acc;
    update.sink.add(GlobalEvent.accountSwitch);
  }

  static void logout() {
    account = null;
    update.sink.add(GlobalEvent.accountSwitch);
  }

  static void _autoLogin() async {
    final db = Database(name: "accounts");
    await db.initialize();
    final acc = await db.get(prefs.autoLogin!);
    if (acc == null) {
      logger.e("Account with id: ${prefs.autoLogin} does not exists");
      return;
    }
    
    try {
      login(Account.fromMap(acc));
    } catch (e) {
      logger.e(e.toString());
    }
    

  }

  static Future<void> initialize() async {
    await prefs.initialize();

    if (prefs.autoLogin != null) {
      _autoLogin();
    }


  }
}
