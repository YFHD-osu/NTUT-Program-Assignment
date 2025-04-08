import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/core/diff_matcher.dart';
import 'package:ntut_program_assignment/core/extension.dart';
import 'package:ntut_program_assignment/core/test_server.dart';

import 'package:ntut_program_assignment/main.dart' show MyApp, logger;
import 'package:ntut_program_assignment/page/homework/details.dart';
import 'package:ntut_program_assignment/widget.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

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

  int _viewMode = 1;

  Testcase get testCase =>
    widget.homework.testCases[_selectTestcase];

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
          child: _testcaseSection()
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

    if (!widget.homework.allowedExtensions.contains(myFile.path.split(".").last)) {
      logger.i("Unsupported format: ${myFile.path}");
      MyApp.showToast(
        MyApp.locale.error_occur, 
        "${MyApp.locale.test_server_file_not_support} ${widget.homework.allowedExtensions.map((e) => ".$e").join(", ")}",
        InfoBarSeverity.error
      );
      return;
    }

    widget.homework.testFile = myFile;
    // final tasks = [_homework.upload(myFile), _setKeyState()];
    // await Future.wait(tasks);

    if (!mounted) return;
    setState(() {});
  }

  void _onDropLeave(DropEvent event) {
    setState(() => _isDragOver = false);
  }

  Future<DropOperation> _onDropOver(DropOverEvent event) async {
    if (_isDragOver) {
      return DropOperation.link;
    }

    final filename = await event.session.items.first.dataReader?.rawReader?.getSuggestedName();

    if (filename != null && !widget.homework.allowedExtensions.contains(filename.split(".").last)) {
      return DropOperation.none;
    }

    if (!_isDragOver) {
      setState(() => _isDragOver = true);
    }
    return DropOperation.link;
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
      testCase.resetTestState();
    }
    
    _isAllTestRunning = true;
    _viewMode = 2;

    try {
      if (mounted) setState(() {});
      
      await widget.homework.testAll(widget.homework.testFile!);
    } on TestException catch (e) {
      logger.e(e.message);

      MyApp.showToast(
        MyApp.locale.error_occur, 
        e.message,
        InfoBarSeverity.error
      );
    } finally {
      for (var testCase in widget.homework.testCases) {
        testCase.setOutput();
      }

      _isAllTestRunning = false;
      if (mounted) setState(() {});
    }
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _testcaseBtns(),
            const SizedBox(height: 5),
            _testcaseWindow(),
            const SizedBox(height: 5),
            Tile.lore(
              title: "輸出檢視模式",
              lore: "調整輸出資料與答案的檢視比較模式",
              icon: const Icon(FluentIcons.entry_view),
              child: ComboBox<int>(
                value: _viewMode,
                items: [
                  ComboBoxItem(
                    value: 1,
                    child: Text("僅顯示答案")
                  ),
                  ComboBoxItem(
                    value: 0,
                    enabled: testCase.hasOutput,
                    child: Text("僅顯示輸出")
                  ),
                  ComboBoxItem(
                    value: 2,
                    enabled: testCase.hasOutput,
                    child: Text("比較答案與輸出")
                  ),
                ],
                onChanged: (value) {
                  _viewMode = value ?? 0;
                  setState(() {});
                }
              )
            ),
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
        )
      )
    );
  }

  Widget _viewPortBuilder() {
    if (_viewMode == 1) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: 350
        ),
        child: SelectableTextBox(text: testCase.output)
      );
    }

    if (testCase.testing) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ProgressRing(),
          SizedBox(width: 10),
          Text(MyApp.locale.hwDetails_test_running)
        ]
      );
    }

    if (testCase.hasError) {
      return Text(MyApp.locale.hwDetails_testArea_testError
        .format([testCase.testError!.join("\n"), testCase.testError!.length]));
    }

    if (! testCase.hasOutput) {
      return Text(MyApp.locale.hwDetails_testArea_haveNotRun);
    }

    if (_viewMode == 0) {
      final text = testCase.testOutput!.join("\n");
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: 350
        ),
        child: SelectableTextBox(text: text)
      );
    }

    return SingleChildScrollView(
      child: TestCaseView(testCase: testCase)
    );
  }

  String? _fetchTextContext() {
    switch (_viewMode) {
      case 0: // Only output context
        final text = testCase.testOutput!.join("\n");
        return text; 

      case 1: // Only answer context
        return testCase.output;

      default: // Compare mode
        return null;
    }
  }

  Widget _testcaseSection() {
    // print("INSPECT ${widget.index} is ${testCase.testing} (1)");

    if (widget.homework.testCases.isEmpty) {
      return Center(
        child: Text(MyApp.locale.hwDetails_cannot_parse_testcase)
      );
    }

    return Tile(
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
                " ${_selectTestcase+1}",
                style: const TextStyle(color: Colors.white)
              )
            ]
          ),
          const SizedBox(height: 10),
          Text(MyApp.locale.input),
          const SizedBox(height: 5),
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: double.infinity,
              maxHeight: 250, minHeight: 0
            ),
            child: SelectableTextBox(
              text: testCase.input,
              suffix: CopyButton(context: testCase.input)
            )
          ),
          const SizedBox(height: 10),
          Text("${MyApp.locale.output} & ${MyApp.locale.test_result}"),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: _viewPortBuilder()
              ),
              SizedBox(width: 5),
              CopyButton(context: _fetchTextContext())
            ]
          ),
          SizedBox(height: 10),
          Text("單獨測試"),
          SizedBox(height: 5),
          FilledButton(
            onPressed: widget.homework.testFile==null ? 
              null : 
              () => _startTest(_selectTestcase),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.play),
                SizedBox(width: 10),
                Text("重新測試")
              ]
            )
          )
        ]
      )
    );
  }

  Future<void> _startTest(int index) async {
    final testCases = widget.homework.testCases;
    testCases[index].resetTestState();

    _viewMode = 2;

    setState(() {});
    // await Future.delayed(Duration(seconds: 10));

    try {
      await widget.homework.compileAndTest(widget.homework.testFile!, index);
    } on TestException catch (e) {
      MyApp.showToast("${MyApp.locale.test}${index+1}", e.message, InfoBarSeverity.error);
      return;
    }
    
    setState(() {});
  }

}