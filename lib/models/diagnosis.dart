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
        // 等级缺失时标记为未知，不要乐观地当成「旺」
        level: (j['level'] as String?)?.isNotEmpty == true
            ? j['level'] as String
            : '未知',
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
    this.sittingDirection = '',
    this.facingDirection = '',
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

  /// 后端给出的坐山 / 向方所在方位（可能为空，见同名 getter 的兜底推导）
  final String sittingDirection;
  final String facingDirection;

  /// 二十四山 -> 方位，用于后端未返回方位字段时兜底
  static const Map<String, String> _mountainDirection = {
    '壬': '正北', '子': '正北', '癸': '正北',
    '丑': '东北', '艮': '东北', '寅': '东北',
    '甲': '正东', '卯': '正东', '乙': '正东',
    '辰': '东南', '巽': '东南', '巳': '东南',
    '丙': '正南', '午': '正南', '丁': '正南',
    '未': '西南', '坤': '西南', '申': '西南',
    '庚': '正西', '酉': '正西', '辛': '正西',
    '戌': '西北', '乾': '西北', '亥': '西北',
  };

  /// 坐山方位，如「正北」
  String get sitting =>
      sittingDirection.isNotEmpty ? sittingDirection : _mountainDirection[mountain] ?? '';

  /// 向方方位，如「正南」
  String get facingDir =>
      facingDirection.isNotEmpty ? facingDirection : _mountainDirection[facing] ?? '';

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
        sittingDirection: j['direction'] ?? '',
        facingDirection: j['facing_direction'] ?? '',
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
    String? label,
    String? role,
  })  : label = label ?? '',
        role = role ?? '';

  final String title;      // 正东 · 旺财位
  final String direction;
  final String starName;
  final String level;
  final String note;
  final String label;
  /// 角色名由后端下发（财位 / 五黄煞 / 病符位 / 破财位 …），
  /// 前端不得自行把最佳一律叫「财位」、最凶一律叫「五黄」。
  final String role;

  /// 展示用的角色名：优先后端角色，其次 label，最后才是星名
  String get roleName =>
      role.isNotEmpty ? role : (label.isNotEmpty ? label : starName);

  factory Extreme.fromJson(Map<String, dynamic> j) => Extreme(
        title: j['title'] ?? '',
        direction: j['direction'] ?? '',
        starName: j['star_name'] ?? '',
        level: j['level'] ?? '',
        note: j['note'] ?? '',
        label: j['label'] ?? '',
        role: j['role'] ?? '',
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

/// 功能区布局建议表的一行（由后端按户型生成，前端不再自行推算）
class LayoutGuideRow {
  LayoutGuideRow({required this.type, required this.good, required this.bad});

  final String type; // 客厅 / 主卧 / 厨房 ...
  final String good; // 宜置方位
  final String bad;  // 忌置方位

  factory LayoutGuideRow.fromJson(Map<String, dynamic> j) => LayoutGuideRow(
        type: j['type'] ?? '',
        good: j['good'] ?? '',
        bad: j['bad'] ?? '',
      );
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
    bool? calendarExact,
  }) : calendarExact = calendarExact ?? true;

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

  /// 节气是否取自真实历法；false 表示用了近似交节日，交节当天可能差一天
  final bool calendarExact;

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
        calendarExact: j['calendar_exact'] ?? true,
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
    List<Advice>? tips,
    List<LayoutGuideRow>? layoutGuide,
    this.ruleVersion = '',
  })  : tips = tips ?? const [],
        layoutGuide = layoutGuide ?? const [];

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

  /// 后端下发的家具摆放建议（按坐向 + 当日吉凶动态生成）
  final List<Advice> tips;

  /// 后端按户型下发的功能区布局建议表
  final List<LayoutGuideRow> layoutGuide;

  /// 本次结果所采用的规则集版本
  final String ruleVersion;

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
      tips: (j['tips'] as List? ?? [])
          .map((e) => Advice.fromJson(e as Map<String, dynamic>))
          .toList(),
      layoutGuide: (j['layout_guide'] as List? ?? [])
          .map((e) => LayoutGuideRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      ruleVersion: j['rules_version'] ?? '',
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
