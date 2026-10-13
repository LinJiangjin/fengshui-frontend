/// 紫微斗数命盘 + 感情 / 职业 / 运势解读。
///
/// 全部内容由服务端确定性引擎算出（/api/v1/ziwei），客户端只做展示，
/// 不在这里做任何推断或兜底文案。
class ZiweiChart {
  const ZiweiChart({
    required this.headline,
    required this.basic,
    required this.palaces,
    required this.love,
    required this.career,
    required this.fortune,
    this.years = const [],
  });

  /// 一句话命格，如「巨门坐命，事业宫见天同」
  final String headline;

  final ZiweiBasic basic;
  final List<ZiweiPalace> palaces;

  /// 感情 · 夫妻宫
  final ZiweiSection love;

  /// 职业 · 官禄宫（内含财帛宫解读）
  final ZiweiSection career;

  /// 运势 · 命宫（内含当前大限）
  final ZiweiSection fortune;

  /// 逐年流年运势（自今年起 10 年）
  final List<ZiweiYear> years;

  factory ZiweiChart.fromJson(Map<String, dynamic> json) {
    final reading =
        json['reading'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return ZiweiChart(
      headline: reading['headline']?.toString() ?? '',
      basic: ZiweiBasic.fromJson(
        json['basic'] as Map<String, dynamic>? ?? const {},
      ),
      palaces: ((json['palaces'] as List?) ?? [])
          .map((e) => ZiweiPalace.fromJson(e as Map<String, dynamic>))
          .toList(),
      love: ZiweiSection.fromJson(
        reading['love'] as Map<String, dynamic>? ?? const {},
      ),
      career: ZiweiSection.fromJson(
        reading['career'] as Map<String, dynamic>? ?? const {},
      ),
      fortune: ZiweiSection.fromJson(
        reading['fortune'] as Map<String, dynamic>? ?? const {},
      ),
      years: ((json['years'] as List?) ?? [])
          .map((e) => ZiweiYear.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 命盘基本信息：命宫 / 身宫 / 五行局 / 紫微落宫
class ZiweiBasic {
  const ZiweiBasic({
    required this.mingZhi,
    required this.mingPillar,
    required this.shenZhi,
    required this.shenPalace,
    required this.ju,
    required this.ziweiZhi,
  });

  final String mingZhi;
  final String mingPillar;
  final String shenZhi;

  /// 身宫落在哪一宫，如「福德」
  final String shenPalace;

  /// 五行局，如「水二局」
  final String ju;

  /// 紫微星落哪个地支
  final String ziweiZhi;

  factory ZiweiBasic.fromJson(Map<String, dynamic> json) => ZiweiBasic(
        mingZhi: json['ming_zhi']?.toString() ?? '',
        mingPillar: json['ming_pillar']?.toString() ?? '',
        shenZhi: json['shen_zhi']?.toString() ?? '',
        shenPalace: json['shen_palace']?.toString() ?? '',
        ju: json['ju']?.toString() ?? '',
        ziweiZhi: json['ziwei_zhi']?.toString() ?? '',
      );

  /// 副标题一行：「命宫癸巳 · 身宫福德 · 水二局 · 紫微在寅」
  String get summary =>
      '命宫$mingPillar · 身宫$shenPalace · $ju · 紫微在$ziweiZhi';
}

/// 十二宫之一
class ZiweiPalace {
  const ZiweiPalace({
    required this.name,
    required this.zhi,
    required this.gan,
    required this.main,
    required this.aux,
    required this.siHua,
    required this.isMing,
    required this.isShen,
    required this.isEmpty,
    required this.daXianFrom,
    required this.daXianTo,
  });

  final String name;
  final String zhi;
  final String gan;

  /// 主星（可能两颗同宫，也可能为空 = 空宫）
  final List<String> main;
  final List<String> aux;

  /// 四化，已格式化为「巨门化禄」
  final List<String> siHua;

  final bool isMing;
  final bool isShen;
  final bool isEmpty;
  final int daXianFrom;
  final int daXianTo;

  factory ZiweiPalace.fromJson(Map<String, dynamic> json) => ZiweiPalace(
        name: json['name']?.toString() ?? '',
        zhi: json['zhi']?.toString() ?? '',
        gan: json['gan']?.toString() ?? '',
        main: _strings(json['main']),
        aux: _strings(json['aux']),
        siHua: ((json['si_hua'] as List?) ?? [])
            .map((e) {
              final m = e as Map<String, dynamic>;
              return '${m['star']}${m['hua']}';
            })
            .toList(),
        isMing: json['is_ming'] ?? false,
        isShen: json['is_shen'] ?? false,
        isEmpty: json['is_empty'] ?? false,
        daXianFrom: (json['da_xian']?['from'] as num?)?.toInt() ?? 0,
        daXianTo: (json['da_xian']?['to'] as num?)?.toInt() ?? 0,
      );

  /// 宫位星曜展示：无主星时给「空宫」
  String get starText => main.isEmpty ? '空宫' : main.join(' ');
}

/// 一段解读（感情 / 职业 / 运势中的一块）
class ZiweiSection {
  const ZiweiSection({
    required this.title,
    required this.palace,
    required this.zhi,
    required this.stars,
    required this.summary,
    required this.points,
    this.borrowed = false,
    this.wealth,
    this.daXian,
  });

  final String title;

  /// 对应宫位名，如「夫妻」
  final String palace;
  final String zhi;
  final List<String> stars;
  final String summary;
  final List<String> points;

  /// 该宫为空宫，解读借用了对宫主星
  final bool borrowed;

  /// 财帛宫解读（仅职业区块有）
  final ZiweiSection? wealth;

  /// 当前十年大限（仅运势区块有）
  final ZiweiDaXian? daXian;

  factory ZiweiSection.fromJson(Map<String, dynamic> json) => ZiweiSection(
        title: json['title']?.toString() ?? '',
        palace: json['palace']?.toString() ?? '',
        zhi: json['zhi']?.toString() ?? '',
        stars: _strings(json['stars']),
        summary: json['summary']?.toString() ?? '',
        points: _strings(json['points']),
        borrowed: json['borrowed'] ?? false,
        wealth: json['wealth'] is Map
            ? ZiweiSection.fromJson(json['wealth'] as Map<String, dynamic>)
            : null,
        daXian: json['da_xian'] is Map
            ? ZiweiDaXian.fromJson(json['da_xian'] as Map<String, dynamic>)
            : null,
      );

  /// 标题栏右侧的小字，如「夫妻 · 卯 · 太阴」
  String get caption {
    final star = stars.isEmpty ? (borrowed ? '空宫' : '') : stars.join(' ');
    return [palace, zhi, star].where((s) => s.isNotEmpty).join(' · ');
  }
}

/// 当前十年大限
class ZiweiDaXian {
  const ZiweiDaXian({
    required this.range,
    required this.palace,
    required this.zhi,
    required this.stars,
    required this.summary,
    required this.points,
  });

  /// 如「32-41 岁」
  final String range;
  final String palace;
  final String zhi;
  final List<String> stars;
  final String summary;
  final List<String> points;

  factory ZiweiDaXian.fromJson(Map<String, dynamic> json) => ZiweiDaXian(
        range: json['range']?.toString() ?? '',
        palace: json['palace']?.toString() ?? '',
        zhi: json['zhi']?.toString() ?? '',
        stars: _strings(json['stars']),
        summary: json['summary']?.toString() ?? '',
        points: _strings(json['points']),
      );

  String get caption => [range, palace, zhi, stars.join(' ')]
      .where((s) => s.isNotEmpty)
      .join(' · ');
}

/// 逐年流年运势：太岁宫 + 流年四化 + 宜动宜守的倾向性提示
class ZiweiYear {
  const ZiweiYear({
    required this.year,
    required this.ganZhi,
    required this.age,
    required this.daXianPalace,
    required this.daXianRange,
    required this.taiSuiPalace,
    required this.taiSuiZhi,
    required this.focus,
    required this.stance,
    required this.siHua,
    required this.points,
  });

  final int year;

  /// 干支，如「丙午」
  final String ganZhi;

  /// 该年周岁
  final int age;

  /// 当年所处的大限宫，如「子女」
  final String daXianPalace;

  /// 大限年龄段，如「32-41」
  final String daXianRange;

  /// 太岁所在宫（当年事务焦点）
  final String taiSuiPalace;
  final String taiSuiZhi;

  /// 重点领域，如「事业 · 财运」
  final String focus;

  /// 宜主动 / 宜守成 / 稳中求进
  final String stance;

  /// 流年四化，已格式化为「天同化禄入官禄」
  final List<String> siHua;

  final List<String> points;

  factory ZiweiYear.fromJson(Map<String, dynamic> json) {
    final dx = json['da_xian'] as Map<String, dynamic>? ?? const {};
    final tai = json['tai_sui'] as Map<String, dynamic>? ?? const {};
    return ZiweiYear(
      year: (json['year'] as num?)?.toInt() ?? 0,
      ganZhi: json['gan_zhi']?.toString() ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      daXianPalace: dx['palace']?.toString() ?? '',
      daXianRange: [
        (dx['from'] as num?)?.toInt(),
        (dx['to'] as num?)?.toInt(),
      ].whereType<int>().join('-'),
      taiSuiPalace: tai['palace']?.toString() ?? '',
      taiSuiZhi: tai['zhi']?.toString() ?? '',
      focus: json['focus']?.toString() ?? '',
      stance: json['stance']?.toString() ?? '',
      siHua: ((json['si_hua'] as List?) ?? []).map((e) {
        final m = e as Map<String, dynamic>;
        return '${m['star']}${m['hua']}入${m['palace']}';
      }).toList(),
      points: _strings(json['points']),
    );
  }

  /// 副标题一行：「35 岁 · 太岁父母 · 大限子女(32-41)」
  String get caption {
    final parts = <String>['$age 岁'];
    if (taiSuiPalace.isNotEmpty) parts.add('太岁$taiSuiPalace');
    if (daXianPalace.isNotEmpty) {
      parts.add(daXianRange.isEmpty
          ? '大限$daXianPalace'
          : '大限$daXianPalace($daXianRange)');
    }
    return parts.join(' · ');
  }
}

List<String> _strings(dynamic value) =>
    ((value as List?) ?? []).map((e) => e.toString()).toList();
