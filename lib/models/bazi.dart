import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 地支藏干：本气 / 中气 / 余气
class BaziHiddenGan {
  BaziHiddenGan({
    required this.gan,
    required this.element,
    required this.role,
    required this.weight,
  });

  final String gan; // 戊
  final String element; // 土
  final String role; // 本气 / 中气 / 余气
  final double weight; // 计分权重 1.0 / 0.6 / 0.3

  factory BaziHiddenGan.fromJson(Map<String, dynamic> j) => BaziHiddenGan(
        gan: j['gan'] ?? '',
        element: j['element'] ?? '',
        role: j['role'] ?? '',
        weight: (j['weight'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'gan': gan,
        'element': element,
        'role': role,
        'weight': weight,
      };
}

/// 一柱：天干 + 地支 + 藏干 + 纳音 + 十神
class BaziPillar {
  BaziPillar({
    required this.key,
    required this.name,
    required this.gan,
    required this.zhi,
    required this.pillar,
    required this.ganElement,
    required this.zhiElement,
    required this.hidden,
    required this.hiddenText,
    required this.naYin,
    required this.ganShiShen,
  });

  final String key; // year / month / day / time
  final String name; // 年柱
  final String gan; // 戊
  final String zhi; // 辰
  final String pillar; // 戊辰
  final String ganElement; // 天干五行
  final String zhiElement; // 地支五行
  final List<BaziHiddenGan> hidden;
  final String hiddenText; // 戊乙癸
  final String naYin; // 大林木
  final String ganShiShen; // 食神

  factory BaziPillar.fromJson(Map<String, dynamic> j) => BaziPillar(
        key: j['key'] ?? '',
        name: j['name'] ?? '',
        gan: j['gan'] ?? '',
        zhi: j['zhi'] ?? '',
        pillar: j['pillar'] ?? '',
        ganElement: j['gan_element'] ?? '',
        zhiElement: j['zhi_element'] ?? '',
        hidden: (j['hidden'] as List? ?? [])
            .map((e) => BaziHiddenGan.fromJson(e as Map<String, dynamic>))
            .toList(),
        hiddenText: j['hidden_text'] ?? '',
        naYin: j['na_yin'] ?? '',
        ganShiShen: j['gan_shi_shen'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'gan': gan,
        'zhi': zhi,
        'pillar': pillar,
        'gan_element': ganElement,
        'zhi_element': zhiElement,
        'hidden': hidden.map((e) => e.toJson()).toList(),
        'hidden_text': hiddenText,
        'na_yin': naYin,
        'gan_shi_shen': ganShiShen,
      };

  /// 天干按五行着色
  Color get ganColor => AppColors.elementColor(ganElement);

  /// 地支按五行着色
  Color get zhiColor => AppColors.elementColor(zhiElement);
}

/// 五行占比条目
class BaziElementItem {
  BaziElementItem({
    required this.element,
    required this.percent,
    required this.score,
    required this.colorKey,
  });

  final String element; // 木
  final int percent; // 39
  final double score; // 加权原始分
  final String colorKey; // wood / fire / earth / metal / water

  factory BaziElementItem.fromJson(Map<String, dynamic> j) => BaziElementItem(
        element: j['element'] ?? '',
        percent: (j['percent'] as num?)?.round() ?? 0,
        score: (j['score'] as num?)?.toDouble() ?? 0,
        colorKey: j['color_key'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'element': element,
        'percent': percent,
        'score': score,
        'color_key': colorKey,
      };

  /// 进度条取色（五行色）
  Color get color => AppColors.elementColor(element);
}

/// 喜用神 / 忌神条目
class BaziGod {
  BaziGod({
    required this.element,
    required this.label,
    required this.reason,
    required this.percent,
    required this.colorKey,
  });

  final String element; // 金
  final String label; // 金 · 收敛
  final String reason; // 财星耗身
  final int percent;
  final String colorKey;

  factory BaziGod.fromJson(Map<String, dynamic> j) => BaziGod(
        element: j['element'] ?? '',
        label: j['label'] ?? '',
        reason: j['reason'] ?? '',
        percent: (j['percent'] as num?)?.round() ?? 0,
        colorKey: j['color_key'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'element': element,
        'label': label,
        'reason': reason,
        'percent': percent,
        'color_key': colorKey,
      };

  /// chip 底色
  Color get background => AppColors.elementSoftBg(element);

  /// chip 文字色
  Color get foreground => AppColors.elementDeep(element);
}

/// 出生信息（含真太阳时校正结果）
class BaziBirth {
  BaziBirth({
    required this.name,
    required this.gender,
    required this.longitude,
    required this.solar,
    required this.trueSolar,
    required this.offsetMinutes,
    required this.hourZhi,
    required this.isNightZi,
    required this.solarTermRange,
    required this.summary,
  });

  final String name;
  final String gender; // 男 / 女
  final double longitude;
  final String solar; // 钟表时间
  final String trueSolar; // 真太阳时
  final double offsetMinutes;
  final String hourZhi; // 辰
  final bool isNightZi; // 是否夜子时
  final String solarTermRange; // 惊蛰后 · 春分前
  final String summary; // 1988.03.12 辰时 · 男

  factory BaziBirth.fromJson(Map<String, dynamic> j) => BaziBirth(
        name: j['name'] ?? '',
        gender: j['gender'] ?? '男',
        longitude: (j['longitude'] as num?)?.toDouble() ?? 120,
        solar: j['solar'] ?? '',
        trueSolar: j['true_solar'] ?? '',
        offsetMinutes: (j['offset_minutes'] as num?)?.toDouble() ?? 0,
        hourZhi: j['hour_zhi'] ?? '',
        isNightZi: j['is_night_zi'] ?? false,
        solarTermRange: j['solar_term_range'] ?? '',
        summary: j['summary'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender,
        'longitude': longitude,
        'solar': solar,
        'true_solar': trueSolar,
        'offset_minutes': offsetMinutes,
        'hour_zhi': hourZhi,
        'is_night_zi': isNightZi,
        'solar_term_range': solarTermRange,
        'summary': summary,
      };
}

/// 日主
class BaziDayMaster {
  BaziDayMaster({
    required this.gan,
    required this.zhi,
    required this.element,
    required this.pillar,
  });

  final String gan; // 丙
  final String zhi; // 寅
  final String element; // 火
  final String pillar; // 丙寅

  factory BaziDayMaster.fromJson(Map<String, dynamic> j) => BaziDayMaster(
        gan: j['gan'] ?? '',
        zhi: j['zhi'] ?? '',
        element: j['element'] ?? '',
        pillar: j['pillar'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'gan': gan,
        'zhi': zhi,
        'element': element,
        'pillar': pillar,
      };
}

/// 日主强弱
class BaziStrength {
  BaziStrength({
    required this.level,
    required this.score,
    required this.detail,
  });

  final String level; // 偏强 / 中和 / 偏弱
  final double score;
  final Map<String, dynamic> detail; // 得令 / 得地 / 得势 明细

  factory BaziStrength.fromJson(Map<String, dynamic> j) => BaziStrength(
        level: j['level'] ?? '',
        score: (j['score'] as num?)?.toDouble() ?? 0,
        detail: Map<String, dynamic>.from(j['detail'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'level': level,
        'score': score,
        'detail': detail,
      };
}

/// 命理档案（与后端 /api/v1/bazi 的 data 字段一一对应）
class BaziProfile {
  BaziProfile({
    required this.birth,
    required this.dayMaster,
    required this.pillars,
    required this.elements,
    required this.elementSummary,
    required this.strength,
    required this.favorable,
    required this.unfavorable,
  });

  final BaziBirth birth;
  final BaziDayMaster dayMaster;
  final List<BaziPillar> pillars;
  final List<BaziElementItem> elements;
  final String elementSummary; // 日主丙火 · 木旺缺金
  final BaziStrength strength;
  final List<BaziGod> favorable;
  final List<BaziGod> unfavorable;

  factory BaziProfile.fromJson(Map<String, dynamic> j) => BaziProfile(
        birth: BaziBirth.fromJson(j['birth'] as Map<String, dynamic>? ?? {}),
        dayMaster:
            BaziDayMaster.fromJson(j['day_master'] as Map<String, dynamic>? ?? {}),
        pillars: (j['pillars'] as List? ?? [])
            .map((e) => BaziPillar.fromJson(e as Map<String, dynamic>))
            .toList(),
        elements: (j['elements'] as List? ?? [])
            .map((e) => BaziElementItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        elementSummary: j['element_summary'] ?? '',
        strength:
            BaziStrength.fromJson(j['strength'] as Map<String, dynamic>? ?? {}),
        favorable: (j['favorable'] as List? ?? [])
            .map((e) => BaziGod.fromJson(e as Map<String, dynamic>))
            .toList(),
        unfavorable: (j['unfavorable'] as List? ?? [])
            .map((e) => BaziGod.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'birth': birth.toJson(),
        'day_master': dayMaster.toJson(),
        'pillars': pillars.map((e) => e.toJson()).toList(),
        'elements': elements.map((e) => e.toJson()).toList(),
        'element_summary': elementSummary,
        'strength': strength.toJson(),
        'favorable': favorable.map((e) => e.toJson()).toList(),
        'unfavorable': unfavorable.map((e) => e.toJson()).toList(),
      };

  /// 八字四柱合写，如「戊辰 乙卯 丙寅 壬辰」
  String get pillarText => pillars.map((p) => p.pillar).join(' ');

  /// 用神喜忌副标题，如「身偏强 · 抑强扶弱」
  String get fortuneSubtitle =>
      strength.level.isEmpty ? '依日主强弱定调候' : '${strength.level} · 抑强扶弱';
}
