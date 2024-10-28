import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:pretty_diff_text/pretty_diff_text.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

import 'package:ntut_program_assignment/widget.dart';
import 'package:ntut_program_assignment/core/api.dart';
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
  // Store the testcase that currently selected
  int _selectTestcase = 0;

  // Store the list of all student ID that passes this homework 
  List<String>? _passList = [];

  // Store all online checked testcases status and messages
  List<CheckResult> _testcasesVal = [];

  bool inputCopy = false, outputCopy = false;

  Future<void> refresh() async {
    final tasks = [_loadSuccess(), _loadTest()];
    await Future.wait(tasks);
  }

  @override
  void initState() {
    super.initState();
    refresh();
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
                  child: _copyIcon(inputCopy)
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: testCase.input));
                  setState(() => inputCopy = true);
                  await Future.delayed(const Duration(milliseconds: 800));
                  setState(() => inputCopy = false);
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
                  child: _copyIcon(outputCopy)
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: testCase.output));
                  setState(() => outputCopy = true);
                  await Future.delayed(const Duration(milliseconds: 800));
                  setState(() => outputCopy = false);
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
                child: !testCase.hasOutput ? const Text("尚未執行測試") : PrettyDiffText(
                  defaultTextStyle: const TextStyle(color: Colors.white, fontFamily: "FiraCode"),
                  oldText: testCase.result!.output.join("\n"),
                  newText: testCase.output
                )
              ),
              Button(
                child: const AnimatedSwitcher(
                  duration: Duration(milliseconds: 100),
                  child: SizedBox.square(
                    dimension: 25,
                    child: Icon(FluentIcons.play)
                  )
                ),
                onPressed: () async {
                  late final TestResult result;
                  try {
                    await testCase.exec(File(r"C:\Users\YFHD\Documents\NTUT-Works\Program Design\015.py"));
                  } on TestException catch (e) {
                    // ignore: use_build_context_synchronously
                    Controller.showToast(context, "測試${index+1} ", e.message, InfoBarSeverity.error);
                    return;
                  }



                  // print(result.output.join("\n"));
                  setState(() {});
                }
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

  bool canDelete() {
    switch (widget.homework.state) {
      case HomeworkState.notPassed:
      case HomeworkState.passed:
        return DateTime.now().compareTo(widget.homework.deadline) <= 0;

      default:
        return false;
    }
  }

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
        const Text("測試與上傳",
          style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        GridView(
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
        ),
        const SizedBox(height: 5),
        _testcaseWindow(),
        const SizedBox(height: 5),
        Tile.lore(
          title: "全部測試",
          lore: "將所有範例測試資料全部驗證過一次",
          icon: const Icon(FluentIcons.test_case),
          child: FilledButton(
            onPressed: () {

            },
            child: const Text("開始測試"),
          )
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
                builder: (context) => const ConfirmDialog()
              );

              if (!(isConfirmed??false)) return;

              logger.i("Homework deleted!");

              final task = widget.homework.delete();
              setState(() {});
              await task;

              _passList = await widget.homework.fetchPassList();
              
              setState(() {});
            }
          )
        )
      ]
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
  bool _isDragOver = false;

  final _homework = Controller.homeworks[Controller.routes.last.value.index];
  
  final key = GlobalKey<_HomeworkDetailState>(); 

  Future<void> _setKeyState() async {
    key.currentState?.setState(() {});
  }
  
  Future<void> _onLoad(path) async {
    var myFile = File(Uri.decodeFull(path.toString().replaceAll(r"file:///", "")));
    await _homework.upload(myFile);
    final tasks = [_homework.upload(myFile), _setKeyState()];
    await Future.wait(tasks);

    key.currentState?.setState(() {});
    await key.currentState?.refresh();
    if (!mounted) return;
    setState(() {});
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

  void _onDropLeave(DropEvent event) {
    setState(() => _isDragOver = false);
  }

  DropOperation _onDropOver(DropOverEvent event) {
    setState(() => _isDragOver = true);
    return event.session.allowedOperations.firstOrNull ?? DropOperation.none;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedOpacity(
          opacity: _isDragOver ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: const DropItemInfo()
        ),
        DropRegion(
          formats: const [
            ...Formats.standardFormats,
            Formats.fileUri
          ],
          hitTestBehavior: HitTestBehavior.opaque,
          onDropOver: _onDropOver,
          onDropLeave: _onDropLeave,
          onPerformDrop: _onPerformDrop,
          child: PageBase(
            child: HomeworkDetail(
              key: key,
              homework: _homework
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
    
    return Center(
      child: Container(
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
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FluentIcons.cloud_upload, size: 100),
              SizedBox(height: 10),
              Text("放開以上傳作業")
            ]
          )
        ) 
      )
    );
  }
}

class ConfirmDialog extends StatefulWidget {
  const ConfirmDialog({
    super.key,
  });

  @override
  State<ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> {
  @override
  Widget build(BuildContext context) {

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