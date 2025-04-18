import 'package:fluent_ui/fluent_ui.dart';

import 'package:ntut_program_assignment/main.dart';
import 'package:ntut_program_assignment/router.dart';
import 'package:ntut_program_assignment/page/homework/details.dart';
import 'package:ntut_program_assignment/page/homework/list.dart';

enum EventType {
  setStateOverview
}

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  @override
  Widget build(BuildContext context) {
    return FluentNavigation(
      title: MyApp.locale.sidebar_homework_title,
      builder: (String route) {
        switch (route) {
          case "hwDetail":
            return HomeworkDetail();

          default:
            return HomeworkList();
        }
      }
    );
  }
}