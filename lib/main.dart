import 'dart:io';
import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/widget.dart';
import 'package:logger/logger.dart' show Logger, PrettyPrinter, DateTimeFormat, Level;

import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/provider/theme.dart';
import 'package:ntut_program_assignment/page/homework/router.dart';
import 'package:ntut_program_assignment/page/settings/router.dart';
import 'package:ntut_program_assignment/core/logger.dart' show FileOutput;

late final Logger logger;

void main() async {
  final output = FileOutput();
  await output.initialize("logs");

  logger = Logger(
    printer: PrettyPrinter(
      dateTimeFormat: DateTimeFormat.onlyTime,
      levelEmojis: {
        Level.debug: "[DEBUG]",
        Level.error: "[ERROR]",
        Level.fatal: "[FETAL]",
        Level.info: "[INFO]",
        Level.warning: "[WARNNING]"
      }
    ),
    output: output,
  );

  // Make http package to accept self-signed certificate 
  HttpOverrides.global = DevHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platforms.isDesktop) {
    doWhenWindowReady(() {
      appWindow.size = const Size(800, 600);
      appWindow.minSize = const Size(800, 600);
      appWindow.title = "NTUT Program Assigiment";
      appWindow.show();
    });

    // Enable windows mica effect
    await Window.initialize();

    await windowManager.ensureInitialized();
    // windowManager.waitUntilReadyToShow(const WindowOptions(), () async {
    //   await windowManager.show();
    //   await windowManager.focus();
    //   await windowManager.setTitle("");
    // });
  }
  
  await GlobalSettings.initialize();
  await ThemeProvider.instance.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider.instance,
      builder: (context, _) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        // print(AppLocalizations.supportedLocales);
        return FluentApp(
          locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
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
  
  int _index = 0;
  PaneDisplayMode _mode = PaneDisplayMode.compact;
  
  @override
  void initState() {
    super.initState();
    _sub = GlobalSettings.stream.listen(_onUpdate);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _sub.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
    final locale = AppLocalizations.of(context)!;
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
        Text(locale.application_title)
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
    final locale = AppLocalizations.of(context)!;
    final FluentThemeData theme = FluentTheme.of(context);
    
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
          Text(locale.application_title),
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
    }

    return const NavigationAppBar();
  }

  void _onUpdate(GlobalEvent event) {
    // Listen for account switch
    if (![GlobalEvent.accountSwitch].contains(event)) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return NavigationView(
      appBar: _appBar(),
      pane: NavigationPane(
        toggleable: false,
        displayMode: Platforms.isMacOS ? PaneDisplayMode.open : _mode,
        size: const NavigationPaneSize(
          openMinWidth: 255, openMaxWidth: 255,
        ),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.backlog_list),
            title: Text(locale.sidebar_homework_title),
            body: const HomeworkRoute()
          ),
          PaneItem(
            icon: const Icon(FluentIcons.info),
            title: Text(locale.sidebar_submitted_assignment_title),
            body: const UnimplementPage()
          ),
          PaneItem(
            icon: const Icon(FluentIcons.red_eye),
            title: Text(locale.sidebar_my_grade_title),
            body: const UnimplementPage()
          ),
          PaneItem(
            icon: const Icon(FluentIcons.comment),
            title: Text(locale.sidebar_comment_title),
            body: const UnimplementPage()
          ),
          PaneItem(
            icon: const Icon(FluentIcons.erase_tool),
            title: Text(locale.sidebar_change_password_title),
            body: const UnimplementPage()
          )
        ],
        footerItems: [
          PaneItemSeparator(),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: Text(locale.sidebar_settings_title),
            body: const SettingsPage(),
            enabled: true)
        ],
        selected: _index,
        onChanged: (i) => setState(() => _index=i) 
      ));
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}