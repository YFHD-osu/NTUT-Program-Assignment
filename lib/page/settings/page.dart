import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/core/updater.dart';

import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/page/settings/test_server.dart';
import 'package:ntut_program_assignment/router.dart';
import 'package:ntut_program_assignment/widget.dart';
import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/page/settings/about.dart';
import 'package:ntut_program_assignment/page/settings/account.dart';
import 'package:ntut_program_assignment/page/settings/personalize.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FluentNavigation(
      title: "設定",
      struct: {
          "default": OptionList(),
          "account": AccountRoute(),
          "testEnvironment": TestServerRoute(),
          "personalize": PersonalizeRoute(),
          "about": AboutRoute(),
        }
    );
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
    return FilledButton(
      child: const Row(
        children: [
          Icon(FluentIcons.upgrade_analysis),
          SizedBox(width: 10),
          Text("有可用的更新，點此查看")
        ]
      ),
      onPressed: () {
        GlobalSettings.route.push("about", title: "軟體資訊");
      }
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
            if (GlobalSettings.route.length > 1) {
              return;
            }
            GlobalSettings.route.push("account", title: "帳號");
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
            if (GlobalSettings.route.length > 1) {
              return;
            }
            GlobalSettings.route.push("testEnvironment", title: "測試環境");
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
            if (GlobalSettings.route.length > 1) {
              return;
            }
            GlobalSettings.route.push("personalize", title: "個人化");
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
            if (GlobalSettings.route.length > 1) {
              return;
            }
            GlobalSettings.route.push("about", title: "軟體資訊");
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