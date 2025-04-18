import 'package:fluent_ui/fluent_ui.dart';

import 'package:ntut_program_assignment/main.dart' show MyApp;
import 'package:ntut_program_assignment/core/global.dart' show GlobalSettings;

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