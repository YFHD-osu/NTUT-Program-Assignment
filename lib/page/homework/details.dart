import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:file_picker/file_picker.dart';
import 'package:ntut_program_assignment/core/extension.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/page/homework/list.dart';
import 'package:ntut_program_assignment/provider/theme.dart';
import 'package:pretty_diff_text/pretty_diff_text.dart';
import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

import 'package:ntut_program_assignment/widget.dart';
import 'package:ntut_program_assignment/core/api.dart';
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

  // Store the list of all student ID that passes this homework 
  List<String>? _passList = [];

  // Store all online checked testcases status and messages
  List<CheckResult> _testcasesVal = [];

  // Store copy button whether should display a check mark or clipboard icon 
  bool inputCopy = false, outputCopy = false;

  File? uploadCandidate;

  late final StreamSubscription<EventType> _sub;

  Future<void> refresh() async {
    try {
      final tasks = [_loadSuccess(), _loadTest()];
      await Future.wait(tasks);
    } catch (e) {
      MyApp.showToast(MyApp.locale.hwDetails_refresh_failed, e.toString(), InfoBarSeverity.error);
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    _sub = HomeworkInstance.stream.listen(_onEvent);
    refresh();
  }

  void _onEvent(EventType e) {
    if (e == EventType.refreshOverview) {
      refresh();
      return;
    } else if (e == EventType.setStateDetail) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    _sub.cancel();
  }

  Future<void> _loadSuccess() async {
    _passList = null;
    if (mounted) setState(() {});
    
    _passList = await homework.fetchPassList();
    if (mounted) setState(() {});
  }

  Future<void> _loadTest() async {
    _testcasesVal = await homework.fetchTestcases();

    if (mounted) setState(() {});
  }

  bool canDelete() {
    switch (homework.state) {
      case HomeworkState.notPassed:
      case HomeworkState.passed:
        return DateTime.now().compareTo(homework.deadline) <= 0;

      default:
        return false;
    }
  }

  Widget _showDeleteConfirm() {
    return ContentDialog(
      constraints: const BoxConstraints(
        minHeight: 0, minWidth: 0, maxHeight: 400, maxWidth: 400),
      title: Text(MyApp.locale.hwDetails_deleteDialog_title),
      content: Text(MyApp.locale.hwDetails_deleteDialog_context),
      actions: [
        CustomWidgets.alertButton(
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
          homework: homework,
          passVal: _passList,
          testcasesVal: _testcasesVal,

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
          homework: homework
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
              context: List<int>.generate(homework.testCases.length, (i) => i)
                .map((i) => "${MyApp.locale.testcase} ${i+1}\n${homework.testCases[i]}")
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
        Tile.lore(
          title: MyApp.locale.hwDetails_widget_deleteHw_title,
          lore: MyApp.locale.hwDetails_widget_deleteHw_context,
          icon: const Icon(FluentIcons.delete),
          child: CustomWidgets.alertButton(
            child: Text(MyApp.locale.delete),
            onPressed: !canDelete() ? null : () async {
              final isConfirmed = await showDialog<bool>(
                context: context,
                builder: (context) => _showDeleteConfirm()
              );

              if (!(isConfirmed??false)) return;

              logger.i("Homework deleted!");

              final task = homework.delete();
              setState(() {});
              
              try {
                await task;
              } catch (e) {
                MyApp.showToast(MyApp.locale.toast_delete_failed, e.toString(), InfoBarSeverity.error);
                setState(() => homework.deleting = false);
                return;
              }

              refresh();
              setState(() {});
            }
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
        child: Tile.lore(
          title: MyApp.locale.hwDetails_state_not_submitted,
          lore: MyApp.locale.hwDetails_state_not_submitted_desc,
          icon: const Icon(FluentIcons.not_executed),
        )
      );
    }

    return Column(
      children: [
        Tile.lore(
          title: MyApp.locale.hwDetails_widget_editFileName_title,
          lore: MyApp.locale.hwDetails_widget_editFileName_lore,
          icon: const Icon(FluentIcons.rename),
          child: Text(state.filename)
        ),
        const SizedBox(height: 5),
        Tile.lore(
          title: MyApp.locale.hwDetails_widget_fileStatus_title,
          lore: MyApp.locale.hwDetails_widget_fileStatus_lore,
          icon: const Icon(FluentIcons.process),
          child: Text(state.status.replaceAll("刪除", "可以變更"))
        ),
        const SizedBox(height: 5),
        Tile.lore(
          title: MyApp.locale.hwDetails_widget_uploadTime_title,
          lore: MyApp.locale.hwDetails_widget_uploadTime_lore,
          icon: const Icon(FluentIcons.date_time),
          child: Text(state.date.toString())
        ),
      ]
    );
  }
}

class CopyButton extends StatefulWidget {
  final String? title;
  final String context;
  
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
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _copyIcon(),
            ..._title()
          ]
        )
      ),
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: widget.context));
        setState(() => copyState = true);
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() => copyState = false);
      }
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
      return WidgetSpan(child: Image.network(line.substring(10, line.length-2)));
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
        child: Center(
          child: Text(MyApp.locale.hwDetails_problem_empty)
        ),
      );
    }
    
    return Tile(
      width: double.infinity,
      child: SelectableText.rich(
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

class TestArea extends StatefulWidget {
  final Homework homework;

  const TestArea({
    super.key,
    required this.homework
  });

  @override
  State<TestArea> createState() => _TestAreaState();
}

class _TestAreaState extends State<TestArea> {
  bool _isAllTestRunning = false;

  bool _isDragOver = false;

  int _selectTestcase = 0;

  Widget _testcaseBtns() => GridView(
    shrinkWrap : true,
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 100,
        childAspectRatio: 2.8,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5
    ),
    children: List<int>.generate(widget.homework.testCases.length, (e) => e)
      .map((e) => _testcaseBtn(e))
      .toList()
  );

  Widget _testcaseWindow() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn,
      child: ClipRRect(
        clipBehavior: Clip.hardEdge,
        child: AnimatedSwitcher(
          switchInCurve: Curves.fastOutSlowIn,
          switchOutCurve: Curves.fastOutSlowIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(animation);

            final slideAnimation = child.key == ValueKey(_selectTestcase) 
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
          duration: const Duration(milliseconds: 300),
          child: _testcaseSection(_selectTestcase)
        )
      )
    );
  }

  Future<void> _onPerformDrop(PerformDropEvent event) async {
    for (var item in event.session.items) {
      if (item.dataReader == null) {
        logger.e("DataReader cannot read file from clipboard.");
        continue;
      }
      item.dataReader!.getValue(Formats.fileUri, _onLoad);
    }
  }

  Future<void> _onLoad(path) async {
    var myFile = File(Uri.decodeFull(path.toString().replaceAll(r"file:///", "")));

    widget.homework.testFile = myFile;
    // final tasks = [_homework.upload(myFile), _setKeyState()];
    // await Future.wait(tasks);

    if (!mounted) return;
    setState(() {});
  }

  void _onDropLeave(DropEvent event) {
    setState(() => _isDragOver = false);
  }

  DropOperation _onDropOver(DropOverEvent event) {
    setState(() => _isDragOver = true);
    return event.session.allowedOperations.firstOrNull ?? DropOperation.none;
  }

  Widget _loreWidget() {
    final testCases = widget.homework.testCases;

    if (widget.homework.testFile == null) {
      return Text(MyApp.locale.hwDetails_testArea_dropfileHere);
    }

    if (_isAllTestRunning) {
      return Text(MyApp.locale.hwDetails_testArea_testRunning);
    }

    final notPass = testCases.where((e) => !e.isPass).length;

    if (notPass == 0) {
      return Text(MyApp.locale.hwDetails_testArea_allPass);
    }

    return Text(MyApp.locale.hwDetails_testArea_stillNotPass.format([notPass]));
  }

  Future<void> _testAll() async {
    for (var testCase in widget.homework.testCases) {
      testCase.result = null;
      testCase.testing = true;
    }
    
    _isAllTestRunning = true;
    if (mounted) setState(() {});
    
    try {
      await widget.homework.testAll(widget.homework.testFile!);
    } on TestException catch (e) {
      logger.e(e.message);
    } finally {
      _isAllTestRunning = false;
      if (mounted) setState(() {});
    }
  }

  Widget _testCaseOutput(int index) {
    final testCase = widget.homework.testCases[index];

    if (testCase.result?.error.isNotEmpty??false) {
      return Text(MyApp.locale.hwDetails_testArea_testError
        .format([testCase.result!.error.join("\n"), testCase.result!.error.length]));
    }

    if (testCase.hasOutput) {
      return PrettyDiffText(
        textWidthBasis: TextWidthBasis.longestLine,
        defaultTextStyle: const TextStyle(color: Colors.white, fontFamily: "FiraCode"),
        oldText: testCase.result!.output.join("\n"),
        newText: testCase.output
      );
    }

    if (testCase.testing) {
      return Text(MyApp.locale.hwDetails_test_running);
    }
    
    return Text(MyApp.locale.hwDetails_testArea_haveNotRun); 
  }

  Future<void> _startTest(int index) async {
    final testCases = widget.homework.testCases;
    testCases[index].testing = true;
    testCases[index].result = null;

    setState(() {});

    try {
      await widget.homework.test(widget.homework.testFile!, index);
    } on TestException catch (e) {
      MyApp.showToast("${MyApp.locale.test}${index+1}", e.message, InfoBarSeverity.error);
      return;
    }
    
    setState(() {});
  }

  Widget _testcaseSection(int index) {
    if (widget.homework.testCases.isEmpty) {
      return Center(
        child: Text(MyApp.locale.hwDetails_cannot_parse_testcase)
      );
    }
    
    final testCase = widget.homework.testCases[index];

    return Tile(
      key: ValueKey(index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: testCase.hasOutput ? 
                    (testCase.isPass ? Colors.green.lightest : Colors.red.lightest) : 
                    Colors.grey,
                  borderRadius: BorderRadius.circular(10)
                )
              ),
              const SizedBox(width: 10),
              Text(
                "${MyApp.locale.testcase}"
                " ${index+1}",
                style: const TextStyle(color: Colors.white)
              )
            ]
          ),
          const SizedBox(height: 10),
          Text(MyApp.locale.input),
          const SizedBox(height: 5),
          SizedBox(
            width: double.infinity,
            child: SelectableTextBox(
              text: testCase.input,
              suffix: CopyButton(context: testCase.input)
            )
          ),
          const SizedBox(height: 10),
          Text(MyApp.locale.output),
          const SizedBox(height: 5),
          SizedBox(
            width: double.infinity,
            child: SelectableTextBox(
            text: testCase.output,
            suffix: CopyButton(context: testCase.output)
          )
          ),
          const SizedBox(height: 10),
          Text(MyApp.locale.test_result),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(child: _testCaseOutput(index)),
              Button(
                onPressed: widget.homework.testFile==null ? 
                  null : 
                  () => _startTest(index),
                child: const SizedBox.square(
                  dimension: 25,
                  child: Icon(FluentIcons.play)
                )
              ),
              const SizedBox(width: 5)
            ]
          )
        ]
      )
    );
  }

  Widget _testcaseBtn(int index) {
    final testCase = widget.homework.testCases[index];

    return Button(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: testCase.hasOutput ?
                (testCase.isPass ? Colors.green.lightest : Colors.red.lightest) : 
                Colors.grey
          )),
          const SizedBox(width: 10),
          Text("${MyApp.locale.data} ${index+1}", style: const TextStyle(fontWeight: FontWeight.bold))
        ]
      ),
      onPressed: () {
        if (widget.homework.testCases.any((e) => e.testing)) {
          return;
        }
        _selectTestcase = index;
        setState(() {});
      }
    );
  }

  Widget _main() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _testcaseBtns(),
        const SizedBox(height: 5),
        _testcaseWindow(),
        const SizedBox(height: 5),
        Tile.lore(
          title: MyApp.locale.hwDetails_testArea_testAll_title,
          lore: MyApp.locale.hwDetails_testArea_testAll_lore,
          icon: const Icon(FluentIcons.test_case),
          child: Row(
            children: [
              _loreWidget(),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: widget.homework.testFile == null || _isAllTestRunning ? null : _testAll,
                child: Text(MyApp.locale.hwDetails_testArea_startTest)
              )
            ]
          )
        )
      ]
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
      child: Container(
        foregroundDecoration: _isDragOver ? BoxDecoration(
          color: Colors.white.withValues(alpha: .075),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: Colors.white,
            width: 3
          )
        ): null,
        child: _main()
      )
    );
  }
}

class OverviewCard extends StatefulWidget {
  final Homework homework;

  // How many people passed this homework
  final List<String>? passVal;

  // Test case passed
  final List<CheckResult>? testcasesVal;

  const OverviewCard({
    super.key,
    required this.homework,
    required this.passVal,
    required this.testcasesVal
  });

  @override
  State<OverviewCard> createState() => _OverviewCardState();
}

class _OverviewCardState extends State<OverviewCard> {
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
          const SizedBox(width: 10),
          Text(MyApp.locale.hwDetails_state_not_submitted, style: TextStyle(fontWeight: FontWeight.bold, color: colors)),
          const Spacer(),
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
            value: widget.testcasesVal!
              .where((e) => e.pass).length
              .toDouble(),
            fractionDigits: 0,
            curve: Curves.easeInOutSine,
            duration: const Duration(milliseconds: 600),
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors)
          ),
          Text("/${widget.testcasesVal!.length}",
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
          const SizedBox(width: 5),
          AnimatedFlipCounter(
            value: widget.testcasesVal!
              .where((e) => e.pass).length
              .toDouble(),
            fractionDigits: 0,
            curve: Curves.easeInOutSine,
            duration: const Duration(milliseconds: 600),
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors)
          ),
          Text("/${widget.testcasesVal!.length}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors)),
          const SizedBox(width: 5),
          Text(MyApp.locale.hwDetails_passed, style: TextStyle(color: colors)),
          const Spacer()
        ]
      );

      case HomeworkState.delete: return Row(
        key: ValueKey(2),
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
        const Spacer(),
      ]
    );
  }

  bool isClickable() {
    switch (widget.homework.state) {
      
      case HomeworkState.notTried:
      case HomeworkState.checking:
      case HomeworkState.delete:
      case HomeworkState.compileFailed:
      case HomeworkState.preparing:
        return false;

      case HomeworkState.notPassed:
      case HomeworkState.passed:
        return (widget.testcasesVal != null);
    }
  }

  Future<void> _showTestcaseFlyOut() async {
    await _testCaseFlyOut.showFlyout(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.bottomRight,
      ),
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      navigatorKey: Navigator.of(context),
      builder: (context) {
        return TestCaseFlyout(
          results: widget.testcasesVal!
        );
      });
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
          passes: widget.passVal!
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    _successVal = widget.passVal == null ? _successVal : widget.passVal!.length.toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Spacer(),
        FlyoutTarget(
          controller: _personFlyOut,
          child: SizedBox(
            height: 50, width: 150,
            child: Button(
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                foregroundColor: WidgetStatePropertyAll(Colors.white)
              ),
              onPressed: widget.passVal == null ? null : _showPeopleFlyOut,
              child: _completeCount()
            )
          )
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 50, width: 150,
          child: Button(
            style: const ButtonStyle(
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
              foregroundColor: WidgetStatePropertyAll(Colors.white)
            ),
            onPressed: isClickable() ? _showTestcaseFlyOut : null,
            child: ClipRRect(
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
  final List<CheckResult> results;

  const TestCaseFlyout({
    super.key,
    required this.results
  });

  Widget _testDataRow(CheckResult result, BuildContext context) {
    return Tile(
      constraints: const BoxConstraints(
        minHeight: 48
      ),
      margin: const EdgeInsets.only(left: 10, right: 11),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: result.pass ? Colors.green.lighter : Colors.red.light,
              borderRadius: BorderRadius.circular(10)
            ),
          ),
          const SizedBox(width: 18),
          Text(result.title),
          const SizedBox(width: 10),
          Flexible(
            child: Text(result.message??"")
          ),
        ]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    final percent = results.where((e) => e.pass).length / results.length * 100;
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
          Tile(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(left: 10, right: 11, bottom: 10),
            child: Row(
              children: [
                Text(MyApp.locale.status),
                const SizedBox(width: 10),
                Text(MyApp.locale.number),
                const SizedBox(width: 10),
                Text(MyApp.locale.output),
                const Spacer(),
                Text("${percent.toStringAsFixed(0)} %", style: const TextStyle(
                  fontWeight: FontWeight.bold
                ))
              ]
            )
          ),
          Expanded(child: ListView.separated(
            itemBuilder: (context, index) => 
              _testDataRow(results[index], context),
            itemCount: results.length,
            separatorBuilder: (context, index) => 
              const SizedBox(height: 10),
          ))
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
    return Tile(
      margin: const EdgeInsets.only(left: 10, right: 11),
      child: Row(
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

    final FilePickerResult? outputFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      lockParentWindow: true,
      allowedExtensions: widget.homework.allowedExtensions,
      dialogTitle: MyApp.locale.hwDetails_select_homework_window_title
    );

    if (outputFile?.paths.first == null) {
      setState(() => _explorerOpen = false);
      return;
    }

    await _upload(outputFile!.paths.first);

    setState(() => _explorerOpen = false);
  }

  Future<void> _onPerformDrop(PerformDropEvent event) async {
    for (var item in event.session.items) {
      if (item.dataReader == null) {
        logger.e("DataReader cannot read file from drag object.");
        continue;
      }
      item.dataReader!.getValue(Formats.fileUri, _upload);
    }
  }

  Future<void> _upload(path) async {
    if ([HomeworkState.passed, HomeworkState.notPassed, HomeworkState.compileFailed].contains(widget.homework.state)) {
      final isConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _showDeleteAlert()
      );
      if (!(isConfirmed??false)) return;

      widget.homework.deleting = true;
      HomeworkInstance.update.add(EventType.refreshOverview);

      try {
        await widget.homework.delete();
      } on RuntimeError catch (e) {
        widget.homework.deleting = false;
        MyApp.showToast(MyApp.locale.hwDetails_failed_delete_homework, e.toString(), InfoBarSeverity.error);
        HomeworkInstance.update.add(EventType.refreshOverview);
        return;
      }
      
      widget.homework.deleting = false;
      HomeworkInstance.update.add(EventType.refreshOverview);
    }

    // For Chinese path support 
    var myFile = File(Uri.decodeFull(path.toString().replaceAll(r"file:///", "")));

    // var myFile = File(path.toString().replaceAll(r"file:///", "").replaceAll("%20", " "));

    widget.homework.submitting = true;
    HomeworkInstance.update.add(EventType.setStateDetail);

    await _uploadFile(myFile);

    GlobalSettings.update.add(GlobalEvent.setHwState);
    HomeworkInstance.update.add(EventType.refreshOverview);
  }

  Future<void> _uploadFile(File file) async{
    try {
      return await widget.homework.upload(file);
    } catch (e) {
      MyApp.showToast(MyApp.locale.hwDetails_failed_upload_homework, e.toString(), InfoBarSeverity.error);
      return;
    }
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
        height: _isDragOver ? 200 : 63,
        duration: const Duration(milliseconds: 150),
        foregroundDecoration: _isDragOver ? DottedDecoration(
          shape: Shape.box,
          strokeWidth: 2.5,
          color: FluentTheme.of(context).brightness.isDark ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(4)
        ): null,
        child: Tile(
          icon: const Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Icon(FluentIcons.upload)
            ] 
          ),
          child: Column(
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