import 'package:ntut_program_assignment/main.dart' show MyApp;

extension Format on String {
  static const needleRegex = r'%#%';
  static final exp = RegExp(needleRegex);

  String format(List l) {
    Iterable<RegExpMatch> matches = exp.allMatches(this);

    assert(l.length == matches.length);

    var i = -1;
    return replaceAllMapped(exp, (match) {
      i = i + 1;
      return '${l[i]}';
    });
  }
}

extension FormatDate on DateTime {

  String toRelative() {
    final now = DateTime.now();
    
    Duration diff = difference(now);

    final decoration = (diff > Duration.zero) ? 
      MyApp.locale.hwDetails_remaining :
      MyApp.locale.hwDetails_ago;
    
    diff = (diff < Duration.zero) ? now.difference(this) : diff;
    
    if (diff > const Duration(days: 7)) {
      // print("[$date] ${diff.inDays} -> ${(diff.inDays / 7).toInt()}");
      return "${diff.inDays ~/ 7} ${MyApp.locale.week} $decoration";
    } else if (diff > const Duration(days: 1)) {
      return "${diff.inDays} ${MyApp.locale.day} $decoration";
    } else if (diff > const Duration(hours: 1)) {
      return "${diff.inHours} ${MyApp.locale.hour} $decoration";
    } else {
      return "${diff.inMinutes} ${MyApp.locale.minute} $decoration";
    }
  }

  String toAbsolute() {
    return "$year年$month月$day日 $hour時$minute分";
  }
  
}