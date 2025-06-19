import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';


class DebugOnlyWidget extends StatelessWidget {
  final Widget child;

  const DebugOnlyWidget({
    super.key,
    required this.child
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      return child;
    }
    return SizedBox();
  }
}