import 'dart:convert';
import 'dart:typed_data';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/window_effect.dart' show WindowEffect;
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:ntut_program_assignment/core/platform.dart';

class Database {
  final String name;

  late CollectionBox box;
  late final BoxCollection collection;

  bool _isInitialized = false;

  Database({
    required this.name
  });

  Future<bool> initialize() async {
    if (_isInitialized) return false;

    final directory = (await getApplicationSupportDirectory()).path;
    
    collection = await BoxCollection.open(
      name, // Name of your database
      {name}, // Names of your boxes,
      path: "$directory/data/",
      key: HiveAesCipher(await _getChipset())
    );

    box = await collection.openBox(name);
    _isInitialized = true;
    return true;
  }

  Future<List<int>> _getChipset() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

    if (Platforms.isWindows) {
      final info = await deviceInfoPlugin.windowsInfo;
      final rawKey = utf8.encode("${info.deviceId}${info.productId}${info.platformId}");
      return sha256.convert(rawKey).bytes;
    }

    if (Platforms.isLinux) {
      final info = await deviceInfoPlugin.linuxInfo;
      final rawKey = utf8.encode("${info.id}${info.machineId}${info.variantId}");
      return sha256.convert(rawKey).bytes;
    }

    if (Platforms.isMacOS) {
      final info = await deviceInfoPlugin.macOsInfo;
      final rawKey = utf8.encode("${info.systemGUID}${info.model}");
      return sha256.convert(rawKey).bytes;
    }

    return Uint8List(0);
  }

  Future<void> put(String key, dynamic value) async {
    return await box.put(key, value);
  }

  Future<void> refresh() async {
    box = await collection.openBox(name);
  }

  Future<Map<String, dynamic>> getAllValues() async {
    return await box.getAllValues();
  }

  Future<dynamic> get(String key) async {
    return await box.get(key);
  }

  Future<void> delete(String key) async {
    return await box.delete(key);
  }
  
}

class Preferences {
  final database = Database(
    name: "settings"
  );

  late ThemeMode _themeMode;

  set themeMode(ThemeMode v) {
    _themeMode = v;
    database.put("themeMode", v.index);
  }

  ThemeMode get themeMode =>
    _themeMode;

  late WindowEffect _windowEffect;

  set windowEffect(WindowEffect v) {
    _windowEffect = v;
    database.put("windowEffect", v.index);
  }

  WindowEffect get windowEffect =>
    _windowEffect;

  late String? _autoLogin;

  String? get autoLogin =>
    _autoLogin;
  
  set autoLogin(String? v) {
    _autoLogin = v;
    database.put("autoLogin", v);
  }

  late double _problemTextFactor;

  double get problemTextFactor =>
    _problemTextFactor;
  
  set problemTextFactor(double v) {
    _problemTextFactor = v;
    database.put("problemTextFactor", v);
  }
  
  late double _testcaseTextFactor;

  double get testcaseTextFactor =>
    _testcaseTextFactor;
  
  set testcaseTextFactor(double v) {
    _testcaseTextFactor = v;
    database.put("testcaseTextFactor", v);
  }

  late String? _pythonPath;

  String? get pythonPath =>
    _pythonPath;
  
  set pythonPath(String? v) {
    _pythonPath = v;
    database.put("pythonPath", v);
  }

  late String? _gccPath;

  String? get gccPath =>
    _gccPath;
  
  set gccPath(String? v) {
    _gccPath = v;
    database.put("gccPath", v);
  }

  late String _language;

  String get language =>
    _language;
  
  set language(String v) {
    _language = v;
    database.put("language", v);
  }

  Future<void> initialize() async {
    await database.initialize();
    await refresh();
  }

  Future<void> refresh() async {
    await database.refresh();
    
    final map = await database.getAllValues();

    final defaultEffect = Platforms.canMicaEffect ? WindowEffect.mica : WindowEffect.disabled;
    _themeMode = ThemeMode.values[map['themeMode']??0];
    _windowEffect = WindowEffect.values[map['windowEffect'] ?? defaultEffect.index];
    _autoLogin = map['autoLogin'];

    _problemTextFactor = map['problemTextFactor'] ?? 1.0;
    _testcaseTextFactor = map['problemTextFactor'] ?? 1.0;

    _gccPath = map['gccPath'];
    _pythonPath = map['pythonPath'];

    _language = map["language"] ?? "zh_Hant";
  }
}

class LocalProblemDatabase {
  final database = Database(
    name: "local_problem"
  );


  Future<void> initialize() async {
    await database.initialize();
    // await refresh();
  }


}