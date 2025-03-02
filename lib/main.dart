import 'dart:io';
import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:logger/logger.dart' show Logger;

import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
// import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/core/updater.dart';
import 'package:ntut_program_assignment/core/logger.dart';
import 'package:ntut_program_assignment/core/test_server.dart';
import 'package:ntut_program_assignment/provider/theme.dart';
import 'package:ntut_program_assignment/page/comments/page.dart' show CommentPage;
import 'package:ntut_program_assignment/page/homework/page.dart' show HomeworkPage;
import 'package:ntut_program_assignment/page/settings/page.dart' show SettingsPage;
import 'package:ntut_program_assignment/widget.dart';
import 'package:window_manager/window_manager.dart' show WindowCaption, windowManager;

late final Logger logger;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await LogToFile.initialize();
  
  logger = Logger(
    printer: Printer(),
    output: FileLogOutput(),
    filter: AlwaysLogFilter()
  );

  // Make http package to accept self-signed certificate 
  HttpOverrides.global = DevHttpOverrides();

  if (Platforms.isDesktop) {
    // Enable windows mica effect
    await windowManager.ensureInitialized();
    await Window.initialize();
  }

  await GlobalSettings.initialize();
  await ThemeProvider.instance.initialize();

  await TestServer.initialize();

  runApp(const MyApp());

  if (Platforms.isDesktop) {
    doWhenWindowReady(() {
      appWindow.size = const Size(800, 600);
      appWindow.minSize = const Size(800, 600);
      appWindow.title = "NTUT Program Assigiment";
      appWindow.show();
    });
  }

  return;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static late BuildContext ctx;
  static late AppLocalizations locale;

  static ToastificationItem? showToast(String title, String message, InfoBarSeverity level) {
    if (!MyApp.ctx.mounted) {
      return null;
    }
    
    return toastification.showCustom(
      context: MyApp.ctx,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 5),
      builder: (BuildContext context, ToastificationItem holder) {
        return Container(
          width: 500,
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color.fromRGBO(39, 39, 39, 1),
          ),
          child: InfoBar(
            isLong: false,
            title: Text(title),
            content: Text(message),
            severity: level
          )
        );
      },
    );
  }

  static ToastificationItem? showSpanToast(InlineSpan title, InlineSpan message, InfoBarSeverity level) {
    if (!MyApp.ctx.mounted) {
      return null;
    }
    
    return toastification.showCustom(
      context: MyApp.ctx,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 5),
      builder: (BuildContext context, ToastificationItem holder) {
        return Container(
          width: 500,
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color.fromRGBO(39, 39, 39, 1),
          ),
          child: InfoBar(
            isLong: false,
            title: RichText(
              text: TextSpan(
                style: TextStyle(color: ThemeProvider.instance.isLight ? Colors.black : Colors.white),
                children: [title]
              )),
            content: RichText(
              text: TextSpan(
                style: TextStyle(color: ThemeProvider.instance.isLight ? Colors.black : Colors.white),
                children: [message]
              )),
            severity: level
          )
        );
      },
    );
  }

  Locale get _locale {
    final data = GlobalSettings.prefs.language.split("_");
    final scriptCode = data.length > 1 ? data.last : null;

    return Locale.fromSubtags(languageCode: data.first, scriptCode: scriptCode);
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider.instance,
      builder: (context, _) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        // print(AppLocalizations.supportedLocales);
        return FluentApp(
          locale: _locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          debugShowCheckedModeBanner: false,
          home: WindowBorder(color: Colors.transparent, child: const HomePage()),
          theme: ThemePack.light,
          darkTheme: ThemePack.dark,
          themeMode: themeProvider.theme,
        );
      });
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late StreamSubscription _sub;
  
  PaneDisplayMode _mode = PaneDisplayMode.compact;

  final routeMap = {
    "hwlist": 0,
    "comments": 1,
    "settings": 2
  };
  
  Future<void> _fetchUpdate() async {
    final need = await Updater.needUpdate();
    if (!need) return;

    MyApp.showSpanToast(
      const TextSpan(text: "更新可用"),
      TextSpan(
        children: [
          const WidgetSpan(child: Padding(
            padding: EdgeInsets.only(bottom: 3.5),
            child: Text("新的版本已經推出,")
          )),
          WidgetSpan(child: HyperlinkButton(
            child: const Text("前往設定"),
            onPressed: () {
              GlobalSettings.route.root = "settings";
              GlobalSettings.route.push("about", title: "軟體資訊");
            }
          )),
          const WidgetSpan(child: Padding(
            padding: EdgeInsets.only(bottom: 3.5),
            child: Text("查看細節")
          ))
        ]
      ),
      InfoBarSeverity.info
    );
  }

  void _setState() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _sub = GlobalSettings.stream.listen(_onUpdate);
    WidgetsBinding.instance.addObserver(this);
    GlobalSettings.route.addListener(_setState);
    GlobalSettings.autoLogin();
    _fetchUpdate();
  }

  @override
  void dispose() {
    _sub.cancel();
    WidgetsBinding.instance.removeObserver(this);
    GlobalSettings.route.removeListener(_setState);
    super.dispose();
  }
  
  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    // Update window effect on system brightness changed
    final theme = ThemeProvider.instance.theme;
    if (theme == ThemeMode.system) {
      ThemeProvider.instance.setTheme(theme);
    }
  }

  NavigationAppBar _windowsAppBar() {
    final FluentThemeData theme = FluentTheme.of(context);
    
    return NavigationAppBar(
    actions: SizedBox(
      width: 138,
      height: 50,
      child: WindowCaption(
        brightness: theme.brightness,
        backgroundColor: Colors.transparent,
      ),
    ),
    title: MoveWindow(
      child: Row(children: [
        ClipRRect(
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(5),
          child: Image.asset(
            "assets/icon@x500.png",
            width: 20, height: 20
          )),
        const SizedBox(width: 10),
        Text(MyApp.locale.application_title)
      ])),
    automaticallyImplyLeading: true,
    leading: Padding(
      padding: const EdgeInsets.all(5),
      child: SizedBox.square(
        dimension: 40,
        child: IconButton(
          icon: const Icon(FluentIcons.global_nav_button),
          onPressed: () {
            switch (_mode) {
              case PaneDisplayMode.open:
                _mode = PaneDisplayMode.compact;
              default:
                _mode = PaneDisplayMode.open;
            }
            setState(() {});
          }
      )))
    );
  }

  NavigationAppBar _macOSAppBar() {
    return NavigationAppBar(
      height: 30,
      title: MoveWindow(
        child: Row(children: [
          const SizedBox(width: 30),
          const Spacer(),
          ClipRRect(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(5),
            child: Image.asset(
              "assets/icon@x500.png",
              width: 20, height: 20
            )),
          const SizedBox(width: 10),
          Text(MyApp.locale.application_title),
          const Spacer(),
        ])),
      automaticallyImplyLeading: false,
    );
  }

  NavigationAppBar _appBar() {
    if (Platforms.isWindows || Platforms.isLinux) {
      return _windowsAppBar();
    } else if (Platforms.isMacOS) {
      return _macOSAppBar();
    } else {
      return const NavigationAppBar();
    }
  }

  void _onUpdate(GlobalEvent event) {
    // Listen for account switch
    if (![GlobalEvent.refreshHwList].contains(event)) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    MyApp.ctx = context;
    MyApp.locale = AppLocalizations.of(context)!;

    return NavigationView(
      appBar: _appBar(),
      pane: NavigationPane(
        displayMode: _mode,
        toggleable: Platforms.isMacOS,
        size: const NavigationPaneSize(
          openMinWidth: 255, openMaxWidth: 255,
        ),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.backlog_list),
            title: Text(MyApp.locale.sidebar_homework_title),
            body: const HomeworkPage()
          ),
          PaneItem(
            icon: const Icon(FluentIcons.comment),
            title: Text(MyApp.locale.sidebar_comment_title),
            body: const CommentPage()
          )
        ],
        footerItems: [
          PaneItemSeparator(),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: Text(MyApp.locale.sidebar_settings_title),
            body: const SettingsPage(),
            infoBadge: ListenableBuilder(
              listenable: Updater.available,
              builder: (context, child) => Container(
                constraints: BoxConstraints(
                  maxHeight: Updater.available.value ? 7 : 0,
                  maxWidth: Updater.available.value ? 7 : 0,  
                ), 
                decoration: BoxDecoration(
                  color: Colors.yellow.darkest,
                  borderRadius: BorderRadius.circular(20)
                ),
              )
            )
          )
        ],
        selected: routeMap[GlobalSettings.route.root]??0,
        onChanged: (i) => GlobalSettings.route.root = routeMap.keys.toList()[i] 
      ));
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}