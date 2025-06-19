
import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_syntax_view/flutter_syntax_view.dart';

import 'package:ntut_program_assignment/main.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/core/local_problem.dart';
import 'package:ntut_program_assignment/page/homework/details.dart';
import 'package:ntut_program_assignment/page/homework/test_area.dart';
import 'package:ntut_program_assignment/widgets/syntax_view.dart';

class ProblemDetail extends StatefulWidget {
  const ProblemDetail({super.key});

  @override
  State<ProblemDetail> createState() => _ProblemDetailState();
}

class _ProblemDetailState extends State<ProblemDetail> {
  
  LocalProblem? get localProblem =>
    GlobalSettings.route.current.parameter?["id"];

  SyntaxTheme getSyntaxTheme(FluentThemeData theme) {
    final syntaxTheme = theme.brightness.isDark
        ? SyntaxTheme.vscodeDark()
        : SyntaxTheme.vscodeLight();

    syntaxTheme.baseStyle = GoogleFonts.firaCode(
      textStyle: syntaxTheme.baseStyle,
    );
    
    syntaxTheme.backgroundColor = FluentTheme.of(context).resources.cardBackgroundFillColorDefault;

    return syntaxTheme;
  }

  Widget _sampleCodeView() {
    if (localProblem?.sampleCode == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(FluentIcons.error),
          SizedBox(width: 10, height: 50),
          Text("此題尚未有範例程式")
        ]
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.all(
        Radius.circular(8.0),
      ),
      child: SyntaxViewShit(
        withZoom: false,
        code: localProblem!.sampleCode!.join("\n"),
        syntaxTheme: getSyntaxTheme(FluentTheme.of(context)),
        syntax: Syntax.C,
        fontSize: 16
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (localProblem == null) {
      return Placeholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(MyApp.locale.problem,
          style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        ProblemBox(
          problem: localProblem!.problem
        ),
        const SizedBox(height: 10),
        Text(MyApp.locale.test,
          style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TestArea(
          testcase: localProblem!.testCase
        ),
        const SizedBox(height: 10),
        Text("範例程式",
          style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 600,
            minWidth: double.infinity
          ),
          child: _sampleCodeView()
        ),
        SizedBox(height: 10),
        Text(MyApp.locale.hwDetails_subtitle_copyarea,
          style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Row(
          children: [
            CopyButton(
              title: MyApp.locale.hwDetails_widget_copyWholeProblem,
              context: localProblem!.problem.join("\n")
            ),
            const SizedBox(width: 10),
            CopyButton(
              title: MyApp.locale.hwDetails_widget_copyWholeTestcase,
              context: List<int>.generate(localProblem!.testCase.cases.length, (i) => i)
                .map((i) => "${MyApp.locale.testcase} ${i+1}\n${localProblem!.testCase.cases[i]}")
                .join("\n\n")
            ),
            const SizedBox(width: 10),
            CopyButton(
              title: "複製範例程式",
              context: localProblem!.sampleCode?.join("\n")
            )
          ]
        ),
        SizedBox(height: 10),
      ]
    );
  }
}