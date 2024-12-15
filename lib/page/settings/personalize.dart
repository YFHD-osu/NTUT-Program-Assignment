import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/window_effect.dart';
import 'package:ntut_program_assignment/core/global.dart';
import 'package:ntut_program_assignment/main.dart';
import 'package:ntut_program_assignment/provider/theme.dart';
import 'package:ntut_program_assignment/widget.dart';

class PersonalizeRoute extends StatefulWidget {
  const PersonalizeRoute({super.key});

  @override
  State<PersonalizeRoute> createState() => _PersonalizeRouteState();
}

class _PersonalizeRouteState extends State<PersonalizeRoute> {
  
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Text("外觀", style: TextStyle(fontWeight: FontWeight.bold),),
        SizedBox(height: 5),
        ThemeSection(),
        SizedBox(height: 10),
        Text("文字大小", style: TextStyle(fontWeight: FontWeight.bold),),
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
  @override
  Widget build(BuildContext context) {
    final title = ["Follow System", "Light Mode", "Dark Mode"];
    return Expander(
      initiallyExpanded: true,
      contentPadding: EdgeInsets.zero,
      header: Tile.lore(
        icon: const Icon(FluentIcons.brush),
        title: "Theme",
        lore: "Choose theme style for this application",
        decoration: const BoxDecoration(
          color: Colors.transparent
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12.5)),
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
        Tile.subTile(
          title: "Window Effect",
          decoration: const BoxDecoration(
            color: Colors.transparent
          ),
          child: ComboBox<WindowEffect>(
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
        Tile.lore(
          title: "題目文字大小",
          lore: "題目細節的顯示文字大小",
          icon: const Icon(FluentIcons.plain_text),
          child: ComboBox<double>(
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
        Tile.lore(
          title: "測試資料文字大小",
          lore: "測試資料細節的顯示文字大小",
          icon: const Icon(FluentIcons.plain_text),
          child: ComboBox<double>(
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