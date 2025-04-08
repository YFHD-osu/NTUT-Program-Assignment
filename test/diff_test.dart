// ignore_for_file: avoid_print

import 'package:ntut_program_assignment/core/diff_matcher.dart';

String previousVersion = // Standard
"""
(799,700)
(799,721)
(801,700)
(801,721)
(801,799)
(823,700)
""";

String updatedVersion = // Output
"""
(799,721)
(801,700)
(999,000)
""";

void main() {
  final res = DifferentMatcher.match(previousVersion, updatedVersion);

  print("COMPLETE");
  
  for (int i=0; i<res.length; i++) {
    print(res.original[i].map((e) => e.text).join(""));
    print(res.response[i].map((e) => e.text).join(""));
    print("------------");
  }

  return;
}