import 'package:fluent_ui/fluent_ui.dart';

import 'package:ntut_program_assignment/provider/theme.dart';

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

class AlertButton extends StatelessWidget {
  final Widget child;
  final void Function()? onPressed;
  final void Function()? onLongPress;
  final void Function()? onTapDown;
  final void Function()? onTapUp;
  final FocusNode? focusNode;
  final bool autofocus;
  final ButtonStyle? style;
  final bool focusable;
  
  const AlertButton({
    super.key, 
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.focusNode,
    this.style,
    this.focusable = false,
    this.autofocus = false
  });

  ButtonStyle get defaultStyle => ButtonStyle(
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

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      focusNode: focusNode,
      autofocus: autofocus,
      style: defaultStyle.merge(style),
      focusable: focusable,
      child: child,
    );
  }
}