// ignore_for_file: avoid_print

import 'package:diff_match_patch/diff_match_patch.dart';

import 'package:ntut_program_assignment/core/diff_matcher.dart';

String previousVersion = // Standard
"""
36 9
38 27
""";

String updatedVersion = // Output
"""
all white
""";

// [ 
//   [(0, "ABCD")]
//   [*(0, "12"), (-1, "34"), (1, "JK")],
//   [(0, "OLKI")]
// ];


void main() {
  final dmp = DiffMatchPatch();

  final l = dmp.diff(previousVersion, updatedVersion);

  print(l.join("\n"));
  final res = DifferentMatcher.match(previousVersion, updatedVersion);

  print("COMPLETE");
  
  for (int i=0; i<res.length; i++) {
    print(res.original[i].map((e) => e.text).join(""));
    print(res.response[i].map((e) => e.text).join(""));
    print("------------");
  }

  return;
}