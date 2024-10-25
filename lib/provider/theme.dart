import 'dart:io';

import 'package:win32/win32.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart' show appWindow;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_acrylic/window.dart';
import 'package:flutter_acrylic/window_effect.dart';

import 'package:shared_preferences/shared_preferences.dart';

enum SystemType {
  win10,
  win11,
  macOS,
  others
}

SystemType getSystemType() {
  if (Platform.isWindows) {
    final version = Platform.operatingSystemVersion;

    if (version.contains("Windows 10")) {
      final exp = RegExp(r"Build\s(\d+)");
      Match? match = exp.firstMatch(version);
      if (match != null) {
        int buildNumber = int.parse(match.group(1)!);
        return (buildNumber >= 22000) ? SystemType.win11 : SystemType.win10;
      }
    }
  } else if(Platform.isMacOS) {
    return SystemType.macOS;
  }

  return SystemType.others;
}

class ThemeProvider extends ChangeNotifier {
  ThemeProvider._();
  static ThemeProvider? _instance;
  static ThemeProvider get instance {
    _instance ??= ThemeProvider._();
    return _instance!;
  }

  bool get isDark {
    switch(theme) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
        return brightness.isDark;
    }
  }

  bool get isLight => !isDark;

  ThemeMode theme = ThemeMode.system;
  WindowEffect effect = WindowEffect.mica;

  final Set<WindowEffect> allowedEffects = {
    WindowEffect.disabled
  };

  void _removeTitleBarButtons() {
    final hWnd = appWindow.handle;
    if (hWnd==null) return;

    final currentStyle = GetWindowLongPtr(
      hWnd,
      WINDOW_LONG_PTR_INDEX.GWL_STYLE
    );

    // Remove minimize, maximize, and close buttons
    SetWindowLongPtr(
      hWnd,
      WINDOW_LONG_PTR_INDEX.GWL_STYLE,
      currentStyle & 
        // ~WINDOW_STYLE.WS_MINIMIZEBOX & 
        // ~WINDOW_STYLE.WS_MAXIMIZEBOX & 
        ~WINDOW_STYLE.WS_SYSMENU,
    );

    // Update the window's style to apply changes
    SetWindowPos(
      hWnd,
      NULL,
      0,
      0,
      0,
      0,
      SET_WINDOW_POS_FLAGS.SWP_NOMOVE | 
        SET_WINDOW_POS_FLAGS.SWP_NOSIZE | 
        SET_WINDOW_POS_FLAGS.SWP_NOZORDER | 
        SET_WINDOW_POS_FLAGS.SWP_FRAMECHANGED
    );
  }
  
  Future<ThemeMode> initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int index = prefs.getInt('themeMode') ?? 0;
    theme = ThemeMode.values[index];
    await setTheme(theme);

    index = prefs.getInt("windowEffect") ?? 0;
    effect = WindowEffect.values[index];
    await setEffect(effect);

    switch(getSystemType()) {
      case SystemType.macOS:
        allowedEffects.addAll({
          WindowEffect.mica,
          WindowEffect.tabbed,
          WindowEffect.acrylic
        });
      case SystemType.win11:
        allowedEffects.addAll({
          WindowEffect.mica,
          WindowEffect.tabbed,
          WindowEffect.acrylic
        });
        _removeTitleBarButtons();
      case SystemType.win10:
        allowedEffects.add(WindowEffect.acrylic);
        _removeTitleBarButtons();
        break;
      
      default:
    }
    return theme;
  }

  Future<void> setEffect(WindowEffect effect) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('windowEffect', effect.index);
    this.effect = effect;
    
    await Window.setEffect(
      dark: isDark,
      effect: effect,
      color: isDark ? Colors.transparent : const Color(0xFFF3F3F3),
    );

    notifyListeners();
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', themeMode.index);
    theme = themeMode;

    switch(themeMode) {
      case ThemeMode.dark:
        await Window.setEffect(
          dark: true,
          effect: effect,
        );
        break;
      case ThemeMode.light:
        await Window.setEffect(
          dark: false,
          effect: effect,
          color: const Color(0xFFF3F3F3),
        );
        break;
      case ThemeMode.system:
        await Window.setEffect(
          effect: effect,
          dark: isDark,
          color: isDark ? Colors.transparent : const Color(0xFFF3F3F3),
        );
        break;
    }
    
    notifyListeners();
  }

}

class ThemePack {
  static FluentThemeData get dark {
    switch(ThemeProvider.instance.effect) {
      case WindowEffect.acrylic:
      case WindowEffect.tabbed:
      case WindowEffect.mica: return _dark.copyWith(
        // micaBackgroundColor: Colors.transparent,
        // scaffoldBackgroundColor: Colors.transparent,
        navigationPaneTheme: const NavigationPaneThemeData(
          backgroundColor: Colors.transparent
        )
      );
    
      default: return _dark;
    }
  }

  static FluentThemeData get light {
    switch(ThemeProvider.instance.effect) {
      case WindowEffect.acrylic:
      case WindowEffect.tabbed:
      case WindowEffect.mica: return _light.copyWith(
        // micaBackgroundColor: Colors.transparent,
        // scaffoldBackgroundColor: Colors.transparent,
        navigationPaneTheme: const NavigationPaneThemeData(
          backgroundColor: Colors.transparent
        )
      );

      default: return _light;
    }
  }

  static final _dark = FluentThemeData(
    brightness: Brightness.dark,
    /*navigationPaneTheme: NavigationPaneThemeData(
      highlightColor: const Color.fromRGBO(76, 194, 255, 1),
      overlayBackgroundColor: const Color.fromRGBO(32, 32, 32, 1),
      selectedIconColor: const WidgetStatePropertyAll(Color.fromRGBO(0, 0, 0, 1)),
      unselectedIconColor: const WidgetStatePropertyAll(Color.fromRGBO(0, 0, 0, 1)),
      selectedTextStyle: const WidgetStatePropertyAll(TextStyle(color: Colors.white)),
      unselectedTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.isDisabled) return const TextStyle(color: Color.fromRGBO(255, 255, 255, .4));
        return const TextStyle(color: Colors.white);
      }),
      itemHeaderTextStyle: const TextStyle(color: Colors.white),
      selectedTopTextStyle: const WidgetStatePropertyAll(TextStyle(color: Colors.white)),
      tileColor: WidgetStateProperty.resolveWith((states) {
        if (states.isHovered || states.isPressed) return const Color.fromRGBO(255, 255, 255, .05);
        if (states.isFocused) return const Color.fromRGBO(255, 255, 255, .1);
        return Colors.transparent; 
      }),
    ),*/
    buttonTheme: ButtonThemeData(
      defaultButtonStyle: ButtonStyle(
        backgroundColor: WidgetStateColor.resolveWith((states) {
          if (states.isPressed) return const Color.fromRGBO(255, 255, 255, .04);
          if (states.isHovered) return const Color.fromRGBO(255, 255, 255, .05);
          return const Color.fromRGBO(255, 255, 255, .09);
        }),
        textStyle: const WidgetStatePropertyAll(TextStyle(color: Colors.white))
      )
    ),
    scrollbarTheme: const ScrollbarThemeData(
      backgroundColor: Colors.transparent
    ),
    dividerTheme: const DividerThemeData(
      horizontalMargin: EdgeInsets.zero
    ),
    animationCurve: Curves.easeOutExpo,
    mediumAnimationDuration: const Duration(milliseconds: 250),
    fastAnimationDuration: const Duration(milliseconds: 200),
    fasterAnimationDuration: const Duration(milliseconds: 100),
  );

  static final _light = FluentThemeData(
    buttonTheme: ButtonThemeData(
      defaultButtonStyle: ButtonStyle(
        backgroundColor: WidgetStateColor.resolveWith((states) {
          if (states.isPressed) return const Color.fromRGBO(255, 255, 255, .04);
          if (states.isHovered) return const Color.fromRGBO(255, 255, 255, .05);
          return const Color.fromRGBO(255, 255, 255, .09);
        }),
        textStyle: const WidgetStatePropertyAll(TextStyle(color: Colors.black))
      )
    ),
    brightness: Brightness.light,
    animationCurve: Curves.easeOutExpo,
    mediumAnimationDuration: const Duration(milliseconds: 250),
    fastAnimationDuration: const Duration(milliseconds: 200),
    fasterAnimationDuration: const Duration(milliseconds: 100),
    scrollbarTheme: const ScrollbarThemeData(
      backgroundColor: Colors.transparent
    ),
    dividerTheme: const DividerThemeData(
      horizontalMargin: EdgeInsets.zero
    ),
  );
}