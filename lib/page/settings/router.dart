import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:ntut_program_assignment/main.dart' show MyApp;
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/page/settings/test_server.dart';
import 'package:ntut_program_assignment/widget.dart';
import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/page/settings/about.dart';
import 'package:ntut_program_assignment/page/settings/account.dart';
import 'package:ntut_program_assignment/page/settings/personalize.dart';


enum EventType {
  setState
}

class Controller {
  static final StreamController<EventType> update = StreamController();
  static final stream = update.stream.asBroadcastStream();

  static final items = <BreadcrumbItem<int>>[
    BreadcrumbItem(
      value: -1,
      label: Text('${MyApp.locale.settings_breadcrumb_title} ',
      style: const TextStyle(fontSize: 30)),
    )
  ];

  static void setState() {
    update.sink.add(EventType.setState);
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final StreamSubscription sub;

  final _routes = [
    const AccountRoute(),
    const TestServerRoute(),
    const PersonalizeRoute(),
    const SpecialThanks(),
  ];

  @override
  void initState() {
    super.initState();
    sub = Controller.stream.listen(_onUpdate);
  }

  @override
  void dispose() {
    super.dispose();
    Controller.items.clear();
    Controller.items.add(
      BreadcrumbItem(
        label: Text('${MyApp.locale.settings_breadcrumb_title} ', 
        style: const TextStyle(fontSize: 30)),
        value: -1
      )
    );

    sub.cancel();
  }

  void _onUpdate(EventType e) {
    if (e == EventType.setState) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: Align(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          margin: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 10),
          child: BreadcrumbBar<int>(
            items: Controller.items,
            chevronIconSize: 20,
            onItemPressed: (item) {
              setState(() {
                final index = Controller.items.indexOf(item);
                Controller.items.removeRange(index + 1, Controller.items.length);
              });
            },
          )
        )
      ),
      content: AnimatedSwitcher(
        transitionBuilder: (Widget child, Animation<double> animation) {
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(animation);

          final slideAnimation = child.key == const ValueKey(-1)
              // Fade out from left to right
              ? Tween<Offset>(begin: const Offset(-1, 0), end: const Offset(0, 0)).animate(animation)
              // Fade in from left to right
              : Tween<Offset>(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(animation);

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
        duration: const Duration(milliseconds: 300),
        child: Controller.items.last.value == -1 ? 
          const PageBase(
            key: ValueKey(-1),  
            child: OptionList()
          ) : 
          PageBase(
            child: _routes[Controller.items.last.value]
          )
      ));
  }
}

class OptionList extends StatelessWidget {
  const OptionList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AccountOverview(
          account: GlobalSettings.account,
        ),
        const SizedBox(height: 20),
        Button(
          style: const ButtonStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.zero)
          ),
          child: Tile.lore(
            decoration: const BoxDecoration(),
            title: "帳號",
            lore: "選擇要登入作業繳交系統的身分",
            icon: const Icon(FluentIcons.accounts),
            child: const Icon(FluentIcons.chevron_right),
          ),
          onPressed: () {
            Controller.items.add(const BreadcrumbItem(
              label: Text(
                "帳號", style: TextStyle(fontSize: 30)),
              value: 0
            ));
            Controller.setState();
          }
        ),
        const SizedBox(height: 10),
        Button(
          style: const ButtonStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.zero)
          ),
          child: Tile.lore(
            decoration: const BoxDecoration(),
            title: "測試環境",
            lore: "設定本機編譯器的位置",
            icon: const Icon(FluentIcons.server_enviroment),
            child: const Icon(FluentIcons.chevron_right)
          ),
          onPressed: () {
            Controller.items.add(const BreadcrumbItem(
              label: Text(
                "測試環境", style: TextStyle(fontSize: 30)),
              value: 1
            ));
            Controller.setState();
          }
        ),
        const SizedBox(height: 10),
        Button(
          style: const ButtonStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.zero)
          ),
          child: Tile.lore(
            decoration: const BoxDecoration(),
            title: "個人化",
            lore: "獨特設計，專屬風格，滿足個人需求",
            icon: const Icon(FluentIcons.personalize),
            child: const Icon(FluentIcons.chevron_right),
          ),
          onPressed: () {
            Controller.items.add(const BreadcrumbItem(
              label: Text(
                "個人化", style: TextStyle(fontSize: 30)),
              value: 2
            ));
            Controller.setState();
          }
        ),
        const SizedBox(height: 10),
        Button(
          style: const ButtonStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.zero)
          ),
          child: Tile.lore(
            decoration: const BoxDecoration(),
            title: "關於",
            lore: "關於這支程式與它的貢獻者",
            icon: const Icon(FluentIcons.info),
            child: const Icon(FluentIcons.chevron_right),
          ),
          onPressed: () {
            Controller.items.add(const BreadcrumbItem(
              label: Text(
                "關於", style: TextStyle(fontSize: 30)),
              value: 3
            ));
            Controller.setState();
          }
        )
      ]
    );
  }
}

class AccountOverview extends StatelessWidget {
  final Account? account;

  const AccountOverview({
    super.key,
    required this.account
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 85, width: 85,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: Colors.green.lightest
          ),
          child: Image.asset(
            r'assets/jong_yih_kuo@x500.png'
          )
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(account?.name ?? "尚未登入", style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 24
            )),
            Text(account == null ? "同學，如果沒有登入的話就要把你退選囉" : "學號 ${account!.username}")
          ]
        )
      ]
    );
  }
}