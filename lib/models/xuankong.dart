// 玄空飞星进阶模型：月盘（月星叠流年星）与宅运盘（运星 / 山星 / 向星三盘叠加）。
//
// 字段与后端 XuankongMonth / XuankongHouse 一一对应。
// 全部数值——入中星、顺逆、到山到向、格局判定、逐宫旺衰——都由服务端确定性
// 引擎算出（引擎已与《四十八局旺山旺向》等主流资料整表对拍），
// **客户端不做任何飞星推算，也不内置吉凶快照**。
//
// 月盘的最旺宫 / 最凶宫复用玄空侧的 [Extreme]：与流年盘、日家紫白是同一份数据，
// 没必要再为月盘造一套。

import 'diagnosis.dart' show Extreme;

/// 月星与流年星同宫的复合结论。
class XuankongStack {
  const XuankongStack({this.key = '', this.level = '', this.note = ''});

  factory XuankongStack.fromJson(Map<String, dynamic> j) => XuankongStack(
        key: j['key']?.toString() ?? '',
        level: j['level']?.toString() ?? '',
        note: j['note']?.toString() ?? '',
      );

  /// 叠吉 / 小吉 / 参半 / 叠凶 / 重凶 / 五黄同宫 / 双五黄
  final String key;

  /// 旺 / 平 / 煞 / 大凶，驱动四档配色
  final String level;
  final String note;
}

/// 玄空月盘的一宫。
class XuankongMonthPalace {
  const XuankongMonthPalace({
    this.luoshu = 0,
    this.trigram = '',
    this.direction = '',
    this.star = 0,
    this.starName = '',
    this.element = '',
    this.level = '',
    this.label = '',
    this.note = '',
    this.isCenter = false,
    this.yearStar = 0,
    this.yearStarName = '',
    this.yearStarLevel = '',
    this.stacked = false,
    this.stack = const XuankongStack(),
  });

  factory XuankongMonthPalace.fromJson(Map<String, dynamic> j) =>
      XuankongMonthPalace(
        luoshu: _int(j['luoshu']),
        trigram: j['trigram']?.toString() ?? '',
        direction: j['direction']?.toString() ?? '',
        star: _int(j['star']),
        starName: j['star_name']?.toString() ?? '',
        element: j['element']?.toString() ?? '',
        level: j['level']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        note: j['note']?.toString() ?? '',
        isCenter: j['is_center'] == true,
        yearStar: _int(j['year_star']),
        yearStarName: j['year_star_name']?.toString() ?? '',
        yearStarLevel: j['year_star_level']?.toString() ?? '',
        stacked: j['stacked'] == true,
        stack: XuankongStack.fromJson(
          (j['stack'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      );

  final int luoshu;
  final String trigram;
  final String direction;

  /// 月星飞临本宫之数
  final int star;
  final String starName;
  final String element;
  final String level;
  final String label;
  final String note;
  final bool isCenter;

  /// 同宫流年星
  final int yearStar;
  final String yearStarName;
  final String yearStarLevel;

  /// 月星与流年星同数同宫（两盘皆顺飞，故要求入中之数相同）
  final bool stacked;
  final XuankongStack stack;
}

/// 玄空月盘：按节气月起飞星，并与流年盘叠看。
class XuankongMonth {
  const XuankongMonth({
    this.date = '',
    this.year = 0,
    this.branch = '',
    this.monthIndex = 0,
    this.monthName = '',
    this.jieqi = '',
    this.jieqiMnemonic = '',
    this.centerStar = 0,
    this.centerStarName = '',
    this.yearCenterStar = 0,
    this.yearCenterStarName = '',
    this.palaces = const [],
    this.best,
    this.worst,
    this.keyPoints = const [],
    this.rulesVersion = '',
  });

  factory XuankongMonth.fromJson(Map<String, dynamic> j) => XuankongMonth(
        date: j['date']?.toString() ?? '',
        year: _int(j['year']),
        branch: j['branch']?.toString() ?? '',
        monthIndex: _int(j['month_index']),
        monthName: j['month_name']?.toString() ?? '',
        jieqi: j['jieqi']?.toString() ?? '',
        jieqiMnemonic: j['jieqi_mnemonic']?.toString() ?? '',
        centerStar: _int(j['center_star']),
        centerStarName: j['center_star_name']?.toString() ?? '',
        yearCenterStar: _int(j['year_center_star']),
        yearCenterStarName: j['year_center_star_name']?.toString() ?? '',
        palaces: _list(j['palaces'], XuankongMonthPalace.fromJson),
        best: _extreme(j['best']),
        worst: _extreme(j['worst']),
        keyPoints: _strings(j['key_points']),
        rulesVersion: j['rules_version']?.toString() ?? '',
      );

  final String date;
  final int year;

  /// 立春分界后的年支
  final String branch;

  /// 节气月序，1 起（正月）
  final int monthIndex;
  final String monthName;

  /// 本月的「节」，如「寒露」
  final String jieqi;
  final String jieqiMnemonic;
  final int centerStar;
  final String centerStarName;
  final int yearCenterStar;
  final String yearCenterStarName;
  final List<XuankongMonthPalace> palaces;
  final Extreme? best;
  final Extreme? worst;
  final List<String> keyPoints;
  final String rulesVersion;
}

/// 某星在当运下的旺衰（玄空论吉凶看的是与当运的关系）。
class XuankongStarState {
  const XuankongStarState({
    this.state = '',
    this.level = '',
    this.note = '',
    this.delta = 0,
    this.isWang = false,
  });

  factory XuankongStarState.fromJson(Map<String, dynamic> j) =>
      XuankongStarState(
        state: j['state']?.toString() ?? '',
        level: j['level']?.toString() ?? '',
        note: j['note']?.toString() ?? '',
        delta: _int(j['delta']),
        isWang: j['is_wang'] == true,
      );

  /// 旺 / 生 / 退 / 死 / 煞
  final String state;
  final String level;
  final String note;

  /// 该星距当运星的偏移
  final int delta;

  /// 是否为当运旺星
  final bool isWang;
}

/// 宅运盘的一宫：山星 / 运星 / 向星三盘叠加。
class XuankongHousePalace {
  const XuankongHousePalace({
    this.luoshu = 0,
    this.trigram = '',
    this.direction = '',
    this.isCenter = false,
    this.shanStar = 0,
    this.shanStarName = '',
    this.yunStar = 0,
    this.yunStarName = '',
    this.xiangStar = 0,
    this.xiangStarName = '',
    this.shanState = const XuankongStarState(),
    this.xiangState = const XuankongStarState(),
    this.yunState = const XuankongStarState(),
    this.level = '',
    this.role = '',
    this.hasLostWuhuang = false,
    this.isSit = false,
    this.isFace = false,
  });

  factory XuankongHousePalace.fromJson(Map<String, dynamic> j) =>
      XuankongHousePalace(
        luoshu: _int(j['luoshu']),
        trigram: j['trigram']?.toString() ?? '',
        direction: j['direction']?.toString() ?? '',
        isCenter: j['is_center'] == true,
        shanStar: _int(j['shan_star']),
        shanStarName: j['shan_star_name']?.toString() ?? '',
        yunStar: _int(j['yun_star']),
        yunStarName: j['yun_star_name']?.toString() ?? '',
        xiangStar: _int(j['xiang_star']),
        xiangStarName: j['xiang_star_name']?.toString() ?? '',
        shanState: _state(j['shan_state']),
        xiangState: _state(j['xiang_state']),
        yunState: _state(j['yun_state']),
        level: j['level']?.toString() ?? '',
        role: j['role']?.toString() ?? '',
        hasLostWuhuang: j['has_lost_wuhuang'] == true,
        isSit: j['is_sit'] == true,
        isFace: j['is_face'] == true,
      );

  final int luoshu;
  final String trigram;
  final String direction;
  final bool isCenter;

  /// 山星，管人丁健康
  final int shanStar;
  final String shanStarName;

  /// 运星，主该宫时运
  final int yunStar;
  final String yunStarName;

  /// 向星，管财禄事业
  final int xiangStar;
  final String xiangStarName;

  final XuankongStarState shanState;
  final XuankongStarState xiangState;
  final XuankongStarState yunState;

  /// 本宫综合吉凶，复用旺 / 平 / 煞 / 大凶值域
  final String level;

  /// 本宫宜作何用
  final String role;

  /// 本宫有失运五黄
  final bool hasLostWuhuang;
  final bool isSit;
  final bool isFace;
}

/// 坐山 / 向首。
class XuankongSide {
  const XuankongSide({
    this.mountain = '',
    this.trigram = '',
    this.direction = '',
    this.luoshu = 0,
    this.dragon = '',
    this.yinYang = '',
    this.degree,
    this.offset,
    this.label = '',
  });

  factory XuankongSide.fromJson(Map<String, dynamic> j) => XuankongSide(
        mountain: j['mountain']?.toString() ?? '',
        trigram: j['trigram']?.toString() ?? '',
        direction: j['direction']?.toString() ?? '',
        luoshu: _int(j['luoshu']),
        dragon: j['dragon']?.toString() ?? '',
        yinYang: j['yin_yang']?.toString() ?? '',
        degree: j['degree'] == null ? null : _num(j['degree']),
        offset: j['offset'] == null ? null : _num(j['offset']),
        label: j['label']?.toString() ?? '',
      );

  final String mountain;
  final String trigram;
  final String direction;
  final int luoshu;

  /// 三元龙：天元 / 地元 / 人元
  final String dragon;

  /// 阴 / 阳。注意判顺逆时用的**不是**本山的阴阳，而是「入中之数在元旦盘
  /// 对应宫里、与本节同一元龙的那一山」的阴阳（由后端算好并给出依据）。
  final String yinYang;

  final double? degree;

  /// 偏离该山中心线的角度，用于兼向提示
  final double? offset;
  final String label;
}

/// 三元九运。
class XuankongYun {
  const XuankongYun({
    this.number = 0,
    this.name = '',
    this.yuan = '',
    this.element = '',
    this.star = 0,
    this.starName = '',
    this.startYear = 0,
    this.endYear = 0,
    this.source = '',
    this.label = '',
    this.summary = '',
  });

  factory XuankongYun.fromJson(Map<String, dynamic> j) => XuankongYun(
        number: _int(j['number']),
        name: j['name']?.toString() ?? '',
        yuan: j['yuan']?.toString() ?? '',
        element: j['element']?.toString() ?? '',
        star: _int(j['star']),
        starName: j['star_name']?.toString() ?? '',
        startYear: _int(j['start_year']),
        endYear: _int(j['end_year']),
        source: j['source']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        summary: j['summary']?.toString() ?? '',
      );

  final int number;
  final String name;

  /// 上元 / 中元 / 下元
  final String yuan;
  final String element;

  /// 当运星，即旺星
  final int star;
  final String starName;
  final int startYear;
  final int endYear;

  /// year / build_year / explicit
  final String source;
  final String label;
  final String summary;

  /// 运的年份区间文案，如「2024 – 2043」
  String get yearRange => '$startYear – $endYear';
}

/// 中宫：山星、向星的入中之数与顺逆依据。
class XuankongCenter {
  const XuankongCenter({
    this.shanStar = 0,
    this.shanForward = false,
    this.xiangStar = 0,
    this.xiangForward = false,
    this.shanDirection = '',
    this.xiangDirection = '',
    this.shanBasis = '',
    this.xiangBasis = '',
  });

  factory XuankongCenter.fromJson(Map<String, dynamic> j) => XuankongCenter(
        shanStar: _int(j['shan_star']),
        shanForward: j['shan_forward'] == true,
        xiangStar: _int(j['xiang_star']),
        xiangForward: j['xiang_forward'] == true,
        shanDirection: j['shan_direction']?.toString() ?? '',
        xiangDirection: j['xiang_direction']?.toString() ?? '',
        shanBasis: j['shan_basis']?.toString() ?? '',
        xiangBasis: j['xiang_basis']?.toString() ?? '',
      );

  final int shanStar;
  final bool shanForward;
  final int xiangStar;
  final bool xiangForward;
  final String shanDirection;
  final String xiangDirection;

  /// 顺逆的判据说明，由后端下发，前端直接展示——这一步是玄空里最容易
  /// 记错的地方，把依据透出来用户才能追溯。
  final String shanBasis;
  final String xiangBasis;
}

/// 宅运格局。
class XuankongPattern {
  const XuankongPattern({
    this.key = '',
    this.name = '',
    this.level = '',
    this.summary = '',
    this.advice = '',
    this.toSit = false,
    this.toFace = false,
    this.shanAtSit = false,
    this.shanAtFace = false,
    this.xiangAtSit = false,
    this.xiangAtFace = false,
  });

  factory XuankongPattern.fromJson(Map<String, dynamic> j) => XuankongPattern(
        key: j['key']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        level: j['level']?.toString() ?? '',
        summary: j['summary']?.toString() ?? '',
        advice: j['advice']?.toString() ?? '',
        toSit: j['to_sit'] == true,
        toFace: j['to_face'] == true,
        shanAtSit: j['shan_at_sit'] == true,
        shanAtFace: j['shan_at_face'] == true,
        xiangAtSit: j['xiang_at_sit'] == true,
        xiangAtFace: j['xiang_at_face'] == true,
      );

  /// 旺山旺向 / 双星会向 / 双星会坐 / 上山下水 / 到山 / 到向 / 两不到
  final String key;
  final String name;
  final String level;
  final String summary;
  final String advice;

  /// 山盘旺星到坐山
  final bool toSit;

  /// 向盘旺星到向首
  final bool toFace;
  final bool shanAtSit;
  final bool shanAtFace;
  final bool xiangAtSit;
  final bool xiangAtFace;
}

/// 三盘的职责说明。
class XuankongRole {
  const XuankongRole({
    this.name = '',
    this.duty = '',
    this.good = '',
    this.bad = '',
  });

  factory XuankongRole.fromJson(Map<String, dynamic> j) => XuankongRole(
        name: j['name']?.toString() ?? '',
        duty: j['duty']?.toString() ?? '',
        good: j['good']?.toString() ?? '',
        bad: j['bad']?.toString() ?? '',
      );

  final String name;
  final String duty;
  final String good;
  final String bad;
}

/// 宅运盘：三盘叠加 + 格局判定 + 逐宫吉凶。
class XuankongHouse {
  const XuankongHouse({
    this.name = '',
    this.title = '',
    this.sit,
    this.face,
    this.yun,
    this.center,
    this.palaces = const [],
    this.pattern,
    this.score = 0,
    this.level = '',
    this.levelKey = '',
    this.jianxiang = false,
    this.roles = const {},
    this.keyPoints = const [],
    this.rulesVersion = '',
  });

  factory XuankongHouse.fromJson(Map<String, dynamic> j) => XuankongHouse(
        name: j['name']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        sit: XuankongSide.fromJson(
          (j['sit'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        face: XuankongSide.fromJson(
          (j['face'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        yun: XuankongYun.fromJson(
          (j['yun'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        center: XuankongCenter.fromJson(
          (j['center'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        palaces: _list(j['palaces'], XuankongHousePalace.fromJson),
        pattern: XuankongPattern.fromJson(
          (j['pattern'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        score: _int(j['score']),
        level: j['level']?.toString() ?? '',
        levelKey: j['level_key']?.toString() ?? '',
        jianxiang: j['jianxiang'] == true,
        roles: ((j['roles'] as Map?)?.cast<String, dynamic>() ?? const {})
            .map((k, v) => MapEntry(
                  k,
                  XuankongRole.fromJson((v as Map).cast<String, dynamic>()),
                )),
        keyPoints: _strings(j['key_points']),
        rulesVersion: j['rules_version']?.toString() ?? '',
      );

  final String name;
  final String title;
  final XuankongSide? sit;
  final XuankongSide? face;
  final XuankongYun? yun;
  final XuankongCenter? center;
  final List<XuankongHousePalace> palaces;
  final XuankongPattern? pattern;
  final int score;
  final String level;
  final String levelKey;

  /// 坐向偏离该山中心较多，已属兼向。本盘按正针下卦起星，替卦须另定。
  final bool jianxiang;
  final Map<String, XuankongRole> roles;
  final List<String> keyPoints;
  final String rulesVersion;

  /// 坐向合写，如「子山午向」
  String get sitFaceTitle =>
      (sit == null || face == null) ? '' : '${sit!.mountain}山${face!.mountain}向';
}

// ---------------------------------------------------------------- 解析小工具
int _int(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double _num(Object? v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

XuankongStarState _state(Object? v) => XuankongStarState.fromJson(
      (v as Map?)?.cast<String, dynamic>() ?? const {},
    );

Extreme? _extreme(Object? v) {
  if (v is! Map) return null;
  return Extreme.fromJson(v.cast<String, dynamic>());
}

List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) parse) =>
    (v as List? ?? const [])
        .whereType<Map>()
        .map((e) => parse(e.cast<String, dynamic>()))
        .toList();

List<String> _strings(Object? v) =>
    (v as List? ?? const []).map((e) => e.toString()).toList();
