import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 合婚的一方
class MarriageParty {
  const MarriageParty({
    this.year = 0,
    this.zodiac = '',
    this.branch = '',
    this.solarYear = 0,
    this.dayPillar = '',
    this.element = '',
    this.favorable = const [],
  });

  factory MarriageParty.fromJson(Map<String, dynamic> j) => MarriageParty(
        year: (j['year'] as num?)?.toInt() ?? 0,
        zodiac: j['zodiac']?.toString() ?? '',
        branch: j['branch']?.toString() ?? '',
        solarYear: (j['solar_year'] as num?)?.toInt() ?? 0,
        dayPillar: j['day_pillar']?.toString() ?? '',
        element: j['element']?.toString() ?? '',
        favorable:
            (j['favorable'] as List? ?? []).map((e) => e.toString()).toList(),
      );

  final int year;
  final String zodiac; // 马 / 羊
  final String branch; // 午 / 未
  final int solarYear; // 按立春校正后的农历年
  final String dayPillar; // 癸未（八字模式）
  final String element; // 日主五行（八字模式）
  final List<String> favorable; // 喜用五行（八字模式）

  /// 「马（午）」；八字模式再补日柱
  String get label {
    final head = zodiac.isEmpty ? branch : '$zodiac（$branch）';
    return dayPillar.isEmpty ? head : '$head · $dayPillar';
  }

  Color get elementColor => AppColors.elementColor(element);
}

/// 合婚的一个分项
class MarriageItem {
  const MarriageItem({
    required this.key,
    required this.label,
    required this.relation,
    required this.level,
    required this.score,
    required this.plain,
    required this.detail,
  });

  factory MarriageItem.fromJson(Map<String, dynamic> j) => MarriageItem(
        key: j['key']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        relation: j['relation']?.toString() ?? '',
        level: j['level']?.toString() ?? '',
        score: (j['score'] as num?)?.toInt() ?? 0,
        plain: j['plain']?.toString() ?? '',
        detail: j['detail']?.toString() ?? '',
      );

  final String key; // year / day_stem / day_branch / yong
  final String label; // 生肖（年支）
  final String relation; // 六合 / 六冲 / 天干五合 …
  final String level; // 旺 / 平 / 煞 / 大凶
  final int score; // 该项加减分，0 表示无加减
  final String plain;
  final String detail;

  /// 加减分文案，如「+16」/「-24」/「±0」
  String get scoreText =>
      score > 0 ? '+$score' : (score < 0 ? '$score' : '±0');

  bool get isGood => score > 0;
  bool get isBad => score < 0;
}

/// 合婚结果
class MarriageResult {
  const MarriageResult({
    required this.mode,
    required this.a,
    required this.b,
    required this.items,
    required this.score,
    required this.level,
    required this.levelKey,
    required this.plain,
    required this.points,
    required this.advice,
    required this.rulesVersion,
  });

  factory MarriageResult.fromJson(Map<String, dynamic> j) => MarriageResult(
        mode: j['mode']?.toString() ?? '',
        a: MarriageParty.fromJson(j['a'] as Map<String, dynamic>? ?? {}),
        b: MarriageParty.fromJson(j['b'] as Map<String, dynamic>? ?? {}),
        items: (j['items'] as List? ?? [])
            .map((e) => MarriageItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        score: (j['score'] as num?)?.toInt() ?? 0,
        level: j['level']?.toString() ?? '',
        levelKey: j['level_key']?.toString() ?? '',
        plain: j['plain']?.toString() ?? '',
        points: (j['points'] as List? ?? []).map((e) => e.toString()).toList(),
        advice: j['advice']?.toString() ?? '',
        rulesVersion: j['rules_version']?.toString() ?? '',
      );

  final String mode; // zodiac / bazi
  final MarriageParty a;
  final MarriageParty b;
  final List<MarriageItem> items;
  final int score;
  final String level; // 上吉 / 吉 / 平 / 欠佳 / 凶
  final String levelKey; // 旺 / 平 / 煞 / 大凶
  final String plain;
  final List<String> points;
  final String advice;
  final String rulesVersion;

  bool get isBazi => mode == 'bazi';

  String get modeName => isBazi ? '八字合婚' : '生肖合婚';

  /// 落在合上的分项
  List<MarriageItem> get goodItems =>
      items.where((i) => i.isGood).toList(growable: false);

  /// 落在冲克上的分项
  List<MarriageItem> get badItems =>
      items.where((i) => i.isBad).toList(growable: false);
}
