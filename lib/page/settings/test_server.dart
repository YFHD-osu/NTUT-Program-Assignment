import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/core/test_server.dart';
import 'package:ntut_program_assignment/main.dart';
import 'package:ntut_program_assignment/widget.dart';

class TestServerRoute extends StatefulWidget {
  const TestServerRoute({super.key});

  @override
  State<TestServerRoute> createState() => _TestServerRouteState();
}

class _TestServerRouteState extends State<TestServerRoute> {

  @override
  void initState() {
    super.initState();

    if ([TestServer.pythonOK, TestServer.gccOK].any((e) => !e)) {
      _refreshEnv();
    }
  }

  Future<void> _refreshEnv() async {
    await TestServer.findGCC();
    await TestServer.findPython();


    if (!mounted) return;
    setState(() {});
  }

  Color statusColor(bool isOK) {
    if (isOK) {
      return Colors.green.lighter;
    }

    return Colors.red.lighter;
  }

  Future<void> _customPath(String type) async {
    final FilePickerResult? outputFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      lockParentWindow: true,
      allowedExtensions: ["*"],
      dialogTitle: '選取編譯器'
    );

    if (outputFile?.paths.first == null) {
      setState(() {});
      return;
    }

    final path = File(outputFile!.paths.first!);

    late final bool result;

    switch (type) {
      case "c":
        result = await TestServer.checkGCCAvailable(path);

      case "python":
        result = await TestServer.checkPythonAvailable(path);

      default:
        MyApp.showToast(
          "無法設定編譯器", "尚未實作編譯器檢測: $type", InfoBarSeverity.error
        );
        return;
    }

    if (!result) {
      setState(() {});
      MyApp.showToast(
        "無效編譯器", "請確定指定的編譯器是有效的 $type 編譯器", InfoBarSeverity.error
      );
      return;
    }

    MyApp.showToast(
      "設定成功", "程式將使用指定路徑的 $type 編譯器", InfoBarSeverity.info
    );
    setState(() {});
    return;    
  }

  Future<void> _envPath(String type) async {
    switch (type) {
      case "c":
        GlobalSettings.prefs.gccPath = null;
        await TestServer.findGCC();
        if (!TestServer.gccOK) {
          MyApp.showToast(
            "找不到編譯器", "環境中無有效的 c 編譯器", InfoBarSeverity.error
          );
          return;
        }

      case "python":
        GlobalSettings.prefs.pythonPath = null;
        await TestServer.findPython();
        if (!TestServer.pythonOK) {
          MyApp.showToast(
            "找不到編譯器", "環境中無有效的 python 編譯器", InfoBarSeverity.error
          );
          return;
        }

      default:
        MyApp.showToast(
          "無法設定編譯器", "尚未實作編譯器檢測: $type", InfoBarSeverity.error
        );
        return;
    }

    MyApp.showToast(
      "設定成功", "已在環境中發現有效的 $type 編譯器", InfoBarSeverity.info
    );
    setState(() {});
  }

  Widget _pythonDetails() {
    String compilerType(Compiler? compiler) {
      if (compiler == null) {
        return "尚未找到";
      }

      switch (compiler.type) {
        case CompilerType.environment:
          return "環境變數";

        case CompilerType.path:
          return "指定路徑 (${GlobalSettings.prefs.pythonPath})";
      }
    }

    String compilerVersion(Compiler? compiler) {
      if (compiler == null) {
        return "尚未找到";
      }

      return compiler.version;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            const Text("來源"),
            const Spacer(),
            Text(compilerType(TestServer.pythonState))
          ]
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text("版本"),
            const Spacer(),
            Text(compilerVersion(TestServer.pythonState))
          ]
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Button(
              onPressed: () => _customPath("python"),
              child: const Text("自訂位置")
            ),
            const SizedBox(width: 10),
            Button(
              onPressed: () => _envPath("python"),
              child: const Text("使用環境變數")
            )
          ]
        )
      ]
    );
  }

  Widget _gccDetails() {
    String compilerType(Compiler? compiler) {
      if (compiler == null) {
        return "尚未找到";
      }

      switch (compiler.type) {
        case CompilerType.environment:
          return "環境變數";

        case CompilerType.path:
          return "指定路徑 (${GlobalSettings.prefs.gccPath})";
      }
    }

    String compilerVersion(Compiler? compiler) {
      if (compiler == null) {
        return "尚未找到";
      }

      return compiler.version;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            const Text("來源"),
            const Spacer(),
            Text(compilerType(TestServer.gccState))
          ]
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text("版本"),
            const Spacer(),
            Text(compilerVersion(TestServer.gccState))
          ]
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Button(
              onPressed: () => _customPath("c"),
              child: const Text("自訂位置")
            ),
            const SizedBox(width: 10),
            Button(
              onPressed: () => _envPath("c"),
              child: const Text("使用環境變數")
            )
          ]
        )
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Tile.lore(
          title: "測試編譯器位置",
          lore: "設定測試程式時所使用的編譯器位置",
          icon: const Icon(FluentIcons.file_code),
          child: AnimatedContainer(
            width: 10, height: 10,
            duration: const Duration(milliseconds: 350),
            decoration: BoxDecoration(
              color: statusColor(TestServer.pythonOK && TestServer.gccOK),
              borderRadius: BorderRadius.circular(10)
            ),
          ), 
        ),
        const SizedBox(height: 5),
        Expander(
          initiallyExpanded: true,
          header: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.asset("assets/language/python.png", height: 40)
              ),
              const SizedBox(width: 10, height: 60),
              const Text("Python 環境"),
              const Spacer(),
              Text(TestServer.pythonOK ? "已偵測到 Python 環境" : "無法偵測到 Python 環境"),
            ]
          ),
          content: _pythonDetails()
        ),
        const SizedBox(height: 5),
        Expander(
          initiallyExpanded: true,
          header: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.asset("assets/language/c.png", height: 40)
              ),
              const SizedBox(width: 10, height: 60),
              const Text("C 語言 環境"),
              const Spacer(),
              Text(TestServer.gccOK ? "已偵測到 C 語言 環境" : "無法偵測到 C 語言 環境")
            ]
          ),
          content: _gccDetails()
        )
      ]
    );
  }
}