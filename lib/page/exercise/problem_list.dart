import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/main.dart';
import 'package:ntut_program_assignment/widget.dart';

class ProblemList extends StatefulWidget {
  const ProblemList({super.key});

  @override
  State<ProblemList> createState() => _ProblemListState();
}

class _ProblemListState extends State<ProblemList> with AutomaticKeepAliveClientMixin{

  Widget _overviewCard() {
    return Row(
      children: [
        // Container(
        //   width: 50, height: 50,
        //   decoration: BoxDecoration(
        //     color: Colors.blue.lightest,
        //     borderRadius: BorderRadius.circular(500)
        //   ),
        //   child: const Icon(FluentIcons.user_optional, size: 20),
        // ),
        // const SizedBox(width: 15),
        // Column(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: [
        //     Text(GlobalSettings.account!.name.toString()),
        //     Text(GlobalSettings.account!.username.toString())
        //   ]
        // ),
        // const SizedBox(width: 15),
        // IconButton(
        //   icon: const Icon(FluentIcons.refresh),
        //   onPressed: () async {
        //     _refresh();
        //   }
        // ),
        const Spacer(),
        Tile(
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
          height: 50, width: 150,
          child: Column(
            children: [
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  Text("${12}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Text("已導入"),
                  const Spacer()
                ]
              ),
              const Spacer()
            ]
          )
        )
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    /*
    if (GlobalSettings.isLoggingIn) {
      return const LoggingInBlock();
    }

    if (GlobalSettings.account == null) {
      return const LoginBlock();
    }

    if (errMsg != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FluentIcons.error, size: 50),
            const SizedBox(height: 10),
            Text("${MyApp.locale.error_occur}\n$errMsg", textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _refresh,
              child: Text(MyApp.locale.refresh),
            )
          ]
        )
      );
    }

    if (!_isReady) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProgressRing(),
            const SizedBox(height: 10),
            Text(MyApp.locale.loading),
          ]
        )
      );
    }
    */
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _overviewCard(),
        const SizedBox(height: 10)
    ]);
  }
  
  @override
  bool get wantKeepAlive => true;
}