/// 号码八星（数字能量）
///
/// ⚠ 数字能量属**近现代民间民俗说法**，没有术数典籍支撑，
/// 与玄空 / 八字 / 六爻不是同一级别的体系。因此：
/// * 星际只做「性格与倾向」的描述，不断具体事件；
/// * `natureNote` 是后端下发的性质声明，前端**必须原样展示，不能淡化**；
/// * 号码属个人信息，模型里只有 `masked`（脱敏），不保留原始号码。
library;

class PhoneEnergyItem {
  const PhoneEnergyItem({
    required this.pair,
    required this.level,
    required this.isTail,
    required this.score,
    required this.plain,
    this.star,
    this.kind = '',
  });

  factory PhoneEnergyItem.fromJson(Map<String, dynamic> j) => PhoneEnergyItem(
        pair: j['pair']?.toString() ?? '',
        star: j['star']?.toString(),
        level: j['level']?.toString() ?? '',
        kind: j['kind']?.toString() ?? '',
        isTail: j['is_tail'] == true,
        score: (j['score'] as num?)?.toInt() ?? 0,
        plain: j['plain']?.toString() ?? '',
      );

  final String pair; // 13
  final String? star; // 天医；含 0 / 5 时为 null
  final String level; // 旺 / 平 / 煞 / 大凶
  final String kind; // 吉 / 凶；含 0 / 5 时为空
  final bool isTail; // 是否末尾加重的一组
  final int score;
  final String plain;

  bool get isClassified => star != null;

  String get label => isClassified ? '$pair ${star!}' : '$pair（含 0 或 5）';

  String get scoreText => score > 0 ? '+$score' : '$score';
}

class PhoneEnergy {
  const PhoneEnergy({
    required this.kind,
    required this.masked,
    required this.length,
    required this.pairs,
    required this.items,
    required this.distribution,
    required this.dominant,
    required this.dominantPlain,
    required this.tailStars,
    required this.zeros,
    required this.fives,
    required this.good,
    required this.bad,
    required this.score,
    required this.level,
    required this.levelKey,
    required this.plain,
    required this.points,
    required this.advice,
    required this.natureNote,
    required this.rulesVersion,
  });

  factory PhoneEnergy.fromJson(Map<String, dynamic> j) => PhoneEnergy(
        kind: j['kind']?.toString() ?? '',
        masked: j['masked']?.toString() ?? '',
        length: (j['length'] as num?)?.toInt() ?? 0,
        pairs: (j['pairs'] as List? ?? []).map((e) => e.toString()).toList(),
        items: (j['items'] as List? ?? [])
            .map((e) => PhoneEnergyItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        distribution: Map<String, int>.from(
          (j['distribution'] as Map? ?? {}).map(
            (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
          ),
        ),
        dominant: j['dominant']?.toString(),
        dominantPlain: j['dominant_plain']?.toString() ?? '',
        tailStars:
            (j['tail_stars'] as List? ?? []).map((e) => e.toString()).toList(),
        zeros: (j['zeros'] as num?)?.toInt() ?? 0,
        fives: (j['fives'] as num?)?.toInt() ?? 0,
        good: (j['good'] as num?)?.toInt() ?? 0,
        bad: (j['bad'] as num?)?.toInt() ?? 0,
        score: (j['score'] as num?)?.toInt() ?? 0,
        level: j['level']?.toString() ?? '',
        levelKey: j['level_key']?.toString() ?? '',
        plain: j['plain']?.toString() ?? '',
        points: (j['points'] as List? ?? []).map((e) => e.toString()).toList(),
        advice: j['advice']?.toString() ?? '',
        natureNote: j['nature_note']?.toString() ?? '',
        rulesVersion: j['rules_version']?.toString() ?? '',
      );

  final String kind; // mobile / plate / address / general
  final String masked; // 138****5678
  final int length;
  final List<String> pairs;
  final List<PhoneEnergyItem> items;
  final Map<String, int> distribution;
  final String? dominant;
  final String dominantPlain;
  final List<String> tailStars;
  final int zeros;
  final int fives;
  final int good;
  final int bad;
  final int score;
  final String level;
  final String levelKey;
  final String plain;
  final List<String> points;
  final String advice;
  final String natureNote;
  final String rulesVersion;
}
