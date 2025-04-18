import 'package:fluent_ui/fluent_ui.dart';

import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/widgets/general_page.dart';

class RouteItem {
  final String name, title;
  final Map<String, dynamic>? parameter;

  RouteItem({
    required this.title,
    required this.name,
    this.parameter,
  });
}

class RouterController extends ChangeNotifier {
  late String _root;

  set root (String x) {
    _root = x;
    routes.clear();
    notifyListeners();
  }

  String get root => _root;

  RouterController({
    required String root
  }) {
    _root = root;
  }

  final List<RouteItem> routes = [];

  bool get canGoBack => routes.length > 1;
  RouteItem get current => routes.lastOrNull ?? RouteItem(title: "根目錄", name: "default");

  bool isForward = true;
  int get length => routes.length;

  void push(String path, {Map<String, dynamic>? parameter, String? title}) {
    if (routes.lastOrNull?.name == path) {
      return;
    }
    isForward = true;
    routes.add(RouteItem(name: path, parameter: parameter, title: title??"未命名"));
    notifyListeners();
  }

  void removeRange(int start, int end) {
    isForward = false;
    routes.removeRange(start, end);
    notifyListeners();
  }

  List<BreadcrumbItem<int>> breadcumber(String root) {
    final list = (routes.isEmpty) ? <BreadcrumbItem<int>>[] : List.generate(routes.length, (i) => i)
      .map((i) => BreadcrumbItem(label: Text(routes[i].title, style: const TextStyle(fontSize: 30)), value: i+1));
      
    return [
      BreadcrumbItem(label: Text(root, style: const TextStyle(fontSize: 30)), value: 0),
      ...list
    ]; 
    
  }
}

class CustomRouter extends StatefulWidget {
  final Widget? Function(String) builder;

  const CustomRouter({
    super.key,
    required this.builder
  });

  @override
  State<CustomRouter> createState() => _CustomRouterState();
}

class _CustomRouterState extends State<CustomRouter> {
  String get cRoute => GlobalSettings.route.current.name;
  bool get isForward => GlobalSettings.route.isForward;

  Widget _pageNotFound() {
    return Center(
      child: Column(
        children: [
          Icon(FluentIcons.error, size: 60),
          SizedBox(height: 10),
          Text("你是怎麼來到這個尚未完工之地的!"),
          Text("請務必把方法分享給我聽聽~"),
          Text(
            "Current route ID: "
            "${GlobalSettings.route._root}/"
            "${GlobalSettings.route.routes.map((e) => e.name).join("/")}"
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      transitionBuilder: (Widget child, Animation<double> animation) {
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(animation);

        final slideAnimation = (ValueKey(cRoute) != child.key) ^ !isForward
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
        child: widget.builder.call(cRoute) ?? _pageNotFound()
      )
    );
  }
}

class FluentNavigation extends StatefulWidget {
  final String title;

  final Widget? Function(String) builder;
  // final Map<String, Widget> struct;

  const FluentNavigation({
    super.key,
    required this.builder,
    required this.title
  });

  @override
  State<FluentNavigation> createState() => _FluentNavigationState();
}

class _FluentNavigationState extends State<FluentNavigation> {
  final _menuController = FlyoutController();

  @override
  void initState() {
    super.initState();
    GlobalSettings.route.addListener(_updateRouter);
  }

  @override
  void dispose() {
    GlobalSettings.route.removeListener(_updateRouter);
    super.dispose();
  }

  void _updateRouter() {
    if (mounted) {
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
            items: GlobalSettings.route.breadcumber(widget.title),
            chevronIconSize: 20,
            onItemPressed: (item) {
              GlobalSettings.route.removeRange(0, GlobalSettings.route.length);
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
                        return RouteFlyout(root: widget.title);
                    });
                  }
                )
              );
            },
          )
        )
      ),
      content: CustomRouter(builder: widget.builder)
    );
  }
}

class RouteFlyout extends StatelessWidget {
  final String root;

  const RouteFlyout({
    super.key,
    required this.root
  });

  Widget _testDataRow(BreadcrumbItem<int> breadcumber, BuildContext context) {
    final titles = [
      root,
      ...GlobalSettings.route.routes.map((e) => e.title) 
    ];
    return HyperlinkButton(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Center(
          child: Text(
            titles[breadcumber.value],
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis
          )
        )
      ),
      onPressed: () {
        GlobalSettings.route.removeRange(breadcumber.value, GlobalSettings.route.routes.length);
        Navigator.of(context).pop();
      }
    );
    
  }

  @override
  Widget build(BuildContext context) {
    final breadcumber = GlobalSettings.route.breadcumber(root);
    return Container(
      constraints: BoxConstraints(
        maxWidth: 180,
        maxHeight: (GlobalSettings.route.length)*36 + 10
      ),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).menuColor,
        borderRadius: BorderRadius.circular(5)
      ),
      child: Column(
        children: breadcumber
          .sublist(0, breadcumber.length-1)
          .map((e) => _testDataRow(e, context))
          .toList()
      )
    );
  }
}