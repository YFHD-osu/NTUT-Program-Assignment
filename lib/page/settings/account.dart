import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:ntut_program_assignment/main.dart' show MyApp, logger;
import 'package:ntut_program_assignment/page/homework/list.dart';
import 'package:ntut_program_assignment/widget.dart';
import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/core/database.dart';

class LoginDialog extends StatefulWidget {
  final List<String> evenCourses, oddCourses;

  const LoginDialog({
    super.key,
    required this.evenCourses,
    required this.oddCourses
  });

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _username = TextEditingController();
  final _password = TextEditingController();

  final _uFocus = FocusNode();
  final _pFocus = FocusNode();

  String? selCourse;

  // Store the state of the "remember password" check box
  bool _rememberPW = true;
  
  // Store the state that login is in progress
  bool _isLoading = false;

  bool get isEven {
    String a = _username.text;
    a = a.length > 3 ? a.substring(a.length-3) : a;
    return (int.tryParse(a)??0).isEven;
  }

  List<String> get courseList =>
    isEven ? widget.evenCourses : widget.oddCourses;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(
        minHeight: 0, minWidth: 0, maxHeight: 400, maxWidth: 400),
      title: Text(MyApp.locale.settings_account_acknoledge),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(MyApp.locale.account),
          const SizedBox(height: 5),
          TextBox(
            focusNode: _uFocus,
            enabled: !_isLoading,
            controller: _username,
            onChanged: (text) {
              // Update UI to fit even or odd student ID
              setState(() {}); 
            },
            onSubmitted: (value) {
              FocusScope.of(context).requestFocus(_pFocus);
            },
          ),
          const SizedBox(height: 10),
          Text(MyApp.locale.password),
          const SizedBox(height: 5),
          TextBox(
            focusNode: _pFocus,
            obscureText: true,
            enabled: !_isLoading,
            controller: _password,
            onSubmitted: (value) async{
              await _login();
            }
          ),
          const SizedBox(height: 10),
          Text(MyApp.locale.settings_account_select_course),
          const SizedBox(height: 5),
          SizedBox(
            width: 400,
            child: ComboBox<String>(
              value: selCourse??courseList.first,
              items: courseList.map<ComboBoxItem<String>>((e) {
                return ComboBoxItem<String>(
                  value: e,
                  child: Container(
                    width: 316,
                    alignment: Alignment.centerLeft,
                    child: Text(e)
                  ),
                );
              }).toList(),
              onChanged: (color) {
                selCourse = color ?? courseList.first;
                setState(() {});
              }
            )
          ),
          const SizedBox(height: 10),
          Checkbox(
            content: Text(MyApp.locale.settings_account_remember_password),
            checked: _rememberPW,
            onChanged: (value) {
              setState(() => _rememberPW = value??false);
            }
          ),
          const SizedBox(height: 10),
          Visibility(
            visible: _isLoading,
            child: const SizedBox(
              width: double.infinity,
              child: ProgressBar()
            )
          )
        ]
      ),
      actions: [
        Button(
          onPressed: _isLoading ? null : () {
            Navigator.pop(context);
          },
          child: Text(MyApp.locale.cancel_button),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _login,
          child: Text(MyApp.locale.login)
        ),
      ],
    );
  }

  Future<void> _login() async {
    final acc = Account(
      course: selCourse ==null ? 1 : courseList.indexOf(selCourse!) + 1,
      courseName: selCourse??courseList.first,
      username: _username.text,
      password: _password.text
    );
    
    setState(() => _isLoading = true);
    try {
      await acc.login();
    } catch (e) {
      if (!mounted) return;
      await showDialog<String>(
        context: context,
        builder: (context) => ContentDialog(
          title: Text(MyApp.locale.settings_account_login_failed),
          content: Text(e.toString()),
          actions: [
            Button(
              child: Text(MyApp.locale.ok),
              onPressed: () => Navigator.of(context).pop()
            )
          ],
        )
      );
      return;
    } finally {
      setState(() => _isLoading = false);
    }

    GlobalSettings.account = acc;

    if (!mounted) return;
    Navigator.of(context).pop(_rememberPW);
  }
}

class ChangePasswordDialog extends StatelessWidget {
  ChangePasswordDialog({super.key});

  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(
        minHeight: 0, minWidth: 0, maxHeight: 215, maxWidth: 400),
      title: Text(MyApp.locale.settings_account_change_password),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(MyApp.locale.settings_account_enter_new_password),
          const SizedBox(height: 5),
          TextBox(
            controller: _controller
          )
        ]
      ),
      actions: [
        Button(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(MyApp.locale.cancel_button),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, _controller.text);
          },
          child: Text(MyApp.locale.change),
        ),
      ],
    );
  }
}

class AccountRoute extends StatefulWidget {
  const AccountRoute({super.key});

  @override
  State<AccountRoute> createState() => _AccountRouteState();
}

class _AccountRouteState extends State<AccountRoute> {
  bool _isDbBusy = false;
  bool _isLogging = false;

  final database = Database(
    name: "accounts"
  );

  List<Account> _accounts = [];

  late final StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _refreshDB();
    _sub = GlobalSettings.stream.listen(_onUpdate);
  }

  @override
  void dispose() {
    super.dispose();
    _sub.cancel();
  }

  void _onUpdate(GlobalEvent event) {
    if (![GlobalEvent.refreshHwList].contains(event)) return;
    setState(() {});
  }

  Future<void> _addAccount() async {
    final oddCourses = await Account.fetchCourse(true);
    final evenCourses = await Account.fetchCourse(false);
    if (!mounted) return;
    final rememberPw = await showDialog<bool>(
      context: context,
      builder: (context) => LoginDialog(
        oddCourses: oddCourses,
        evenCourses: evenCourses,
      )
    );
    if (rememberPw ?? false) {
      await database.put(
        GlobalSettings.account!.username,
        GlobalSettings.account!.toMap()
      );
    }

    await _refreshDB();
    GlobalSettings.update.add(GlobalEvent.refreshHwList);
  }

  Future<void> _changePasswd() async {
    final newPass = await showDialog<String>(
      context: context,
      builder: (context) => ChangePasswordDialog()
    );

    if (newPass == null) {
      return;
    }

    try {
      await GlobalSettings.account!.changePasswd(newPass);
    } catch (e) {
      logger.e("Failed to chagne password: ${e.toString()}");
      MyApp.showToast(MyApp.locale.failed, e.toString(), InfoBarSeverity.error);
      return;
    }

    MyApp.showToast(
      MyApp.locale.success,
      MyApp.locale.settings_account_password_updated,
      InfoBarSeverity.success
    );
  }

  Future<void> _refreshDB() async {
    if (_isDbBusy) return;

    setState(() => _isDbBusy = true);
    
    if (!await database.initialize()) {
      await database.refresh();
    }
    
    final maps = await database.getAllValues();
    _accounts = maps
      .values
      .map((e) => Account.fromMap(e))
      .toList();

    setState(() => _isDbBusy = false);
  }

  Widget _loginAccountInfo() {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.green.lightest,
            borderRadius: BorderRadius.circular(500)
          ),
          child: const Icon(FluentIcons.user_optional),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(GlobalSettings.account!.name.toString()),
            Text(GlobalSettings.account!.username)
          ]
        ),
        const Spacer(),
        CustomWidgets.alertButton(
          onPressed: () {
            GlobalSettings.logout();
            setState(() {});
          },
          child: Text(MyApp.locale.logout)
        )
      ]
    );
  }

  Widget _logoutAccountInfo() {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.yellow.darker,
            borderRadius: BorderRadius.circular(500)
          ),
          child: const Icon(FluentIcons.user_optional),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(MyApp.locale.settings_account_not_logged_in),
            Text(MyApp.locale.settings_account_not_logged_in_desc)
          ]
        )
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(MyApp.locale.settings_account_logged_in_as),
        const SizedBox(height: 5),
        Tile(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: GlobalSettings.isLogin ? 
              _loginAccountInfo() : _logoutAccountInfo()
          )
        ),
        const SizedBox(height: 5),
        Tile.lore(
          icon: const Icon(FluentIcons.power_automate_logo),
          title: MyApp.locale.settings_account_auto_login,
          lore: MyApp.locale.settings_account_auto_login_desc,
          child: SizedBox(
            width: 200,
            child: ComboBox<String>(
              value: GlobalSettings.prefs.autoLogin ?? MyApp.locale.disable,
              items: [
                ComboBoxItem<String>(
                  value: MyApp.locale.disable,
                  child: Container(
                    width: 156,
                    alignment: Alignment.centerLeft,
                    child: Text(MyApp.locale.disable)
                  ),
                ),
                ..._accounts.map<ComboBoxItem<String>>((e) {
                  return ComboBoxItem<String>(
                    value: e.username,
                    child: Container(
                      width: 156,
                      alignment: Alignment.centerLeft,
                      child: Text("${e.username} ${e.name}")
                    )
                  );
                })
              ],
              onChanged: (value) {
                GlobalSettings.prefs.autoLogin = value;
                setState(() {});
              },
              placeholder: Text(MyApp.locale.disable)
            )
          )
        ),
        const SizedBox(height: 5),
        Tile.lore(
          icon: const Icon(FluentIcons.password_field),
          title: MyApp.locale.settings_account_change_password,
          lore: MyApp.locale.settings_account_change_password_desc,
          child: Button(
            onPressed: GlobalSettings.account == null ? 
              null :
              _changePasswd,
            child: Text(MyApp.locale.change),
          )
        ),
        const SizedBox(height: 10),
        Text(MyApp.locale.settings_account_other_user),
        const SizedBox(height: 5),
        Tile(
          child: Row(
            children: [
              Text(MyApp.locale.settings_account_add_user),
              const Spacer(),
              Visibility(
                visible: _isLogging,
                child: const SizedBox.square(
                  dimension: 28,
                  child: ProgressRing(
                    strokeWidth: 3
                  ),
                )
              ),
              const SizedBox(
                width: 10
              ),
              FilledButton(
                onPressed: _isLogging ? null : () async {
                  setState(() => _isLogging = true);
                  try {
                    await _addAccount();
                  } catch (e) {
                    MyApp.showToast(
                      MyApp.locale.error_occur,
                      e.toString(),
                      InfoBarSeverity.error
                    );
                  }
                  if (!mounted) return;
                  setState(() => _isLogging = false);
                },
                child: Text(MyApp.locale.settings_account_add_account)
              )
            ]
          )
        ),
        const SizedBox(height: 5),
        _accountList(),
        const SizedBox(height: 5),
        Align(
          alignment: Alignment.centerLeft,
          child: HyperlinkButton(
            onPressed: _refreshDB,
            child: Text(MyApp.locale.settings_account_refresh),
          )
        )

      ].map((e) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: e,
      )).toList()
    );
  }

  Future<void> _login(Account account) async {
    setState(() => _isLogging = true);

    try {
      await GlobalSettings.login(account);
    } catch (e) {
      MyApp.showToast(
        MyApp.locale.failed,
        e.toString(),
        InfoBarSeverity.error
      ); 
      return;
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }

    HomeworkInstance.homeworks.clear();
    MyApp.showToast(
      MyApp.locale.success, 
      "${MyApp.locale.welcome} ${GlobalSettings.account?.name}", 
      InfoBarSeverity.info
    );
    
  }

  Widget _accountItem(Account account) {
    final key = GlobalKey<SplitButtonState>();
    return Tile.lore(
      title: account.name.toString(),
      lore: account.username,
      icon: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.lightest,
          borderRadius: BorderRadius.circular(500)
        ),
        child: const Icon(FluentIcons.user_optional),
      ),
      child: SplitButton(
        key: key,
        enabled: !_isLogging,
        flyout: FlyoutContent(
          padding: const EdgeInsets.all(3),
          constraints: const BoxConstraints(
            maxWidth: 200.0, minWidth: 100),
          child: Wrap(
            runSpacing: 1.0,
            spacing: 8.0,
            children: [
              HyperlinkButton(
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.all(4.0),
                  ),
                ),
                onPressed: () {
                  _removeAccount(account);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 100,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2.5),
                  child: Text(MyApp.locale.settings_account_remove_account,
                    style: TextStyle(color: Colors.red))
                )
              )
            ]
          ),
        ),
        onInvoked: _isLogging ? null : () => _login(account),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
          child: Text(MyApp.locale.login)
        )
      )
    );
  }

  Future<void> _removeAccount(Account account) async {
    await database.delete(account.username);
    _refreshDB();
  }

  Widget _accountList() {
    final accCount = 
      _accounts.length - (GlobalSettings.isLogin ? 1 : 0);

    final spaceCount = accCount > 0 ?
       accCount - 1 : 0;

    if (_isDbBusy) {
      return const Align(
        child: SizedBox.square(
          child: ProgressRing()
        )
      );
    }

    if (_accounts.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Text(MyApp.locale.settings_account_no_account)
      );
    }

    return SizedBox(
      height: (65 * accCount + 5 * spaceCount).toDouble(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _accounts
          .where((e) => e.username != GlobalSettings.account?.username)
          .map((e) => _accountItem(e))
          .toList()
      )
    );
  }
}