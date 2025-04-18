import 'package:win32/win32.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart' show appWindow;
import 'package:flutter/scheduler.dart';
import 'package:flutter_acrylic/window.dart';
import 'package:flutter_acrylic/window_effect.dart';

import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/core/platform.dart';

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

  ThemeMode get theme =>
    GlobalSettings.prefs.themeMode;

  WindowEffect get effect => 
    GlobalSettings.prefs.windowEffect;

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

  static Set<WindowEffect> get allowEffects {
    final Set<WindowEffect> effects = {
      WindowEffect.disabled
    };
    if (Platforms.isWindows) {
      effects.addAll({WindowEffect.acrylic});

      if (Platforms.canMicaEffect) {
        effects.addAll({WindowEffect.mica, WindowEffect.tabbed});
      }

    } else if (Platforms.isMacOS) {
      effects.addAll({
        WindowEffect.mica,
        WindowEffect.tabbed,
        WindowEffect.acrylic
      });
    }

    return effects;
  }
  
  Future<ThemeMode> initialize() async {
    await setTheme(theme);    

    if (Platforms.isWindows) {
      _removeTitleBarButtons();
    }

    notifyListeners();
    return theme;
  }

  Future<void> setEffect(WindowEffect effect) async {
    GlobalSettings.prefs.windowEffect = effect;
    
    await Window.setEffect(
      dark: isDark,
      effect: effect,
      color: isDark ? Colors.transparent : Colors.red,
    );

    notifyListeners();
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    GlobalSettings.prefs.themeMode = themeMode;
    await setEffect(effect);
    notifyListeners();
  }

}

class ThemePack {
  static FluentThemeData get dark {
    switch(ThemeProvider.instance.effect) {
      case WindowEffect.acrylic:
      case WindowEffect.tabbed:
      case WindowEffect.mica: return _dark.copyWith(
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
        navigationPaneTheme: const NavigationPaneThemeData(
          backgroundColor: Colors.transparent
        )
      );

      default: return _light;
    }
  }

  static final _dark = FluentThemeData(
    brightness: Brightness.dark,
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
    scaffoldBackgroundColor: Colors.transparent,
    micaBackgroundColor: Colors.transparent,
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
    scaffoldBackgroundColor: Colors.transparent,
    micaBackgroundColor: Colors.transparent,
    scrollbarTheme: const ScrollbarThemeData(
      backgroundColor: Colors.transparent
    ),
    dividerTheme: const DividerThemeData(
      horizontalMargin: EdgeInsets.zero
    ),
    infoBarTheme: InfoBarThemeData(
      decoration: (severity) {
        return const BoxDecoration(
          color: Colors.white
        );
      },
    )
  );
}