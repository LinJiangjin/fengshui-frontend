import 'package:flutter/material.dart' show TimeOfDay;

/// 命理档案：用户录入过的出生信息。
///
/// 同一份数据既用于排盘（POST /api/v1/bazi），也用于落库
/// （PUT /api/v1/bazi/profile），字段名与后端保持一一对应，
/// 避免各层之间来回改名导致对不上。
class BaziRecord {
  const BaziRecord({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.gender,
    required this.longitude,
    this.name = '',
    this.province = '',
    this.city = '',
    this.id = '',
    this.pillars = '',
    this.updatedAt,
  });

  /// 从页面上的日期 / 时刻选择器构造
  factory BaziRecord.fromDateTime({
    required DateTime date,
    required TimeOfDay time,
    required String gender,
    required double longitude,
    String name = '',
    String province = '',
    String city = '',
    String id = '',
    String pillars = '',
    DateTime? updatedAt,
  }) {
    return BaziRecord(
      year: date.year,
      month: date.month,
      day: date.day,
      hour: time.hour,
      minute: time.minute,
      gender: gender,
      longitude: longitude,
      name: name,
      province: province,
      city: city,
      id: id,
      pillars: pillars,
      updatedAt: updatedAt,
    );
  }

  factory BaziRecord.fromJson(Map<String, dynamic> json) => BaziRecord(
        id: json['id']?.toString() ?? '',
        year: (json['year'] as num?)?.toInt() ?? 1900,
        month: (json['month'] as num?)?.toInt() ?? 1,
        day: (json['day'] as num?)?.toInt() ?? 1,
        hour: (json['hour'] as num?)?.toInt() ?? 0,
        minute: (json['minute'] as num?)?.toInt() ?? 0,
        gender: json['gender']?.toString() ?? '男',
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        name: json['name']?.toString() ?? '',
        province: json['province']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        pillars: json['pillars']?.toString() ?? '',
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      );

  /// 服务端记录 id；本地草稿阶段为空
  final String id;

  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;

  /// 男 / 女
  final String gender;

  /// 出生地东经度数（真太阳时校正用，必填）
  final double longitude;

  /// 姓名（可选）
  final String name;

  /// 出生地省份 / 城市，仅作回显
  final String province;
  final String city;

  /// 四柱摘要（服务端算好回传，仅用于展示）
  final String pillars;

  final DateTime? updatedAt;

  DateTime get date => DateTime(year, month, day);

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  /// 出生地回显：「广东 · 广州」；只填了省或市时退化成单个
  String get placeText {
    if (province.isEmpty) return city;
    if (city.isEmpty) return province;
    return '$province · $city';
  }

  /// 提交给后端的请求体（id / pillars / 时间戳由服务端生成，不回传）
  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'day': day,
        'hour': hour,
        'minute': minute,
        'gender': gender,
        'longitude': longitude,
        'name': name,
        'province': province,
        'city': city,
      };
}
