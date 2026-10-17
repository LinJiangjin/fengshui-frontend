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
        // 性别/经度缺失时标记为未知，不要把缺失数据伪装成「男 / 东经120°」
        gender: (j['gender'] as String?)?.isNotEmpty == true
            ? j['gender'] as String
            : '未知',
        longitude: (j['longitude'] as num?)?.toDouble() ?? 0,
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

/// 一步大运（十年）
///
/// 后端字段名是 `from_age` / `to_age` 而不是 `from` / `to`——`from` 是
/// Python 关键字，做不了 pydantic 字段名，两端都用带后缀的那套。
class BaziDaYunStep {
  BaziDaYunStep({
    required this.index,
    required this.ganZhi,
    required this.gan,
    required this.zhi,
    required this.element,
    required this.shiShen,
    required this.naYin,
    required this.field,
    required this.fromAge,
    required this.toAge,
    required this.fromYear,
    required this.toYear,
    required this.isCurrent,
    required this.plain,
  });

  final int index; // 第几步，0 起
  final String ganZhi; // 甲申
  final String gan;
  final String zhi;
  final String element; // 大运天干五行
  final String shiShen; // 对日主的十神
  final String naYin;
  final String field; // 该十神对应的生活领域
  final int fromAge;
  final int toAge;
  final int fromYear;
  final int toYear;
  final bool isCurrent;
  final String plain; // 白话解释

  factory BaziDaYunStep.fromJson(Map<String, dynamic> j) => BaziDaYunStep(
        index: (j['index'] as num?)?.toInt() ?? 0,
        ganZhi: j['gan_zhi'] ?? '',
        gan: j['gan'] ?? '',
        zhi: j['zhi'] ?? '',
        element: j['element'] ?? '',
        shiShen: j['shi_shen'] ?? '',
        naYin: j['na_yin'] ?? '',
        field: j['field'] ?? '',
        fromAge: (j['from_age'] as num?)?.toInt() ?? 0,
        toAge: (j['to_age'] as num?)?.toInt() ?? 0,
        fromYear: (j['from_year'] as num?)?.toInt() ?? 0,
        toYear: (j['to_year'] as num?)?.toInt() ?? 0,
        isCurrent: j['is_current'] ?? false,
        plain: j['plain'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'index': index,
        'gan_zhi': ganZhi,
        'gan': gan,
        'zhi': zhi,
        'element': element,
        'shi_shen': shiShen,
        'na_yin': naYin,
        'field': field,
        'from_age': fromAge,
        'to_age': toAge,
        'from_year': fromYear,
        'to_year': toYear,
        'is_current': isCurrent,
        'plain': plain,
      };

  /// 卡片副标题：干支 + 十神 + 年龄段
  String get caption => '$ganZhi · $shiShen · $fromAge-$toAge 岁';

  /// 年份区间，如「2022-2031」
  String get yearRange => '$fromYear-$toYear';
}

/// 大运：起运岁数 + 八步运程
class BaziDaYun {
  BaziDaYun({
    required this.forward,
    required this.jieName,
    required this.jieAt,
    required this.gapDays,
    required this.startAge,
    required this.startMonths,
    required this.startDate,
    required this.startYear,
    required this.age,
    required this.basis,
    required this.plain,
    required this.steps,
    this.current,
  });

  final bool forward; // true 顺行（阳男阴女）
  final String jieName; // 起运所数的那个节
  final String jieAt;
  final int gapDays;
  final int startAge;
  final int startMonths;
  final String startDate;
  final int startYear;
  final int age; // 当前周岁
  final String basis; // 起运推算依据
  final String plain;
  final List<BaziDaYunStep> steps;

  /// 当前所走的一步；未入运时为 null
  final BaziDaYunStep? current;

  factory BaziDaYun.fromJson(Map<String, dynamic> j) => BaziDaYun(
        forward: j['forward'] ?? true,
        jieName: j['jie_name'] ?? '',
        jieAt: j['jie_at'] ?? '',
        gapDays: (j['gap_days'] as num?)?.toInt() ?? 0,
        startAge: (j['start_age'] as num?)?.toInt() ?? 0,
        startMonths: (j['start_months'] as num?)?.toInt() ?? 0,
        startDate: j['start_date'] ?? '',
        startYear: (j['start_year'] as num?)?.toInt() ?? 0,
        age: (j['age'] as num?)?.toInt() ?? 0,
        basis: j['basis'] ?? '',
        plain: j['plain'] ?? '',
        steps: (j['steps'] as List? ?? [])
            .map((e) => BaziDaYunStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        current: j['current'] is Map
            ? BaziDaYunStep.fromJson(j['current'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'forward': forward,
        'jie_name': jieName,
        'jie_at': jieAt,
        'gap_days': gapDays,
        'start_age': startAge,
        'start_months': startMonths,
        'start_date': startDate,
        'start_year': startYear,
        'age': age,
        'basis': basis,
        'plain': plain,
        'steps': steps.map((e) => e.toJson()).toList(),
        'current': current?.toJson(),
      };

  /// 起运说明，如「3 岁 4 个月起运」
  String get startText =>
      startMonths > 0 ? '$startAge 岁 $startMonths 个月起运' : '$startAge 岁起运';
}

/// 流年地支与命局某一支的关系
class BaziYearRelation {
  BaziYearRelation({
    required this.kind,
    required this.palace,
    required this.branch,
    required this.plain,
  });

  final String kind; // 冲 / 刑 / 害 / 合
  final String palace; // 命局中被牵动的那一柱
  final String branch;
  final String plain;

  factory BaziYearRelation.fromJson(Map<String, dynamic> j) => BaziYearRelation(
        kind: j['kind'] ?? '',
        palace: j['palace'] ?? '',
        branch: j['branch'] ?? '',
        plain: j['plain'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'palace': palace,
        'branch': branch,
        'plain': plain,
      };

  /// 如「日柱（未）相合」
  String get label => '$palace（$branch）相$kind';
}

/// 一年流年
class BaziYear {
  BaziYear({
    required this.year,
    required this.ganZhi,
    required this.age,
    required this.shiShen,
    required this.shiShenPlain,
    required this.isDaYunSwitch,
    required this.relations,
    required this.tianKeDiChong,
    required this.favorableHit,
    required this.unfavorableHit,
    required this.focus,
    required this.stance,
    required this.plain,
    required this.points,
    this.daYun,
  });

  final int year;
  final String ganZhi;
  final int age;
  final String shiShen;
  final String shiShenPlain;
  final bool isDaYunSwitch;
  final List<BaziYearRelation> relations;
  final bool tianKeDiChong;
  final bool favorableHit;
  final bool unfavorableHit;
  final String focus;
  final String stance; // 宜主动 / 宜守成 / 稳中求进
  final String plain;
  final List<String> points;

  /// 当年所属大运的摘要；未入运时为 null
  final Map<String, dynamic>? daYun;

  factory BaziYear.fromJson(Map<String, dynamic> j) => BaziYear(
        year: (j['year'] as num?)?.toInt() ?? 0,
        ganZhi: j['gan_zhi'] ?? '',
        age: (j['age'] as num?)?.toInt() ?? 0,
        shiShen: j['shi_shen'] ?? '',
        shiShenPlain: j['shi_shen_plain'] ?? '',
        isDaYunSwitch: j['is_da_yun_switch'] ?? false,
        relations: (j['relations'] as List? ?? [])
            .map((e) => BaziYearRelation.fromJson(e as Map<String, dynamic>))
            .toList(),
        tianKeDiChong: j['tian_ke_di_chong'] ?? false,
        favorableHit: j['favorable_hit'] ?? false,
        unfavorableHit: j['unfavorable_hit'] ?? false,
        focus: j['focus'] ?? '',
        stance: j['stance'] ?? '',
        plain: j['plain'] ?? '',
        points: (j['points'] as List? ?? []).map((e) => e.toString()).toList(),
        daYun: j['da_yun'] is Map
            ? Map<String, dynamic>.from(j['da_yun'] as Map)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'year': year,
        'gan_zhi': ganZhi,
        'age': age,
        'shi_shen': shiShen,
        'shi_shen_plain': shiShenPlain,
        'is_da_yun_switch': isDaYunSwitch,
        'relations': relations.map((e) => e.toJson()).toList(),
        'tian_ke_di_chong': tianKeDiChong,
        'favorable_hit': favorableHit,
        'unfavorable_hit': unfavorableHit,
        'focus': focus,
        'stance': stance,
        'plain': plain,
        'points': points,
        'da_yun': daYun,
      };

  /// 所属大运的显示名，如「第 4 步 癸巳」；未入运时为空
  String get daYunText {
    final d = daYun;
    if (d == null) return '未入运';
    return '第 ${(d['index'] as int? ?? 0) + 1} 步 ${d['gan_zhi']}';
  }
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
    this.daYun,
    this.years = const [],
  });

  final BaziBirth birth;
  final BaziDayMaster dayMaster;
  final List<BaziPillar> pillars;
  final List<BaziElementItem> elements;
  final String elementSummary; // 日主丙火 · 木旺缺金
  final BaziStrength strength;
  final List<BaziGod> favorable;
  final List<BaziGod> unfavorable;

  /// 大运（起运岁数 + 八步运程）；老版本后端不下发时为 null
  final BaziDaYun? daYun;

  /// 逐年流年（默认 12 年）
  final List<BaziYear> years;

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
        daYun: j['da_yun'] is Map
            ? BaziDaYun.fromJson(j['da_yun'] as Map<String, dynamic>)
            : null,
        years: (j['years'] as List? ?? [])
            .map((e) => BaziYear.fromJson(e as Map<String, dynamic>))
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
        'da_yun': daYun?.toJson(),
        'years': years.map((e) => e.toJson()).toList(),
      };

  /// 八字四柱合写，如「戊辰 乙卯 丙寅 壬辰」
  String get pillarText => pillars.map((p) => p.pillar).join(' ');

  /// 用神喜忌副标题：按日主强弱给出对应的取用原则，
  /// 不再对所有命局都写同一句「抑强扶弱」。
  String get fortuneSubtitle {
    switch (strength.level) {
      case '偏强':
        return '身偏强 · 宜泄宜克';
      case '偏弱':
        return '身偏弱 · 宜生宜帮';
      case '中和':
        return '身中和 · 调候通关';
      default:
        return '依日主强弱定调候';
    }
  }
}
