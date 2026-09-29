/// 诊断结果模型（与后端 /api/v1/diagnose 的 data 字段一一对应）
class Palace {
  Palace({
    required this.key,
    required this.trigram,
    required this.direction,
    required this.star,
    required this.starName,
    required this.element,
    required this.level,
    required this.label,
    required this.note,
    required this.isCenter,
  });

  final String key;       // 方位：东南 / 正南 ...
  final String trigram;   // 巽 / 离 ...
  final String direction;
  final int star;
  final String starName;  // 一白
  final String element;   // 水
  final String level;     // 旺 / 平 / 煞 / 大凶
  final String label;     // 利文昌
  final String note;
  final bool isCenter;

  factory Palace.fromJson(Map<String, dynamic> j) => Palace(
        key: j['key'] ?? '',
        trigram: j['trigram'] ?? '',
        direction: j['direction'] ?? '',
        star: j['star'] ?? 0,
        starName: j['star_name'] ?? '',
        element: j['element'] ?? '',
        level: j['level'] ?? '旺',
        label: j['label'] ?? '',
        note: j['note'] ?? '',
        isCenter: j['is_center'] ?? false,
      );

  /// 宫位标题，如「东南 · 巽」
  String get title => isCenter ? '中宫 · 太极' : '$direction · $trigram';

  /// 星曜标题，如「一白 水」
  String get starTitle => '$starName $element';
}

class OrientationInfo {
  OrientationInfo({
    required this.degree,
    required this.declination,
    required this.mountain,
    required this.facing,
    required this.title,
    required this.trigram,
    required this.houseType,
    required this.readable,
    required this.description,
  });

  final double degree;
  final double declination;
  final String mountain;
  final String facing;
  final String title;      // 子山午向
  final String trigram;    // 坎
  final String houseType;  // 坎宅
  final String readable;   // 坐北朝南
  final String description;

  factory OrientationInfo.fromJson(Map<String, dynamic> j) => OrientationInfo(
        degree: (j['degree'] as num?)?.toDouble() ?? 0,
        declination: (j['declination'] as num?)?.toDouble() ?? 0,
        mountain: j['mountain'] ?? '',
        facing: j['facing'] ?? '',
        title: j['title'] ?? '',
        trigram: j['trigram'] ?? '',
        houseType: j['house_type'] ?? '',
        readable: j['readable'] ?? '',
        description: j['description'] ?? '',
      );

  /// 卦位副标，如「子山午向 · 坎宅」
  String get subtitle => '$title · $houseType';
}

class Extreme {
  Extreme({
    required this.title,
    required this.direction,
    required this.starName,
    required this.level,
    required this.note,
  });

  final String title;      // 正东 · 旺财位
  final String direction;
  final String starName;
  final String level;
  final String note;

  factory Extreme.fromJson(Map<String, dynamic> j) => Extreme(
        title: j['title'] ?? '',
        direction: j['direction'] ?? '',
        starName: j['star_name'] ?? '',
        level: j['level'] ?? '',
        note: j['note'] ?? '',
      );
}

class Metric {
  Metric({required this.name, required this.grade, required this.desc});

  final String name;   // 藏风聚气
  final String grade;  // 优 / 良 / 弱
  final String desc;

  factory Metric.fromJson(Map<String, dynamic> j) => Metric(
        name: j['name'] ?? '',
        grade: j['grade'] ?? '',
        desc: j['desc'] ?? '',
      );

  String get value => '$name · $grade';
}

class Advice {
  Advice({required this.type, required this.title, required this.desc});

  final String type; // warn / good / info
  final String title;
  final String desc;

  factory Advice.fromJson(Map<String, dynamic> j) => Advice(
        type: j['type'] ?? 'info',
        title: j['title'] ?? '',
        desc: j['desc'] ?? '',
      );
}

/// 当日紫白盘（日家九宫飞星）：今日吉位 / 今日忌方随日期变化
class DailyChart {
  DailyChart({
    required this.date,
    required this.dayPillar,
    required this.solarTermRange,
    required this.escape,
    required this.escapeDesc,
    required this.boundary,
    required this.yuan,
    required this.centerStar,
    required this.centerStarName,
    required this.palaces,
    required this.best,
    required this.worst,
  });

  final String date;          // 2026-09-29
  final String dayPillar;     // 日柱：丙午
  final String solarTermRange;// 秋分后 · 寒露前
  final String escape;        // 阳遁 / 阴遁
  final String escapeDesc;    // 冬至后顺行 / 夏至后逆行
  final String boundary;      // 本段起算的交节日
  final String yuan;          // 上元 / 中元 / 下元
  final int centerStar;       // 入中星 1-9
  final String centerStarName;// 三碧
  final List<Palace> palaces;
  final Extreme best;
  final Extreme worst;

  factory DailyChart.fromJson(Map<String, dynamic> j) => DailyChart(
        date: j['date'] ?? '',
        dayPillar: j['day_pillar'] ?? '',
        solarTermRange: j['solar_term_range'] ?? '',
        escape: j['escape'] ?? '',
        escapeDesc: j['escape_desc'] ?? '',
        boundary: j['boundary'] ?? '',
        yuan: j['yuan'] ?? '',
        centerStar: j['center_star'] ?? 0,
        centerStarName: j['center_star_name'] ?? '',
        palaces: (j['palaces'] as List? ?? [])
            .map((e) => Palace.fromJson(e as Map<String, dynamic>))
            .toList(),
        best: Extreme.fromJson(j['best'] ?? {}),
        worst: Extreme.fromJson(j['worst'] ?? {}),
      );

  /// 例：三碧入中 · 丙午日
  String get summary => '$centerStarName入中 · $dayPillar日';

  /// 例：阴遁上元 · 夏至后逆行
  String get escapeSummary =>
      escapeDesc.isEmpty ? '$escape$yuan' : '$escape$yuan · $escapeDesc';
}

class Diagnosis {
  Diagnosis({
    required this.score,
    required this.orientation,
    required this.palaces,
    required this.best,
    required this.worst,
    required this.metrics,
    required this.advice,
    required this.year,
    required this.houseName,
    required this.area,
    this.daily,
  });

  final int score;
  final OrientationInfo orientation;
  final List<Palace> palaces;
  final Extreme best;
  final Extreme worst;
  final List<Metric> metrics;
  final List<Advice> advice;
  final int year;
  final String houseName;
  final double area;

  /// 当日紫白盘（后端按测算日期算出；为空时首页回退到流年盘）
  final DailyChart? daily;

  /// 今日吉位：优先取日盘，没有日盘时退回流年盘
  Extreme get todayBest => daily?.best ?? best;

  /// 今日忌方：优先取日盘，没有日盘时退回流年盘
  Extreme get todayWorst => daily?.worst ?? worst;

  factory Diagnosis.fromJson(Map<String, dynamic> j) {
    final ex = j['extremes'] as Map<String, dynamic>? ?? {};
    return Diagnosis(
      score: j['score'] ?? 0,
      orientation: OrientationInfo.fromJson(j['orientation'] ?? {}),
      palaces: (j['palaces'] as List? ?? [])
          .map((e) => Palace.fromJson(e as Map<String, dynamic>))
          .toList(),
      best: Extreme.fromJson(ex['best'] ?? {}),
      worst: Extreme.fromJson(ex['worst'] ?? {}),
      metrics: (j['metrics'] as List? ?? [])
          .map((e) => Metric.fromJson(e as Map<String, dynamic>))
          .toList(),
      advice: (j['advice'] as List? ?? [])
          .map((e) => Advice.fromJson(e as Map<String, dynamic>))
          .toList(),
      year: j['year'] ?? DateTime.now().year,
      houseName: j['house_name'] ?? '我的房屋',
      area: (j['area'] as num?)?.toDouble() ?? 0,
      daily: j['daily'] is Map<String, dynamic>
          ? DailyChart.fromJson(j['daily'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 九宫按设计稿顺序渲染：上南下北，左东右西
  static const displayOrder = [
    '东南',
    '正南',
    '西南',
    '正东',
    '中宫',
    '正西',
    '东北',
    '正北',
    '西北',
  ];

  List<Palace> get orderedPalaces {
    final map = {for (final p in palaces) p.direction: p};
    return displayOrder.map((k) => map[k]).whereType<Palace>().toList();
  }
}
