part of pica_settings;

class SetJmComicsOrderController extends StateController{
  int settingsOrder;
  SetJmComicsOrderController(this.settingsOrder);
  late String value = appdata.settings[settingsOrder];

  void set(String v){
    value = v;
    appdata.settings[settingsOrder] = v;
    appdata.writeData();
    App.globalBack();
  }
}


class JmSettings extends StatefulWidget {
  const JmSettings(this.popUp, {Key? key}) : super(key: key);
  final bool popUp;

  @override
  State<JmSettings> createState() => _JmSettingsState();
}

class _JmSettingsState extends State<JmSettings> {
  bool autoSelectStream = appdata.settings[15] == "1";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text("禁漫天堂".tl),
        ),
        ListTile(
          leading: const Icon(Icons.favorite_border),
          title: Text("收藏夹中漫画排序模式".tl),
          trailing: Select(
            initialValue: int.parse(appdata.settings[42]),
            values: [
              "最新收藏".tl, "最新更新".tl
            ],
            onChange: (i){
              appdata.settings[42] = i.toString();
              appdata.updateSettings();
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.track_changes),
          title: Text("自动选择域名".tl),
          subtitle: Text("登录时自动选择API域名".tl),
          trailing: Switch(
            value: autoSelectStream,
            onChanged: (b){
              b ? appdata.settings[15] = "1" : appdata.settings[15] = "0";
              setState(() {
                autoSelectStream = b;
              });
              appdata.updateSettings();
              JmNetwork().loginFromAppdata();
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.domain),
          title: Text("API域名".tl),
          trailing: Select(
            initialValue: int.parse(appdata.settings[17]),
            values: [
              "分流1".tl,"分流2".tl,"分流3".tl,"分流4".tl,
            ],
            onChange: (i){
              appdata.settings[17] = i.toString();
              appdata.updateSettings();
              JmNetwork().loginFromAppdata();
            },
          )
        ),
        ListTile(
          leading: const Icon(Icons.image),
          title: Text("图片分流".tl),
          trailing: Select(
            initialValue: int.parse(appdata.settings[37]),
            values: [
              "分流1".tl,"分流2".tl,"分流3".tl,"分流4".tl, "分流5".tl, "分流6".tl
            ],
            onChange: (i){
              appdata.settings[37] = i.toString();
              appdata.updateSettings();
            },
          ),
        ),
      ],
    );
  }

  void changeDomain(BuildContext context){
    var controller = TextEditingController();

    void onFinished() {
      var text = controller.text;
      if(!text.contains("https://")){
        text = "https://$text";
      }
      App.globalBack();
      if(!text.isURL){
        showToast(message: "Invalid URL");
      }else {
        appdata.settings[56] = text;
        appdata.updateSettings();
        setState(() {});
        JmNetwork().loginFromAppdata();
      }
    }

    showDialog(context: context, builder: (context){
      return SimpleDialog(
        title: const Text("Change Domain"),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            width: 400,
            child: TextField(
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("Domain")
              ),
              controller: controller,
              onEditingComplete: onFinished,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onFinished, child: Text("完成".tl)),
              const SizedBox(width: 16,),
            ],
          )
        ],
      );
    });
  }
}