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