import 'dart:async';

import 'package:ntut_program_assignment/core/api.dart';

enum GlobalEvent {
  accountSwitch
}

class GlobalSettings {
  // The account that current using
  static Account? account;

  static final update = StreamController<GlobalEvent>();
  static final stream = update.stream.asBroadcastStream();

  static bool get isLogin =>
    account != null ;

  static Future<void> login(Account acc) async {
    await acc.login();
    logger.d("Logged in with session: ${acc.sessionID}");
    account = acc;
    update.sink.add(GlobalEvent.accountSwitch);
  }

  static void logout() {
    account = null;
    update.sink.add(GlobalEvent.accountSwitch);
  }
}
