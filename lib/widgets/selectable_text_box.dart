import 'package:fluent_ui/fluent_ui.dart';

import 'package:ntut_program_assignment/core/global.dart' show GlobalSettings;

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