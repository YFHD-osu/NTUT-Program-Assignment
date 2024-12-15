import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/core/updater.dart';

import 'package:ntut_program_assignment/main.dart' show MyApp;
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/page/settings/test_server.dart';
import 'package:ntut_program_assignment/widget.dart';
import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/page/settings/about.dart';
import 'package:ntut_program_assignment/page/settings/account.dart';
import 'package:ntut_program_assignment/page/settings/personalize.dart';
import 'package:ntut_program_assignment/page/homework/router.dart' show BreadcrumbValue;

enum EventType {
  setState
}

class Controller {
  static final StreamController<EventType> update = StreamController();
  static final stream = update.stream.asBroadcastStream();

  static final routes = <BreadcrumbItem<BreadcrumbValue>>[
    BreadcrumbItem(
      value: BreadcrumbValue(
        label: '${MyApp.locale.settings_breadcrumb_title} ',
        index: -1
      ),
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
  final _menuController = FlyoutController();

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
    Controller.routes.clear();
    Controller.routes.add(
      BreadcrumbItem(
        label: Text('${MyApp.locale.settings_breadcrumb_title} ', 
        style: const TextStyle(fontSize: 30)),
        value: BreadcrumbValue(
          index: -1,
          label: '${MyApp.locale.settings_breadcrumb_title} ',
        )
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
          child: BreadcrumbBar<BreadcrumbValue>(
            items: Controller.routes,
            chevronIconSize: 20,
            onItemPressed: (item) {
              setState(() {
                final index = Controller.routes.indexOf(item);
                Controller.routes.removeRange(index + 1, Controller.routes.length);
              });
            },
            overflowButtonBuilder: (context, openFlyout) {
              return FlyoutTarget(
                controller: _menuController,
                child: IconButton(
                  icon: const Icon(FluentIcons.more),
                  onPressed: () {
                    _menuController.showFlyout(
                      autoModeConfiguration: FlyoutAutoConfiguration(
                        preferredMode: FlyoutPlacementMode.bottomLeft,
                      ),
                      barrierDismissible: true,
                      dismissOnPointerMoveAway: false,
                      dismissWithEsc: true,
                      navigatorKey: Navigator.of(context),
                      builder: (context) {
                        return const RouteFlyout();
                    });
                  }
                )
              );
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
        child: Controller.routes.last.value.index == -1 ? 
          const PageBase(
            key: ValueKey(-1),  
            child: OptionList()
          ) : 
          PageBase(
            child: _routes[Controller.routes.last.value.index]
          )
      ));
  }
}

class UpadteNotify extends StatefulWidget {
  const UpadteNotify({super.key});

  @override
  State<UpadteNotify> createState() => _UpadteNotifyState();
}

class _UpadteNotifyState extends State<UpadteNotify> {
  void _onUpdateChange() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    Updater.available.addListener(_onUpdateChange);
  }

  @override
  void dispose() {
    super.dispose();
    Updater.available.removeListener(_onUpdateChange);
  }

  Widget _context() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10, vertical: 5
      ),
      decoration: BoxDecoration(
        color: Colors.yellow.darker.withOpacity(.75),
        borderRadius: BorderRadius.circular(8)
      ),
      child: const Row(
        children: [
          Icon(FluentIcons.upgrade_analysis),
          SizedBox(width: 5),
          Text("有可用的更新，請至軟體資訊查看更新")
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: Updater.available.value ? const Offset(0, 0) : const Offset(0, 1.25),
      duration: const Duration(milliseconds: 150),
      child: AnimatedOpacity(
        opacity: Updater.available.value ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        child: _context()
      )
    );
  }
}

class OptionList extends StatelessWidget {
  const OptionList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccountOverview(
              account: GlobalSettings.account,
            ),
            const Spacer(),
            const UpadteNotify()
          ]
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
            if (Controller.routes.length > 1) {
              return;
            }
            Controller.routes.add(BreadcrumbItem(
              label: const Text(
                "帳號", style: TextStyle(fontSize: 30)),
              value: BreadcrumbValue(
                index: 0,
                label: "帳號"
              )
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
            if (Controller.routes.length > 1) {
              return;
            }
            Controller.routes.add(BreadcrumbItem(
              label: const Text(
                "測試環境", style: TextStyle(fontSize: 30)),
              value: BreadcrumbValue(
                index: 1,
                label: "測試環境"
              )
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
            if (Controller.routes.length > 1) {
              return;
            }
            Controller.routes.add(BreadcrumbItem(
              label: const Text(
                "個人化", style: TextStyle(fontSize: 30)),
              value: BreadcrumbValue(
                index: 2,
                label: "個人化"
              )
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
            title: "軟體資訊",
            lore: "關於這支程式與它的貢獻者",
            icon: const Icon(FluentIcons.info),
            child: const Icon(FluentIcons.chevron_right),
          ),
          onPressed: () {
            if (Controller.routes.length > 1) {
              return;
            }
            Controller.routes.add(BreadcrumbItem(
              label: const Text(
                "軟體資訊", style: TextStyle(fontSize: 30)),
              value: BreadcrumbValue(
                index: 3,
                label: "軟體資訊"
              )
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

class RouteFlyout extends StatelessWidget {
  const RouteFlyout({super.key});

  Widget _testDataRow(BreadcrumbItem<BreadcrumbValue> breadcumber, BuildContext context) {
    return HyperlinkButton(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Center(
          child: Text(
            breadcumber.value.label,
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis
          )
        )
      ),
      onPressed: () {
        final index = Controller.routes.indexOf(breadcumber);
        Controller.routes.removeRange(index + 1, Controller.routes.length);
        Navigator.of(context).pop();
        Controller.setState();
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 180,
        maxHeight: Controller.routes.length*36 + 10
      ),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).menuColor,
        borderRadius: BorderRadius.circular(5)
      ),
      child: Column(
        children: Controller.routes
          .map((e) => _testDataRow(e, context))
          .toList()
      )
    );
  }
}