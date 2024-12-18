import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/core/test_server.dart';
import 'package:ntut_program_assignment/widget.dart';

class TestServerRoute extends StatefulWidget {
  const TestServerRoute({super.key});

  @override
  State<TestServerRoute> createState() => _TestServerRouteState();
}

class _TestServerRouteState extends State<TestServerRoute> {
  bool? _pythonOk, _gccOk;

  @override
  void initState() {
    super.initState();
    _refreshEnv();
  }

  Future<void> _refreshEnv() async {
    _gccOk = await TestServer.findGCC();
    _pythonOk = await TestServer.findPython();


    if (!mounted) return;
    setState(() {});
  }

  Color get statusColor {
    if (_pythonOk == null) {
      return Colors.yellow;
    }

    if (_pythonOk!) {
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
        ),
        const SizedBox(height: 5),
        Tile(
          padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 11.5
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.asset("assets/language/python.png", height: 40)
              ),
              const SizedBox(width: 10),
              const Text("Python 環境"),
              const Spacer(),
              Text(_pythonOk ?? false ? "已偵測到 Python 環境" : "無法偵測到 Python 環境"),
              const SizedBox(width: 10)
            ]
          )
        ),
        const SizedBox(height: 5),
        Tile(
          padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 11.5
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.asset("assets/language/c.png", height: 40)
              ),
              const SizedBox(width: 10),
              const Text("C 語言 環境"),
              const Spacer(),
              Text(_gccOk ?? false ? "已偵測到 C 語言 環境" : "無法偵測到 C 語言 環境"),
              const SizedBox(width: 10)
            ]
          )
        ),
      ]
    );
  }
}