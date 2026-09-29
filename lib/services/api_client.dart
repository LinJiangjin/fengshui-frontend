import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/bazi.dart';
import '../models/diagnosis.dart';

/// 后端地址。
/// Android 模拟器请改 10.0.2.2，真机请填电脑局域网 IP。
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.3:8000',
);

/// 是否使用内置快照（不开后端也能预览界面；切 false 走真实接口）
const bool kUseMockData = false;

/// 设计稿同场景（358° / 磁偏角 -5.2° / 2026 丙午年）的真实计算结果快照，
/// 由后端规则引擎生成，非手写固定值。
const String kMockDiagnoseJson = '''
{
  "code": 0,
  "status": "ok",
  "data": {
    "score": 65,
    "orientation": {
      "degree": 352.8, "declination": -5.2, "mountain": "子", "facing": "午",
      "title": "子山午向", "trigram": "坎", "house_type": "坎宅",
      "readable": "坐北朝南",
      "description": "坐北朝南，负阴抱阳，为传统上佳之向。"
    },
    "palaces": [
      {"key":"中宫","trigram":"太极","direction":"中宫","star":1,"star_name":"一白","element":"水","level":"旺","label":"利文昌","note":"主文昌、桃花，宜设书房或水景。","is_center":true},
      {"key":"西北","trigram":"乾","direction":"西北","star":2,"star_name":"二黑","element":"土","level":"煞","label":"防病符","note":"病符星，忌作卧室与厨房，宜静不宜动。","is_center":false},
      {"key":"正西","trigram":"兑","direction":"正西","star":3,"star_name":"三碧","element":"木","level":"平","label":"防口舌","note":"主争执，宜用红色系泄其木气。","is_center":false},
      {"key":"东北","trigram":"艮","direction":"东北","star":4,"star_name":"四绿","element":"木","level":"旺","label":"利学业","note":"文昌位，宜设书桌、摆放绿植。","is_center":false},
      {"key":"正南","trigram":"离","direction":"正南","star":5,"star_name":"五黄","element":"土","level":"大凶","label":"大凶 · 宜静","note":"五黄大煞，忌动土安床，宜用铜器化煞。","is_center":false},
      {"key":"正北","trigram":"坎","direction":"正北","star":6,"star_name":"六白","element":"金","level":"旺","label":"利贵人","note":"主官贵，宜保持明亮整洁，可置金属摆件。","is_center":false},
      {"key":"西南","trigram":"坤","direction":"西南","star":7,"star_name":"七赤","element":"金","level":"煞","label":"防破财","note":"主破财盗贼，忌放贵重物品，宜用水泄之。","is_center":false},
      {"key":"正东","trigram":"震","direction":"正东","star":8,"star_name":"八白","element":"土","level":"旺","label":"旺财位","note":"当旺财星，宜保持明亮，可置水晶、聚宝盆。","is_center":false},
      {"key":"东南","trigram":"巽","direction":"东南","star":9,"star_name":"九紫","element":"火","level":"旺","label":"喜庆位","note":"主喜庆姻缘，宜用暖光与红色点缀。","is_center":false}
    ],
    "extremes": {
      "best": {"title":"正东 · 旺财位","direction":"正东","star_name":"八白","level":"旺","note":"当旺财星，宜保持明亮，可置水晶、聚宝盆。"},
      "worst": {"title":"正南 · 五黄","direction":"正南","star_name":"五黄","level":"大凶","note":"五黄大煞，忌动土安床，宜用铜器化煞。"}
    },
    "metrics": [
      {"name":"藏风聚气","grade":"优","desc":"背有实墙，气流回旋"},
      {"name":"采光纳阳","grade":"大凶","desc":"向方受制，宜增镜面与暖光"},
      {"name":"动线生旺","grade":"弱","desc":"直冲气散，宜设玄关缓冲区"}
    ],
    "advice": [
      {"type":"warn","title":"正南见五黄，忌动土","desc":"建议该方位减少活动与修造；五黄大煞，忌动土安床，宜用铜器化煞。"},
      {"type":"good","title":"正东为旺财位，宜重点利用","desc":"当旺财星，宜保持明亮，可置水晶、聚宝盆。"},
      {"type":"info","title":"子山午向 · 坎宅","desc":"坐北朝南，负阴抱阳，为传统上佳之向。"}
    ],
    "year": 2026,
    "house_name": "朗诗国际 3室2厅",
    "area": 96.0,
    "daily": {
      "date": "2026-09-29",
      "day_pillar": "丙午",
      "solar_term_range": "秋分后 · 寒露前",
      "escape": "阴遁",
      "escape_desc": "夏至后逆行",
      "boundary": "2026-06-21",
      "yuan": "上元",
      "center_star": 3,
      "center_star_name": "三碧",
      "palaces": [
        {"trigram":"太极","direction":"中宫","star":3,"star_name":"三碧","element":"木","level":"平","label":"防口舌","note":"主争执，宜用红色系泄其木气。","is_center":true},
        {"trigram":"乾","direction":"西北","star":4,"star_name":"四绿","element":"木","level":"旺","label":"利学业","note":"文昌位，宜设书桌、摆放绿植。","is_center":false},
        {"trigram":"兑","direction":"正西","star":5,"star_name":"五黄","element":"土","level":"大凶","label":"大凶 · 宜静","note":"五黄大煞，忌动土安床，宜用铜器化煞。","is_center":false},
        {"trigram":"艮","direction":"东北","star":6,"star_name":"六白","element":"金","level":"旺","label":"利贵人","note":"主官贵，宜保持明亮整洁，可置金属摆件。","is_center":false},
        {"trigram":"离","direction":"正南","star":7,"star_name":"七赤","element":"金","level":"煞","label":"防破财","note":"主破财盗贼，忌放贵重物品，宜用水泄之。","is_center":false},
        {"trigram":"坎","direction":"正北","star":8,"star_name":"八白","element":"土","level":"旺","label":"旺财位","note":"当旺财星，宜保持明亮，可置水晶、聚宝盆。","is_center":false},
        {"trigram":"坤","direction":"西南","star":9,"star_name":"九紫","element":"火","level":"旺","label":"喜庆位","note":"主喜庆姻缘，宜用暖光与红色点缀。","is_center":false},
        {"trigram":"震","direction":"正东","star":1,"star_name":"一白","element":"水","level":"旺","label":"利文昌","note":"主文昌、桃花，宜设书房或水景。","is_center":false},
        {"trigram":"巽","direction":"东南","star":2,"star_name":"二黑","element":"土","level":"煞","label":"防病符","note":"病符星，忌作卧室与厨房，宜静不宜动。","is_center":false}
      ],
      "best": {"title":"正北 · 旺财位","direction":"正北","star_name":"八白","level":"旺","note":"当旺财星，宜保持明亮，可置水晶、聚宝盆。"},
      "worst": {"title":"正西 · 五黄","direction":"正西","star_name":"五黄","level":"大凶","note":"五黄大煞，忌动土安床，宜用铜器化煞。"}
    }
  }
}
''';

/// 设计稿 S4 同场景（1988-03-12 08:00 辰时 · 男 · 东经 120°）的真实排盘快照，
/// 由后端 bazi 引擎生成，非手写固定值。
const String kMockBaziJson = '''
{
  "code": 0,
  "status": "ok",
  "data": {
    "birth": {
      "name": "", "gender": "男", "longitude": 120.0,
      "solar": "1988-03-12 08:00", "true_solar": "1988-03-12 08:00",
      "offset_minutes": 0.0, "hour_zhi": "辰", "is_night_zi": false,
      "solar_term_range": "惊蛰后 · 春分前",
      "summary": "1988.03.12 辰时 · 男"
    },
    "day_master": {"gan": "丙", "zhi": "寅", "element": "火", "pillar": "丙寅"},
    "pillars": [
      {"key":"year","name":"年柱","gan":"戊","zhi":"辰","pillar":"戊辰","gan_element":"土","zhi_element":"土","hidden":[{"gan":"戊","element":"土","role":"本气","weight":1.0},{"gan":"乙","element":"木","role":"中气","weight":0.6},{"gan":"癸","element":"水","role":"余气","weight":0.3}],"hidden_text":"戊乙癸","na_yin":"大林木","gan_shi_shen":"食神"},
      {"key":"month","name":"月柱","gan":"乙","zhi":"卯","pillar":"乙卯","gan_element":"木","zhi_element":"木","hidden":[{"gan":"乙","element":"木","role":"本气","weight":1.0}],"hidden_text":"乙","na_yin":"大溪水","gan_shi_shen":"正印"},
      {"key":"day","name":"日柱","gan":"丙","zhi":"寅","pillar":"丙寅","gan_element":"火","zhi_element":"木","hidden":[{"gan":"甲","element":"木","role":"本气","weight":1.0},{"gan":"丙","element":"火","role":"中气","weight":0.6},{"gan":"戊","element":"土","role":"余气","weight":0.3}],"hidden_text":"甲丙戊","na_yin":"炉中火","gan_shi_shen":"日主"},
      {"key":"time","name":"时柱","gan":"壬","zhi":"辰","pillar":"壬辰","gan_element":"水","zhi_element":"土","hidden":[{"gan":"戊","element":"土","role":"本气","weight":1.0},{"gan":"乙","element":"木","role":"中气","weight":0.6},{"gan":"癸","element":"水","role":"余气","weight":0.3}],"hidden_text":"戊乙癸","na_yin":"长流水","gan_shi_shen":"七杀"}
    ],
    "elements": [
      {"element":"木","percent":39,"score":4.2,"color_key":"wood"},
      {"element":"火","percent":15,"score":1.6,"color_key":"fire"},
      {"element":"土","percent":31,"score":3.3,"color_key":"earth"},
      {"element":"金","percent":0,"score":0.0,"color_key":"metal"},
      {"element":"水","percent":15,"score":1.6,"color_key":"water"}
    ],
    "element_summary": "日主丙火 · 木旺缺金",
    "strength": {
      "level": "偏强", "score": 4.3,
      "detail": {"得令":3.0,"得地":1.0,"得势":0.3,"月支本气":"乙(木·生我)","日支":"寅","根":"寅中气根","天干帮扶":"乙+0.8、壬-0.5"}
    },
    "favorable": [
      {"element":"金","label":"金 · 收敛","reason":"财星耗身","percent":0,"color_key":"metal"},
      {"element":"水","label":"水 · 智藏","reason":"官杀制身","percent":15,"color_key":"water"}
    ],
    "unfavorable": [
      {"element":"木","label":"木 · 生发","reason":"印绶生身","percent":39,"color_key":"wood"},
      {"element":"火","label":"火 · 温暖","reason":"比劫扶身","percent":15,"color_key":"fire"}
    ]
  }
}
''';

class ApiClient {
  ApiClient({this.baseUrl = kApiBaseUrl});

  final String baseUrl;

  Future<Diagnosis> diagnose({
    required double degree,
    double declination = 0.0,
    int year = 2026,
    String houseName = '我的房屋',
    double area = 96.0,
    DateTime? date,
  }) async {
    if (kUseMockData) return _mock();

    final d = date ?? DateTime.now();
    final uri = Uri.parse('$baseUrl/api/v1/diagnose');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'degree': degree,
            'declination': declination,
            'year': year,
            'house_name': houseName,
            'area': area,
            // 日家紫白按测算当日推算，今日吉位 / 今日忌方随日期变化
            'month': d.month,
            'day': d.day,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw Exception('诊断失败：HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['code'] != 0) {
      throw Exception('诊断失败：${body['status']}');
    }
    return Diagnosis.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 八字排盘：四柱、五行占比、日主强弱与用神喜忌
  /// 全部由后端确定性规则引擎算出，前端只负责渲染。
  Future<BaziProfile> fetchBazi({
    required int year,
    required int month,
    required int day,
    required int hour,
    int minute = 0,
    String gender = '男',
    double longitude = 120.0,
    String name = '',
  }) async {
    if (kUseMockData) return _mockBazi();

    final uri = Uri.parse('$baseUrl/api/v1/bazi');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'year': year,
            'month': month,
            'day': day,
            'hour': hour,
            'minute': minute,
            'gender': gender,
            'longitude': longitude,
            'name': name,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw Exception('排盘失败：HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['code'] != 0) {
      throw Exception('排盘失败：${body['status']}');
    }
    return BaziProfile.fromJson(body['data'] as Map<String, dynamic>);
  }

  BaziProfile _mockBazi() {
    final body = jsonDecode(kMockBaziJson) as Map<String, dynamic>;
    return BaziProfile.fromJson(body['data'] as Map<String, dynamic>);
  }

  Diagnosis _mock() {
    final body = jsonDecode(kMockDiagnoseJson) as Map<String, dynamic>;
    return Diagnosis.fromJson(body['data'] as Map<String, dynamic>);
  }
}
