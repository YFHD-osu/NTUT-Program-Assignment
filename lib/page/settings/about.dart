import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:ntut_program_assignment/core/updater.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ntut_program_assignment/widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';


const String termOfUse = """
使用者條款
生效日期： 剛剛 (大約1ms)

歡迎使用本軟體！在使用本程式之前，請仔細閱讀以下使用者條款。使用本程式即表示您同意遵守這些條款。如果您不同意這些條款，請勿使用本程式。

1. 使用者資格
1.1 本軟體僅限於合格的教師與學生使用。教師使用者無權利用本程式對學生作出死當、當掉、退選或恐嚇等行為。

1.2 教師應以正當用途使用本程式，並確保在使用過程中不對學生造成任何不當影響或傷害。

2. 正當用途
2.1 本軟體僅提供師生進行正當的教學與學習活動。使用者不得利用本程式侵犯他人的隱私或破壞刻成的規定。

2.2 禁止使用本程式進行任何形式的欺詐、詐騙或違法活動。

3. 資料保護
3.1 本程式的密碼和其他個人資訊將僅儲存在本地設備上，並不會上傳至任何雲端位置。使用者需自行負責保護其電腦安全，避免資料外洩。

3.2 若使用者的電腦遭受駭客攻擊或其他安全事件，導致資料外洩，本公司對於因此造成的損失不承擔任何責任。

4. 禁止行為
4.1 嚴禁利用本程式達成以下行為：

4.1.1 違反任何適用的法律或法規。
4.1.2 製造虛假身份以誤導他人。
4.1.3 使用、下載或以其他方式複製或向個人或實體提供（無論是否收費）服務使用者的任何目錄或其他使用者或使用資訊或其任何部分。
4.2 如發現任何違規行為，本公司保留隨時終止使用者帳戶的權利，並依法追究相關法律責任。

5. 責任限制
5.1 本公司不對因使用本程式而產生的直接、間接、附帶、特別或懲罰性損害負責，包括但不限於利潤損失、數據損失或其他無法預見的損失。

5.2 本公司不保證本程式的功能、可用性或可靠性，並不對因技術故障或其他原因導致的服務中斷負責。

6. 條款修改
6.1 本公司保留隨時修改本使用者條款的權利，並將於修改後在本網站上公告。使用者在條款修改後繼續使用本程式即表示接受修改後的條款。

7. 法律適用
7.1 本條款受[國家/地區]法律的管轄。如本條款的任何部分被視為無效或不可執行，該部分將被視為可分割的，不影響其餘條款的有效性和可執行性。

8. 聯絡資訊
8.1 如對本使用者條款有任何疑問或需要進一步資訊，請聯絡我們的客服部門：[沒有聯絡資訊]。
""";

class SpecialThanks extends StatefulWidget {
  const SpecialThanks({super.key});

  @override
  State<SpecialThanks> createState() => SpecialThanksState();
}

class SpecialThanksState extends State<SpecialThanks> {
  String? version;

  Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<void> _checkUpdate() async {
    try {
      await Updater.needUpdate();
    } catch (_) {}
    setState(() {});
  }

  List<String> getInfo() {
    return [version??"載入中...", "Stable", kDebugMode ? 'Debug' : 'Release'];
  }
  
  @override
  void initState() {
    super.initState();
    
    getAppVersion()
      .then((e) => version = e)
      .then((e) {if (mounted) setState(() {});});

    _checkUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("關於程式"),
        const SizedBox(height: 5),
        ThanksCard(
          title: Updater.available.value ? "有可用的新版本" : "您處於最新版本",
          lore: "最新版本: ${Updater.latest??'尚未檢查'}",
          image: Container(
            decoration: BoxDecoration(
              color: Updater.available.value ? Colors.yellow.darkest : Colors.green.lighter,
              borderRadius: BorderRadius.circular(30)
            ),
            child: Icon(Updater.available.value ? FluentIcons.upload : FluentIcons.check_mark)
          ),
          content: HyperlinkButton(
            onPressed: () async {
              final uri = Uri.parse("https://github.com/YFHD-osu/NTUT-Program-Assignment/releases/latest");
              await launchUrl(uri);
            },
            child: const Text("Download"))
        ),
        const SizedBox(height: 5),
        ThanksCard(
          title: "NTUT Program Assignment",
          lore: getInfo().join(" | "),
          image: Image.asset(r"assets/icon@x500.png"),
          content: HyperlinkButton(
            onPressed: () async {
              final uri = Uri.parse("https://github.com/YFHD-osu/NTUT-Program-Assignment");
              await launchUrl(uri);
            },
            child: const Text("Source Code"))
        ),
        const SizedBox(height: 5),
        ThanksCard(
          title: "使用者條約",
          lore: "規範用戶使用軟體的法律文件",
          image: const Icon(FluentIcons.business_rule),
          content: FilledButton(
            onPressed: () async {
              await showDialog<String>(
                context: context,
                builder: (context) => ContentDialog(
                  constraints: const BoxConstraints(
                    maxWidth: 450, maxHeight: 800
                  ),
                  title: const Text("使用者條約"),
                  content: const SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(termOfUse)
                    )
                  ),
                  actions: [
                    Button(
                      child: const Text("同意"),
                      onPressed: () => Navigator.of(context).pop()
                    )
                  ],
                )
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 1),
              child: Text("檢視")
            ),
          )
        ),
        const SizedBox(height: 20),
        Text(locale.settings_about_developer,),
        const SizedBox(height: 5),
        ThanksCard(
          title: locale.settings_about_YFHD_name,
          lore: locale.settings_about_YFHD_desc,
          image: Image.asset(r"assets/acknowledge/yfhd.png"),
          content: HyperlinkButton(
            onPressed: () async {
              final uri = Uri.parse("https://github.com/YFHD-osu/");
              await launchUrl(uri);
            },
            child: const Text("Github")
          )
        ),
        const SizedBox(height: 10),
        const Text("特別銘謝"),
        const SizedBox(height: 5),
        ThanksCard(
          title: "PurpleSheep",
          lore: "打屁聊天，輕鬆愉快中深入分析程式碼。 a.k.a 愛上火車、蒼之彼空四重奏、千戀萬花、拔作島宿舍高級玩家!",
          image: Image.asset(r"assets/acknowledge/purple_sheep.jpg"),
        ),
        const SizedBox(height: 10),
        ThanksCard(
          title: "小牛",
          lore: "不過~ OOHHHHH, 回憶中的瞬間全都錄下來, 珍藏在心中, 永不會遺忘。",
          image: Image.asset(r"assets/acknowledge/small_cow.png")
        ),
        const SizedBox(height: 10),
        ThanksCard(
          title: "Ray 大帥哥",
          lore: "「提供人頭戶」指的是非法提供銀行帳戶給他人使用，通常用於掩蓋不法交易。",
          image: Image.asset(r"assets/acknowledge/ray.png")
        ),
        const SizedBox(height: 10),
        ThanksCard(
          title: "Winter's wife",
          lore: "現在開始播放音樂，讓你的心情隨之律動，享受這一刻的愉快旋律。",
          image: Image.asset(r"assets/acknowledge/xuan.png")
        ),
        const SizedBox(height: 10),
        ThanksCard(
          title: "奶牛",
          lore: "線上賭場讓人沉迷，各種遊戲隨時可以體驗，刺激與風險並存，享受不一樣的娛樂方式。",
          image: Image.asset(r"assets/acknowledge/milk_cow.png")
        ),
        const SizedBox(height: 10),
        ThanksCard(
          title: "登冠卻樓",
          lore: "惦記，被退選的同學啊。",
          image: Image.asset(r"assets/acknowledge/dgcl.png")
        ),
        const SizedBox(height: 10),
        ThanksCard(
          title: "428",
          lore: "我不會打程式，郭忠義我恨你。",
          image: Image.asset(r"assets/acknowledge/428.png")
        )
      ]
    );
  }
}

class ThanksCard extends StatelessWidget {
  final String title, lore;
  final Widget? image, content;

  const ThanksCard({
    super.key,
    required this.title,
    required this.lore,
    this.image,
    this.content
  });

  @override
  Widget build(BuildContext context) {
    return Tile.lore(
      title: title,
      lore: lore,
      icon: SizedBox.square(
        dimension: 35,
        child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
          child: image?? Container(
            decoration: BoxDecoration(
              color: Colors.blue.lightest,
              borderRadius: BorderRadius.circular(40)
            ),
            child: const Icon(FluentIcons.accounts)
          )
        )
      ),
      child: content
    );
  }
}