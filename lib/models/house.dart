import '../services/compass_service.dart';
import 'orientation_calc.dart';

/// 当地磁偏角默认值（真北 = 磁北 + 偏角）。
/// 每套房屋可单独覆盖，房屋档案里改了就按房屋的来。
const double kDefaultDeclination = -5.2;

/// 房屋档案 —— 诊断结果的唯一输入源。
///
/// 后端不存业务数据，前端把房屋信息（名称 / 户型 / 面积 / 坐向 / 磁偏角）
/// 作为入参传给 `/api/v1/diagnose`，分数、坐向、指标全部由后端规则引擎算出。
class HouseProfile {
  HouseProfile({
    required this.id,
    required this.name,
    required this.layout,
    required this.area,
    required this.degree,
    this.declination = kDefaultDeclination,
    int? year,
  }) : year = year ?? DateTime.now().year;

  /// 唯一标识（新建时用时间戳生成）
  final String id;

  /// 小区 / 楼盘名，如「朗诗国际」
  final String name;

  /// 户型，如「3室2厅」
  final String layout;

  /// 建筑面积（㎡）
  final double area;

  /// 手机读取的磁方位角（磁北 0~359）
  final double degree;

  /// 当地磁偏角
  final double declination;

  /// 流年（默认当前公历年）
  final int year;

  /// 真北坐向度数 = 磁北 + 磁偏角
  double get trueNorth => Angle.normalize(degree + declination);

  /// 卡片 / 标题展示名：朗诗国际 3室2厅
  String get displayName => layout.isEmpty ? name : '$name $layout';

  /// 面积文案：96㎡ / 89.5㎡
  String get areaText =>
      '${area.toStringAsFixed(area.truncateToDouble() == area ? 0 : 1)}㎡';

  /// 本地换算的坐向（与后端 engine/compass.py 规则一致）
  OrientationResult get orientation => OrientationCalc.of(trueNorth);

  HouseProfile copyWith({
    String? id,
    String? name,
    String? layout,
    double? area,
    double? degree,
    double? declination,
    int? year,
  }) {
    return HouseProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      layout: layout ?? this.layout,
      area: area ?? this.area,
      degree: degree ?? this.degree,
      declination: declination ?? this.declination,
      year: year ?? this.year,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'layout': layout,
        'area': area,
        'degree': degree,
        'declination': declination,
        'year': year,
      };

  factory HouseProfile.fromJson(Map<String, dynamic> j) => HouseProfile(
        id: j['id'] ?? newHouseId(),
        name: j['name'] ?? '我的房屋',
        layout: j['layout'] ?? '',
        area: (j['area'] as num?)?.toDouble() ?? 96.0,
        degree: (j['degree'] as num?)?.toDouble() ?? 0.0,
        declination: (j['declination'] as num?)?.toDouble() ?? kDefaultDeclination,
        year: (j['year'] as num?)?.toInt() ?? DateTime.now().year,
      );

  /// 首次启动的示例房屋（可随时在「我的房屋」里改或删）
  factory HouseProfile.seed() => HouseProfile(
        id: 'house_seed',
        name: '朗诗国际',
        layout: '3室2厅',
        area: 96,
        degree: 358,
      );
}

/// 新房屋 id：时间戳，保证本地唯一
String newHouseId() => 'house_${DateTime.now().microsecondsSinceEpoch}';
