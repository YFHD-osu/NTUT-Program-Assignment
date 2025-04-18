import 'package:fluent_ui/fluent_ui.dart';

import 'package:ntut_program_assignment/core/local_problem.dart';
import 'package:ntut_program_assignment/page/exercise/details.dart';
import 'package:ntut_program_assignment/page/exercise/problem_list.dart';
import 'package:ntut_program_assignment/router.dart';

class ProblemInstance {
  static List<ProblemCollection>? onlineList;
  static List<ProblemCollection>? localList;

  static int get onlineCount {
    if (onlineList == null) {
      return 0;
    }

    return onlineList!
      .map((e) => e.problemIDs.length)
      .reduce((a ,b) => a+b);
  }

  static int get localCount {
    if (localList == null) {
      return 0;
    }

    return localList!
      .map((e) => e.problemIDs.length)
      .reduce((a ,b) => a+b);
  }
}

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> with AutomaticKeepAliveClientMixin {

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FluentNavigation(
      title: "練習區",
      builder: (String route) {
        switch (route) {
          case "exercise":
            return ProblemDetail();
          
          default:
            return ProblemList();
        }
      }
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}