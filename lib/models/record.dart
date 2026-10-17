/// 测算记录：某次测算的**参数**快照，不是结果。
///
/// 打开记录时由各测算页按 [params] 重新请求对应计算接口——引擎规则随
/// RULES_VERSION 改版（文案与权重都绑版本），存结果快照会留下过期判词；
/// 而六爻 / 梅花的服务端装卦是纯函数（不含随机数），同一份入参必然还原
/// 同一次测算。号码八星刻意不在可保存范围（隐私：不落完整号码）。
class CalcRecord {
  const CalcRecord({
    required this.id,
    required this.kind,
    required this.title,
    this.summary = '',
    this.params = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// 测算类型，见 [kRecordKindLabels]；后端白名单是权威校验
  final String kind;
  final String title;
  final String summary;

  /// 测算入参。列表接口不下发（保持列表轻量），只有详情接口带
  final Map<String, dynamic> params;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CalcRecord.fromJson(Map<String, dynamic> json) {
    return CalcRecord(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      params: (json['params'] as Map?)?.cast<String, dynamic>() ?? const {},
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}

/// 测算类型 → 展示名。后端 `RECORD_KINDS` 是权威白名单（有测试锁住），
/// 这里只管展示；新增 kind 时两边同步加。查不到时回退显示 kind 本身。
const Map<String, String> kRecordKindLabels = {
  'bazi': '八字 · 紫微排盘',
  'bazhai': '八宅游年',
  'xuankong': '玄空飞星',
  'almanac': '黄历通书',
  'divination': '六爻 · 梅花问事',
  'marriage': '合婚配对',
  'diagnose': '户型诊断',
};

/// 记录列表里用的类型名；未收录的新 kind 原样显示，不崩。
String recordKindLabel(String kind) => kRecordKindLabels[kind] ?? kind;
