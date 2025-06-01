import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/l10n/app_localizations.dart';

import 'package:ntut_program_assignment/api/api_service.dart';
import 'package:ntut_program_assignment/core/updater.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/main.dart' show MyApp;
import 'package:ntut_program_assignment/page/settings/test_server.dart';
import 'package:ntut_program_assignment/provider/theme.dart';
import 'package:ntut_program_assignment/router.dart';
import 'package:ntut_program_assignment/page/settings/about.dart';
import 'package:ntut_program_assignment/page/settings/account.dart';
import 'package:ntut_program_assignment/page/settings/personalize.dart';
import 'package:ntut_program_assignment/widgets/tile.dart';

final _languageStream = ValueNotifier<String>("");

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  void initState() {
    _languageStream.addListener(_onLanguageChanged);
    super.initState();
  }
  
  @override
  void dispose() {
    _languageStream.removeListener(_onLanguageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FluentNavigation(
      title: MyApp.locale.sidebar_settings_title,
      builder: (String route) {
        switch (route) {
          case "account":
            return AccountRoute();
          
          case "testEnvironment":
            return TestServerRoute();

          case "personalize":
            return PersonalizeRoute();

          case "about":
            return AboutRoute();

          default:
            return OptionList();
        }
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
      child: Row(
        children: [
          Icon(FluentIcons.upgrade_analysis),
          SizedBox(width: 10),
          Text(MyApp.locale.settings_page_update_available)
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
        LanguageSection(),
        const SizedBox(height: 10),
        Tile(
          limitIconSize: true,
          title: Text(MyApp.locale.account),
          subtitle: Text(MyApp.locale.settings_page_account_desc),
          leading: const Icon(FluentIcons.accounts),
          trailing: const Icon(FluentIcons.chevron_right),
          onPressed: () {
            if (GlobalSettings.route.length > 1) {
              return;
            }
            GlobalSettings.route.push("account", title: "帳號");
          }
        ),
        const SizedBox(height: 10),
        Tile(
          limitIconSize: true,
          title: Text(MyApp.locale.settings_page_test_environment),
          subtitle: Text(MyApp.locale.settings_page_test_environment_desc),
          leading: const Icon(FluentIcons.server_enviroment),
          trailing: const Icon(FluentIcons.chevron_right),
          onPressed: () {
            if (GlobalSettings.route.length > 1) {
              return;
            }
            GlobalSettings.route.push("testEnvironment", title: MyApp.locale.settings_page_test_environment);
          }
        ),
        const SizedBox(height: 10),
        Tile(
          limitIconSize: true,
          title: Text(MyApp.locale.settings_page_personalize),
          subtitle: Text(MyApp.locale.settings_page_personalize_desc),
          leading: const Icon(FluentIcons.personalize),
          trailing: const Icon(FluentIcons.chevron_right),
          onPressed: () {
            if (GlobalSettings.route.length > 1) {
              return;
            }
            GlobalSettings.route.push("personalize", title: MyApp.locale.settings_page_personalize);
          }
        ),
        const SizedBox(height: 10),
        Tile(
          limitIconSize: true,
          title: Text(MyApp.locale.settings_page_about),
          subtitle: Text(MyApp.locale.settings_page_about_desc),
          leading: const Icon(FluentIcons.info),
          trailing: const Icon(FluentIcons.chevron_right),
          onPressed: () {
            if (GlobalSettings.route.length > 1) {
              return;
            }
            GlobalSettings.route.push("about", title: MyApp.locale.settings_page_about);
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
            Text(account?.name ?? MyApp.locale.settings_account_not_logged_in, style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 24
            )),
            Text(account == null ? MyApp.locale.settings_page_not_login : "${MyApp.locale.studnet_id} ${account!.username}")
          ]
        )
      ]
    );
  }
}

class LanguageSection extends StatefulWidget {
  const LanguageSection({super.key});

  @override
  State<LanguageSection> createState() => _LanguageSectionState();
}

class _LanguageSectionState extends State<LanguageSection> {

  final Map<String, String> _trans = {
    "en": "English",
    "zh": "中文 (簡體)",
    "zh_Hant": "中文 (繁體)"
  };

  @override
  Widget build(BuildContext context) {
    return Tile(
      title: Text(MyApp.locale.settings_page_language),
      subtitle: Text(MyApp.locale.settings_page_language_desc),
      leading: const Icon(FluentIcons.locale_language),
      trailing: ComboBox(
        value: GlobalSettings.prefs.language,
        items: AppLocalizations.supportedLocales
          .map((e) => ComboBoxItem(
            value: e.toString(),
            child: Text(_trans[e.toString()] ?? e.toString()))
          )
          .toList(),
        onChanged: (v) {
          if (v == null) {
            return;
          }
          GlobalSettings.prefs.language = v;

          _languageStream.value = v;
          ThemeProvider.instance.setTheme(ThemeProvider.instance.theme);
        }
      )
    );
  }
}