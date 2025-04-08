import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:ntut_program_assignment/core/global.dart';

import 'package:ntut_program_assignment/main.dart' show MyApp;
import 'package:ntut_program_assignment/provider/theme.dart';

class Tile extends StatelessWidget {
  const Tile({
    super.key, 
    this.mode, 
    this.alignment, 
    this.child,
    this.clipBehavior = Clip.none, 
    this.constraints, 
    this.height, 
    this.width, 
    this.margin, 
    this.padding, 
    this.decoration, 
    this.borderRadius, 
    this.title, 
    this.lore, 
    this.icon, 
    this.leading
  });

  final int? mode;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final BoxConstraints? constraints; 
  final Widget? child;
  final double? height, width;
  final EdgeInsets? margin, padding;
  final BoxDecoration? decoration;
  final BorderRadiusGeometry? borderRadius;

  final String? title;
  final String? lore;
  final Widget? icon;
  
  final Widget? leading;
  BoxDecoration _merge(BoxDecoration a, BoxDecoration? b) {
    return BoxDecoration(
      color: b?.color ?? a.color,
      image: b?.image ?? a.image,
      border: b?.border ?? a.border,
      borderRadius: b?.borderRadius ?? a.borderRadius,
      boxShadow: b?.boxShadow == null
        ? a.boxShadow
        : (a.boxShadow == null
            ? b?.boxShadow
            : [...a.boxShadow!]),
      gradient: b?.gradient ?? a.gradient,
      backgroundBlendMode: b?.backgroundBlendMode ?? a.backgroundBlendMode,
      shape: b?.shape ?? a.shape
    );
  }

  bool _isDark(BuildContext context) =>
    FluentTheme.of(context).brightness.isDark;

  Widget _container(BuildContext context, Widget? childWidget) {
    final normalDecoration = BoxDecoration(
      color: _isDark(context) ? 
       const Color(0x0dffffff) :
       const Color(0xb3ffffff),
      borderRadius: borderRadius??BorderRadius.circular(5)
    );

    return Container(
      alignment: alignment,
      clipBehavior: clipBehavior,
      constraints: constraints,
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: 20, vertical: 12.5
      ),
      decoration: _merge(normalDecoration, decoration),
      width: width,
      height: height,
      margin: margin,
      child: childWidget
    );
  }

  @override
  Widget build(BuildContext context) {
    if (mode == 1) { // Mode 1 stands for "Tile.lore()" mode
      final modeChild = Row(
        children: [
          icon!,
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title!),
                Text(lore!,
                  style: TextStyle(
                    color: FluentTheme.of(context).brightness.isDark ? 
                      const Color.fromRGBO(207, 207, 207, 1) :
                      const Color.fromRGBO(95, 95, 96, 1),
                    overflow: TextOverflow.ellipsis
                  )
                ),
              ]
            )
          ),
          const SizedBox(width: 10),
          child ?? const SizedBox()
        ]
      );
      
      return _container(context, modeChild);
    }

    if (mode == 2) {
      final modeChild = Row(
        children: [
          SizedBox(width: leading == null ? 0 : 7),
          leading??const SizedBox(),
          const SizedBox(width: 10),
          Text(title!),
          const SizedBox(width: 5),
          lore!=null ? Text(
            lore!,
            style: TextStyle(
              color: FluentTheme.of(context).brightness.isDark ? 
                const Color.fromRGBO(207, 207, 207, 1) :
                const Color.fromRGBO(95, 95, 96, 1)
            ),
          ) : const SizedBox(),
          const Spacer(),
          child??const SizedBox()
        ]
      );

      return _container(context, modeChild);
    }

    return _container(context, child);
  }

  factory Tile.lore({
    Key? key,
    Alignment? alignment,
    Widget? child,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    double? height,
    EdgeInsets? margin,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    double? width,
    BoxDecoration? decoration,
    required String title,
    required String lore,
    required Widget icon
  }) {
    return Tile(
      key: key,
      mode: 1,
      alignment: alignment,
      clipBehavior: clipBehavior??Clip.none,
      constraints: constraints,
      height: height,
      margin: margin,
      padding: padding,
      decoration: decoration,
      borderRadius: borderRadius,
      width: width,
      title: title,
      lore: lore,
      icon: icon,
      child: child,
    );
  }

  factory Tile.subTile({
    Key? key,
    Alignment? alignment,
    Widget? child,
    Clip clipBehavior = Clip.none,
    BoxConstraints? constraints,
    double? height,
    EdgeInsets margin = const EdgeInsets.fromLTRB(26, 0, 0, 0),
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    double? width,
    BoxDecoration decoration = const BoxDecoration(),
    required String title,
    String? lore,
    Widget? leading
  }) {
    return Tile(
      key: key,
      mode: 2,
      alignment: alignment,
      clipBehavior: clipBehavior,
      constraints: constraints,
      height: height,
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      width: width,
      decoration: decoration,
      title: title,
      lore: lore,
      leading: leading,
      child: child,
    );
  }
}

class IconStyleButton extends Button {
  const IconStyleButton({
    super.key,
    required super.child,
    required super.onPressed,
    super.onLongPress,
    super.onTapDown,
    super.onTapUp,
    super.focusNode,
    super.autofocus = false,
    ButtonStyle? style,
    super.focusable = true,
  }) : super(
    style: const ButtonStyle(
      padding: WidgetStatePropertyAll(EdgeInsets.zero)
    )
  );

}

class CustomWidgets {
  static FilledButton alertButton({
    Key? key,
    required Widget child,
    required void Function()? onPressed,
    void Function()? onLongPress,
    void Function()? onTapDown,
    void Function()? onTapUp,
    FocusNode? focusNode,
    bool autofocus = false,
    ButtonStyle? style,
    bool focusable = true,
  }) {
    final alertStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((state) {
        if (state.contains(WidgetState.disabled)) {
          return ThemeProvider.instance.isDark ? 
            const Color.fromRGBO(81, 84, 91, 1) : 
            const Color.fromRGBO(198, 198, 198, 1);
        }

        if (state.contains(WidgetState.hovered)) {
          return Colors.red.lightest;
        }
        if (state.contains(WidgetState.pressed)) {
          return Colors.red.light;
        }
        if (state.contains(WidgetState.selected)) {
          return Colors.red.lightest;
        }

        return Colors.red.lighter;
        
      })
    );

    return FilledButton(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      focusNode: focusNode,
      autofocus: autofocus,
      style: alertStyle.merge(style),
      focusable: focusable,
      child: child,
    );
  }
}

class PageBase extends StatelessWidget {
  final Widget child;

  const PageBase({
    super.key,
    required this.child
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(10),
          constraints: BoxConstraints(
            maxWidth: 1000,
            minHeight: MediaQuery.of(context).size.height-157
          ),
          child: child
    )));
  }
}

class SelectableTextBox extends StatelessWidget {
  final Widget? suffix;
  final String text;
  final double? textFactor;
  final ScrollController? scrollController;
  
  const SelectableTextBox({
    super.key,
    required this.text,
    this.suffix,
    this.textFactor = 1,
    this.scrollController
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return Text("< 此行沒有輸出內容 >", style: TextStyle(
        fontFamily: "FiraCode",
        color: Color.fromRGBO(112, 112, 112, 1),
        fontSize: 14 * GlobalSettings.prefs.testcaseTextFactor
      ));
    }

    final lines = text.split("\n");
    final chars = lines.map((e) => e.length).toList();
    chars.sort();

    return IntrinsicWidth(
      child: IntrinsicHeight(
        child: TextBox(
          scrollController: scrollController,
          style: TextStyle(
            fontFamily: "FiraCode",
            fontSize: 14 * GlobalSettings.prefs.testcaseTextFactor
          ),
          readOnly: true,
          maxLength: 10,
          // minLines: lines.length,
          maxLines: null,
          padding: EdgeInsets.zero,
          // scrollPhysics: const NeverScrollableScrollPhysics(),
          foregroundDecoration: WidgetStatePropertyAll(
            BoxDecoration(
              border: Border.all(
                color: Colors.transparent
              )
            )
          ),
          decoration: WidgetStatePropertyAll(
            BoxDecoration(
              border: Border.all(
                color: Colors.transparent
              ),
              color: Colors.transparent
            )
          ),
          controller: TextEditingController(
            text: text
          ),
          suffix: suffix,
        )
      )
    );
  }
}

class Platforms {
  static String? result;

  static bool get isWindows =>
    (result == null) ? fetchSystem() == "windows" : result == "windows";

  static bool get isWeb =>
    (result == null) ? fetchSystem() == "web" : result == "web";

  static bool get isMacOS =>
    (result == null) ? fetchSystem() == "macos" : result == "macos";

  static bool get isLinux =>
    (result == null) ? fetchSystem() == "linux" : result == "linux";

  static bool get isDesktop =>
    [isWindows, isMacOS, isLinux].any((e) => e);

  static String fetchSystem() {
    if (kIsWeb) {
      return result = "web";
    }

    if (Platform.isWindows) {
      return result = "windows";
    }

    if (Platform.isMacOS) {
      return result = "macos";
    }

    if (Platform.isLinux) {
      return result = "linux";
    }

    return result = "others";
  }

  static bool get canMicaEffect {
    if (!isWindows) {
      return false;
    }

    final version = Platform.operatingSystemVersion;

    if (version.contains("Windows 10")) {
      final exp = RegExp(r"Build\s(\d+)");
      Match? match = exp.firstMatch(version);
      if (match != null) {
        int buildNumber = int.parse(match.group(1)!);
        return (buildNumber >= 22000);
      }
    }

    return false;
  }
}

class UnimplementPage extends StatelessWidget {
  const UnimplementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FluentIcons.auto_enhance_on, size: 50),
          const SizedBox(height: 10),
          Text(MyApp.locale.unimplement_page_lore)
        ]
      )
    );
  }
}

class LoginBlock extends StatelessWidget {
  const LoginBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FluentIcons.account_management, size: 50),
          const SizedBox(height: 15),
          const Text("尚未登入任何帳號"),
          const SizedBox(height: 5),
          HyperlinkButton(
            onPressed: () {
              GlobalSettings.route.root = "settings";
              GlobalSettings.route.push("account", title: "帳號");
            },
            child: const Text("前往登入"),
          )
        ]
      )
    );
  }
}

class LoggingInBlock extends StatelessWidget {
  const LoggingInBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgressRing(),
          SizedBox(height: 10),
          Text("登入中...")
        ]
      )
    );
  }
}