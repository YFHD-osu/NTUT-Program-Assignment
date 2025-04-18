import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import 'package:ntut_program_assignment/widgets/diff_indicator.dart';
import 'package:ntut_program_assignment/widgets/selectable_text_box.dart';
import 'package:ntut_program_assignment/widgets/tile.dart';
import 'package:ntut_program_assignment/core/extension.dart';
import 'package:ntut_program_assignment/core/test_server.dart';
import 'package:ntut_program_assignment/main.dart' show MyApp, logger;
import 'package:ntut_program_assignment/page/homework/details.dart';

class TestArea extends StatefulWidget {
  final Testcase testcase;

  const TestArea({
    super.key,
    required this.testcase
  });

  @override
  State<TestArea> createState() => _TestAreaState();
}

class _TestAreaState extends State<TestArea> {
  bool _isDragOver = false;
  int _selectTestcase = 0;
  int _viewMode = 1;

  Case get _current =>
    widget.testcase.cases[_selectTestcase];

  Testcase get _testCase =>
    widget.testcase;
  
  bool get _canStartTest =>
    widget.testcase.testFile == null || widget.testcase.anyTestRunning;

  Widget _testcaseBtns() => GridView(
    shrinkWrap : true,
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 100,
        childAspectRatio: 2.8,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5
    ),
    children: List<int>.generate(widget.testcase.cases.length, (e) => e)
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

    if (!widget.testcase.allowedExtensions.contains(myFile.path.split(".").last)) {
      logger.i("Unsupported format: ${myFile.path}");
      MyApp.showToast(
        MyApp.locale.error_occur, 
        "${MyApp.locale.test_server_file_not_support} ${widget.testcase.allowedExtensions.map((e) => ".$e").join(", ")}",
        InfoBarSeverity.error
      );
      return;
    }

    _testCase.testFile = myFile;

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

    if (filename != null && !widget.testcase.allowedExtensions.contains(filename.split(".").last)) {
      return DropOperation.none;
    }

    if (!_isDragOver) {
      setState(() => _isDragOver = true);
    }
    return DropOperation.link;
  }

  Widget _loreWidget() {
    // print(widget.homework.testCases.map((e) => e.testing));
    if (_testCase.testFile == null) {
      return Text(MyApp.locale.hwDetails_testArea_dropfileHere);
    }

    if (_testCase.anyTestRunning) {
      return Text(MyApp.locale.hwDetails_testArea_testRunning);
    }

    final notPass = _testCase.cases.where((e) => !e.isPass).length;

    if (notPass == 0) {
      return Text(MyApp.locale.hwDetails_testArea_allPass);
    }

    return Text(MyApp.locale.hwDetails_testArea_stillNotPass.format([notPass]));
  }

  Future<void> _testAll() async {
    _viewMode = 2;

    for (var testCase in _testCase.cases) {
      testCase.resetTestState();
    }

    try {
      if (mounted) setState(() {});

      await _testCase.testAll(
        widget.testcase.testFile!,
        widget.testcase.codeType
      );

    } catch (e) {
      logger.e(e.toString());
    } finally {
      for (var testCase in _testCase.cases) {
        testCase.setOutput();
      }

      if (mounted) setState(() {});
    }
  }  

  Widget _testcaseBtn(int index) {
    final testCasse = _testCase.cases[index];

    return Button(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: testCasse.hasOutput ?
                (testCasse.isPass ? Colors.green.lightest : Colors.red.lightest) : 
                Colors.grey
          )),
          const SizedBox(width: 10),
          Text("${MyApp.locale.data} ${index+1}", style: const TextStyle(fontWeight: FontWeight.bold))
        ]
      ),
      onPressed: () {
        if (_testCase.cases.any((e) => e.testing)) {
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
            Tile(
              title: Text("輸出檢視模式"),
              subtitle: Text("調整輸出資料與答案的檢視比較模式"),
              leading: const Icon(FluentIcons.entry_view),
              trailing: ComboBox<int>(
                value: _viewMode,
                items: [
                  ComboBoxItem(
                    value: 1,
                    child: Text("僅顯示答案")
                  ),
                  ComboBoxItem(
                    value: 0,
                    enabled: _current.hasOutput,
                    child: Text("僅顯示輸出")
                  ),
                  ComboBoxItem(
                    value: 2,
                    enabled: _current.hasOutput,
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
            Tile(
              title: Text(MyApp.locale.hwDetails_testArea_testAll_title),
              subtitle: Text(MyApp.locale.hwDetails_testArea_testAll_lore),
              leading: const Icon(FluentIcons.test_case),
              trailing: Row(
                children: [
                  _loreWidget(),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _canStartTest ? null : _testAll,
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
        child: SelectableTextBox(text: _current.output)
      );
    }

    if (_current.testing) {
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

    if (_current.hasError) {
      return SelectableTextBox(
        text: "${MyApp.locale.hwDetails_testArea_testError}\n"
              "${_current.testError!.join('\n')}"
      );
    }

    if (! _current.hasOutput) {
      return SelectableTextBox(text: MyApp.locale.hwDetails_testArea_haveNotRun);
    }

    if (_viewMode == 0) {
      final text = _current.testOutput!.join("\n");
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: 350
        ),
        child: SelectableTextBox(text: text)
      );
    }

    return SingleChildScrollView(
      child: TestCaseView(testCase: _current)
    );
  }

  String? _fetchTextContext() {
    switch (_viewMode) {
      case 0: // Only output context
        final text = _current.testOutput!.join("\n");
        return text; 

      case 1: // Only answer context
        return _current.output;

      default: // Compare mode
        return null;
    }
  }

  Widget _testcaseSection() {
    if (_testCase.cases.isEmpty) {
      return Center(
        child: Text(MyApp.locale.hwDetails_cannot_parse_testcase)
      );
    }

    return Tile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: _current.hasOutput ? 
                    (_current.isPass ? Colors.green.lightest : Colors.red.lightest) : 
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
              text: _current.input,
              suffix: CopyButton(context: _current.input)
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
            onPressed: _canStartTest ? 
              null : () => _startTest(_selectTestcase),
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
    _testCase.cases[index].resetTestState();
    _viewMode = 2;

    setState(() {});

    try {
      await _testCase.compileAndTest(
        widget.testcase.testFile!,
        index,
        widget.testcase.codeType
      );
    } on TestException catch (e) {
      MyApp.showToast("${MyApp.locale.test}${index+1}", e.message, InfoBarSeverity.error);
      if (mounted) setState(() {});
      
      return;
    }
    
    setState(() {});
  }
}