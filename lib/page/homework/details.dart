import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:file_picker/file_picker.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:pretty_diff_text/pretty_diff_text.dart';
import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

import 'package:ntut_program_assignment/widget.dart';
import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/main.dart' show logger;
import 'package:ntut_program_assignment/page/homework/router.dart';

class HomeworkDetail extends StatefulWidget {
  final Homework homework;
  
  const HomeworkDetail({
    super.key,
    required this.homework
  });

  @override
  State<HomeworkDetail> createState() => _HomeworkDetailState();
}

class _HomeworkDetailState extends State<HomeworkDetail> {
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
    final tasks = [_loadSuccess(), _loadTest()];
    await Future.wait(tasks);
  }

  @override
  void initState() {
    super.initState();
    _sub = Controller.stream.listen(_onEvent);
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
    setState(() => _passList = null);
    
    _passList = await widget.homework.fetchPassList();

    if (mounted) setState(() {});
  }

  Future<void> _loadTest() async {
    setState(() {});
    _testcasesVal = await widget.homework.fetchTestcases();

    if (mounted) setState(() {});
  }

  bool canDelete() {
    switch (widget.homework.state) {
      case HomeworkState.notPassed:
      case HomeworkState.passed:
        return DateTime.now().compareTo(widget.homework.deadline) <= 0;

      default:
        return false;
    }
  }

  Widget _showDeleteConfirm() {
    return ContentDialog(
      constraints: const BoxConstraints(
        minHeight: 0, minWidth: 0, maxHeight: 400, maxWidth: 400),
      title: const Text("刪除操作確認"),
      content: const Text("您確定要刪除此作業嗎?"),
      actions: [
        CustomWidgets.alertButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: const Text('刪除'),
        ),
        Button(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('取消'),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.homework.description == null) {
      return const Center(
        child: ProgressRing()
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        OverviewCard(
          homework: widget.homework,
          passVal: _passList,
          testcasesVal: _testcasesVal,

        ),
        const SizedBox(height: 10),
        const Text("上傳",
          style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        UploadSection(
          homework: widget.homework
        ),
        const SizedBox(height: 10),
        const Text("題目",
          style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Tile(
          width: double.infinity,
          child: SelectableTextBox(
            text: widget.homework.description!.problem
          )
        ),
        const SizedBox(height: 10),
        const Text("測試",
          style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        const SizedBox(height: 5),
        

        TestAllTile(
          homework: widget.homework
        ),
        const SizedBox(height: 5),
        const SizedBox(height: 10),
        const Text("危險區域",
          style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Tile.lore(
          title: "刪除作業",
          lore: "將目前所上傳的作業檔案刪除",
          icon: const Icon(FluentIcons.delete),
          child: CustomWidgets.alertButton(
            child: const Text("刪除作業"),
            onPressed: !canDelete() ? null : () async {
              final isConfirmed = await showDialog<bool>(
                context: context,
                builder: (context) => _showDeleteConfirm()
              );

              if (!(isConfirmed??false)) return;

              logger.i("Homework deleted!");

              final task = widget.homework.delete();
              setState(() {});
              await task;

              refresh();
              
              setState(() {});
            }
          )
        )
      ]
    );
  }
}

class TestAllTile extends StatefulWidget {
  final Homework homework;

  const TestAllTile({
    super.key,
    required this.homework
  });

  @override
  State<TestAllTile> createState() => _TestAllTileState();
}

class _TestAllTileState extends State<TestAllTile> {
  File? selFile;
  bool _isAllTestRunning = false;

  bool _isDragOver = false;

  int _selectTestcase = 0;

  List<bool> copyState = [false, false];

  Widget _copyIcon(bool key) {
    if (!key) {
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

  Widget _testcaseBtns() => GridView(
    shrinkWrap : true,
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 100,
        childAspectRatio: 2.8,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5
    ),
    children: List<int>.generate(widget.homework.description!.testCases.length, (e) => e)
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

    selFile = myFile;
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
    final testCases = widget.homework.description!.testCases;

    if (selFile == null) {
      return const Text("尚未選取檔案");
    }

    if (_isAllTestRunning) {
      return const Text("測試中...");
    }

    final notPass = testCases.where((e) => !e.isPass).length;

    if (notPass == 0) {
      return const Text("通過所有測資");
    }

    return Text("尚有 $notPass 個未通過");
  }

  Future<void> _testAll() async {
    final testCases = widget.homework.description!.testCases;

    setState(() => _isAllTestRunning = true);
    
    final tasks = testCases
      .map((e) => e.exec(selFile!));
    
    try {
      await Future.wait(tasks);
    } on TestException catch (e) {
      logger.e(e.message);
    } finally {
      setState(() => _isAllTestRunning = false);
    }
  }

  Widget _testCaseOutput(int index) {
    final testCase = widget.homework.description!.testCases[index];

    if (testCase.result?.error.isNotEmpty??false) {
      return Text("發生錯誤: ${testCase.result!.error.join("\n")} (${testCase.result!.error.length})");
    }

    if (testCase.hasOutput) {
      return PrettyDiffText(
        defaultTextStyle: const TextStyle(color: Colors.white, fontFamily: "FiraCode"),
        oldText: testCase.result!.output.join("\n"),
        newText: testCase.output
      );
    }
    
    return const Text("尚未執行測試"); 
  }

  Widget _testcaseSection(int index) {
    final testCase = widget.homework.description!.testCases[index];

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
              Text("測試資料 ${index+1}", style: const TextStyle(color: Colors.white))
            ]
          ),
          const SizedBox(height: 10),
          const Text("輸入"),
          const SizedBox(height: 5),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              SizedBox(
                width: double.infinity,
                child: SelectableTextBox(text: testCase.input)
              ),
              Button(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 100),
                  child: _copyIcon(copyState.first)
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: testCase.input));
                  setState(() => copyState.first = true);
                  await Future.delayed(const Duration(milliseconds: 800));
                  setState(() => copyState.first = false);
                }
              )
            ]
          ),
          const SizedBox(height: 10),
          const Text("輸出"),
          const SizedBox(height: 5),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              SizedBox(
                width: double.infinity,
                child: SelectableTextBox(text: testCase.output)
              ),
              Button(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 100),
                  child: _copyIcon(copyState.last)
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: testCase.output));
                  setState(() => copyState.last = true);
                  await Future.delayed(const Duration(milliseconds: 800));
                  setState(() => copyState.last = false);
                }
              )
            ]
          ),
          const SizedBox(height: 10),
          const Text("測試結果"),
          const SizedBox(height: 5),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              SizedBox(
                width: double.infinity,
                child: _testCaseOutput(index)
              ),
              Button(
                onPressed: selFile==null ? null : () async {
                  try {
                    await testCase.exec(selFile!);
                  } on TestException catch (e) {
                    GlobalSettings.showToast("測試${index+1} ", e.message, InfoBarSeverity.error);
                    return;
                  }
                  // print(result.output.join("\n"));
                  setState(() {});
                },
                child: const SizedBox.square(
                  dimension: 25,
                  child: Icon(FluentIcons.play)
                )
              )
            ]
          )
        ]
      )
    );
  }

  Widget _testcaseBtn(int index) {
    final testCase = widget.homework.description!.testCases[index];

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
          Text("資料 ${index+1}", style: const TextStyle(fontWeight: FontWeight.bold))
        ]
      ),
      onPressed: () => setState(() => _selectTestcase = index)
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
          title: "全部測試",
          lore: "將所有範例測試資料全部驗證過一次",
          icon: const Icon(FluentIcons.test_case),
          child: Row(
            children: [
              _loreWidget(),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: selFile == null ? null : _testAll,
                child: const Text("開始測試")
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
          color: Colors.white.withOpacity(.075),
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
          const Text("尚未繳交", style: TextStyle(fontWeight: FontWeight.bold)),
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
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          Text("/${widget.testcasesVal!.length}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          const Text("未通過"),
          const Spacer(),
        ]
      );

      case HomeworkState.checking: return const Row(
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
          Text("批改中", style: TextStyle(fontWeight: FontWeight.bold)),
          Spacer()
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
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          Text("/${widget.testcasesVal!.length}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          const Text("通過"),
          const Spacer()
        ]
      );

      case HomeworkState.delete: return const Row(
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
          Text("刪除中", style: TextStyle(fontWeight: FontWeight.bold)),
          Spacer()
        ]
      );
    }
  }

  Widget _completeCount() {
    return Row(
      children: [
        const Spacer(),
        AnimatedFlipCounter(
          value: _successVal,
          fractionDigits: 0,
          curve: Curves.easeInOutSine,
          duration: const Duration(milliseconds: 600),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        ),
        const SizedBox(width: 10),
        const Text("完成人數"),
        const Spacer(),
      ]
    );
  }

  bool isClickable() {
    switch (widget.homework.state) {
      
      case HomeworkState.notTried:
      case HomeworkState.checking:
      case HomeworkState.delete:
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

class DetailRoute extends StatefulWidget {
  const DetailRoute({super.key});

  @override
  State<DetailRoute> createState() => _DetailRouteState();
}

class _DetailRouteState extends State<DetailRoute> {
  @override
  Widget build(BuildContext context) {
    if (Controller.routes.last.value.index >= Controller.homeworks.length) {
      return const Text("Index out of range");
    }

    final homework = Controller.homeworks[Controller.routes.last.value.index];
    return PageBase(
      child: HomeworkDetail(
        homework: homework
      )
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
        color: Colors.black.withOpacity(.25),
        child: const Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(FluentIcons.select_all, size: 35),
            SizedBox(width: 10),
            Text("放開選取檔案")
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
            child: Text(result.message??"吃我機八")
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
                const Text("狀態"),
                const SizedBox(width: 10),
                const Text("編號"),
                const SizedBox(width: 10),
                const Text("輸出"),
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
      allowedExtensions: ["py"],
      dialogTitle: '選取作業');

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

    if ([HomeworkState.passed, HomeworkState.notPassed].contains(widget.homework.state)) {
      final isConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _showDeleteAlert()
      );
      if (!(isConfirmed??false)) return;

      await widget.homework.delete();
      Controller.update.add(EventType.refreshOverview);
    }

    var myFile = File(Uri.decodeFull(path.toString().replaceAll(r"file:///", "")));

    widget.homework.submitting = true;
    Controller.update.add(EventType.setStateDetail);

    await widget.homework.upload(myFile);

    Controller.update.add(EventType.refreshOverview);
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
      title: const Text("重新繳交作業"),
      content: const Text("必須要先刪除現有版本才能重新上傳，確定要操作嗎?"),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: const Text('刪除並上傳'),
        ),
        Button(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('取消'),
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("作業上傳"),
                      Text("選擇檔案或是將檔案拖曳制這裡來上傳作業")
                    ]
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: isClickable ? _browseHomework : null,
                    child: const Text("選取檔案"),
                  )
                ]
              ),
              Expanded(
                child: Center(
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(FluentIcons.cloud_upload, size: 50)),
                        WidgetSpan(child: SizedBox(width: 10)),
                        TextSpan(text: "放開來上傳檔案")
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