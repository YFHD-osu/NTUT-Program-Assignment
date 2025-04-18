import 'dart:math';
import 'dart:core';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:diff_match_patch/diff_match_patch.dart';

class DiffWidgetData {
  final List<TextSpan> original;
  final List<TextSpan> response;
  final bool isEqual;

  DiffWidgetData({required this.original, required this.response, required this.isEqual});

  factory DiffWidgetData.fromDiffs(List<Diff> original, List<Diff> response) {
    return DiffWidgetData(
      original: _diffsToText(original),
      response: _diffsToText(response),
      isEqual: _isLineCorrect(original, response)
    );
  }

  static bool _isLineCorrect(List<Diff> original, List<Diff> response) {
    if (!original.every((e) => e.operation == 0)) {
      return false;
    }
    
    return response.every((e) => e.operation == 0);
  }

  static List<TextSpan> _diffsToText(List<Diff> diffs) {
    if (diffs.isEmpty) {
      return [TextSpan(
        text: "< 此行沒有輸出內容 >",
        style: TextStyle(
          color: Color.fromRGBO(112, 112, 112, 1)
        )
      )];
    }

    TextSpan convert(Diff e) {
      if (e.operation == 0) {
        return TextSpan(
          text: e.text,
          style: TextStyle(
            color: Colors.white
          )
        );
      }

      if (e.operation < 0) {
        return TextSpan(
          text: e.text,
          style: TextStyle(
            color: Colors.red.lighter
          )
        );
      }
      
      return TextSpan(
        text: e.text,
        style: TextStyle(
          color: Colors.white
        )
      );
    }

    return diffs
      .map(convert)
      .toList();
  }

}

class DifferentMatcher {
  static final dmp = DiffMatchPatch();

  /*
    A threshold to determine whether a matcher result is reliable or not
    Take for an example, under this circumstances:
    [Line 1]
    [OG] ( ABCD )
    [OP] ( A

    [Line 2]
    [OG] ( EFGH )
    [OP] BFG

    [Line 3]
    [OG] ( IJKL )
    [OP] L )

    We will consider that this match result is not reliable,
    so it's required to switch to the parser that compare result line by line

    This threahold can control the lowest percent of the valid string
  */
  static const double threshold = 0.75;

  final List<List<Diff>> original, response;

  final List<DiffWidgetData> widgets;

  int get length => 
    max(original.length, response.length);

  DifferentMatcher({
    required this.original,
    required this.response,
    required this.widgets
  });

  static bool _checkReliability(List<List<Diff>> original, List<List<Diff>> response) {
    // Calculate string length for each diff match result 
    final orig = original.map((e) => e.fold(0, (p, e) => p+e.text.length)).toList();
    final resp = response.map((e) => e.fold(0, (p, e) => p+e.text.length)).toList();

    final invalidLineCount = List<int>
      .generate(min(resp.length, orig.length), (e) => e)
      .map((e) => (orig[e] - resp[e]).abs() / max(orig[e], resp[e]))
      .where((e) => e != 0)
      .where((e) => e < threshold)
      .length;
    // print(invalidLineCount / orig.length < 1-threshold);
    return invalidLineCount / orig.length < 1-threshold;
  }
  
  factory DifferentMatcher.match(String original, String response) {
    final List<List<Diff>> originalDiff = [], responseDiff = [];

    _matchOverall(original, response, originalDiff, responseDiff);
    
    if (_checkReliability(originalDiff, responseDiff) || true) {
      final lineCount = max(originalDiff.length, responseDiff.length);

      return DifferentMatcher(
        original: originalDiff,
        response: responseDiff,
        widgets: List
          .generate(lineCount, (e) => e)
          .map((e) => DiffWidgetData.fromDiffs(
            e < originalDiff.length ? originalDiff[e] : [],
            e < responseDiff.length ? responseDiff[e] : []
          ))
          .toList()
      );
    }

    /*
    originalDiff.clear();
    responseDiff.clear();

    _matchLineByLine(original, response, originalDiff, responseDiff);

    return DifferentMatcher(
      original: originalDiff, 
      response: responseDiff,
      widgets: List
        .generate(originalDiff.length, (e) => e)
        .map((e) => DiffWidgetData.fromDiffs(originalDiff[e], responseDiff[e]))
        .toList()
    );
    */
  }

  static void _matchOverall(
    String original, String response,
    List<List<Diff>> originalDiff, List<List<Diff>> responseDiff
  ) {
    final diffs = dmp.diff(response, original);

    originalDiff.add([]);
    responseDiff.add([]);

    // Re-order the list with splitted by '\n' and turn them into an 2 dim array 
    for (var diff in diffs) {
      if (!diff.text.contains("\n")) {
        if (diff.operation <= 0) {
          responseDiff.last.add(diff);
        }

        if (diff.operation >= 0) {
          originalDiff.last.add(diff);
        }
        continue;
      }

      final splitted = diff.text.split("\n");

      if (diff.operation <= 0) {
        responseDiff.last.add(Diff(
          diff.operation, splitted.first));
      
        for (int i=1; i<splitted.length-1; i++) {
          responseDiff.add([Diff(diff.operation, splitted[i])]);
        }

        responseDiff.add([Diff(diff.operation, splitted.last)]);
      }
      
      if (diff.operation >= 0) {
        originalDiff.last.add(Diff(
          diff.operation, splitted.first));
      
        for (int i=1; i<splitted.length-1; i++) {
          originalDiff.add([Diff(diff.operation, splitted[i])]);
        }

        originalDiff.add([Diff(diff.operation, splitted.last)]);
      }
    }

    return;
  }

  /*
  static void _matchLineByLine(
    String original, String response,
    List<List<Diff>> originalDiff, List<List<Diff>> responseDiff
  ) {

    final orig = original.split("\n");
    final resp = response.split("\n");

    final minLen = min(orig.length, resp.length);

    for (int i=0; i<minLen; i++) {
      originalDiff.add([]);
      responseDiff.add([]);

      final diffs = dmp.diff(orig[i], resp[i]);

      for (var diff in diffs) {
        if (diff.operation == 0) {
          originalDiff.last.add(diff);
          responseDiff.last.add(diff);
        } else if ((diff.operation > 0)) {
          responseDiff.last.add(diff);
        } else {
          originalDiff.last.add(diff);
        }
      }

    }

    for (int i=minLen-1; i<orig.length; i++) {
      originalDiff.add([]);
      responseDiff.add([]);
      originalDiff.last.add(Diff(-1, orig[i]));
    }

    for (int i=minLen-1; i<resp.length; i++) {
      originalDiff.add([]);
      responseDiff.add([]);
      responseDiff.last.add(Diff(-1, resp[i]));
    }
  }
  */
  
  factory DifferentMatcher.trimAndMatch(List<String> original, List<String> response) {
    // Remove last newline character 

    while (original.lastOrNull?.isEmpty ?? false) {
      original.removeLast();
    }

    while (response.lastOrNull?.isEmpty ?? false) {
      response.removeLast();
    }

    return DifferentMatcher.match(
      original
        .map((e) => e.trimRight())
        .join("\n"),
        
      response
        .map((e) => e.trimRight())
        .join("\n")
    );
  }

}