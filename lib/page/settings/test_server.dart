import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/window_effect.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/core/test_server.dart';
import 'package:ntut_program_assignment/main.dart';
import 'package:ntut_program_assignment/provider/theme.dart';
import 'package:ntut_program_assignment/widget.dart';

class TestServerRoute extends StatefulWidget {
  const TestServerRoute({super.key});

  @override
  State<TestServerRoute> createState() => _TestServerRouteState();
}

class _TestServerRouteState extends State<TestServerRoute> {
  bool? _testEnvironmentOk;

  @override
  void initState() {
    super.initState();
    _refreshEnv();
  }

  Future<void> _refreshEnv() async {
    _testEnvironmentOk = await TestServer.findPython();

    if (!mounted) return;
    setState(() {});
  }

  Color get statusColor {
    if (_testEnvironmentOk == null) {
      return Colors.yellow;
    }

    if (_testEnvironmentOk!) {
      return Colors.green.lighter;
    }

    return Colors.red.lighter;
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
              color: statusColor,
              borderRadius: BorderRadius.circular(10)
            ),
          ), 
        )
      ]
    );
  }
}