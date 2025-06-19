
import 'package:fluent_ui/fluent_ui.dart';
// import 'package:flutter/material.dart';

import 'package:flutter_syntax_view/flutter_syntax_view.dart';
import 'package:ntut_program_assignment/core/extension.dart';

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
        _buildNumber(numLines),
        SizedBox(width: 10),
        buildCode()
      ],
    );
  }

  Widget _buildNumber(int numLines) {
    return RichText(
      text: TextSpan(
        children: List
          .generate(numLines, (i) => i+1)
          .map((e) => TextSpan(text: "${e.toString().padLeft(2)}\n"))
          .toList(),
        style: TextStyle(
          fontFamily: 'firacode',
          fontSize: widget.fontSize*1.05,
          color: widget.syntaxTheme!.linesCountColor
        )
      )
    );
  }

  Widget buildCode() {
    final style = TextStyle(fontFamily: 'firacode', fontSize: widget.fontSize);
    final children = <TextSpan>[
      getSyntax(widget.syntax, widget.syntaxTheme).format(widget.code)
    ];

    if (widget.selectable) {
      return SelectableText.rich(
        selectionControls: fluentTextSelectionControls,
        TextSpan(
          style: style,
          children: children
        ),
        strutStyle: StrutStyle(
          height: 1.3,
          forceStrutHeight: true,
        ),
      );
    } else {
      return RichText(
        text: TextSpan(
          style: style,
          children: children
        ),
        strutStyle: StrutStyle(
          height: 1.3,
          forceStrutHeight: true,
        )
      );
    }
  }
}
