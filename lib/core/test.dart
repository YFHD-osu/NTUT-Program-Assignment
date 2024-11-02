import 'dart:io';

class TestServer {
  static Future<List> fetchAllPython() async {
    final programData = Platform.environment["PROGRAMDATA"];
    final dir = Directory("$programData\\Microsoft\\Windows\\AppRepository\\Packages");
    print(dir);
    if (await dir.exists()) {
      print("object");
      await for (var file in dir.list()) {
        print(file.path);
      }
    }

    
    return [];
  }  
}