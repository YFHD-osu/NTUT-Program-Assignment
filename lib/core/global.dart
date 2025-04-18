import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';

import 'package:ntut_program_assignment/router.dart';
import 'package:ntut_program_assignment/core/database.dart';
import 'package:ntut_program_assignment/api/api_service.dart';
import 'package:ntut_program_assignment/main.dart' show MyApp, logger;

enum GlobalEvent {
  refreshHwList,

  // Refresh homework state, (Used while homework upload complete)
  setHwState,
}

class GlobalSettings {
  // The account that current using
  static Account? account;

  static final update = StreamController<GlobalEvent>();
  static final stream = update.stream.asBroadcastStream();

  static final prefs = Preferences();
  static final route = RouterController(root: "hwList");

  static bool get isLogin =>
    account != null ;

  static Future<void> login(Account acc) async {
    await acc.login();
    
    logger.i("Logged in with user: ${acc.username}");
    account = acc;
    update.sink.add(GlobalEvent.refreshHwList);
  }

  static void logout() {
    account = null;
    update.sink.add(GlobalEvent.refreshHwList);
  }

  static void autoLogin() async {
    if (prefs.autoLogin == null) {
      logger.i("No auto login account found!");
      return;
    }
    
    final db = Database(name: "accounts");
    await db.initialize();
    final acc = await db.get(prefs.autoLogin!);

    if (acc == null) {
      logger.e("Account with id: ${prefs.autoLogin} does not exists");
      update.sink.add(GlobalEvent.refreshHwList);
      return;
    }

    account = Account.fromMap(acc);
    account!.isLoggingIn = true;
    update.sink.add(GlobalEvent.setHwState);

    try {
      await GlobalSettings.login(account!);
    } catch (e) {
      logger.e(e.toString());
      MyApp.showToast("無法自動登入", e.toString(), InfoBarSeverity.error);
    } finally {
      update.sink.add(GlobalEvent.refreshHwList);
    }
  }

  static Future<void> initialize() async {
    await prefs.initialize();
  }
}