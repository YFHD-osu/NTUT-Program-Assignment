
import 'package:fluent_ui/fluent_ui.dart';
// import 'package:flutter/material.dart';

import 'package:flutter_syntax_view/flutter_syntax_view.dart';

class SyntaxViewShit extends StatefulWidget {
  
  const SyntaxViewShit(
      {
      super.key, 
      required this.code,
      required this.syntax,
      this.syntaxTheme,
      this.withZoom = true,
      this.withLinesCount = true,
      this.fontSize = 12.0,
      this.expanded = false,
      this.selectable = true});

  /// Code text
  final String code;

  /// Syntax/Language (Dart, C, C++...)
  final Syntax syntax;

  /// Enable/Disable zooming controls (default: true)
  final bool withZoom;

  /// Enable/Disable line number in left (default: true)
  final bool withLinesCount;

  /// Theme of syntax view example SyntaxTheme.dracula() (default: SyntaxTheme.dracula())
  final SyntaxTheme? syntaxTheme;

  /// Font Size with a default value of 12.0
  final double fontSize;

  /// Expansion which allows the SyntaxView to be used inside a Column or a ListView... (default: false)
  final bool expanded;

  /// selectable allow user to let user select the code
  final bool selectable;

  @override
  State<StatefulWidget> createState() => SyntaxViewShitState();
}

class SyntaxViewShitState extends State<SyntaxViewShit> {
  /// For zooming Controls
  late ScrollController _verticalScrollController;

  @override
  void initState() {
    super.initState();
    _verticalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.withLinesCount
          ? const EdgeInsets.only(left: 15, top: 10, right: 5, bottom: 10)
          : const EdgeInsets.all(10),
      color: widget.syntaxTheme!.backgroundColor,
      constraints: BoxConstraints(
        minHeight: 0, maxHeight: 400,
        minWidth: double.infinity
      ),
      child: Scrollbar(
        controller: _verticalScrollController,
        child: SingleChildScrollView(
          controller: _verticalScrollController,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: widget.withLinesCount
                ? buildCodeWithLinesCount() // Syntax view with line number to the left
                : buildCode() // Syntax view
            ))));
  }

  Widget buildCodeWithLinesCount() {
    final int numLines = '\n'.allMatches(widget.code).length + 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 1; i <= numLines; i++)
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                        fontFamily: 'firacode',
                        fontSize: widget.fontSize*1.05,
                        color: widget.syntaxTheme!.linesCountColor),
                    text: "$i",
                  ))
            ]),
        SizedBox(
          width: 10,
          // direction: Axis.horizontal
        ),
        buildCode()
      ],
    );
  }

  Widget buildCode() {
    if (widget.selectable) {
      return SelectableText.rich(
        selectionControls: fluentTextSelectionControls,
        TextSpan(
          style: TextStyle(fontFamily: 'firacode', fontSize: widget.fontSize),
          children: <TextSpan>[
            getSyntax(widget.syntax, widget.syntaxTheme).format(widget.code)
          ]
        )
      );
    } else {
      return RichText(
        text: TextSpan(
          style: TextStyle(fontFamily: 'firacode', fontSize: widget.fontSize),
          children: <TextSpan>[
            getSyntax(widget.syntax, widget.syntaxTheme).format(widget.code)
          ]
        )
      );
    }
  }
}
