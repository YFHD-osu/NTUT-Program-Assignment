import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/core/api.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/main.dart';
import 'package:ntut_program_assignment/provider/theme.dart';

import 'package:ntut_program_assignment/router.dart';
import 'package:ntut_program_assignment/widget.dart';

class CommentPage extends StatelessWidget {
  const CommentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentNavigation(
      title: MyApp.locale.comment_board_title,
      struct: {
        "default": CommentView()
      }
    );
  }
}

class CommentView extends StatefulWidget {
  const CommentView({super.key});

  @override
  State<CommentView> createState() => CommentViewState();
}

class CommentViewState extends State<CommentView> {
  List<Comment>? comments;
  String? _error;

  final _update = StreamController<int>();
  late final StreamSubscription<int> _sub;
  
  Future<void> _refresh() async {
    _error = null;
    setState(() {});

    try {
      comments = await GlobalSettings.account!.fetchMsgBoard();
    } on RuntimeError catch (e) {
      _error = e.message;
      if (mounted) {
        setState(() {});
      }
      return;
    } catch (e) {
      _error = e.toString();
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _sub = _update.stream.listen((e) => _refresh());

    if (GlobalSettings.isLogin) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FluentIcons.error, size: 50),
            const SizedBox(height: 10),
            Text("${MyApp.locale.error_occur}\n$_error", textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _refresh,
              child: Text(MyApp.locale.refresh),
            )
          ]
        )
      );  
    }

    if (comments == null) {
      return Center(
        child: Column(
          children: [
            ProgressRing(),
            SizedBox(height: 5),
            Text(MyApp.locale.loading)
          ]
        )
      );
    }

    return CommentList(
      stream: _update,
      comments: comments!
    );
  }
}

class CommentList extends StatefulWidget {
  const CommentList({
    super.key,
    required this.comments,
    required this.stream,
    this.master
  });
  
  final List<Comment> comments;
  final Comment? master;
  final StreamController<int> stream;

  @override
  State<CommentList> createState() => CommentListState();
}

class CommentListState extends State<CommentList> {
  final _controller = TextEditingController();
  bool _isSending = false;

  Future<void> _send() async {
    setState(() => _isSending = true);

    try {
      if (widget.master == null) {
        await GlobalSettings.account!.addMsgBoard(_controller.text);
      } else {
        await GlobalSettings.account!.replyMsgBoard(widget.master!.metadata, _controller.text);
      }
    } catch (e) {
      MyApp.showToast(MyApp.locale.error_occur, e.toString(), InfoBarSeverity.error);
      return;
    }

    if (mounted) {
      setState(() => _isSending = false);
    }

    _controller.text  = "";
    widget.stream.add(0);
  }

  Widget _replyBox() => Tile(
    padding: EdgeInsets.fromLTRB(16, 0, 10, 0),
    child: ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 10),
      title: RichText(
        text: TextSpan(
          style: TextStyle(color: ThemeProvider.instance.isLight ? Colors.black : Colors.white),
          children: [
            TextSpan(
              text: GlobalSettings.account!.username,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
            ),
            TextSpan(
              text: "  ${MyApp.locale.comment_board_add_reply}",
              style: TextStyle(fontSize: 13)
            ),
          ]
        )
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 5, right: 10),
        child: TextBox(
          enabled: !_isSending,
          controller: _controller,
          onChanged: (v) => setState(() {}),
        )
      ),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.lighter,
          borderRadius: BorderRadius.circular(40)
        ),
        child: Icon(FluentIcons.profile_search)
      ),
      trailing: FilledButton(
        onPressed: _controller.text.isEmpty ? 
          null : _send,
        child: Text(MyApp.locale.send),
      ),
    )
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _replyBox(),
        SizedBox(height: 5),
        ...widget.comments.reversed.map((e) => CommentTile(comment: e, stream: widget.stream)),
      ]
    );
  }
}

class CommentTile extends StatefulWidget {
  final Comment comment;
  final StreamController<int> stream;
  
  const CommentTile({
    super.key,
    required this.comment,
    required this.stream
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _isOpen = false;

  Widget _buildTrailing() {
    if (!widget.comment.canReply) {
      return SizedBox();
    }

    if (widget.comment.child.isEmpty) {
      return Row(
        children: [
          Text(MyApp.locale.comment_board_add_reply),
          SizedBox(width: 10),
          Icon(FluentIcons.add, size: 12)
        ]
      );
    }

    return Row(
      children: [
        Text("${widget.comment.child.length} ${MyApp.locale.comment_board_replies}"),
        SizedBox(width: 10),
        Icon(_isOpen ? FluentIcons.chevron_up : FluentIcons.chevron_down, size: 12)
      ]
    );
  }

  Widget _commentCard() => ListTile(
    contentPadding: EdgeInsets.symmetric(vertical: 10),
    title: RichText(
      text: TextSpan(
        style: TextStyle(color: ThemeProvider.instance.isLight ? Colors.black : Colors.white),
        children: [
          TextSpan(
            text: widget.comment.author,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
          ),
          TextSpan(
            text: "  ${widget.comment.metadata}",
            style: TextStyle(fontSize: 13)
          ),
        ]
      )
    ),
    subtitle: RichText(
      text: TextSpan(
        style: TextStyle(color: ThemeProvider.instance.isLight ? Colors.black : Colors.white),
        children: [
          TextSpan(
            text: "\n",
            style: TextStyle(fontSize: 1)
          ),
          TextSpan(
            text: widget.comment.text,
            style: TextStyle(fontSize: 17)
          )
        ]
      )
    ),
    leading: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.blue.lighter,
        borderRadius: BorderRadius.circular(40)
      ),
      child: Icon(FluentIcons.profile_search)
    ),
    // trailing: _buildTrailing(),
  );

  @override
  Widget build(BuildContext context) {
    
    if (!widget.comment.canReply) {
      return Tile(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.fromLTRB(16, 0, 10, 0),
        child: _commentCard()
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Expander(
        onStateChanged: (state) {
          _isOpen = state;
          setState(() {});
        },
        contentPadding: EdgeInsets.all(10),
        header: _commentCard(),
        content: CommentList(
          master: widget.comment,
          comments: widget.comment.child,
          stream: widget.stream,
        ),
        icon: _buildTrailing()
      )
    );
  }
}