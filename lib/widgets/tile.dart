import 'package:fluent_ui/fluent_ui.dart';

class Tile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;

  final double? height, width;

  final VoidCallback? onPressed;

  final EdgeInsetsGeometry? padding;

  final BoxConstraints? constraints;

  final bool limitIconSize;

  const Tile({
    super.key,
    this.padding,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onPressed, 
    this.height, 
    this.width, 
    this.constraints,
    this.limitIconSize = false 
  });

  EdgeInsetsGeometry? get _padding => 
    padding ?? EdgeInsets.symmetric(horizontal: 20, vertical: 12.5);

  double? get iconSize {
    if (!limitIconSize) {
      return null;
    }

    return leading == null ? 0: 20;
  }

  Widget _widgetBuilder(BuildContext context) {
    if (title == null && subtitle == null && leading == null) {
      return trailing ?? SizedBox();
    }

    return Row(
      children: [
        SizedBox.square(
          dimension: iconSize,
          child: leading
        ),
        SizedBox(
          width: leading == null ? 0 : 20
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title ?? SizedBox(),
              DefaultTextStyle(
                style: TextStyle(
                color: FluentTheme.of(context).brightness.isDark ? 
                  const Color.fromRGBO(207, 207, 207, 1) :
                  const Color.fromRGBO(95, 95, 96, 1)
                ),
                child: subtitle ?? SizedBox()
              )              
            ]
          )
        ),
        trailing ?? SizedBox()
      ]
    );
  }

  Color _colorResolve(BuildContext context, Set<WidgetState> state) {
    if (state.contains(WidgetState.pressed)) {
      return FluentTheme.of(context).resources.systemFillColorAttentionBackground;
    }

    if (state.contains(WidgetState.hovered)) {
      return FluentTheme.of(context).resources.dividerStrokeColorDefault;
    }
    
    return FluentTheme.of(context).resources.cardBackgroundFillColorDefault;
  } 

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) {
      return Container(
        constraints: constraints ?? BoxConstraints(
          minHeight: 50
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: FluentTheme.of(context).resources.cardBackgroundFillColorDefault
        ),
        padding: _padding,
        child: _widgetBuilder(context)
      );
    }
    
    return Button(
      style: ButtonStyle(
        backgroundColor: WidgetStateColor.resolveWith(
          (state) => _colorResolve(context, state)
        ),
        shape: WidgetStatePropertyAll(ShapeBorder.lerp(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // No border radius
            side: BorderSide.none, // No border
          ),
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5), // Example rounded border
            side: BorderSide(color: Colors.transparent), // Transparent border
          ),
          1)),
        padding: WidgetStatePropertyAll(_padding)
      ),
      onPressed: onPressed,
      child: _widgetBuilder(context)
    );
  }
}