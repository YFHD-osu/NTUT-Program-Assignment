import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/core/database.dart';
import 'package:ntut_program_assignment/main.dart' show MyApp, logger;
import 'package:toastification/toastification.dart';

enum GlobalEvent {
  refreshHwList,

  // Refresh homework state, (Used while homework upload complete)
  setHwState,
}

class GlobalSettings {
  // The account that current using
  static Account? account;

  static bool isLoggingIn = false;
  static final update = StreamController<GlobalEvent>();
  static final stream = update.stream.asBroadcastStream();

  static final prefs = Preferences();

  static bool get isLogin =>
    account != null ;

  static Future<void> login(Account acc) async {
    await acc.login();
    
    logger.d("Logged in with session: ${acc.username}");
    account = acc;
    update.sink.add(GlobalEvent.refreshHwList);
  }

  static void logout() {
    account = null;
    update.sink.add(GlobalEvent.refreshHwList);
  }

  static void _autoLogin() async {
    final db = Database(name: "accounts");
    await db.initialize();
    final acc = await db.get(prefs.autoLogin!);
    if (acc == null) {
      logger.e("Account with id: ${prefs.autoLogin} does not exists");
      isLoggingIn = false;
      update.sink.add(GlobalEvent.refreshHwList);

      return;
    }

    isLoggingIn = true;
    update.sink.add(GlobalEvent.refreshHwList);
    
    try {
      await GlobalSettings.login(Account.fromMap(acc));
    } catch (e) {
      logger.e(e.toString());
      showToast("無法自動登入", e.toString(), InfoBarSeverity.error);
    } finally {
      isLoggingIn = false;
      update.sink.add(GlobalEvent.refreshHwList);
    }
  }

  static Future<void> initialize() async {
    await prefs.initialize();

    if (prefs.autoLogin != null) {
      _autoLogin();
    }
  }

  static ToastificationItem? showToast(String title, String message, InfoBarSeverity level) {
    if (!MyApp.ctx.mounted) {
      return null;
    }
    
    return toastification.showCustom(
      context: MyApp.ctx,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 5),
      builder: (BuildContext context, ToastificationItem holder) {
        return Container(
          width: 500,
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color.fromRGBO(39, 39, 39, 1),
          ),
          child: InfoBar(
            isLong: false,
            title: Text(title),
            content: Text(message),
            severity: level
          )
        );
      },
    );
  }
}