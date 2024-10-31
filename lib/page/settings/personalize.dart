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