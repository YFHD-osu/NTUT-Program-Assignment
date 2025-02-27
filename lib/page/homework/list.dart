import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/main.dart';

import 'package:ntut_program_assignment/widget.dart';
import 'package:ntut_program_assignment/page/homework/page.dart';

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
  double? _loadPercent;
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
      setState(() => {});
    } else if (e == GlobalEvent.setHwState) {
      setState(() {});
    }
  }

  Future<void> _refresh() async {
    if (_loadPercent != null) {
      return;
    }

    if (GlobalSettings.account == null) {
      return;
    }

    HomeworkInstance.homeworks.clear();
    
    errMsg = null;
    _loadPercent = 0;
    setState(() => _isReady = false);

    try {
      HomeworkInstance.homeworks = await GlobalSettings.account!.fetchHomeworkList();
      await _fetchDescription();
      await Homework.refreshHandedIn(HomeworkInstance.homeworks);
    } on RuntimeError catch (e) {
      errMsg = e.message;
      _loadPercent = null;
      
      if (mounted) setState(() {});
      return;
    }
    
    _isReady = true;
    _loadPercent = null;

    if (mounted) setState(() {});
  }

  Future<void> _fetchDescription() async {
    final sum = HomeworkInstance.homeworks.length;
    int index = 0;
    if (mounted) setState(() => _loadPercent = 0);
    for (var hw in HomeworkInstance.homeworks) {
      if (hw.id == 39) continue;
      await hw.fetchHomeworkDetail();

      index ++;
      if (mounted) setState(() => _loadPercent = index/sum*100);
    }
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
          height: (65 * notPasses.length) + (10 * (notPasses.length-1)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: notPasses
              .map((e) => ListItem(homework: e))
              .toList()
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
          height: (65 * passed.length) + (10 * (passed.length-1)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: passed
              .map((e) => ListItem(homework: e))
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
        Tile(
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
          height: 50, width: 150,
          child: Column(
            children: [
              const Spacer(),
              Row(
                children: [
                  const Spacer(),
                  Text("${passes.length}/${HomeworkInstance.homeworks.length}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Text(MyApp.locale.hwDetails_completion),
                  const Spacer(),
                ]
              ),
              const Spacer(),
              SizedBox(
                width: 150,
                child: ProgressBar(value: passRate)
              )
            ]
          )
        ),
        const SizedBox(width: 10),
        Tile(
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
          height: 50, width: 150,
          child: Column(
            children: [
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  Text("${HomeworkInstance.homeworks.length-passes.length}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Text(MyApp.locale.hwDetails_failed),
                  const Spacer()
                ]
              ),
              const Spacer()
            ]
          )
        )
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (GlobalSettings.isLoggingIn) {
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
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              tween: Tween<double>(
                begin: 0,
                end: _loadPercent ?? 0,
              ),
              builder: (context, value, _) =>
                ProgressRing(value: value), 
            ),
            const SizedBox(height: 10),
            Text(MyApp.locale.loading),
          ]
        )
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _overviewCard(),
        const SizedBox(height: 10),
        _pendingHws(),
        const SizedBox(height: 10),
        _passedHws()
    ]);
  }
  
  @override
  bool get wantKeepAlive => true;

}

class ListItem extends StatefulWidget {
  final Homework homework;

  const ListItem({
    super.key,
    required this.homework
  });

  @override
  State<ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {

  String fetchTitle() {
    return "${widget.homework.number} ${widget.homework.title??''}";
  }

  String fetchDeadline() {
    final hw = widget.homework;
    return "${MyApp.locale.hwDetails_deadline}: ${formatDate(hw.deadline)}";
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    
    Duration diff = date.difference(now);

    final decoration = (diff > Duration.zero) ? 
      MyApp.locale.hwDetails_remaining :
      MyApp.locale.hwDetails_ago;
    
    diff = (diff < Duration.zero) ? now.difference(date) : diff;
    
    if (diff > const Duration(days: 7)) {
      // print("[$date] ${diff.inDays} -> ${(diff.inDays / 7).toInt()}");
      return "${diff.inDays ~/ 7} ${MyApp.locale.week} $decoration";
    } else if (diff > const Duration(days: 1)) {
      return "${diff.inDays} ${MyApp.locale.day} $decoration";
    } else if (diff > const Duration(hours: 1)) {
      return "${diff.inHours} ${MyApp.locale.hour} $decoration";
    } else {
      return "${diff.inMinutes} ${MyApp.locale.minute} $decoration";
    }
  }

  IconData fetchIcon() {
    final hw = widget.homework;

    if (!hw.canHandIn) {
      return hw.state == HomeworkState.passed ? FluentIcons.check_mark : FluentIcons.clear;
    }

    return FluentIcons.edit;
  }

  @override
  Widget build(BuildContext context) {
    return Button(
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero)
      ),
      child: Tile.lore(
        decoration: const BoxDecoration(),
        title: fetchTitle(),
        lore: fetchDeadline(),
        icon: Icon(fetchIcon()),
        child: const Icon(FluentIcons.chevron_right),
      ),
      onPressed: () {
        if (GlobalSettings.route.current.name == "hwDetail") {
          return;
        }
        GlobalSettings.route.push(
          "hwDetail",
          title: "${widget.homework.number} ${widget.homework.title??MyApp.locale.no_title}", 
          parameter: {"id": widget.homework.id-1},
        );
      }
    );
  }
}