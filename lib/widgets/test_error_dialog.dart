
import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/core/test_server.dart';
import 'package:ntut_program_assignment/main.dart';
import 'package:ntut_program_assignment/page/homework/details.dart' show CopyButton;
import 'package:ntut_program_assignment/widgets/selectable_text_box.dart';

class TestErrorDialog extends StatelessWidget {
  final Object error;
  const TestErrorDialog({
    super.key,
    required this.error
  });

  String parseErrorTitle(Object? error) {
    switch (error) {
      case TimeoutException():
        return MyApp.locale.testcase_timeout;
      
      case OSError():
        return MyApp.locale.testcase_invalid_test_file;

      // case Exception():
      //   return "$error";

      case TestException():
        return "編譯失敗";

      default:
        return MyApp.locale.testcase_file_failed_to_execute;
    }
  }

  String parseErrorDetail(Object? error) {
    switch (error) {
      case TimeoutException():
        return "";
      
      case OSError():
        return error.message;

      case TestException():
        return error.message;

      default:
        return "$error";
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMsg = parseErrorDetail(error);
    
    return ContentDialog(
      constraints: BoxConstraints(
        minHeight: 0, minWidth: 0, 
        maxHeight: errorMsg.isEmpty ? 200 : 800, 
        maxWidth: errorMsg.isEmpty ? 400 : 800
      ),
      title: Text("測試發生錯誤"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(parseErrorTitle(error)),
          errorMsg.isEmpty ? 
            SizedBox() : SelectableTextBox(text: errorMsg)
        ]
      ),
      actions: [
        CopyButton(
          context: errorMsg
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: Text("完成"),
        )
      ],
    );
  }
}