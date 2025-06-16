import 'package:fluent_ui/fluent_ui.dart';

import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/widgets/tile.dart';
import 'package:ntut_program_assignment/models/diff_model.dart';

class DiffIndicator extends StatelessWidget {
  final DifferentMatcher matcher;
  
  const DiffIndicator({super.key, required this.matcher});

  Widget _lineTile(BuildContext context, int index) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.5),
      child: Tile(
        padding: EdgeInsets.symmetric(vertical: 3),
        leading: Container(
          width: 40,
          margin: EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: matcher.widgets[index].isEqual ? 
              Colors.green.lighter : Colors.red.lighter,
            borderRadius: BorderRadius.circular(4)
          ),
          child: Text("行\n$index", textAlign: TextAlign.center)
        ),
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: "FiraCode",
              fontSize: 14 * GlobalSettings.prefs.testcaseTextFactor
            ),
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(
                  FluentIcons.check_mark,
                  size: 12 * GlobalSettings.prefs.testcaseTextFactor
                )
              ),
              WidgetSpan(
                child: SizedBox(width: 5)
              ),
              ... matcher.widgets[index].original
            ]
        )),
        subtitle: RichText(
          text: TextSpan(
            style: TextStyle(
              height: 1,
              fontFamily: "FiraCode",
              fontSize: 14 * GlobalSettings.prefs.testcaseTextFactor
            ),
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(
                  FluentIcons.lightbulb_solid,
                  size: 12 * GlobalSettings.prefs.testcaseTextFactor
                )
              ),
              WidgetSpan(
                child: SizedBox(width: 5)
              ),
              ... matcher.widgets[index].response
            ]
          )
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      shrinkWrap: true,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: matcher.length,
            _lineTile
          )
        )
      ]
    );
  }
}