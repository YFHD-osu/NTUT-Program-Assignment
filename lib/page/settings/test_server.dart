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
      dialogTitle: MyApp.locale.settings_test_server_select_compiler
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
          MyApp.locale.success, 
          "${MyApp.locale.settings_test_server_compiler_not_implement}: $type", 
          InfoBarSeverity.error
        );
        return;
    }

    if (!result) {
      setState(() {});
      MyApp.showToast(
        MyApp.locale.failed,
        "${MyApp.locale.settings_test_server_compiler_invaild} ($type)",
        InfoBarSeverity.error
      );
      return;
    }

    MyApp.showToast(
      MyApp.locale.success,
      "${MyApp.locale.settings_test_server_compiler_set} ($type)",
      InfoBarSeverity.info
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
            MyApp.locale.failed, 
            MyApp.locale.settings_test_server_c_not_found,
            InfoBarSeverity.error
          );
          return;
        }

      case "python":
        GlobalSettings.prefs.pythonPath = null;
        await TestServer.findPython();
        if (!TestServer.pythonOK) {
          MyApp.showToast(
            MyApp.locale.failed,
            MyApp.locale.settings_test_server_python_not_found,
            InfoBarSeverity.error
          );
          return;
        }

      default:
        MyApp.showToast(
          MyApp.locale.failed,
          "${MyApp.locale.settings_test_server_not_implemented}: $type",
          InfoBarSeverity.error
        );
        return;
    }

    MyApp.showToast(
      MyApp.locale.success,
      "${MyApp.locale.settings_test_server_env_compiler_found} ($type)", 
      InfoBarSeverity.info
    );
    setState(() {});
  }

  Widget _pythonDetails() {
    String compilerType(Compiler? compiler) {
      if (compiler == null) {
        return MyApp.locale.settings_test_server_not_found;
      }

      switch (compiler.type) {
        case CompilerType.environment:
          return MyApp.locale.settings_test_server_environment_variable;

        case CompilerType.path:
          return "${MyApp.locale.settings_test_server_sepcified_path} (${GlobalSettings.prefs.pythonPath})";
      }
    }

    String compilerVersion(Compiler? compiler) {
      if (compiler == null) {
        return MyApp.locale.settings_test_server_not_found;
      }

      return compiler.version;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Text(MyApp.locale.settings_test_server_source),
            const Spacer(),
            Text(compilerType(TestServer.pythonState))
          ]
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(MyApp.locale.settings_test_server_version),
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
              child: Text(MyApp.locale.settings_test_server_custom_path)
            ),
            const SizedBox(width: 10),
            Button(
              onPressed: () => _envPath("python"),
              child: Text(MyApp.locale.settings_test_server_use_environment_variable)
            )
          ]
        )
      ]
    );
  }

  Widget _gccDetails() {
    String compilerType(Compiler? compiler) {
      if (compiler == null) {
        return MyApp.locale.settings_test_server_not_found;
      }

      switch (compiler.type) {
        case CompilerType.environment:
          return MyApp.locale.settings_test_server_environment_variable;

        case CompilerType.path:
          return "${MyApp.locale.settings_test_server_sepcified_path} (${GlobalSettings.prefs.gccPath})";
      }
    }

    String compilerVersion(Compiler? compiler) {
      if (compiler == null) {
        return MyApp.locale.settings_test_server_not_found;
      }

      return compiler.version;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Text(MyApp.locale.settings_test_server_source),
            const Spacer(),
            Text(compilerType(TestServer.gccState))
          ]
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(MyApp.locale.settings_test_server_version),
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
              child: Text(MyApp.locale.settings_test_server_custom_path)
            ),
            const SizedBox(width: 10),
            Button(
              onPressed: () => _envPath("c"),
              child: Text(MyApp.locale.settings_test_server_use_environment_variable)
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
          title: MyApp.locale.settings_test_server_test_compiler_path,
          lore: MyApp.locale.settings_test_server_test_compiler_path_desc,
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
              Text(MyApp.locale.settings_test_server_test_python_environment),
              const Spacer(),
              Text(TestServer.pythonOK ?
                MyApp.locale.settings_test_server_environment_detected : 
                MyApp.locale.settings_test_server_environment_not_detected
              ),
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
              Text(MyApp.locale.settings_test_server_test_c_environment),
              const Spacer(),
              Text(TestServer.gccOK ?
                MyApp.locale.settings_test_server_environment_detected : 
                MyApp.locale.settings_test_server_environment_not_detected
              ),
            ]
          ),
          content: _gccDetails()
        )
      ]
    );
  }
}