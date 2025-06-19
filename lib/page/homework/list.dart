import 'dart:async';
import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import 'package:ntut_program_assignment/core/extension.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/main.dart';
import 'package:ntut_program_assignment/models/api_model.dart' show Homework;
import 'package:ntut_program_assignment/page/homework/details.dart';
import 'package:ntut_program_assignment/page/homework/page.dart';
import 'package:ntut_program_assignment/widgets/debug_widget.dart';
import 'package:ntut_program_assignment/widgets/general_page.dart';
import 'package:ntut_program_assignment/widgets/tile.dart';

class HomeworkInstance {
  static final StreamController<EventType> update = StreamController();
  static final stream = update.stream.asBroadcastStream();
  static List<Homework> homeworks = [];
}

class HomeworkList extends StatefulWidget {
  const HomeworkList({super.key});

  @override
  State<HomeworkList> createState() => _HomeworkListState();
}

class _HomeworkListState extends State<HomeworkList> with AutomaticKeepAliveClientMixin{
  String? errMsg;
  int? _loadCount;

  late bool _isReady = HomeworkInstance.homeworks.isNotEmpty;
  late StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _sub = GlobalSettings.stream.listen(_onGlobalEvent);
    if (HomeworkInstance.homeworks.isEmpty) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  void _onGlobalEvent(GlobalEvent e) {
    if (e == GlobalEvent.refreshHwList) {
      _refresh();
      if (mounted) setState(() {});
    } else if (e == GlobalEvent.setHwState) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _refresh() async {
    if (_loadCount != null) {
      return;
    }

    if (!GlobalSettings.isLogin) {
      return;
    }

    HomeworkInstance.homeworks.clear();
    
    errMsg = null;
    _loadCount = 0;
    setState(() => _isReady = false);

    try {
      HomeworkInstance.homeworks = await GlobalSettings.account!.fetchHomeworkList();
      await _fetchDescription();
      await Homework.refreshHomeworkListHandedIn(HomeworkInstance.homeworks);
    } catch (e) {
      errMsg = e.toString();
      _loadCount = null;
      
      if (mounted) setState(() {});
      return;
    }
    
    _isReady = true;
    _loadCount = null;

    if (mounted) setState(() {});
  }

  void _onHomeworkLoadDone(val) {
    _loadCount = (_loadCount??0) + 1 ;
    if (mounted) return;
    setState(() {});
  }

  Future<void> _fetchDescription() async {
    if (mounted) setState(() => _loadCount = 0);

    Future<int> handleError(Object? e, StackTrace s) async {
       MyApp.showToast(
        MyApp.locale.error_occur, 
        e.toString(),
        InfoBarSeverity.error
      );
      return 0;
    }

    final tasks = HomeworkInstance.homeworks.map((hw) => 
      hw.fetchHomeworkDetail()
        .then(_onHomeworkLoadDone)
        .onError(handleError)
    );
    
    await Future.wait(tasks);
  }

  Widget _listItem(Homework hw) {
    return Tile(
      title: Text(
        "${hw.hwId} ${hw.title??''}"
      ),
      subtitle: Text(
        "${MyApp.locale.hwDetails_deadline}: ${hw.deadline.toRelative()}"
      ),
      leading: Icon(
        hw.isPass ? FluentIcons.check_mark :
          hw.canHandIn ? FluentIcons.pen_workspace : FluentIcons.clear 
      ),
      trailing: Icon(FluentIcons.chevron_right),
      onPressed: () {
        if (GlobalSettings.route.current.name == "hwDetail") {
          return;
        }
        GlobalSettings.route.push(
          "hwDetail",
          title: "${hw.hwId} ${hw.title??MyApp.locale.no_title}", 
          parameter: {"id": hw.id-1},
        );
      }
    );
  }

  Widget _pendingHws() {
    final notPasses = HomeworkInstance.homeworks
      .where((e) => !e.isPass);

    if (notPasses.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(MyApp.locale.hwDetails_failed, style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        SizedBox(
          height: (61 * notPasses.length) + (10 * (notPasses.length-1)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: notPasses
              .map((e) => _listItem(e))
              .toList()
          )
        )
      ]
    );
  }

  Widget _debugSection() {
    String result = HomeworkInstance.homeworks
      .map((e) => json.encode(e.toMap()))
      .join("\n");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("偵錯選項", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Tile(
          limitIconSize: true,
          title: Text("複製所有題目"),
          subtitle: Text("將所有題目轉換成 JSON 後複製到剪貼簿"),
          leading: const Icon(FluentIcons.clipboard_list),
          trailing: CopyButton(
            context: result
          )
        )
      ]
    );
  }

  Widget _passedHws() {
    final passed = HomeworkInstance.homeworks
      .reversed
      .where((e) => e.isPass);

    if (passed.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(MyApp.locale.hwDetails_passed, style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        SizedBox(
          height: (60 * passed.length) + (10 * (passed.length-1)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: passed
              .map((e) => _listItem(e))
              .toList()
          )
        )
      ]
    );
  }

  Widget _overviewCard() {
    final passes = HomeworkInstance.homeworks.where((e) => e.isPass);

    final passRate = passes.length / HomeworkInstance.homeworks.length * 100;
    return Row(
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.lightest,
            borderRadius: BorderRadius.circular(500)
          ),
          child: const Icon(FluentIcons.user_optional, size: 20),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(GlobalSettings.account!.name.toString()),
            Text(GlobalSettings.account!.username.toString())
          ]
        ),
        const SizedBox(width: 15),
        IconButton(
          icon: const Icon(FluentIcons.refresh),
          onPressed: () async {
            _refresh();
          }
        ),
        const Spacer(),
        SizedBox(
          height: 50, width: 150,
          child: Tile(
          // alignment: Alignment.center,
            padding: EdgeInsets.zero, 
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Row(
                  children: [
                    Spacer(),
                    Text("${passes.length}/${HomeworkInstance.homeworks.length}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Text(MyApp.locale.hwDetails_completion),
                    Spacer()
                  ]
                ),
                const Spacer(),
                SizedBox(
                  width: 150,
                  child: ProgressBar(value: passRate)
                )
              ]
            )
          )
        ),
        
        const SizedBox(width: 10),
        SizedBox(
          height: 50, width: 150,
          child: Tile(
            padding: EdgeInsets.zero,
            trailing: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Text("${HomeworkInstance.homeworks.length-passes.length}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Text(MyApp.locale.hwDetails_failed),
                const Spacer()
              ]
            )
          )
        )
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (GlobalSettings.account?.isLoggingIn ?? false) {
      return const LoggingInBlock();
    }

    if (GlobalSettings.account == null) {
      return const LoginBlock();
    }

    if (errMsg != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FluentIcons.error, size: 50),
            const SizedBox(height: 10),
            Text("${MyApp.locale.error_occur}\n$errMsg", textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _refresh,
              child: Text(MyApp.locale.refresh),
            )
          ]
        )
      );
    }

    if (!_isReady) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProgressRing(),
            const SizedBox(height: 10),
            Text(MyApp.locale.loading),
          ]
        )
      );
    }

    final widgetList = [
      _overviewCard(),
      _pendingHws(),
      _passedHws(),
      DebugOnlyWidget(
        child: _debugSection()
      )
    ];
    
    return ListView.separated(
      shrinkWrap: true,
      itemBuilder: (context, index) => 
        widgetList[index],
      separatorBuilder: (context, index) =>
        const SizedBox(height: 10),
      itemCount: widgetList.length
    );
  }
  
  @override
  bool get wantKeepAlive => true;

}