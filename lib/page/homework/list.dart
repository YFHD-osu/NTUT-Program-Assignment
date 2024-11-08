import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/core/global.dart';

import 'package:ntut_program_assignment/page/homework/router.dart';
import 'package:ntut_program_assignment/widget.dart';


class HomeworkList extends StatefulWidget {
  const HomeworkList({super.key});

  @override
  State<HomeworkList> createState() => _HomeworkListState();
}

class _HomeworkListState extends State<HomeworkList> {
  String? errMsg;
  late bool _isReady = Controller.homeworks.isNotEmpty;
  late StreamSubscription _sub;


  @override
  void initState() {
    super.initState();
    _sub = GlobalSettings.stream.listen(_onGlobalEvent);
    if (Controller.homeworks.isEmpty) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  void _onGlobalEvent(GlobalEvent e) {
    if (e == GlobalEvent.accountSwitch) {
      _refresh();
      setState(() {});
    }
  }

  Future<void> _refresh() async {
    if (GlobalSettings.account == null) {
      return;
    }

    Controller.homeworks.clear();
    
    errMsg = null;
    setState(() => _isReady = false);

    try {
      Controller.homeworks =
      await GlobalSettings.account!.fetchHomeworkList();
    } on NetworkError catch (e) {
      errMsg = e.message;
    } on RuntimeError catch (e) {
      errMsg = e.message;
    } catch (e) {
      errMsg = e.toString();
    }
    
    setState(() => _isReady = true);
  }

  Widget _pendingHws() {
    final notPasses = Controller.homeworks
      .where((e) => !e.isPass);

    if (notPasses.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("尚未通過", style: TextStyle(fontWeight: FontWeight.bold)),
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
    final passed = Controller.homeworks
      .where((e) => e.isPass);

    if (passed.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("已通過", style: TextStyle(fontWeight: FontWeight.bold)),
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
    final passes = Controller.homeworks.where((e) => e.isPass);

    final passRate = passes.length / Controller.homeworks.length * 100;
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
                  Text("${passes.length}/${Controller.homeworks.length}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  const Text("完成比"),
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
                  Text("${Controller.homeworks.length-passes.length}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  const Text("未通過"),
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
    
    if (GlobalSettings.account == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FluentIcons.account_management, size: 50),
            SizedBox(height: 10),
            Text("請先移至設定、帳戶登入帳號")
          ]
        )
      );
    }

    if (errMsg != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FluentIcons.error, size: 50),
            const SizedBox(height: 10),
            Text("發生錯誤\n$errMsg", textAlign: TextAlign.center,),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _refresh, 
              child: const Text("重新整理"),
            )
          ]
        )
      );
    }

    if (!_isReady) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProgressRing(),
            SizedBox(height: 10),
            Text("題目載入中..."),
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
  String? _errorMsg;

  Future<void> _fetchDescription() async {
    try {
      await widget.homework.fetchHomeworkDetail();
    } on RuntimeError catch (e) {
      _errorMsg = e.message;
    } on NetworkError catch (e) {
      _errorMsg = e.message;
    } catch (e) {
      _errorMsg = e.toString();
    }

    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _fetchDescription();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMsg != null) {
      return Button(
        style: const ButtonStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.zero)
        ),
        child: Tile.lore(
          decoration: const BoxDecoration(),
          title: "${widget.homework.number} 無法加載詳細資料",
          lore: "繳交期限: ${widget.homework.deadline}",
          icon: const Icon(FluentIcons.delete),
          child: const Icon(FluentIcons.chevron_right),
        ),
        onPressed: () {
          Controller.routes.add(BreadcrumbItem(
            label: Text(
              "${widget.homework.number} ${widget.homework.description?.title??''}",
              style: const TextStyle(fontSize: 30)),
            value: BreadcrumbValue(label: "${widget.homework.number} ${widget.homework.description?.title??''}", index: widget.homework.id-1)
          ));
          Controller.setState();
        }
      );
    }

    return Button(
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero)
      ),
      child: Tile.lore(
        decoration: const BoxDecoration(),
        title: "${widget.homework.number} ${widget.homework.description?.title??''}",
        lore: "繳交期限: ${widget.homework.deadline}",
        icon: const Icon(FluentIcons.delete),
        child: const Icon(FluentIcons.chevron_right),
      ),
      onPressed: () {
        Controller.routes.add(BreadcrumbItem(
          label: Text(
            "${widget.homework.number} ${widget.homework.description?.title??''}",
            style: const TextStyle(fontSize: 30)),
          value: BreadcrumbValue(label: "${widget.homework.number} ${widget.homework.description?.title??''}", index: widget.homework.id-1)
        ));
        Controller.setState();
      }
    );
  }
}