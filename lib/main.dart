import 'dart:io';
import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/provider/theme.dart';
import 'package:ntut_program_assignment/page/homework/router.dart';
import 'package:ntut_program_assignment/page/settings/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  windowManager.waitUntilReadyToShow(const WindowOptions(), () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Enable windows mica effect
  await Window.initialize();

  doWhenWindowReady(() {
    appWindow.title = "Media Box";
    appWindow.size = const Size(800, 600);
    appWindow.minSize = const Size(800, 600);
    appWindow.show();
  });

  await ThemeProvider.instance.initialize();
  HttpOverrides.global = DevHttpOverrides();
  
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

          return FluentApp(
            title: 'NTUT Program Assignment',
            debugShowCheckedModeBanner: false,
            home: WindowBorder(
                color: Colors.transparent, child: const HomePage()),
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
  
  int _index = 2;
  PaneDisplayMode _mode = PaneDisplayMode.compact;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Update window effect on system brightness changed
    final theme = ThemeProvider.instance.theme;
    if (theme == ThemeMode.system) {
      ThemeProvider.instance.setTheme(theme);
    }
  }

  NavigationAppBar _windowsAppBar() {
    return NavigationAppBar(
    actions: const TitleBar(),
    title: MoveWindow(
      child: Row(children: [
        ClipRRect(
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(5),
          child: Image.asset(
            "assets\\icon@x500.png",
            width: 20, height: 20
          )),
        const SizedBox(width: 10),
        const Text("NTUT Program Assignment")
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
    return const NavigationAppBar(
      height: 28,
      title: Center(
        child: Text("Media Box")
      ),
      automaticallyImplyLeading: false,
    );
  }

  NavigationAppBar _appBar() {
    if (Platform.isWindows) {
      return _windowsAppBar();
    } else if (Platform.isMacOS) {
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
  void initState() {
    super.initState();
    _sub = GlobalSettings.stream.listen(_onUpdate);
  }

  @override
  void dispose() {
    super.dispose();
    _sub.cancel();
  }

  @override
  Widget build(BuildContext context) {

    return NavigationView(
      appBar: _appBar(),
      pane: NavigationPane(
        toggleable: false,
        displayMode: Platform.isMacOS ? PaneDisplayMode.open : _mode,
        size: const NavigationPaneSize(
          openMinWidth: 255, openMaxWidth: 255,
        ),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.backlog_list),
            title: const Text('作業列表'),
            body: const HomeworkRoute(),
            enabled: GlobalSettings.isLogin
          )
        ],
        footerItems: [
          PaneItemSeparator(),
          PaneItem(
            icon: const Icon(FluentIcons.task_list),
            title: const Text('Tasks'),
            body: const Placeholder(),
            enabled: true),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Settings'),
            body: const SettingsPage(),
            enabled: true)
        ],
        selected: _index,
        onChanged: (i) => setState(() => _index=i) 
      ));
  }
}

class TitleBar extends StatefulWidget {
  const TitleBar({
    super.key,
  });

  @override
  State<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<TitleBar> with WindowListener {
  bool _isMaximized = false;

  void _setState() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    windowManager.addListener(this);
    ThemeProvider.instance.addListener(_setState);
    super.initState();
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    ThemeProvider.instance.removeListener(_setState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = ThemeProvider.instance.isLight;
    return WindowTitleBarBox(
      child: Row(
        children: [
          const SizedBox(width: 50),
          const Spacer(),
          MinimizeWindowButton(
            colors: WindowButtonColors(
              iconNormal: isLight ? Colors.black : Colors.white)),
          _isMaximized
            ? RestoreWindowButton(
                colors: WindowButtonColors(
                    iconNormal: isLight ? Colors.black : Colors.white),
                onPressed: () => setState(() {
                  appWindow.restore();
                }),
              )
            : MaximizeWindowButton(
                colors: WindowButtonColors(
                    iconNormal: isLight ? Colors.black : Colors.white),
                onPressed: () => setState(() {
                  appWindow.maximize();
                }),
              ),
          CloseWindowButton(
            colors: WindowButtonColors(
              mouseOver: Colors.red,
              iconNormal: isLight ? Colors.black : Colors.white,
              iconMouseOver: Colors.white),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}