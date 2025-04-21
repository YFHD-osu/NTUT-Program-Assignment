import 'package:fluent_ui/fluent_ui.dart';

import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/core/test_server.dart';
import 'package:ntut_program_assignment/widgets/tile.dart';
import 'package:ntut_program_assignment/models/diff_model.dart';

class DiffIndicator extends StatelessWidget {
  final DifferentMatcher matcher;
  
  const DiffIndicator({super.key, required this.matcher});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: matcher.length,
            (BuildContext context, int index) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 3.5),
                child: Tile(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  leading: Container(
                    width: 40,
                    margin: EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: matcher.widgets[index].isEqual ? 
                        Colors.green.lighter : Colors.red.lighter,
                      borderRadius: BorderRadius.circular(4)
                    ),
                    child: Column(
                      children: [
                        Text("行"),
                        Text(index.toString())
                      ]
                    )
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
          )
        )
      ]
    );
  }
}

class TestCaseView extends StatelessWidget {
  final Case testCase;

  const TestCaseView({
    super.key,
    required this.testCase
  });

  num get diffPortHeight {
    final len = testCase.matcher!.length;

    final result = 50 * len + len * 2 * 14 * (GlobalSettings.prefs.testcaseTextFactor - 1);
    return result > 350 ? 350 : result;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: diffPortHeight.toDouble(),
      child: DiffIndicator(matcher: testCase.matcher!)
    ); 
  }
}