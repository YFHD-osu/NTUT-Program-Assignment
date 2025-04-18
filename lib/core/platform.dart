
import 'dart:io';

import 'package:flutter/foundation.dart';

class Platforms {
  static String? result;

  static bool get isWindows =>
    (result == null) ? fetchSystem() == "windows" : result == "windows";

  static bool get isWeb =>
    (result == null) ? fetchSystem() == "web" : result == "web";

  static bool get isMacOS =>
    (result == null) ? fetchSystem() == "macos" : result == "macos";

  static bool get isLinux =>
    (result == null) ? fetchSystem() == "linux" : result == "linux";

  static bool get isDesktop =>
    [isWindows, isMacOS, isLinux].any((e) => e);

  static String fetchSystem() {
    if (kIsWeb) {
      return result = "web";
    }

    if (Platform.isWindows) {
      return result = "windows";
    }

    if (Platform.isMacOS) {
      return result = "macos";
    }

    if (Platform.isLinux) {
      return result = "linux";
    }

    return result = "others";
  }

  static bool get canMicaEffect {
    if (!isWindows) {
      return false;
    }

    final version = Platform.operatingSystemVersion;

    if (version.contains("Windows 10")) {
      final exp = RegExp(r"Build\s(\d+)");
      Match? match = exp.firstMatch(version);
      if (match != null) {
        int buildNumber = int.parse(match.group(1)!);
        return (buildNumber >= 22000);
      }
    }

    return false;
  }
}