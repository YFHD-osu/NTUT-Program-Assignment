import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:ntut_program_assignment/router.dart';
import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/page/homework/details.dart';
import 'package:ntut_program_assignment/page/homework/list.dart';

enum EventType {
  refreshOverview,
  setStateDetail
}

final StreamController<EventType> update = StreamController();
final stream = update.stream.asBroadcastStream();
List<Homework> homeworks = [];

class HomeworkPage extends StatelessWidget {
  const HomeworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FluentNavigation(
      title: "作業列表",
      struct: {
        "default": HomeworkList(),
        "hwDetail": HomeworkDetail()
      }
    );
  }
}