import 'package:fluent_ui/fluent_ui.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

import 'package:ntut_program_assignment/core/extension.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/main.dart';
import 'package:ntut_program_assignment/page/exercise/page.dart' show ProblemInstance;
import 'package:ntut_program_assignment/core/local_problem.dart';
import 'package:ntut_program_assignment/widgets/tile.dart';

class ProblemList extends StatefulWidget {
  const ProblemList({super.key});

  @override
  State<ProblemList> createState() => _ProblemListState();
}

class _ProblemListState extends State<ProblemList> with AutomaticKeepAliveClientMixin {
  String? _onlineError;

  int get totalImport =>
    ProblemInstance.onlineCount + 
    ProblemInstance.localCount; 

  Future<void> _refresh() async {
    _onlineError = null;
    ProblemInstance.onlineList = null;
    if (mounted) setState(() {});

    try {
      ProblemInstance.onlineList = await OnlineProblemAPI.fetchCollections();
    } catch (error) {
      logger.e("Error loading problem: ${error.toString()}");
      _onlineError = error.toString();
    } finally {
      if (mounted) setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    if (ProblemInstance.onlineList == null) {
      _refresh();
    }
  }

  Widget _overviewCard() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(FluentIcons.refresh),
          onPressed: _refresh
        ),
        const Spacer(),
        SizedBox(
          height: 50, width: 150,
          child: Tile(
            trailing: Row(
              children: [
                const Spacer(),
                AnimatedFlipCounter(
                  value: totalImport,
                  fractionDigits: 0,
                  curve: Curves.easeInOutSine,
                  duration: const Duration(milliseconds: 400),
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )
                ),
                // Text("$totalImport",
                //   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Text("已導入"),
                const Spacer()
              ]
            )
          )
        )
      ]
    );
  }

  Widget _buildOnlineList() {
    if (_onlineError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FluentIcons.error, size: 40),
            SizedBox(height: 10),
            Text("${MyApp.locale.error_occur}: $_onlineError"),
            SizedBox(height: 10),
            FilledButton(
              onPressed: _refresh,
              child: Text(MyApp.locale.refresh)
            )
          ]
        )
      );
    }

    if (ProblemInstance.onlineList == null) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProgressRing(),
            SizedBox(height: 60, width: 10),
            Text("載入中...")
          ]
        )
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: ProblemInstance.onlineList?.length ?? 0,
      itemBuilder: (context, index) => CollectionView(
        collection: ProblemInstance.onlineList![index]
      ),
      separatorBuilder: (context, index) => 
        SizedBox(height: 10)
    );
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _overviewCard(),
        Text("線上題庫", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        _buildOnlineList(),
        SizedBox(height: 10),
        // Text("自訂題庫", style: TextStyle(fontWeight: FontWeight.bold)),
        // SizedBox(height: 5),
        // ListView.separated(
        //   shrinkWrap: true,
        //   itemCount: ProblemInstance.localList?.length ?? 0,
        //   itemBuilder: (context, index) => CollectionView(
        //     collection: ProblemInstance.localList![index]
        //   ),
        //   separatorBuilder: (context, index) => 
        //     SizedBox(height: 10)
        // )
        
    ]);
  }
  
  @override
  bool get wantKeepAlive => true;
}

class CollectionView extends StatefulWidget {
  final ProblemCollection collection;

  const CollectionView({
    super.key,
    required this.collection
  });

  @override
  State<CollectionView> createState() => _CollectionViewState();
}

class _CollectionViewState extends State<CollectionView> {

  Future<void> _fetchProblem() async {
    await widget.collection.fetchProblems();
    if (mounted) setState(() {});
  }

  void _push(LocalProblem problem) {
    if (GlobalSettings.route.current.name == "hwDetail") {
      return;
    }
    GlobalSettings.route.push(
      "exercise",
      title: problem.title, 
      parameter: {"id": problem},
    );
  }

  Widget _contentBuilder() {
    if (!widget.collection.isInitialized) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProgressRing(),
            SizedBox(width: 10, height: 45),
            Text("題目載入中...")
          ] 
        )
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: widget.collection.problems.length,
      separatorBuilder: (context, index) => 
        SizedBox(height: 3),
      itemBuilder:(context, index) {
        final problem = widget.collection.problems[index];
        return Tile(
          limitIconSize: true,
          leading: Icon(FluentIcons.pen_workspace),
          title: Text(problem.title),
          subtitle: Text(problem.createDate.toAbsolute()),
          trailing: Icon(FluentIcons.chevron_right),
          onPressed: () => _push(problem)
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expander(
      contentBackgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(vertical: 2),
      leading: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5),
        child: SizedBox(
        height: 60,
        child: Icon(FluentIcons.folder)
      )
      ),
      header: Padding(
        padding: EdgeInsets.only(left: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.collection.name),
            Text(widget.collection.description)
          ],
        )
      ),
      content: _contentBuilder(),
      onStateChanged: (isOpen) async {
        if (isOpen && widget.collection.isInitialized == false) {
          await _fetchProblem();
        }
      }
    );
  }
}