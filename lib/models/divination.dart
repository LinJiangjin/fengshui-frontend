import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 六爻的一爻（自初爻到上爻）
///
/// 爻值约定由后端定义：6 老阴（阴·动）、7 少阳（阳·静）、
/// 8 少阴（阴·静）、9 老阳（阳·动）。装卦结果全部由服务端算好下发，
/// 客户端不做任何推导。
class DivinationLine {
  const DivinationLine({
    required this.index,
    required this.position,
    required this.value,
    required this.valueName,
    required this.isYang,
    required this.symbol,
    required this.isMoving,
    required this.part,
    required this.trigram,
    required this.gan,
    required this.zhi,
    required this.pillar,
    required this.element,
    required this.liuQin,
    required this.liuQinNote,
    required this.liuShen,
    required this.liuShenNote,
    required this.wangXiang,
    required this.wangXiangNote,
    required this.isShi,
    required this.isYing,
  });

  factory DivinationLine.fromJson(Map<String, dynamic> j) => DivinationLine(
        index: (j['index'] as num?)?.toInt() ?? 0,
        position: j['position']?.toString() ?? '',
        value: (j['value'] as num?)?.toInt() ?? 0,
        valueName: j['value_name']?.toString() ?? '',
        isYang: j['is_yang'] == true,
        symbol: j['symbol']?.toString() ?? '',
        isMoving: j['is_moving'] == true,
        part: j['part']?.toString() ?? '',
        trigram: j['trigram']?.toString() ?? '',
        gan: j['gan']?.toString() ?? '',
        zhi: j['zhi']?.toString() ?? '',
        pillar: j['pillar']?.toString() ?? '',
        element: j['element']?.toString() ?? '',
        liuQin: j['liu_qin']?.toString() ?? '',
        liuQinNote: j['liu_qin_note']?.toString() ?? '',
        liuShen: j['liu_shen']?.toString() ?? '',
        liuShenNote: j['liu_shen_note']?.toString() ?? '',
        wangXiang: j['wang_xiang']?.toString() ?? '',
        wangXiangNote: j['wang_xiang_note']?.toString() ?? '',
        isShi: j['is_shi'] == true,
        isYing: j['is_ying'] == true,
      );

  final int index;
  final String position; // 初爻 / 二爻 …
  final int value; // 6/7/8/9
  final String valueName; // 老阴 / 少阳 …
  final bool isYang;
  final String symbol; // ▅▅▅▅▅ / ▅▅ ▅▅
  final bool isMoving;
  final String part; // 内卦 / 外卦
  final String trigram;
  final String gan;
  final String zhi;
  final String pillar; // 丁巳
  final String element;
  final String liuQin; // 六亲：妻财 / 官鬼 …
  final String liuQinNote;
  final String liuShen; // 六神：青龙 / 白虎 …
  final String liuShenNote;
  final String wangXiang; // 旺 / 相 / 休 / 囚 / 死
  final String wangXiangNote;
  final bool isShi;
  final bool isYing;

  /// 这一爻的角色标记：世 / 应 / 动 / 空
  String get mark {
    if (isShi) return '世';
    if (isYing) return '应';
    if (isMoving) return '动';
    return '';
  }

  Color get elementColor => AppColors.elementColor(element);
}

/// 一个卦（本卦 / 变卦 / 主卦 / 互卦）
class DivinationHexagram {
  const DivinationHexagram({
    required this.name,
    required this.upper,
    required this.lower,
    required this.symbol,
    this.palace = '',
    this.element = '',
    this.order = '',
  });

  factory DivinationHexagram.fromJson(Map<String, dynamic> j) =>
      DivinationHexagram(
        name: j['name']?.toString() ?? '',
        upper: j['upper']?.toString() ?? '',
        lower: j['lower']?.toString() ?? '',
        symbol: j['symbol']?.toString() ?? '',
        palace: j['palace']?.toString() ?? '',
        element: j['element']?.toString() ?? '',
        order: j['order']?.toString() ?? '',
      );

  final String name;
  final String upper;
  final String lower;
  final String symbol;
  final String palace;
  final String element;
  final String order;

  String get subtitle {
    final head = palace.isEmpty ? '' : '$palace宫';
    return [head, element, order].where((s) => s.isNotEmpty).join(' · ');
  }

  @override
  String toString() => name;
}

/// 卦例（六爻或梅花，由 mode 区分）
class DivinationChart {
  const DivinationChart({
    required this.mode,
    required this.question,
    required this.topic,
    required this.when,
    required this.level,
    required this.stance,
    required this.plain,
    required this.points,
    required this.rulesVersion,
    this.day,
    this.ben,
    this.bian,
    this.lines = const [],
    this.moving = const [],
    this.shi,
    this.ying,
    this.yong,
    this.zhu,
    this.hu,
    this.source = '',
    this.basis = '',
    this.ti,
    this.yongGua,
    this.relation = '',
    this.verdict = '',
    this.movingIndex = 0,
    this.score = 0,
  });

  factory DivinationChart.fromJson(Map<String, dynamic> j) => DivinationChart(
        mode: j['mode']?.toString() ?? '',
        question: j['question']?.toString() ?? '',
        topic: j['topic']?.toString() ?? '',
        when: j['when']?.toString() ?? '',
        level: j['level']?.toString() ?? '',
        stance: j['stance']?.toString() ?? '',
        plain: j['plain']?.toString() ?? '',
        points: (j['points'] as List? ?? []).map((e) => e.toString()).toList(),
        rulesVersion: j['rules_version']?.toString() ?? '',
        day: j['day'] is Map ? Map<String, dynamic>.from(j['day'] as Map) : null,
        ben: j['ben'] is Map
            ? DivinationHexagram.fromJson(j['ben'] as Map<String, dynamic>)
            : null,
        bian: j['bian'] is Map
            ? DivinationHexagram.fromJson(j['bian'] as Map<String, dynamic>)
            : null,
        lines: (j['lines'] as List? ?? [])
            .map((e) => DivinationLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        moving: (j['moving'] as List? ?? []).map((e) => e.toString()).toList(),
        shi: j['shi'] is Map
            ? Map<String, dynamic>.from(j['shi'] as Map)
            : null,
        ying: j['ying'] is Map
            ? Map<String, dynamic>.from(j['ying'] as Map)
            : null,
        yong: j['yong'] is Map
            ? Map<String, dynamic>.from(j['yong'] as Map)
            : null,
        zhu: j['zhu'] is Map
            ? DivinationHexagram.fromJson(j['zhu'] as Map<String, dynamic>)
            : null,
        hu: j['hu'] is Map
            ? DivinationHexagram.fromJson(j['hu'] as Map<String, dynamic>)
            : null,
        source: j['source']?.toString() ?? '',
        basis: j['basis']?.toString() ?? '',
        ti: j['ti'] is Map ? Map<String, dynamic>.from(j['ti'] as Map) : null,
        yongGua:
            j['yong'] is Map ? Map<String, dynamic>.from(j['yong'] as Map) : null,
        relation: j['relation']?.toString() ?? '',
        verdict: j['verdict']?.toString() ?? '',
        movingIndex: (j['moving_index'] as num?)?.toInt() ?? 0,
        score: (j['score'] as num?)?.toInt() ?? 0,
      );

  final String mode; // liuyao / meihua
  final String question;
  final String topic;
  final String when;
  final String level;
  final String stance;
  final String plain;
  final List<String> points;
  final String rulesVersion;

  /// 六爻：日干支与月建
  final Map<String, dynamic>? day;
  final DivinationHexagram? ben;
  final DivinationHexagram? bian;
  final List<DivinationLine> lines;
  final List<String> moving;
  final Map<String, dynamic>? shi;
  final Map<String, dynamic>? ying;
  final Map<String, dynamic>? yong;

  /// 梅花：主卦 / 互卦 / 起卦依据 / 体用
  final DivinationHexagram? zhu;
  final DivinationHexagram? hu;
  final String source;
  final String basis;
  final Map<String, dynamic>? ti;
  final Map<String, dynamic>? yongGua;
  final String relation;
  final String verdict;
  final int movingIndex;
  final int score;

  bool get isLiuyao => mode == 'liuyao';

  /// 六爻的爻按「从上爻到初爻」显示（传统画法自上而下）
  List<DivinationLine> get linesTopDown =>
      lines.reversed.toList(growable: false);

  String get modeName => isLiuyao ? '六爻纳甲' : '梅花易数';
}

/// 问事类别（用神取哪一亲由它决定）
class DivinationTopic {
  const DivinationTopic(this.key, this.label);

  final String key;
  final String label;

  static const all = [
    DivinationTopic('决策', '决策'),
    DivinationTopic('财运', '财运'),
    DivinationTopic('事业', '事业'),
    DivinationTopic('感情', '感情'),
    DivinationTopic('健康', '健康'),
    DivinationTopic('出行', '出行'),
    DivinationTopic('失物', '失物'),
  ];
}
