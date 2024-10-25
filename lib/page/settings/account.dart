import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';

import 'package:hive/hive.dart';

import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/widget.dart';

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

  String selCourse = "選擇課程";

  // Store the state of the "remember password" check box
  bool _rememberPW = true;
  
  // Store the state that login is in progress
  bool _isLoading = false;

  bool get isEven {
    String a = _username.text;
    a = a.length > 3 ? a.substring(a.length-3) : a;
    return (int.tryParse(a)??0).isEven;
  } 

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
    final courseList = isEven ? widget.evenCourses : widget.oddCourses;

    return ContentDialog(
      constraints: const BoxConstraints(
        minHeight: 0, minWidth: 0, maxHeight: 400, maxWidth: 400),
      title: const Text("加入帳號"),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("帳號"),
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
          const Text("密碼"),
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
          const Text("選擇課程"),
          const SizedBox(height: 5),
          SizedBox(
            width: 400,
            child: ComboBox<String>(
              value: selCourse,
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
              },
              placeholder: const Text('選擇課程')
            )
          ),
          const SizedBox(height: 10),
          Checkbox(
            content: const Text("記住帳號密碼"),
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
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _login,
          child: const Text('登入'),
        ),
      ],
    );
  }

  Future<void> _login() async {
    final acc = Account(
      course: widget.evenCourses.indexOf(selCourse) + 1,
      username: _username.text,
      password: _password.text
    );

    setState(() => _isLoading = true);
    try {
      await acc.login();
    } catch (e) {
      await showDialog<String>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => ContentDialog(
          title: const Text("登入錯誤"),
          content: Text(e.toString()),
          actions: [
            Button(
              child: const Text("確定"),
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

    if (_rememberPW) {
      final collection = await BoxCollection.open(
        'data', // Name of your database
        {'accounts'}, // Names of your boxes
      );

      final box = await collection.openBox("accounts");
      await box.put(GlobalSettings.account!.name!, GlobalSettings.account!.toMap());
    }

    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();

    // TODO: Create a "login success" pop up toast
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
  
  bool _btnDisabled = false;

  late BoxCollection collection;
  late CollectionBox _box;

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

  void _setEnable(bool state) {
    setState(() => _btnDisabled = state);
  }

  void _onUpdate(GlobalEvent event) {
    if (![GlobalEvent.accountSwitch].contains(event)) return;
    setState(() {});
  }

  Future<void> _addAccount() async {
    final oddCourses = await Account.fetchCourse(true);
    final evenCourses = await Account.fetchCourse(false);
    await showDialog<String>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => LoginDialog(
        oddCourses: oddCourses,
        evenCourses: evenCourses,
      )
    );
    await _refreshDB();
  }

  Future<void> _refreshDB() async {
    if (_isDbBusy) return;

    setState(() => _isDbBusy = true);
    collection = await BoxCollection.open(
      'data', // Name of your database
      {'accounts'}, // Names of your boxes
    );

    _box = await collection.openBox("accounts");
    final maps = await _box.getAllValues();
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
          child: const Text("登出"),
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("尚未登入"),
            Text("請從下方列表選擇帳號登入或新增帳號")
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
        const Text("目前登入"),
        const SizedBox(height: 5),
        Tile(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: GlobalSettings.isLogin ? 
              _loginAccountInfo() : _logoutAccountInfo()
          )
        ),
        const SizedBox(height: 10),
        const Text("其他使用者"),
        const SizedBox(height: 5),
        Tile(
          child: Row(
            children: [
              const Text("新增其他使用者"),
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
                  await _addAccount();
                  setState(() => _isLogging = false);
                },
                child: const Text("新增帳號")
              )
            ]
          )
        ),
        const SizedBox(height: 10),
        _accountList(),
        Align(
          alignment: Alignment.centerLeft,
          child: HyperlinkButton(
            onPressed: _refreshDB,
            child: const Text("沒有看到你的帳號嗎? 點此重新整理"),
          )
        )

      ].map((e) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: e,
      )).toList()
    );
  }

  Widget _accountList() {
    if (_isDbBusy) {
      return const Align(
        child: SizedBox.square(
          child: ProgressRing()
        )
      );
    }

    if (_accounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Text("尚未加入任何帳號，請點擊上方的新增帳號開始")
      );
    }

    return Column(
      children: _accounts
        .where((e) => e.username != GlobalSettings.account?.username)
        .map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AccountItem(
            data: e,
            enable: _btnDisabled,
            callback: _setEnable
          )
        ))
        .toList()
    );
  }
}

class AccountItem extends StatefulWidget {
  final bool enable;
  final Account data;
  final Function(bool) callback;
  
  const AccountItem({
    super.key, 
    required this.data,
    required this.enable,
    required this.callback
  });

  @override
  State<AccountItem> createState() => _AccountItemState();
}

class _AccountItemState extends State<AccountItem> {
  bool _processing = false;
  final splitButtonKey = GlobalKey<SplitButtonState>();

  @override
  Widget build(BuildContext context) {
    return Tile(
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.lightest,
              borderRadius: BorderRadius.circular(500)
            ),
            child: const Icon(FluentIcons.user_optional),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.data.name.toString()),
              Text(widget.data.username.toString())
            ]
          ),
          const Spacer(),
          AnimatedOpacity(
            opacity: _processing ? 1: 0,
            duration: const Duration(milliseconds: 350),
            child: const ProgressRing()
          ),
          const SizedBox(width: 10),
          SplitButton(
            key: splitButtonKey,
            enabled: !widget.enable && !_processing,
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
                      setState(() => {});
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 100,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2.5),
                      child: Text("移除帳號",
                        style: TextStyle(color: Colors.red))
                    )
                  )
                ]
              ),
            ),
            onInvoked: !(!widget.enable && !_processing) ? null : () async {
              widget.callback(true);
              setState(() => _processing = true);
              await GlobalSettings.login(widget.data);
              
              widget.callback(false);
              if (!mounted) return;
              setState(() => _processing = false);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
              child: Text("登入")
            )
          )
        ]
      )
    );
  }
}