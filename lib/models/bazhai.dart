// 八宅盘模型：命卦 + 宅卦 + 游年八星 + 宅命匹配 + 房间选位。
//
// 字段与后端 BazhaiResponse 一一对应。所有吉凶判定都来自后端确定性引擎，
// 客户端不做任何推导，也不内置结果快照——与玄空诊断、八字排盘同一口径。

/// 八宅所用的出生信息（含立春分界结果）
class BazhaiBirth {
  const BazhaiBirth({
    required this.year,
    this.month = 0,
    this.day = 0,
    this.gender = '男',
    this.name = '',
    this.solarYear = 0,
    this.lichunAdjusted = false,
    this.summary = '',
  });

  factory BazhaiBirth.fromJson(Map<String, dynamic> j) => BazhaiBirth(
        year: (j['year'] as num?)?.toInt() ?? 0,
        month: (j['month'] as num?)?.toInt() ?? 0,
        day: (j['day'] as num?)?.toInt() ?? 0,
        gender: j['gender']?.toString() ?? '男',
        name: j['name']?.toString() ?? '',
        solarYear: (j['solar_year'] as num?)?.toInt() ?? 0,
        lichunAdjusted: j['lichun_adjusted'] == true,
        summary: j['summary']?.toString() ?? '',
      );

  final int year;
  final int month;
  final int day;
  final String gender;
  final String name;

  /// 命卦归属年份：立春前出生为上一年
  final int solarYear;

  /// 是否因立春而回退到上一年
  final bool lichunAdjusted;

  /// 卡片副标题，如「1990 年生 · 男 · 东四命」
  final String summary;
}

/// 卦信息：命卦与宅卦共用（宅卦多出坐向明细字段）
class BazhaiGua {
  const BazhaiGua({
    this.trigram = '',
    this.name = '',
    this.luoshu = 0,
    this.direction = '',
    this.group = '',
    this.groupKey = '',
    this.label = '',
    this.description = '',
    this.mountain = '',
    this.facing = '',
    this.title = '',
    this.readable = '',
    this.facingTrigram = '',
    this.facingDirection = '',
    this.degree,
    this.summary = '',
    this.note = '',
    this.number = 0,
    this.solarYear = 0,
    this.lichunAdjusted = false,
  });

  factory BazhaiGua.fromJson(Map<String, dynamic> j) => BazhaiGua(
        trigram: j['trigram']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        luoshu: (j['luoshu'] as num?)?.toInt() ?? 0,
        direction: j['direction']?.toString() ?? '',
        group: j['group']?.toString() ?? '',
        groupKey: j['group_key']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        mountain: j['mountain']?.toString() ?? '',
        facing: j['facing']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        readable: j['readable']?.toString() ?? '',
        facingTrigram: j['facing_trigram']?.toString() ?? '',
        facingDirection: j['facing_direction']?.toString() ?? '',
        degree: (j['degree'] as num?)?.toDouble(),
        summary: j['summary']?.toString() ?? '',
        note: j['note']?.toString() ?? '',
        number: (j['number'] as num?)?.toInt() ?? 0,
        solarYear: (j['solar_year'] as num?)?.toInt() ?? 0,
        lichunAdjusted: j['lichun_adjusted'] == true,
      );

  /// 八卦名：乾坎艮震巽离坤兑
  final String trigram;

  /// 如「坎命」「坎宅」
  final String name;

  /// 洛书数 1-9
  final int luoshu;

  /// 卦位方位，如「正北」
  final String direction;

  /// 东四命 / 西四命 / 东四宅 / 西四宅
  final String group;

  /// 东四 / 西四
  final String groupKey;

  /// 展示用组合文案，如「坎命 · 东四命」
  final String label;

  /// 坐向吉凶评语（仅宅卦）
  final String description;

  // 以下坐向明细仅宅卦且给了罗盘度数时才有值
  final String mountain;
  final String facing;
  final String title;
  final String readable;
  final String facingTrigram;
  final String facingDirection;
  final double? degree;

  /// 命卦专属：命卦说明
  final String summary;
  final String note;
  final int number;
  final int solarYear;
  final bool lichunAdjusted;

  /// 是否已知具体坐向（未测度数时只有卦名）
  bool get hasOrientation => title.isNotEmpty;
}

/// 游年八星之一
class BazhaiStar {
  const BazhaiStar({
    this.code = '',
    this.star = '',
    this.alias = '',
    this.element = '',
    this.level = '',
    this.trigram = '',
    this.direction = '',
    this.luoshu = 0,
    this.meaning = '',
    this.suitable = const [],
    this.avoid = const [],
    this.isBase = false,
  });

  factory BazhaiStar.fromJson(Map<String, dynamic> j) => BazhaiStar(
        code: j['code']?.toString() ?? '',
        star: j['star']?.toString() ?? '',
        alias: j['alias']?.toString() ?? '',
        element: j['element']?.toString() ?? '',
        level: j['level']?.toString() ?? '',
        trigram: j['trigram']?.toString() ?? '',
        direction: j['direction']?.toString() ?? '',
        luoshu: (j['luoshu'] as num?)?.toInt() ?? 0,
        meaning: j['meaning']?.toString() ?? '',
        suitable: (j['suitable'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        avoid:
            (j['avoid'] as List? ?? const []).map((e) => e.toString()).toList(),
        isBase: j['is_base'] == true,
      );

  /// 生 / 天 / 延 / 伏 / 祸 / 六 / 五 / 绝
  final String code;

  /// 生气 / 天医 / 延年 / 伏位 / 祸害 / 六煞 / 五鬼 / 绝命
  final String star;

  /// 星曜别名，如「贪狼」
  final String alias;
  final String element;

  /// 旺 / 平 / 煞 / 大凶（与玄空九星同值域，前端配色可直接沿用）
  final String level;
  final String trigram;
  final String direction;
  final int luoshu;
  final String meaning;
  final List<String> suitable;
  final List<String> avoid;

  /// 是否伏位（本卦宫）
  final bool isBase;

  /// 吉星（生气 / 天医 / 延年 / 伏位）
  bool get isAuspicious => code == '生' || code == '天' || code == '延' || code == '伏';
}

/// 宅命匹配
class BazhaiCompat {
  const BazhaiCompat({
    this.matched = false,
    this.sameGua = false,
    this.level = '',
    this.score = 0,
    this.mingGroup = '',
    this.zhaiGroup = '',
    this.summary = '',
    this.advice = const [],
  });

  factory BazhaiCompat.fromJson(Map<String, dynamic> j) => BazhaiCompat(
        matched: j['matched'] == true,
        sameGua: j['same_gua'] == true,
        level: j['level']?.toString() ?? '',
        score: (j['score'] as num?)?.toInt() ?? 0,
        mingGroup: j['ming_group']?.toString() ?? '',
        zhaiGroup: j['zhai_group']?.toString() ?? '',
        summary: j['summary']?.toString() ?? '',
        advice:
            (j['advice'] as List? ?? const []).map((e) => e.toString()).toList(),
      );

  final bool matched;
  final bool sameGua;

  /// 同宫 / 相配 / 不配
  final String level;
  final int score;
  final String mingGroup;
  final String zhaiGroup;
  final String summary;
  final List<String> advice;
}

/// 某功能房间的选位建议
class BazhaiRoom {
  const BazhaiRoom({
    this.key = '',
    this.name = '',
    this.recommend = const [],
    this.avoid = const [],
    this.headline = '',
    this.note = '',
  });

  factory BazhaiRoom.fromJson(Map<String, dynamic> j) => BazhaiRoom(
        key: j['key']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        recommend: (j['recommend'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(BazhaiStar.fromJson)
            .toList(),
        avoid: (j['avoid'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(BazhaiStar.fromJson)
            .toList(),
        headline: j['headline']?.toString() ?? '',
        note: j['note']?.toString() ?? '',
      );

  final String key;
  final String name;

  /// 推荐方位，按优先级
  final List<BazhaiStar> recommend;

  /// 忌用方位
  final List<BazhaiStar> avoid;

  /// 首选方位文案，如「东南 · 生气」
  final String headline;
  final String note;
}

/// 本命吉方：床位、书桌、办公位的朝向依据
class BazhaiDirections {
  const BazhaiDirections({
    this.lucky = const [],
    this.unlucky = const [],
    this.summary = '',
    this.bed = '',
    this.desk = '',
  });

  factory BazhaiDirections.fromJson(Map<String, dynamic> j) => BazhaiDirections(
        lucky: (j['lucky'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(BazhaiStar.fromJson)
            .toList(),
        unlucky: (j['unlucky'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(BazhaiStar.fromJson)
            .toList(),
        summary: j['summary']?.toString() ?? '',
        bed: j['bed']?.toString() ?? '',
        desk: j['desk']?.toString() ?? '',
      );

  final List<BazhaiStar> lucky;
  final List<BazhaiStar> unlucky;
  final String summary;
  final String bed;
  final String desk;
}

/// 八宅盘总览
class BazhaiChart {
  const BazhaiChart({
    required this.birth,
    required this.mingGua,
    required this.zhaiGua,
    required this.compat,
    this.stars = const [],
    this.auspicious = const [],
    this.inauspicious = const [],
    this.mingStars = const [],
    required this.mingDirections,
    this.rooms = const [],
    this.keyPoints = const [],
    this.rulesVersion = '',
  });

  factory BazhaiChart.fromJson(Map<String, dynamic> j) {
    List<BazhaiStar> stars(String key) => (j[key] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BazhaiStar.fromJson)
        .toList();
    return BazhaiChart(
      birth: BazhaiBirth.fromJson(
          (j['birth'] as Map<String, dynamic>?) ?? const {}),
      mingGua:
          BazhaiGua.fromJson((j['ming_gua'] as Map<String, dynamic>?) ?? const {}),
      zhaiGua: BazhaiGua.fromJson(
          (j['zhai_gua'] as Map<String, dynamic>?) ?? const {}),
      compat: BazhaiCompat.fromJson(
          (j['compat'] as Map<String, dynamic>?) ?? const {}),
      stars: stars('stars'),
      auspicious: stars('auspicious'),
      inauspicious: stars('inauspicious'),
      mingStars: stars('ming_stars'),
      mingDirections: BazhaiDirections.fromJson(
          (j['ming_directions'] as Map<String, dynamic>?) ?? const {}),
      rooms: (j['rooms'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BazhaiRoom.fromJson)
          .toList(),
      keyPoints: (j['key_points'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      rulesVersion: j['rules_version']?.toString() ?? '',
    );
  }

  final BazhaiBirth birth;

  /// 命卦：由出生年与性别决定
  final BazhaiGua mingGua;

  /// 宅卦：由坐山卦决定
  final BazhaiGua zhaiGua;
  final BazhaiCompat compat;

  /// 宅卦游年八星，自乾起顺时针 8 项
  final List<BazhaiStar> stars;

  /// 四吉方，按吉次排序
  final List<BazhaiStar> auspicious;

  /// 四凶方，按凶重排序
  final List<BazhaiStar> inauspicious;

  /// 命卦游年八星（个人吉方）
  final List<BazhaiStar> mingStars;
  final BazhaiDirections mingDirections;
  final List<BazhaiRoom> rooms;
  final List<String> keyPoints;
  final String rulesVersion;
}
