import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/window_effect.dart';

import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/main.dart';
import 'package:ntut_program_assignment/provider/theme.dart';
import 'package:ntut_program_assignment/widgets/tile.dart';

class PersonalizeRoute extends StatefulWidget {
  const PersonalizeRoute({super.key});

  @override
  State<PersonalizeRoute> createState() => _PersonalizeRouteState();
}

class _PersonalizeRouteState extends State<PersonalizeRoute> {
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Text(MyApp.locale.settings_personalize_appearance, style: TextStyle(fontWeight: FontWeight.bold),),
        SizedBox(height: 5),
        ThemeSection(),
        SizedBox(height: 10),
        Text(MyApp.locale.settings_personalize_font_size, style: TextStyle(fontWeight: FontWeight.bold),),
        SizedBox(height: 5),
        FontFactorSection()
      ]
    );
  }
  
}

class ThemeSection extends StatefulWidget {
  const ThemeSection({super.key});

  @override
  State<ThemeSection> createState() => _ThemeSectionState();
}

class _ThemeSectionState extends State<ThemeSection> {
  List<String> get title => [
    MyApp.locale.settings_personalize_follow_system,
    MyApp.locale.settings_personalize_light_theme,
    MyApp.locale.settings_personalize_dark_theme
  ];

  @override
  Widget build(BuildContext context) {
    return Expander(
      initiallyExpanded: true,
      contentPadding: EdgeInsets.zero,
      leading: Padding(
        padding: EdgeInsets.fromLTRB(4, 20, 9, 20),
        child: const Icon(FluentIcons.brush)
      ),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(MyApp.locale.settings_personalize_theme),
          Text(MyApp.locale.settings_personalize_theme_desc),
        ]
      ),
      content:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        ...List.generate(ThemeMode.values.length * 2 - 1, (e) => e).map((e) {
          if (e.isEven) {
            return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 55),
                child: RadioButton(
                  checked: ThemeProvider.instance.theme ==
                      ThemeMode.values[e ~/ 2],
                  onChanged: (v) async {
                    await ThemeProvider.instance
                        .setTheme(ThemeMode.values[e ~/ 2]);
                    setState(() {});
                  },
                  content: Text(title[e ~/ 2]),
                ));
          } else {
            return const SizedBox(height: 20);
          }
        }),
        const SizedBox(height: 20),
        const Divider(
          style: DividerThemeData(horizontalMargin: EdgeInsets.zero)),
        ListTile(
          contentPadding: EdgeInsets.only(left: 40, right: 15, top: 5, bottom: 5),
          title: Text(MyApp.locale.settings_personalize_window_effect),
          trailing: ComboBox<WindowEffect>(
            items: ThemeProvider.allowEffects
              .map((e) => ComboBoxItem<WindowEffect>(
                  value: e, child: Text(e.name.capitalize())))
              .toList(),
            value: GlobalSettings.prefs.windowEffect,
            onChanged: (WindowEffect? effect) async {
              ThemeProvider.instance
                .setEffect(effect ?? WindowEffect.disabled);
              setState(() {});
            })
        )
      ]));
  }
}

class FontFactorSection extends StatefulWidget {
  const FontFactorSection({super.key});

  @override
  State<FontFactorSection> createState() => _FontFactorSectionState();
}

class _FontFactorSectionState extends State<FontFactorSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Tile(
          title: Text(MyApp.locale.settings_personalize_problem_font_size),
          subtitle: Text(MyApp.locale.settings_personalize_problem_font_size_desc),
          leading: const Icon(FluentIcons.plain_text),
          trailing: ComboBox<double>(
            value: GlobalSettings.prefs.problemTextFactor,
            items: [1.0, 1.25, 1.5, 1.75, 2.0]
              .map((e) => ComboBoxItem<double>(
                value: e,
                child: Text("${(e*100).toStringAsFixed(0)}%"),
              )).toList(),
            onChanged: (e) {
              GlobalSettings.prefs.problemTextFactor = e??1.0;
              setState(() {});
            }
          ),
        ),
        const SizedBox(height: 5),
        Tile(
          title: Text(MyApp.locale.settings_personalize_testcase_font_size),
          subtitle: Text(MyApp.locale.settings_personalize_testcase_font_size_desc),
          leading: const Icon(FluentIcons.plain_text),
          trailing: ComboBox<double>(
            value: GlobalSettings.prefs.testcaseTextFactor,
            items: [1.0, 1.25, 1.5, 1.75, 2.0]
              .map((e) => ComboBoxItem<double>(
                value: e,
                child: Text("${(e*100).toStringAsFixed(0)}%"),
              )).toList(),
            onChanged: (e) {
              GlobalSettings.prefs.testcaseTextFactor = e??1.0;
              setState(() {});
            }
          ),
        )
      ]
    );
  }
}