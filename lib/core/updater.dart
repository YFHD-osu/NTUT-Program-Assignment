import 'dart:convert';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ntut_program_assignment/main.dart';

import 'package:package_info_plus/package_info_plus.dart';

class Updater {
  static final updateAPI = Uri.parse("https://api.github.com/repos/YFHD-osu/NTUT-Program-Assignment/tags");

  // Store the current state of update availablitity
  static ValueNotifier<bool> available = ValueNotifier(false);

  static String? latest;

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

    logger.d("Latest version: $latest, currently: ${packageInfo.version}");
    
    // Whether latest version is greater than current version  
    available.value = latest!.compareTo(packageInfo.version) > 0;
    return available.value;
  }
}