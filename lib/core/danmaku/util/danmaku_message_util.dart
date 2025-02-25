import 'dart:collection';

import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/plugins/extension/string_extension.dart';

/// 弹幕信息转义
final class DanmakuMessageUtil {
  static String handleMessage(String? txt) {
    if (txt.isNullOrEmpty) {
      return "";
    }
    var tmpText = txt ?? "";
    var regExp = RegExp(r"\[([^\]]+)\]");
    var replaceText = tmpText.replaceAllMapped(regExp, (match) {
      var allTxt = match.group(0) ?? "";
      var txt = match.group(1);
      var emojiText = emojiMap[txt];
      if (emojiText.isNullOrEmpty) {
        CoreLog.d("un match: $txt");
        return allTxt;
      }
      return emojiText ?? allTxt;
    });
    return replaceText;
  }

  static HashMap<String, String> get emojiMap {
    var map = HashMap<String, String>();
    map["赞"] = "👍️";
    map["比心"] = "💕";
    map["爱心"] = "❤";
    map["心"] = "❤";
    map["鼓掌"] = "👏";
    map["太阳"] = "☀️";
    map["龇牙"] = "😬";
    map["呲牙"] = "😬";
    map["捂脸"] = "🫢";
    map["感谢"] = "🫂";
    map["看"] = "👁️";
    map["玫瑰"] = "🌹";

    map["胜利"] = "✌️";
    map["互粉"] = "🩷";
    map["流泪"] = "😭";
    map["拳头"] = "✊";

    map["加一"] = "👍";
    map["互粉"] = "🩷";

    map["一起加油"] = "💪";
    map["加油"] = "💪";
    map["疑问"] = "❓";

    map["难过"] = "😞";
    map["求求了"] = "🙏";
    map["打call"] = "🤙";
    map["666"] = "🤙";

    map["福"] = "㊗";

    map["亲亲"] = "😘";
    map["kiss"] = "😘";
    map["kisskiss"] = "😘";
    map["灵机一动"] = "💡";

    map["庆祝"] = "🎉";
    map["發"] = "🤑";
    map["发"] = "🤑";
    map["飞吻"] = "😘";
    map["大笑"] = "😄";
    map["微笑"] = "😊";
    map["无语"] = "😑";
    map["翻白眼"] = "🙄";
    map["投降"] = "🙌";

    map["来看我"] = "👁️";
    map["呆无辜"] = "😦";
    map["开心"] = "😄";
    map["好开心"] = "😄";
    map["愉快"] = "😄";

    map["抱抱你"] = "🫂";

    map["白眼"] = "🙄";
    map["翻白眼"] = "🙄";
    map["纸飞机"] = "✈";
    map["啤酒"] = "🍺";
    map["恐惧"] = "😨";
    map["弱"] = "🫥";
    map["耶"] = "✌";
    map["悠闲"] = "🕶";
    map["色"] = "😍";
    map["动动脑子"] = "🧠";
    map["candy"] = "🍬";
    map["扎心"] = "💔";
    map["得意"] = "😏";
    map["送心"] = "💞";
    map["OK"] = "👌";
    map["憨笑"] = "憨笑";
    map["握爪"] = "🤝";
    map["摸头"] = "🫳🏾";
    map["给跪了"] = "🧎‍♂️";
    map["给跪了"] = "🙎";
    map["不失礼貌的微笑"] = "😊";
    map["咖啡"] = "☕";
    map["不看"] = "🙈";
    map["惊恐"] = "😲";
    map["我想静静"] = "🤫";
    map["咒骂"] = "🤬";
    map["表面呲牙"] = "😬";
    map["躺平"] = "🛌";
    map["年兽兔"] = "🐇";
    map["打脸"] = "🤦";
    map["小黄鸭"] = "🦆";
    map["糖葫芦"] = "🍭"; //？
    map["凝视"] = "👁";
    map["舔屏"] = "👅";
    map["不看"] = "🙈";
    map["吐血"] = "🤮";
    map["亚运鼓掌"] = "👏";
    map["小鼓掌"] = "👏";
    map["思考"] = "🤔";
    map["凋谢"] = "🥀";
    map["烟花"] = "🎇";
    map["惊讶"] = "😮";
    map["大哭"] = "😭";
    map["哭"] = "😭";
    map["哭泣"] = "😭";
    map["坏笑"] = "😆";
    map["害羞"] = "😳";
    map["听歌"] = "🎶";
    map["再见"] = "👋";
    map["衰"] = "😥";
    map["撒花"] = "🎊";
    map["屎"] = "💩";
    map["握手"] = "🤝";
    map["吐彩虹"] = "🌈";
    map["吃瓜群众"] = "🍉";
    map["尬笑"] = "😂";
    map["干杯"] = "🍻";
    map["擦汗"] = "😰";
    map["礼物"] = "🎁";
    map["发怒"] = "😡";
    map["灯笼"] = "🏮";
    map["求抱抱"] = "🤗";
    map["笑哭"] = "🤣";
    map["巧克力"] = "🍫";
    map["抓狂"] = "🤪";
    map["气球"] = "🎈";
    map["二哈"] = "🐕";
    map["闭嘴"] = "🤐";
    map["敢怒不敢言"] = "🫢";
    map["给力"] = "🤙";
    map["iloveyou"] = "❤";

    // map["抠鼻"] = "👍";
    // map["抠鼻"] = "👍";
    return map;
  }
}
