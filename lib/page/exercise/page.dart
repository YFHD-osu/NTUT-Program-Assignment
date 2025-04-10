import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

import 'package:ntut_program_assignment/router.dart';
import 'package:ntut_program_assignment/widget.dart';
import 'package:ntut_program_assignment/page/exercise/problem_list.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return UnimplementPage();
    }

    return FluentNavigation(
      title: "練習區",
      struct: {
        "default": ProblemList()
      }
    );
  }
}