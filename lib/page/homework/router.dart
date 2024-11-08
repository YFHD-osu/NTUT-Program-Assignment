import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/core/global.dart';

import 'package:ntut_program_assignment/widget.dart';
import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/page/homework/details.dart';
import 'package:ntut_program_assignment/page/homework/list.dart';
import 'package:toastification/toastification.dart';

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
    if (e == GlobalEvent.accountSwitch) {
      homeworks.clear();
    }
  }
  
  static ToastificationItem showToast(BuildContext context, String title, String message, InfoBarSeverity level) {
    return toastification.showCustom(
      // ignore: use_build_context_synchronously
      context: context,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 5),
      builder: (BuildContext context, ToastificationItem holder) {
        return Container(
          width: 500,
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color.fromRGBO(39, 39, 39, 1),
          ),
            child: InfoBar(
            isLong: false,
            title: Text(title),
            content: Text(message),
            severity: level
          )
        );
      },
    );
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
          child: BreadcrumbBar<BreadcrumbValue>(
            items: Controller.routes,
            chevronIconSize: 20,
            onItemPressed: (item) {
              setState(() {
                final index = Controller.routes.indexOf(item);
                Controller.routes.removeRange(index + 1, Controller.routes.length);
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
                        return const RouteFlyout();
                    });
                  }
                )
              );
            },
          )
        )
      ),
      content: AnimatedSwitcher(
        transitionBuilder: (Widget child, Animation<double> animation) {
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(animation);

          final slideAnimation = child.key == const ValueKey(1)
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
        child: Controller.routes.last.value.index == -1 ? 
          const PageBase(
            key: ValueKey(1),
            child: HomeworkList()
          ) : 
          const DetailRoute()
      ));
  }
}

class RouteFlyout extends StatelessWidget {
  const RouteFlyout({super.key});

  Widget _testDataRow(BreadcrumbItem<BreadcrumbValue> breadcumber) {
    return SizedBox(

      child: HyperlinkButton(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(breadcumber.value.label, style: const TextStyle(color: Colors.white))
        ),
        onPressed: () {

        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 300, maxHeight: 100
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).menuColor,
        borderRadius: BorderRadius.circular(5)
      ),
      child: Column(
        children: Controller.routes
          .map((e) => _testDataRow(e))
          .toList()
      )
    );
  }
}