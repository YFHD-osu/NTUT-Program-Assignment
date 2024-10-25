import 'package:fluent_ui/fluent_ui.dart';

import 'package:ntut_program_assignment/provider/theme.dart';

extension on BoxDecoration {
  BoxDecoration merge(BoxDecoration? a) {
    return BoxDecoration(
      color: a?.color ?? color,
      image: a?.image ?? image,
      border: a?.border ?? border,
      borderRadius: a?.borderRadius ?? borderRadius,
      boxShadow: a?.boxShadow == null
          ? boxShadow
          : (boxShadow == null
              ? a?.boxShadow
              : [...boxShadow!]),
      gradient: a?.gradient ?? gradient,
      backgroundBlendMode: a?.backgroundBlendMode ?? backgroundBlendMode,
      shape: a?.shape ?? shape
    );
  }
}

class Tile extends Container {
  Tile({
    super.key,
    super.alignment,
    super.child,
    super.clipBehavior,
    super.constraints,
    super.height,
    super.margin,
    super.transform,
    super.transformAlignment,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    BoxDecoration? decoration,
    super.width
  }) : super(
    decoration: BoxDecoration(
      color: ThemeProvider.instance.isDark ? 
       const Color(0x0dffffff) :
       const Color(0xb3ffffff),
      borderRadius: borderRadius??BorderRadius.circular(5)
    ).merge(decoration),
    padding: padding ?? const EdgeInsets.symmetric(
      horizontal: 20, vertical: 12.5
    )
  );

  factory Tile.lore({
    Key? key,
    Alignment? alignment,
    Widget? child,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    double? height,
    EdgeInsetsGeometry? margin,
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
      alignment: alignment,
      clipBehavior: clipBehavior??Clip.none,
      constraints: constraints,
      height: height,
      margin: margin,
      transform: transform,
      transformAlignment: transformAlignment,
      padding: padding,
      decoration: decoration,
      borderRadius: borderRadius,
      width: width,
      child: Row(
        children: [
          icon,
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(lore,
                  style: TextStyle(
                    color: ThemeProvider.instance.isDark ? 
                      const Color.fromRGBO(207, 207, 207, 1) :
                      const Color.fromRGBO(95, 95, 96, 1),
                    overflow: TextOverflow.ellipsis
                  )
                ),
              ]
            )
          ),
          const SizedBox(width: 10),
          child??const SizedBox()
        ]
      ),
    );
  }

  factory Tile.subTile({
    Key? key,
    Alignment? alignment,
    Widget? child,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    double? height,
    EdgeInsetsGeometry? margin,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    double? width,
    BoxDecoration? decoration,
    required String title,
    String? lore,
    Widget? leading
  }) {
    return Tile(
      key: key,
      alignment: alignment,
      clipBehavior: clipBehavior??Clip.none,
      constraints: constraints,
      height: height,
      margin: margin,
      transform: transform,
      transformAlignment: transformAlignment,
      padding: padding ?? EdgeInsets.zero,
      borderRadius: borderRadius,
      width: width,
      decoration: decoration?? const BoxDecoration(),
      child: Padding(
        padding: padding ?? const EdgeInsets.only(
          left: 46, right: 20, top: 10, bottom: 10
        ),
        child: Row(
          children: [
            SizedBox(width: leading == null ? 0 : 7),
            leading??const SizedBox(),
            const SizedBox(width: 10),
            Text(title),
            const SizedBox(width: 5),
            lore!=null ? Text(
              lore,
              style: TextStyle(
                color: ThemeProvider.instance.isDark ? 
                  const Color.fromRGBO(207, 207, 207, 1) :
                  const Color.fromRGBO(95, 95, 96, 1)
              ),
            ) : const SizedBox(),
            const Spacer(),
            child??const SizedBox()
          ]
        ) 
      )
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
          return Colors.grey;
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
  final String text;
  
  const SelectableTextBox({
    super.key,
    required this.text
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.split("\n");
    final chars = lines.map((e) => e.length).toList();
    chars.sort();

    return IntrinsicWidth(
      child: TextBox(
        readOnly: true,
        maxLength: 9999,
        // minLines: lines.length,
        maxLines: null,
        padding: EdgeInsets.zero,
        scrollPhysics: const NeverScrollableScrollPhysics(),
        foregroundDecoration: BoxDecoration(
          border: Border.all(
            color: Colors.transparent
          )
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.transparent
          ),
          color: Colors.transparent
        ),
        controller: TextEditingController(
          text: text
        )
      )
    );
  }
}