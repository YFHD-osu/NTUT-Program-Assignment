import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/core/global.dart';

import 'package:ntut_program_assignment/widget.dart';
import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/page/homework/details.dart';
import 'package:ntut_program_assignment/page/homework/list.dart';
enum EventType {
  setStateRouter,
  refreshOverview,
  setStateDetail
}

class BreadcrumbValue {
  final String label;
  final int index;

  BreadcrumbValue({
    required this.label,
    required this.index
  });
}

class Controller {
  // Stream subscription from GlobalEvent due to account switch update
  static StreamSubscription? globalSub;

  static final StreamController<EventType> update = StreamController();
  static final stream = update.stream.asBroadcastStream();

  static List<Homework> homeworks = [];

  static final routes = <BreadcrumbItem<BreadcrumbValue>>[
    BreadcrumbItem(label: const Text('作業列表 ', style: TextStyle(fontSize: 30)), value: BreadcrumbValue(label: "作業列表", index: -1))
  ];


  static void setState() {
    update.sink.add(EventType.setStateRouter);
  }

  static initialize() {
    if (globalSub != null) return;
    globalSub = GlobalSettings.stream.listen(onGlobalEvent);
  }

  static onGlobalEvent(GlobalEvent e) {
    if (e == GlobalEvent.refreshHwList) {
      homeworks.clear();
    }
  }
}

class HomeworkRoute extends StatefulWidget {
  const HomeworkRoute({super.key});

  @override
  State<HomeworkRoute> createState() => _HomeworkRouteState();
}

class _HomeworkRouteState extends State<HomeworkRoute> {
  late StreamSubscription _localSub;
  final _menuController = FlyoutController();

  final _route = <String>["hwList"];

  List<BreadcrumbItem<int>> get breadcumber {
    return _route.map((e) => 
      BreadcrumbItem(label: Text('${fetchBreadTitle(e)} ', style: const TextStyle(fontSize: 30)), value: 0)
    ).toList();
  }

  String fetchBreadTitle(String e) {
    if (e.contains("hwList")) {
      return "作業列表";
    }

    if (e.contains("hwDetail")) {
      final id = int.parse(e.split("?").last);
      final hws = Controller.homeworks;
      return "${hws[id].number} ${hws[id].title}";
    }

    return e;
  }

  @override
  void initState() {
    super.initState();
    _localSub = Controller.stream.listen(_onUpdate);
    Controller.initialize();
  }

  @override
  void dispose() {
    _localSub.cancel();
    super.dispose();
  }

  void _onUpdate(EventType e) {
    if (e == EventType.setStateRouter) {
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: Align(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          margin: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 10),
          child: BreadcrumbBar<int>(
            items: breadcumber,
            chevronIconSize: 20,
            onItemPressed: (item) {
              setState(() {
                _route.removeRange(1, _route.length);
              });
            },
            overflowButtonBuilder: (context, openFlyout) {
              return FlyoutTarget(
                controller: _menuController,
                child: IconButton(
                  icon: const Icon(FluentIcons.more),
                  onPressed: () {
                    _menuController.showFlyout(
                      autoModeConfiguration: FlyoutAutoConfiguration(
                        preferredMode: FlyoutPlacementMode.bottomLeft,
                      ),
                      barrierDismissible: true,
                      dismissOnPointerMoveAway: false,
                      dismissWithEsc: true,
                      navigatorKey: Navigator.of(context),
                      builder: (context) {
                        return RouteFlyout(
                          route: _route,
                        );
                    });
                  }
                )
              );
            },
          )
        )
      ),
      content: Router(
        route: _route,
        struct: {
          "hwList": HomeworkList(route: _route),
          "hwDetail": HomeworkDetail(route: _route)
        }
      ));
  }
}

class RouteFlyout extends StatelessWidget {
  final List route; 
  const RouteFlyout({super.key, required this.route});

  Widget _testDataRow(BreadcrumbItem<BreadcrumbValue> breadcumber, BuildContext context) {
    return HyperlinkButton(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Center(
          child: Text(
            breadcumber.value.label,
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis
          )
        )
      ),
      onPressed: () {
        route.removeRange(1, route.length);
        Navigator.of(context).pop();
        Controller.setState();
      }
    );
    
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 180,
        maxHeight: Controller.routes.length*36 + 10
      ),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).menuColor,
        borderRadius: BorderRadius.circular(5)
      ),
      child: Column(
        children: Controller.routes
          .map((e) => _testDataRow(e, context))
          .toList()
      )
    );
  }
}

class Router extends StatefulWidget {
  final List<String> route;
  final Map<String, Widget> struct;

  const Router({
    super.key,
    required this.route,
    required this.struct
  });

  @override
  State<Router> createState() => _RouterState();
}

class _RouterState extends State<Router> {
  String get cRoute => widget.route.last;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      transitionBuilder: (Widget child, Animation<double> animation) {
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(animation);

        final slideAnimation = (ValueKey(cRoute) != child.key) ^ widget.route.length.isOdd
          // Fade out from left to right
          ? Tween<Offset>(begin: const Offset(-1, 0), end: const Offset(0, 0)).animate(animation)
          // Fade in from left to right
          : Tween<Offset>(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(animation);

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child
          ),
        );
      },
      switchInCurve: Curves.fastOutSlowIn,
      switchOutCurve: Curves.fastOutSlowIn,
      duration: const Duration(milliseconds: 300),
      child: PageBase(
        key: ValueKey(cRoute),
        child: widget.struct[cRoute.split("?").first] ?? const SizedBox()
      )
    );
  }
}