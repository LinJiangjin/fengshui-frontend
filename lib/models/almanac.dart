// 黄历模型：通书日课（建除 / 天神 / 宿曜 / 冲煞 / 宜忌 / 时辰）、择日候选、月历热力。
//
// 字段与后端 AlmanacDay / AlmanacSelectResponse / AlmanacCalendar 一一对应。
// 历法数据与吉凶打分全部来自服务端确定性引擎（底层是 lunar-python 的历法表），
// **客户端不做任何历法推算，也不内置宜忌快照**——与玄空诊断、八字、八宅同一口径。
//
// 当日紫白直接复用玄空侧的 [Extreme]「吉位 / 忌方」模型：两者是同一份数据，
// 没必要为黄历再造一套。

import 'diagnosis.dart' show Extreme;

/// 农历日期
class AlmanacLunar {
  const AlmanacLunar({
    this.text = '',
    this.year = '',
    this.month = '',
    this.day = '',
    this.isLeap = false,
  });

  factory AlmanacLunar.fromJson(Map<String, dynamic> j) => AlmanacLunar(
        text: j['text']?.toString() ?? '',
        year: j['year']?.toString() ?? '',
        month: j['month']?.toString() ?? '',
        day: j['day']?.toString() ?? '',
        isLeap: j['is_leap'] == true,
      );

  /// 完整农历串，如「二〇二六年九月初五」
  final String text;
  final String year;

  /// 含「月」字，如「九月」
  final String month;

  /// 如「初五」
  final String day;
  final bool isLeap;
}

/// 年月日干支与生肖
class AlmanacGanZhi {
  const AlmanacGanZhi({
    this.year = '',
    this.month = '',
    this.day = '',
    this.yearAnimal = '',
    this.monthAnimal = '',
    this.dayAnimal = '',
  });

  factory AlmanacGanZhi.fromJson(Map<String, dynamic> j) => AlmanacGanZhi(
        year: j['year']?.toString() ?? '',
        month: j['month']?.toString() ?? '',
        day: j['day']?.toString() ?? '',
        yearAnimal: j['year_animal']?.toString() ?? '',
        monthAnimal: j['month_animal']?.toString() ?? '',
        dayAnimal: j['day_animal']?.toString() ?? '',
      );

  final String year;
  final String month;
  final String day;
  final String yearAnimal;
  final String monthAnimal;
  final String dayAnimal;
}

/// 旬与旬空
class AlmanacXun {
  const AlmanacXun({this.name = '', this.kong = ''});

  factory AlmanacXun.fromJson(Map<String, dynamic> j) => AlmanacXun(
        name: j['name']?.toString() ?? '',
        kong: j['kong']?.toString() ?? '',
      );

  final String name;
  final String kong;
}

/// 建除十二神。[tone] 为吉凶档：大吉 / 黄道 / 黑道 / 大凶
class AlmanacJianChu {
  const AlmanacJianChu({
    this.name = '',
    this.label = '',
    this.tone = '',
    this.meaning = '',
    this.good = '',
    this.bad = '',
    this.motto = '',
  });

  factory AlmanacJianChu.fromJson(Map<String, dynamic> j) => AlmanacJianChu(
        name: j['name']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        tone: j['tone']?.toString() ?? '',
        meaning: j['meaning']?.toString() ?? '',
        good: j['good']?.toString() ?? '',
        bad: j['bad']?.toString() ?? '',
        motto: j['motto']?.toString() ?? '',
      );

  final String name;

  /// 如「闭日」
  final String label;
  final String tone;
  final String meaning;
  final String good;
  final String bad;

  /// 分档口诀，用于向用户解释依据
  final String motto;

  /// 吉档（大吉 / 黄道）
  bool get isFavorable => tone == '大吉' || tone == '黄道';
}

/// 日家十二天神（黄道六神 / 黑道六神）
class AlmanacTianShen {
  const AlmanacTianShen({
    this.name = '',
    this.type = '',
    this.luck = '',
    this.meaning = '',
  });

  factory AlmanacTianShen.fromJson(Map<String, dynamic> j) => AlmanacTianShen(
        name: j['name']?.toString() ?? '',
        type: j['type']?.toString() ?? '',
        luck: j['luck']?.toString() ?? '',
        meaning: j['meaning']?.toString() ?? '',
      );

  final String name;

  /// 黄道 / 黑道
  final String type;
  final String luck;
  final String meaning;

  bool get isLucky => type == '黄道';
}

/// 二十八宿
class AlmanacXiu {
  const AlmanacXiu({
    this.name = '',
    this.full = '',
    this.animal = '',
    this.mansion = '',
    this.luck = '',
  });

  factory AlmanacXiu.fromJson(Map<String, dynamic> j) => AlmanacXiu(
        name: j['name']?.toString() ?? '',
        full: j['full']?.toString() ?? '',
        animal: j['animal']?.toString() ?? '',
        mansion: j['mansion']?.toString() ?? '',
        luck: j['luck']?.toString() ?? '',
      );

  final String name;

  /// 全名，如「轸水蚓」
  final String full;
  final String animal;

  /// 所属四象，如「南方朱雀」
  final String mansion;
  final String luck;

  bool get isLucky => luck == '吉';
}

/// 冲煞
class AlmanacChong {
  const AlmanacChong({this.zodiac = '', this.desc = '', this.sha = ''});

  factory AlmanacChong.fromJson(Map<String, dynamic> j) => AlmanacChong(
        zodiac: j['zodiac']?.toString() ?? '',
        desc: j['desc']?.toString() ?? '',
        sha: j['sha']?.toString() ?? '',
      );

  final String zodiac;

  /// 如「(乙卯)兔」
  final String desc;

  /// 煞方，如「东」
  final String sha;

  /// 展示文案：优先「(乙卯)兔」，缺则退回生肖
  String get display => desc.isNotEmpty ? desc : zodiac;
}

/// 彭祖百忌
class AlmanacPengZu {
  const AlmanacPengZu({this.gan = '', this.zhi = ''});

  factory AlmanacPengZu.fromJson(Map<String, dynamic> j) => AlmanacPengZu(
        gan: j['gan']?.toString() ?? '',
        zhi: j['zhi']?.toString() ?? '',
      );

  final String gan;
  final String zhi;

  List<String> get lines =>
      [gan, zhi].where((s) => s.isNotEmpty).toList(growable: false);
}

/// 五神方位之一
class AlmanacGod {
  const AlmanacGod({this.key = '', this.name = '', this.direction = ''});

  factory AlmanacGod.fromJson(Map<String, dynamic> j) => AlmanacGod(
        key: j['key']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        direction: j['direction']?.toString() ?? '',
      );

  final String key;

  /// 喜神 / 福神 / 财神 / 阳贵 / 阴贵
  final String name;
  final String direction;
}

/// 单个时辰的黄黑道与宜忌。
///
/// 子时被拆成「早子时」（00:00-00:59）与「晚子时」（23:00-23:59），两者干支
/// 与吉凶不同，因此一天是 13 项而非 12 项——用 [slotLabel] 区分展示。
class AlmanacHour {
  const AlmanacHour({
    this.index = 0,
    this.branch = '',
    this.label = '',
    this.slotLabel = '',
    this.range = '',
    this.ganZhi = '',
    this.naYin = '',
    this.tianShen = '',
    this.tianShenType = '',
    this.luck = '',
    this.isLucky = false,
    this.chong = const AlmanacChong(),
    this.caiDirection = '',
    this.yi = const [],
    this.ji = const [],
  });

  factory AlmanacHour.fromJson(Map<String, dynamic> j) => AlmanacHour(
        index: (j['index'] as num?)?.toInt() ?? 0,
        branch: j['branch']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        slotLabel: j['slot_label']?.toString() ?? '',
        range: j['range']?.toString() ?? '',
        ganZhi: j['gan_zhi']?.toString() ?? '',
        naYin: j['na_yin']?.toString() ?? '',
        tianShen: j['tian_shen']?.toString() ?? '',
        tianShenType: j['tian_shen_type']?.toString() ?? '',
        luck: j['luck']?.toString() ?? '',
        isLucky: j['is_lucky'] == true,
        chong: AlmanacChong.fromJson(
            (j['chong'] as Map<String, dynamic>?) ?? const {}),
        caiDirection: j['cai_direction']?.toString() ?? '',
        yi: (j['yi'] as List? ?? const []).map((e) => e.toString()).toList(),
        ji: (j['ji'] as List? ?? const []).map((e) => e.toString()).toList(),
      );

  final int index;
  final String branch;
  final String label;

  /// 如「子时（早）」；非子时与 [label] 相同
  final String slotLabel;

  /// 如「00:00–00:59」
  final String range;
  final String ganZhi;
  final String naYin;
  final String tianShen;

  /// 黄道 / 黑道
  final String tianShenType;
  final String luck;
  final bool isLucky;
  final AlmanacChong chong;
  final String caiDirection;
  final List<String> yi;
  final List<String> ji;
}

/// 当日紫白（与玄空日盘同源）
class AlmanacPurpleWhite {
  const AlmanacPurpleWhite({
    this.centerStar = 0,
    this.centerStarName = '',
    this.escape = '',
    this.escapeDesc = '',
    this.yuan = '',
    this.best,
    this.worst,
    this.calendarExact = true,
  });

  factory AlmanacPurpleWhite.fromJson(Map<String, dynamic> j) =>
      AlmanacPurpleWhite(
        centerStar: (j['center_star'] as num?)?.toInt() ?? 0,
        centerStarName: j['center_star_name']?.toString() ?? '',
        escape: j['escape']?.toString() ?? '',
        escapeDesc: j['escape_desc']?.toString() ?? '',
        yuan: j['yuan']?.toString() ?? '',
        best: j['best'] is Map<String, dynamic>
            ? Extreme.fromJson(j['best'] as Map<String, dynamic>)
            : null,
        worst: j['worst'] is Map<String, dynamic>
            ? Extreme.fromJson(j['worst'] as Map<String, dynamic>)
            : null,
        calendarExact: j['calendar_exact'] != false,
      );

  final int centerStar;
  final String centerStarName;

  /// 阳遁 / 阴遁
  final String escape;
  final String escapeDesc;

  /// 上元 / 中元 / 下元
  final String yuan;

  /// 今日吉位
  final Extreme? best;

  /// 今日忌方
  final Extreme? worst;

  /// 节气是否取自真实历法（false 表示用了近似交节日）
  final bool calendarExact;
}

/// 一日通书
class AlmanacDay {
  const AlmanacDay({
    required this.date,
    this.weekday = '',
    this.weekdayIndex = 0,
    this.lunar = const AlmanacLunar(),
    this.ganZhi = const AlmanacGanZhi(),
    this.xun = const AlmanacXun(),
    this.solarTerm = '',
    this.solarTermRange = '',
    this.jianChu = const AlmanacJianChu(),
    this.tianShen = const AlmanacTianShen(),
    this.xiu = const AlmanacXiu(),
    this.chong = const AlmanacChong(),
    this.naYin = '',
    this.yi = const [],
    this.ji = const [],
    this.allAvoid = false,
    this.jiShen = const [],
    this.xiongSha = const [],
    this.pengZu = const AlmanacPengZu(),
    this.fiveGods = const [],
    this.hours = const [],
    this.luckyHours = const [],
    this.unluckyHours = const [],
    this.purpleWhite = const AlmanacPurpleWhite(),
    this.score = 0,
    this.level = '',
    this.tone = '',
    this.scoreReasons = const [],
    this.rulesVersion = '',
  });

  factory AlmanacDay.fromJson(Map<String, dynamic> j) {
    List<String> strings(String key) =>
        (j[key] as List? ?? const []).map((e) => e.toString()).toList();
    List<AlmanacHour> hours(String key) => (j[key] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AlmanacHour.fromJson)
        .toList();
    return AlmanacDay(
      date: j['date']?.toString() ?? '',
      weekday: j['weekday']?.toString() ?? '',
      weekdayIndex: (j['weekday_index'] as num?)?.toInt() ?? 0,
      lunar: AlmanacLunar.fromJson((j['lunar'] as Map<String, dynamic>?) ?? const {}),
      ganZhi:
          AlmanacGanZhi.fromJson((j['gan_zhi'] as Map<String, dynamic>?) ?? const {}),
      xun: AlmanacXun.fromJson((j['xun'] as Map<String, dynamic>?) ?? const {}),
      solarTerm: j['solar_term']?.toString() ?? '',
      solarTermRange: j['solar_term_range']?.toString() ?? '',
      jianChu: AlmanacJianChu.fromJson(
          (j['jian_chu'] as Map<String, dynamic>?) ?? const {}),
      tianShen: AlmanacTianShen.fromJson(
          (j['tian_shen'] as Map<String, dynamic>?) ?? const {}),
      xiu: AlmanacXiu.fromJson((j['xiu'] as Map<String, dynamic>?) ?? const {}),
      chong: AlmanacChong.fromJson((j['chong'] as Map<String, dynamic>?) ?? const {}),
      naYin: j['na_yin']?.toString() ?? '',
      yi: strings('yi'),
      ji: strings('ji'),
      allAvoid: j['all_avoid'] == true,
      jiShen: strings('ji_shen'),
      xiongSha: strings('xiong_sha'),
      pengZu:
          AlmanacPengZu.fromJson((j['peng_zu'] as Map<String, dynamic>?) ?? const {}),
      fiveGods: (j['five_gods'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AlmanacGod.fromJson)
          .toList(),
      hours: hours('hours'),
      luckyHours: hours('lucky_hours'),
      unluckyHours: hours('unlucky_hours'),
      purpleWhite: AlmanacPurpleWhite.fromJson(
          (j['purple_white'] as Map<String, dynamic>?) ?? const {}),
      score: (j['score'] as num?)?.toInt() ?? 0,
      level: j['level']?.toString() ?? '',
      tone: j['tone']?.toString() ?? '',
      scoreReasons: strings('score_reasons'),
      rulesVersion: j['rules_version']?.toString() ?? '',
    );
  }

  final String date;
  final String weekday;
  final int weekdayIndex;
  final AlmanacLunar lunar;
  final AlmanacGanZhi ganZhi;
  final AlmanacXun xun;

  /// 当日若交节则为节气名，否则空
  final String solarTerm;

  /// 所处节气区间，如「寒露后 · 霜降前」
  final String solarTermRange;
  final AlmanacJianChu jianChu;
  final AlmanacTianShen tianShen;
  final AlmanacXiu xiu;
  final AlmanacChong chong;
  final String naYin;

  /// 宜（服务端已剔除字面量「无」）
  final List<String> yi;

  /// 忌
  final List<String> ji;

  /// 忌项含「诸事不宜」
  final bool allAvoid;
  final List<String> jiShen;
  final List<String> xiongSha;
  final AlmanacPengZu pengZu;
  final List<AlmanacGod> fiveGods;

  /// 十三时辰（子时拆早晚）
  final List<AlmanacHour> hours;
  final List<AlmanacHour> luckyHours;
  final List<AlmanacHour> unluckyHours;
  final AlmanacPurpleWhite purpleWhite;

  /// 当日总体吉凶分（不含具体事项）
  final int score;
  final String level;

  /// 配色档：旺 / 平 / 煞 / 大凶（与九宫格同值域）
  final String tone;

  /// 逐条打分依据
  final List<String> scoreReasons;
  final String rulesVersion;

  /// 形如「2026-10-14」→ DateTime；解析失败返回 null
  DateTime? get day =>
      DateTime.tryParse('$date 00:00:00') ?? DateTime.tryParse(date);

  /// 「周三 · 农历九月初五」这类副标题
  String get subtitle {
    final parts = <String>[weekday];
    if (lunar.text.isNotEmpty) parts.add('农历${lunar.text}');
    return parts.where((s) => s.isNotEmpty).join(' · ');
  }
}

/// 可择日的事项
class AlmanacActivity {
  const AlmanacActivity({
    required this.key,
    required this.name,
    this.terms = const [],
    this.note = '',
  });

  factory AlmanacActivity.fromJson(Map<String, dynamic> j) => AlmanacActivity(
        key: j['key']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        terms: (j['terms'] as List? ?? const []).map((e) => e.toString()).toList(),
        note: j['note']?.toString() ?? '',
      );

  final String key;
  final String name;
  final List<String> terms;
  final String note;
}

/// 择日结果中的可用吉时
class AlmanacLuckyHour {
  const AlmanacLuckyHour({
    this.label = '',
    this.range = '',
    this.tianShen = '',
    this.ganZhi = '',
  });

  factory AlmanacLuckyHour.fromJson(Map<String, dynamic> j) => AlmanacLuckyHour(
        label: j['label']?.toString() ?? '',
        range: j['range']?.toString() ?? '',
        tianShen: j['tian_shen']?.toString() ?? '',
        ganZhi: j['gan_zhi']?.toString() ?? '',
      );

  final String label;
  final String range;
  final String tianShen;
  final String ganZhi;

  String get display => '$label $range';
}

/// 择日结果的一条候选日
class AlmanacPick {
  const AlmanacPick({
    required this.date,
    this.weekday = '',
    this.lunar = '',
    this.ganZhi = '',
    this.jianChu = '',
    this.jianChuLabel = '',
    this.jianChuTone = '',
    this.tianShen = '',
    this.tianShenType = '',
    this.xiu = '',
    this.xiuLuck = '',
    this.chong = const AlmanacChong(),
    this.score = 0,
    this.level = '',
    this.tone = '',
    this.hits = const [],
    this.misses = const [],
    this.reasons = const [],
    this.clash = false,
    this.luckyHourCount = 0,
    this.luckyHours = const [],
    this.bestHour = '',
  });

  factory AlmanacPick.fromJson(Map<String, dynamic> j) => AlmanacPick(
        date: j['date']?.toString() ?? '',
        weekday: j['weekday']?.toString() ?? '',
        lunar: j['lunar']?.toString() ?? '',
        ganZhi: j['gan_zhi']?.toString() ?? '',
        jianChu: j['jian_chu']?.toString() ?? '',
        jianChuLabel: j['jian_chu_label']?.toString() ?? '',
        jianChuTone: j['jian_chu_tone']?.toString() ?? '',
        tianShen: j['tian_shen']?.toString() ?? '',
        tianShenType: j['tian_shen_type']?.toString() ?? '',
        xiu: j['xiu']?.toString() ?? '',
        xiuLuck: j['xiu_luck']?.toString() ?? '',
        chong: AlmanacChong.fromJson(
            (j['chong'] as Map<String, dynamic>?) ?? const {}),
        score: (j['score'] as num?)?.toInt() ?? 0,
        level: j['level']?.toString() ?? '',
        tone: j['tone']?.toString() ?? '',
        hits: (j['hits'] as List? ?? const []).map((e) => e.toString()).toList(),
        misses:
            (j['misses'] as List? ?? const []).map((e) => e.toString()).toList(),
        reasons:
            (j['reasons'] as List? ?? const []).map((e) => e.toString()).toList(),
        clash: j['clash'] == true,
        luckyHourCount: (j['lucky_hour_count'] as num?)?.toInt() ?? 0,
        luckyHours: (j['lucky_hours'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AlmanacLuckyHour.fromJson)
            .toList(),
        bestHour: j['best_hour']?.toString() ?? '',
      );

  final String date;
  final String weekday;
  final String lunar;
  final String ganZhi;
  final String jianChu;
  final String jianChuLabel;
  final String jianChuTone;
  final String tianShen;
  final String tianShenType;
  final String xiu;
  final String xiuLuck;
  final AlmanacChong chong;
  final int score;
  final String level;
  final String tone;

  /// 命中的宜项
  final List<String> hits;

  /// 命中的忌项
  final List<String> misses;

  /// 逐条打分依据
  final List<String> reasons;

  /// 是否冲用户生肖（仍会展示，但显式标注）
  final bool clash;
  final int luckyHourCount;
  final List<AlmanacLuckyHour> luckyHours;
  final String bestHour;

  /// 「10月17日 · 周二」这类紧凑标签
  String get shortLabel {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return '${parsed.month}月${parsed.day}日 · $weekday';
  }
}

/// 择日区间
class AlmanacSelectRange {
  const AlmanacSelectRange({this.start = '', this.end = '', this.days = 0});

  factory AlmanacSelectRange.fromJson(Map<String, dynamic> j) =>
      AlmanacSelectRange(
        start: j['start']?.toString() ?? '',
        end: j['end']?.toString() ?? '',
        days: (j['days'] as num?)?.toInt() ?? 0,
      );

  final String start;
  final String end;
  final int days;
}

/// 择日结果
class AlmanacSelectResult {
  const AlmanacSelectResult({
    required this.activity,
    this.range = const AlmanacSelectRange(),
    this.zodiac = '',
    this.minScore = 0,
    this.scanned = 0,
    this.recommendedCount = 0,
    this.items = const [],
    this.best,
    this.rulesVersion = '',
  });

  factory AlmanacSelectResult.fromJson(Map<String, dynamic> j) =>
      AlmanacSelectResult(
        activity: AlmanacActivity.fromJson(
            (j['activity'] as Map<String, dynamic>?) ?? const {}),
        range: AlmanacSelectRange.fromJson(
            (j['range'] as Map<String, dynamic>?) ?? const {}),
        zodiac: j['zodiac']?.toString() ?? '',
        minScore: (j['min_score'] as num?)?.toInt() ?? 0,
        scanned: (j['scanned'] as num?)?.toInt() ?? 0,
        recommendedCount: (j['recommended_count'] as num?)?.toInt() ?? 0,
        items: (j['items'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AlmanacPick.fromJson)
            .toList(),
        best: j['best'] is Map<String, dynamic>
            ? AlmanacPick.fromJson(j['best'] as Map<String, dynamic>)
            : null,
        rulesVersion: j['rules_version']?.toString() ?? '',
      );

  final AlmanacActivity activity;
  final AlmanacSelectRange range;
  final String zodiac;
  final int minScore;
  final int scanned;

  /// 达标条数（可能大于 [items] 长度，已按 limit 截断）
  final int recommendedCount;

  /// 按分数降序
  final List<AlmanacPick> items;

  /// 区间内最高分的一天
  final AlmanacPick? best;
  final String rulesVersion;
}

/// 月历中的单日
class AlmanacCalendarDay {
  const AlmanacCalendarDay({
    required this.date,
    this.day = 0,
    this.weekday = '',
    this.lunarDay = '',
    this.score = 0,
    this.level = '',
    this.tone = '',
    this.jianChu = '',
    this.xiu = '',
    this.xiuLuck = '',
    this.chong = '',
    this.clash = false,
    this.luckyHourCount = 0,
  });

  factory AlmanacCalendarDay.fromJson(Map<String, dynamic> j) =>
      AlmanacCalendarDay(
        date: j['date']?.toString() ?? '',
        day: (j['day'] as num?)?.toInt() ?? 0,
        weekday: j['weekday']?.toString() ?? '',
        lunarDay: j['lunar_day']?.toString() ?? '',
        score: (j['score'] as num?)?.toInt() ?? 0,
        level: j['level']?.toString() ?? '',
        tone: j['tone']?.toString() ?? '',
        jianChu: j['jian_chu']?.toString() ?? '',
        xiu: j['xiu']?.toString() ?? '',
        xiuLuck: j['xiu_luck']?.toString() ?? '',
        chong: j['chong']?.toString() ?? '',
        clash: j['clash'] == true,
        luckyHourCount: (j['lucky_hour_count'] as num?)?.toInt() ?? 0,
      );

  final String date;
  final int day;
  final String weekday;
  final String lunarDay;
  final int score;
  final String level;
  final String tone;
  final String jianChu;
  final String xiu;
  final String xiuLuck;
  final String chong;
  final bool clash;
  final int luckyHourCount;
}

/// 整月每日吉凶（月历热力）
class AlmanacCalendar {
  const AlmanacCalendar({
    required this.year,
    required this.month,
    this.activityName = '',
    this.zodiac = '',
    this.firstWeekday = 0,
    this.days = const [],
    this.best,
    this.rulesVersion = '',
  });

  factory AlmanacCalendar.fromJson(Map<String, dynamic> j) {
    final activity = j['activity'];
    return AlmanacCalendar(
      year: (j['year'] as num?)?.toInt() ?? 0,
      month: (j['month'] as num?)?.toInt() ?? 0,
      activityName: activity is Map<String, dynamic>
          ? activity['name']?.toString() ?? ''
          : '',
      zodiac: j['zodiac']?.toString() ?? '',
      firstWeekday: (j['first_weekday'] as num?)?.toInt() ?? 0,
      days: (j['days'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AlmanacCalendarDay.fromJson)
          .toList(),
      best: j['best'] is Map<String, dynamic>
          ? AlmanacCalendarDay.fromJson(j['best'] as Map<String, dynamic>)
          : null,
      rulesVersion: j['rules_version']?.toString() ?? '',
    );
  }

  final int year;
  final int month;

  /// 为空表示「当日总体吉凶」
  final String activityName;
  final String zodiac;

  /// 当月 1 日是周几，0=周一（与 Dart 的 DateTime.weekday-1 对齐）
  final int firstWeekday;
  final List<AlmanacCalendarDay> days;
  final AlmanacCalendarDay? best;
  final String rulesVersion;
}
