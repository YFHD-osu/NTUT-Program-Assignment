import 'dart:convert';

import 'package:version/version.dart';
import 'package:http/http.dart' as http;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:ntut_program_assignment/main.dart' show logger;

class Updater {
  static final updateAPI = Uri.parse("https://api.github.com/repos/YFHD-osu/NTUT-Program-Assignment/tags");

  // Store the current state of update availablitity
  static ValueNotifier<bool> available = ValueNotifier(false);

  static String? latest;

  static bool _isVersionGreater(Version v1, Version v2) {
    if (v1.major != v2.major) {
      return v1.major > v2.major;
    } else if (v1.minor != v2.minor) {
      return v1.minor > v2.minor;
    } else if (v1.patch != v2.patch) {
      return v1.patch > v2.patch;
    } else {
      return v1.build.compareTo(v2.build) > 0;
    }
  }

  // Fetch latest release tag from Github
  static Future<String> fetchLatest() async {
    final response = await http.get(updateAPI);
    final map = List<Map<String, dynamic>>.from(json.decode(response.body));

    // Substring for the first 'v' character
    return map[0]["name"].toString().substring(1);
  }

  static Future<bool> needUpdate() async {
    try {
      latest = await fetchLatest();
    } catch (e) {
      logger.e("Cannot fetch latest version");
      return false;
    }

    final packageInfo = await PackageInfo.fromPlatform();

    late final String current;

    if (packageInfo.buildNumber.isEmpty) {
      current = packageInfo.version;
    } else {
      current = "${packageInfo.version}+${packageInfo.buildNumber}";
    }

    Version v1 = Version.parse(latest!);
    Version v2 = Version.parse(current);

    // Whether latest version is greater than current version  
    available.value = _isVersionGreater(v1, v2);

    logger.d("Latest version: $latest, currently: $current, need update: ${available.value}");

    return available.value;
  }
}