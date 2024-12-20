import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/main.dart';
import 'package:ntut_program_assignment/router.dart';
import 'package:ntut_program_assignment/widget.dart';
import 'package:ntut_program_assignment/core/global.dart' show GlobalSettings;

class HandedInPage extends StatelessWidget {
  const HandedInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FluentNavigation(
      title: "已繳交的作業",
      struct: {
        "default": FileList(),
        // "hwDetail": HomeworkDetail()
      }
    );
  }
}

class FileList extends StatefulWidget {
  const FileList({super.key});

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  List<HomeworkStatus> files = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() async {
    if (GlobalSettings.account == null) {
      logger.e("Cannot fetch handed in list, account not login");
      return;
    }

    files = await GlobalSettings.account!.fetchHanddedHomeworks();
    setState(() {});
  }

  Widget _tiles(HomeworkStatus hw) {
    return Tile(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(hw.id),
          const SizedBox(width: 10),
          const Icon(FluentIcons.assign),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: "檔名: ${hw.filename}\n"),
                TextSpan(text: "狀態: ${hw.status.trim()}\n"),
                TextSpan(text: "時間: ${hw.date}")
              ]
            )),
          const SizedBox(width: 10)
        ]
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (GlobalSettings.isLoggingIn) {
      return const LoggingInBlock();
    }

    if (GlobalSettings.account == null) {
      return const LoginBlock();
    }

    if (files.isEmpty) {
      return const Placeholder();
    }

    return GridView(
      shrinkWrap : true,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          childAspectRatio: 5,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5
      ),
      children: files
        .map(_tiles)
        .expand((e) => [const SizedBox(height: 10), e])
        .toList()
        .sublist(1)
    );
  }
}