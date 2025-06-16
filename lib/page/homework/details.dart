import 'dart:io';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:ntut_program_assignment/core/platform.dart' show Platforms;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

import 'package:ntut_program_assignment/models/api_model.dart';
import 'package:ntut_program_assignment/page/homework/test_area.dart';
import 'package:ntut_program_assignment/widgets/button.dart';
import 'package:ntut_program_assignment/widgets/tile.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/page/homework/list.dart';
import 'package:ntut_program_assignment/provider/theme.dart';
import 'package:ntut_program_assignment/main.dart' show MyApp, logger;
import 'package:ntut_program_assignment/page/homework/page.dart';

class HomeworkDetail extends StatefulWidget {
  const HomeworkDetail({
    super.key
  });

  @override
  State<HomeworkDetail> createState() => _HomeworkDetailState();
}

class _HomeworkDetailState extends State<HomeworkDetail> {
  Homework get homework =>
    HomeworkInstance.homeworks[GlobalSettings.route.current.parameter?["id"]??0];

  File? selFile;

  // Store copy button whether should display a check mark or clipboard icon 
  bool inputCopy = false, outputCopy = false;

  File? uploadCandidate;

  late final StreamSubscription<EventType> _sub;

  Future<void> refresh() async {
    try {
      await homework.refreshTestcaseAndPasslist();
    } catch (e) {
      MyApp.showToast(MyApp.locale.hwDetails_refresh_failed, e.toString(), InfoBarSeverity.error);
      return;
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _sub = HomeworkInstance.stream.listen(_onEvent);
    refresh();
  }

  void _onEvent(EventType e) {
    if (e == EventType.setStateOverview) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    _sub.cancel();
  }

  Widget _deleteConfirm() {
    return ContentDialog(
      constraints: const BoxConstraints(
        minHeight: 0, minWidth: 0, maxHeight: 400, maxWidth: 400),
      title: Text(MyApp.locale.hwDetails_deleteDialog_title),
      content: Text(MyApp.locale.hwDetails_deleteDialog_context),
      actions: [
        AlertButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: Text(MyApp.locale.hwDetails_deleteDialog_delete_btn),
        ),
        Button(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: Text(MyApp.locale.cancel_button),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {   
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        OverviewCard(
          homework: homework

        ),
        const SizedBox(height: 10),
        Text(MyApp.locale.upload,
          style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        UploadSection(
          homework: homework
        ),
        const SizedBox(height: 10),
        Text(MyApp.locale.problem,
          style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        ProblemBox(
          problem: homework.problem
        ),
        const SizedBox(height: 10),
        Text(MyApp.locale.test,
          style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TestArea(
          testcase: homework.testCase
        ),
        const SizedBox(height: 10),
        Text(MyApp.locale.hwDetails_subtitle_copyarea,
          style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Row(
          children: [
            CopyButton(
              title: MyApp.locale.hwDetails_widget_copyWholeProblem,
              context: homework.problem.join("\n")
            ),
            const SizedBox(width: 10),
            CopyButton(
              title: MyApp.locale.hwDetails_widget_copyWholeTestcase,
              context: List<int>.generate(homework.testCase.cases.length, (i) => i)
                .map((i) => "${MyApp.locale.testcase} ${i+1}\n${homework.testCase.cases[i]}")
                .join("\n\n")
            )
          ]
        ),
        const SizedBox(height: 10),
        Text(MyApp.locale.hwDetails_subtitle_homeworkStatus,
          style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        StateSection(
          homework: homework
        ),
        const SizedBox(height: 10),
        Text(MyApp.locale.hwDetails_subtitle_dangerZone,
          style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Tile(
          title: Text(MyApp.locale.hwDetails_widget_deleteHw_title),
          subtitle: Text(MyApp.locale.hwDetails_widget_deleteHw_context),
          leading: const Icon(FluentIcons.delete),
          trailing: AlertButton(
            onPressed: !homework.canDelete ? null : () async {
              final isConfirmed = await showDialog<bool>(
                context: context,
                builder: (context) => _deleteConfirm()
              );

              if (!(isConfirmed??false)) return;

              logger.i("Homework deleted!");

              homework.deleting = true;
              setState(() {});
              
              try {
                await homework.delete();
                await refresh();
              } catch (e) {
                MyApp.showToast(MyApp.locale.toast_delete_failed, e.toString(), InfoBarSeverity.error);
                setState(() => homework.deleting = false);
                return;
              }
              
              setState(() {});
            },
            child: Text(MyApp.locale.delete)
          )
        )
      ]
    );
  }
}

class StateSection extends StatefulWidget {
  final Homework homework;

  const StateSection({
    super.key,
    required this.homework
  });

  @override
  State<StateSection> createState() => _StateSectionState();
}

class _StateSectionState extends State<StateSection> {
  HomeworkStatus get state =>
    widget.homework.fileState!;

  @override
  Widget build(BuildContext context) {
    if (widget.homework.fileState == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Tile(
          title: Text(MyApp.locale.hwDetails_state_not_submitted),
          subtitle: Text(MyApp.locale.hwDetails_state_not_submitted_desc),
          trailing: const Icon(FluentIcons.not_executed),
        )
      );
    }

    return Column(
      children: [
        Tile(
          title: Text(MyApp.locale.hwDetails_widget_editFileName_title),
          subtitle: Text(MyApp.locale.hwDetails_widget_editFileName_lore),
          leading: const Icon(FluentIcons.rename),
          trailing: Text(state.filename)
        ),
        const SizedBox(height: 5),
        Tile(
          title: Text(MyApp.locale.hwDetails_widget_fileStatus_title),
          subtitle: Text(MyApp.locale.hwDetails_widget_fileStatus_lore),
          leading: const Icon(FluentIcons.process),
          trailing: Text(state.status.replaceAll("刪除", "可以變更"))
        ),
        const SizedBox(height: 5),
        Tile(
          title: Text(MyApp.locale.hwDetails_widget_uploadTime_title),
          subtitle: Text(MyApp.locale.hwDetails_widget_uploadTime_lore),
          leading: const Icon(FluentIcons.date_time),
          trailing: Text(state.date.toString())
        ),
      ]
    );
  }
}

class CopyButton extends StatefulWidget {
  final String? title;
  final String? context;
  
  const CopyButton({
    super.key,
    this.title,
    required this.context
  });

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool copyState = false;

  Widget _copyIcon() {
    if (!copyState) {
      return const SizedBox.square(
        key: ValueKey(1),
        dimension: 25,
        child: Icon(FluentIcons.copy)
      );
    }

    return const SizedBox.square(
      key: ValueKey(0),
      dimension: 25,
      child:  Icon(FluentIcons.check_mark)
    );
  }

  List<Widget> _title() {
    if (widget.title == null) return [];
    return [
      const SizedBox(width: 10),
      Text(widget.title!)
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: widget.context==null ? null : () async {
        await Clipboard.setData(ClipboardData(text: widget.context!));
        if (mounted) setState(() => copyState = true);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) setState(() => copyState = false);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _copyIcon(),
            ..._title()
          ]
        )
      )
    );
  }
}

class ProblemBox extends StatelessWidget {
  final List<String> problem;

  const ProblemBox({
    super.key,
    required this.problem
  });

  InlineSpan _fetchSpan(String line) {
    if (line.contains(RegExp("<img src=.+>"))) {
      return WidgetSpan(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            line.substring(10, line.length-2),
            errorBuilder: (context, error, stackTrace) {
              return Row(
                children: [
                  const Icon(FluentIcons.error),
                  SizedBox(width: 5, height: 60),
                  Text("圖片載入失敗...")
                ]
              );
            },
          )
        )
      );
    }
    return TextSpan(
      text: line,
      style: TextStyle(
        fontFamily: "FiraCode",
        color: ThemeProvider.instance.isLight ? Colors.black : Colors.white
      )
    );
  }

  @override
  Widget build(BuildContext context) {

    if (problem.isEmpty) {
      return Tile(
        width: double.infinity,
        height: 50,
        title: Center(
          child: Text(MyApp.locale.hwDetails_problem_empty)
        ),
      );
    }
    
    return Tile(
      width: double.infinity,
      title: SelectableText.rich(
        selectionControls: fluentTextSelectionControls,
        TextSpan(
          style: TextStyle(
            fontSize: 14 * GlobalSettings.prefs.problemTextFactor,
            color: ThemeProvider.instance.isLight ? Colors.black : Colors.white
          ),
          children: problem
            .map((e) => _fetchSpan(e))
            .expand((element) => [element, const TextSpan(text: "\n")])
            .toList()
            .sublist(0, problem.length*2-1)
        )
      ) 
    );
  }
}

class OverviewCard extends StatefulWidget {
  final Homework homework;

  const OverviewCard({
    super.key,
    required this.homework
  });

  @override
  State<OverviewCard> createState() => _OverviewCardState();
}

class _OverviewCardState extends State<OverviewCard> {
  CheckResult? get testResult =>
    widget.homework.testResults;

  List<String>? get passVal =>
    widget.homework.passList;

  double _successVal = 0;

  final _personFlyOut = FlyoutController();
  final _testCaseFlyOut = FlyoutController();

  Widget _contextWidget() {
    final colors = FluentTheme.of(context).brightness.isLight ? 
      Colors.black : Colors.white;

    switch (widget.homework.state) {
      case HomeworkState.notTried: return Row(
        key: const ValueKey(0),
        children: [
          const Spacer(),
          Container(
            height: 10, width: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.red.lighter
            ),
          ),
          const SizedBox(width: 15),
          Text(MyApp.locale.hwDetails_state_not_submitted, style: TextStyle(fontWeight: FontWeight.bold, color: colors)),
          const Spacer()
        ]
      );

      case HomeworkState.compileFailed: return Row(
        key: const ValueKey(0),
        children: [
          const Spacer(),
          Container(
            height: 10, width: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.red.lighter
            ),
          ),
          const SizedBox(width: 10),
          Text(MyApp.locale.hwDetails_compilation_failed, style: TextStyle(fontWeight: FontWeight.bold, color: colors)),
          const Spacer(),
        ]
      );

      case HomeworkState.preparing: return Row(
        key: const ValueKey(0),
        children: [
          const Spacer(),
          Container(
            height: 10, width: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.orange.lighter
            ),
          ),
          const SizedBox(width: 10),
          Text(MyApp.locale.hwDetails_preparing, style: TextStyle(fontWeight: FontWeight.bold, color: colors)),
          const Spacer(),
        ]
      );

      case HomeworkState.notPassed: return Row(
        key: const ValueKey(1),
        children: [
          const Spacer(),
          Container(
            height: 10, width: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.red.lighter
            ),
          ),
          const SizedBox(width: 5),
          AnimatedFlipCounter(
            value: (testResult?.passCount ?? 0).toDouble(),
            fractionDigits: 0,
            curve: Curves.easeInOutSine,
            duration: const Duration(milliseconds: 600),
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors)
          ),
          Text("/${testResult?.allCount ?? 0}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors)),
          const SizedBox(width: 5),
          Text(MyApp.locale.hwDetails_failed, style: TextStyle(color: colors)),
          const Spacer(),
        ]
      );

      case HomeworkState.checking: return Row(
        key: const ValueKey(2),
        children: [
          const Spacer(),
          const SizedBox.square(
            dimension: 20,
            child: ProgressRing(
              strokeWidth: 3.0,
            )
          ),
          const SizedBox(width: 10),
          Text(MyApp.locale.hwDetails_submitting, style: TextStyle(fontWeight: FontWeight.bold, color: colors)),
          const Spacer()
        ]
      );

      case HomeworkState.passed: return Row(
        key: const ValueKey(3),
        children: [
          const Spacer(),
          Container(
            height: 10, width: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.green.lighter
            ),
          ),
          const SizedBox(width: 10),
          Text(MyApp.locale.hwDetails_passed, style: TextStyle(color: colors, fontWeight: FontWeight.bold)),
          const Spacer()
        ]
      );

      case HomeworkState.delete: return Row(
        key: ValueKey(4),
        children: [
          Spacer(),
          SizedBox.square(
            dimension: 20,
            child: ProgressRing(
              strokeWidth: 3.0,
            )
          ),
          SizedBox(width: 10),
          Text(MyApp.locale.hwDetails_deleting, style: TextStyle(fontWeight: FontWeight.bold)),
          Spacer()
        ]
      );

      case HomeworkState.plagiarism:
      case HomeworkState.other: return Row(
        key: ValueKey(5),
        children: [
          const Spacer(),
          Container(
            height: 10, width: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.orange.lighter
            ),
          ),
          const SizedBox(width: 10),
          Text(widget.homework.status, style: TextStyle(fontWeight: FontWeight.bold, color: colors)),
          const Spacer(),
        ]
      );
    }
  }

  Widget _completeCount() {
    final colors = FluentTheme.of(context).brightness.isLight ? 
      Colors.black : Colors.white;
    return Row(
      children: [
        const Spacer(),
        AnimatedFlipCounter(
          value: _successVal,
          fractionDigits: 0,
          curve: Curves.easeInOutSine,
          duration: const Duration(milliseconds: 600),
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors
          )
        ),
        const SizedBox(width: 10),
        Text(MyApp.locale.hwDetails_number_of_completions, style: TextStyle(color: colors)),
        const Spacer()
      ]
    );
  }

  bool get isClickable {
    switch (widget.homework.state) {
      
      case HomeworkState.notTried:
      case HomeworkState.checking:
      case HomeworkState.delete:
      case HomeworkState.preparing:
      case HomeworkState.other:
        return false;

      case HomeworkState.compileFailed:
      case HomeworkState.plagiarism:
      case HomeworkState.notPassed:
      case HomeworkState.passed:
        return (testResult != null);
    }
  }

  Future<void> _showTestcaseFlyOut() async {
    final result = await _testCaseFlyOut.showFlyout(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.bottomRight,
      ),
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      navigatorKey: Navigator.of(context),
      builder: (context) {
        if (widget.homework.state == HomeworkState.plagiarism) {
          return PlagiarismFlyout(
            result: testResult!
          );
        }

        if (widget.homework.state == HomeworkState.compileFailed) {
          return CompileFailFlyout(
            result: testResult!
          );
        }
        
        return TestCaseFlyout(
          results: testResult!
        );
      });

    if (result == null) {
      return;
    }

    if (result) {
      if (widget.homework.bytes == null || widget.homework.filename == null) {
        if (!await pickHomeworkFile()) {
          return;
        }
      }

      switch (widget.homework.state) {
        case HomeworkState.plagiarism:
          widget.homework.applyTrashCode();
        
        case HomeworkState.compileFailed:
          widget.homework.applyDelComment();

        default:
      }

      await _uploadWithInnerBytesFile();
    }
  }

  Future<bool> pickHomeworkFile() async {
    final FilePickerResult? outputFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      lockParentWindow: true,
      allowedExtensions: widget.homework.testCase.allowedExtensions,
      dialogTitle: MyApp.locale.hwDetails_select_homework_window_title
    );

    if (outputFile?.paths.first == null) {
      return false;
    }

    var myFile = File(
      outputFile!.paths.first
      .toString()
      .replaceAll(r"file:///", "")
      .replaceAll("%20", " ")
    );

    widget.homework.bytes = await myFile.readAsBytes();
    widget.homework.filename = myFile.uri.pathSegments.last;
    return true;
  }
  
  Future<void> _delete() async {
    if (widget.homework.canDelete) {
      widget.homework.deleting = true;
      setState(() {});

      try {
        await widget.homework.delete();
      } on RuntimeError catch (e) {
        widget.homework.deleting = false;
        MyApp.showToast(MyApp.locale.hwDetails_failed_delete_homework, e.toString(), InfoBarSeverity.error);
        setState(() {});
        return;
      }

      // Only refresh new pass list only if the homework is already passed
      // It's intended to illustrate user's name being removed from the list
      if (widget.homework.state == HomeworkState.passed) {
        await widget.homework.refreshTestcaseAndPasslist();
      }

      widget.homework.deleting = false;

      setState(() {});
    }
  }

  Future<void> _uploadWithInnerBytesFile() async {
    await _delete();

    widget.homework.applyTrashCode();
    widget.homework.submitting = true;
    setState(() {});

    try {
      await widget.homework.upload(widget.homework.bytes!, widget.homework.filename!);
      await widget.homework.fetchTestcases();
      await widget.homework.refreshPassList();
      await widget.homework.refreshSelfHandedIn();
    } catch (error) {
      MyApp.showToast(
        MyApp.locale.error_occur,
        error.toString(),
        InfoBarSeverity.error
      );
    }
    
    setState(() {});
  }

  Future<void> _showPeopleFlyOut() async {
    await _personFlyOut.showFlyout(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.bottomRight,
      ),
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      navigatorKey: Navigator.of(context),
      builder: (context) {
        return PersonFlyout(
          passes: passVal!
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    _successVal = passVal == null ? _successVal : passVal!.length.toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Spacer(),
        FlyoutTarget(
          controller: _personFlyOut,
          child: SizedBox(
            height: 50, width: 150,
            child: Tile(
              onPressed: passVal == null ? () {} : _showPeopleFlyOut,
              trailing: _completeCount()
            )
          )
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 50, width: 150,
          child: Tile(
            onPressed: isClickable ? _showTestcaseFlyOut : () {},
            trailing: ClipRRect(
            clipBehavior: Clip.hardEdge,
              child: FlyoutTarget(
                controller: _testCaseFlyOut,
                child: AnimatedSwitcher(
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(animation);
                    child.key;

                    final slideAnimation = [const ValueKey(1), const ValueKey(3)].contains(child.key) 
                        // Fade out from left to right
                        ? Tween<Offset>(begin: const Offset(0, -1), end: const Offset(0, 0)).animate(animation)
                        // Fade in from left to right
                        : Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0)).animate(animation);

                    return FadeTransition(
                      opacity: fadeAnimation,
                      child: SlideTransition(
                        position: slideAnimation,
                        child: child
                      ),
                    );
                  },
                  switchInCurve: Curves.fastOutSlowIn,
                  switchOutCurve: Curves.fastOutSlowIn,

                  duration: const Duration(milliseconds: 350),
                  child: _contextWidget()
                )
              )
          )
          )
        )
      ]
    );
  }
}

class DropItemInfo extends StatelessWidget {
  const DropItemInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      constraints: const BoxConstraints(
        maxWidth: 1000
      ),
      decoration: DottedDecoration(
        shape: Shape.box,
        strokeWidth: 1.5,
        color: Colors.white,
        borderRadius: BorderRadius.circular(4)
      ),
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        color: Colors.black.withValues(alpha: .075),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(FluentIcons.select_all, size: 35),
            SizedBox(width: 10),
            Text(MyApp.locale.hwDetails_drop_file_here)
          ]
        )
      ) 
    );
  }
}

class TestCaseFlyout extends StatelessWidget {
  final CheckResult results;

  const TestCaseFlyout({
    super.key,
    required this.results
  });

  Widget _testDataRow(TestCase testcase, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 11),
      child: Tile(
        title: Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: testcase.pass ? Colors.green.lighter : Colors.red.light,
                borderRadius: BorderRadius.circular(10)
              ),
            ),
            const SizedBox(width: 18),
            Text(testcase.title),
            const SizedBox(width: 10),
            Flexible(
              child: Text(testcase.testResult??"")
            ),
          ]
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 500, maxWidth: 300
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).menuColor,
        borderRadius: BorderRadius.circular(5)
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 11, bottom: 10),
            child: Tile(
              padding: const EdgeInsets.all(10),
              title: Row(
                children: [
                  Text(MyApp.locale.status),
                  const SizedBox(width: 10),
                  Text(MyApp.locale.number),
                  const SizedBox(width: 10),
                  Text(MyApp.locale.output),
                  const Spacer(),
                  Text("${results.passRate} %", style: const TextStyle(
                    fontWeight: FontWeight.bold
                  ))
                ]
              )
            )
          ),
          Expanded(child: ListView.separated(
            itemBuilder: (context, index) => 
              _testDataRow(results.cases[index], context),
            itemCount: results.cases.length,
            separatorBuilder: (context, index) => 
              const SizedBox(height: 10),
          ))
        ]
      )
    );
  }
}

class PlagiarismFlyout extends StatelessWidget {
  final CheckResult result;

  const PlagiarismFlyout({
    super.key,
    required this.result
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 195, maxWidth: 300
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).menuColor,
        borderRadius: BorderRadius.circular(5)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("作業抄襲", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Tile(
            constraints: BoxConstraints(),
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            title: Text(result.cases.firstOrNull?.message ?? "???")
          ),
          SizedBox(height: 10),
          
          Text("提示", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Tile(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            constraints: BoxConstraints(),
            title: RichText(
              text: TextSpan(
                text: "少年，你相信光嗎?\n",
                children: [
                  TextSpan(
                    text: "使用此程式的黑魔法讓你光速繞過抄襲檢查"
                  )
                ]
              )
            )
          ),
          SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Button(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("一鍵黑魔法"),
            )
          )
        ]
      )
    );
  }
}

class CompileFailFlyout extends StatelessWidget {
  final CheckResult result;

  const CompileFailFlyout({
    super.key,
    required this.result
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 195, maxWidth: 280, minWidth: 280
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).menuColor,
        borderRadius: BorderRadius.circular(5)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("編譯失敗", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Tile(
            constraints: BoxConstraints(),
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            title: Text(result.cases.firstOrNull?.message ?? "???")
          ),
          SizedBox(height: 10),
          
          Text("提示", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Tile(
            constraints: BoxConstraints(),
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            title: RichText(
              text: TextSpan(
                text: "少年，你相信光嗎?\n",
                children: [
                  TextSpan(
                    text: "有時候刪掉註解對這個問題有幫助！"
                  )
                ]
              )
            )
          ),
          SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Button(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("一鍵刪除註解"),
            )
          )
        ]
      )
    );
  }
}

class PersonFlyout extends StatelessWidget {
  final List<String> passes;

  const PersonFlyout({
    super.key,
    required this.passes
  });

  Widget _testDataRow(String result, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 11),
      child: Tile(
        title: Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: Colors.green.lighter,
                borderRadius: BorderRadius.circular(10)
              ),
            ),
            const SizedBox(width: 18),
            Text(result)
          ]
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 500, maxWidth: 300
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).menuColor,
        borderRadius: BorderRadius.circular(5)
      ),
      child: Column(
        children: [
          Expanded(child: ListView.separated(
            itemBuilder: (context, index) => 
              _testDataRow(passes[index], context),
            itemCount: passes.length,
            separatorBuilder: (context, index) => 
              const SizedBox(height: 10),
          ))
        ]
      )
    );
  }
}
class UploadSection extends StatefulWidget {
  final Homework homework;
  
  const UploadSection({
    super.key,
    required this.homework
  });

  @override
  State<UploadSection> createState() => _UploadSectionState();
}

class _UploadSectionState extends State<UploadSection> {
  bool _isDragOver = false;
  bool _explorerOpen = false;

  Future<void> _browseHomework() async {
    if (_explorerOpen) return;

    setState(() => _explorerOpen = true);

    late final FilePickerResult? outputFile; 

    try {
      outputFile = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        lockParentWindow: true,
        allowedExtensions: widget.homework.testCase.allowedExtensions,
        dialogTitle: MyApp.locale.hwDetails_select_homework_window_title
      );
    } on Exception catch (e) {
      if (Platform.isLinux) {
        logger.e("Cannot open file picker, you need to install qarma, zenity or kdialog:\n$e");
      } else {
        logger.e(e);
      }

      setState(() => _explorerOpen = false);
      return;
    }

    if (outputFile?.paths.first == null) {
      setState(() => _explorerOpen = false);
      return;
    }

    var myFile = File(
      outputFile!.paths.first
      .toString()
      .replaceAll(r"file:///", "")
      .replaceAll("%20", " ")
    );

    await _upload(myFile);

    if (mounted) setState(() => _explorerOpen = false);
  }

  Future<void> _onPerformDrop(PerformDropEvent event) async {
    // Block upload progress if upload is performing
    if (! widget.homework.canUpload) {
      return;
    }

    for (var item in event.session.items) {
      if (item.dataReader == null) {
        logger.e("DataReader cannot read file from drag object.");
        continue;
      }
      item.dataReader!.getValue(Formats.fileUri, _convertDragPath);
    }
  }

  void _convertDragPath(path) async {
    // For Chinese path support 
    String fileUri = Uri.decodeFull(path.toString().replaceAll(r"file:///", ""));

    // Fix file path doesn't start with '/' and cause file not found error
    if (Platforms.isLinux && !fileUri.startsWith("/")) {
      fileUri = "/$fileUri";
    }

    var myFile = File(fileUri);

    if (!widget.homework.testCase.allowedExtensions.contains(myFile.path.split(".").last)) {
      logger.i("Unsupported format: ${myFile.path}");
      MyApp.showToast(
        MyApp.locale.error_occur, 
        "${MyApp.locale.test_server_file_not_support} ${widget.homework.testCase.allowedExtensions.map((e) => ".$e").join(", ")}",
        InfoBarSeverity.error
      );
      return;
    }

    await _upload(myFile);
  }

  Future<void> _upload(File file) async {
    if (widget.homework.canDelete) {
      final isConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _showDeleteAlert()
      );
      if (!(isConfirmed??false)) return;

      widget.homework.deleting = true;
      HomeworkInstance.update.add(EventType.setStateOverview);

      try {
        await widget.homework.delete();
      } on RuntimeError catch (e) {
        widget.homework.deleting = false;
        MyApp.showToast(MyApp.locale.hwDetails_failed_delete_homework, e.toString(), InfoBarSeverity.error);
        HomeworkInstance.update.add(EventType.setStateOverview);
        return;
      }
      
      await widget.homework.refreshPassList();
      await widget.homework.fetchTestcases();
      widget.homework.deleting = false;
      HomeworkInstance.update.add(EventType.setStateOverview);
    }

    widget.homework.submitting = true;
    HomeworkInstance.update.add(EventType.setStateOverview);

    // Upload process
    if (!await file.exists()) {
      MyApp.showToast(MyApp.locale.hwDetails_failed_upload_homework, MyApp.locale.file_not_found, InfoBarSeverity.error);
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      await widget.homework.upload(bytes, file.uri.pathSegments.last);
      await widget.homework.refreshPassList();
      await widget.homework.fetchTestcases();
      await widget.homework.refreshSelfHandedIn();
    } catch (e) {
      MyApp.showToast(MyApp.locale.hwDetails_failed_upload_homework, e.toString(), InfoBarSeverity.error);
      return;
    } 

    GlobalSettings.update.add(GlobalEvent.setHwState);
    HomeworkInstance.update.add(EventType.setStateOverview);
  }

  void _onDropLeave(DropEvent event) {
    setState(() => _isDragOver = false);
  }

  DropOperation _onDropOver(DropOverEvent event) {
    if (widget.homework.canHandIn) {
      setState(() => _isDragOver = true);
      return event.session.allowedOperations.firstOrNull ?? DropOperation.none;
    }
    return DropOperation.none;
  }

  bool get isClickable {
    if (_explorerOpen) return false;

    if (widget.homework.submitting) return false;
    if (widget.homework.deleting) return false;

    return widget.homework.canHandIn;
  }

  Widget _showDeleteAlert() {
    return ContentDialog(
      constraints: const BoxConstraints(
        minHeight: 0, minWidth: 0, maxHeight: 400, maxWidth: 400),
      title: Text(MyApp.locale.hwDetails_resubmitt_homework),
      content: Text(MyApp.locale.hwDetails_resubmitt_homework_desc),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: Text(MyApp.locale.hwDetails_delete_and_upload_btn),
        ),
        Button(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: Text(MyApp.locale.cancel_button),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DropRegion(
      formats: const [
        ...Formats.standardFormats,
        Formats.fileUri
      ],
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: _onDropOver,
      onDropLeave: _onDropLeave,
      onPerformDrop: _onPerformDrop,
      child: AnimatedContainer(
        height: _isDragOver && widget.homework.canUpload ? 200 : 65,
        duration: const Duration(milliseconds: 150),
        foregroundDecoration: _isDragOver && widget.homework.canUpload ? DottedDecoration(
          shape: Shape.box,
          strokeWidth: 2.5,
          color: FluentTheme.of(context).brightness.isDark ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(4)
        ): null,
        child: Tile(
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(FluentIcons.upload),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(MyApp.locale.hwDetails_homework_upload),
                      Text(MyApp.locale.hwDetails_homework_upload_desc)
                    ]
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: isClickable ? _browseHomework : null,
                    child: Text(MyApp.locale.hwDetails_select_file),
                  )
                ]
              ),
              Expanded(
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: ThemeProvider.instance.isLight ? Colors.black : Colors.white),
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(FluentIcons.cloud_upload, size: 50)),
                        WidgetSpan(child: SizedBox(width: 10)),
                        TextSpan(
                          text: MyApp.locale.hwDetails_release_to_upload
                        )
                      ]
                    ) 
                  )
                ) 
              )
            ]
          )
        )
      )
    );
  }
}