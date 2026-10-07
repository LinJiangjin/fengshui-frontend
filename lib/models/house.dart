import '../services/compass_service.dart';
import 'orientation_calc.dart';

/// 磁偏角默认值（真北 = 磁北 + 偏角）。
///
/// 磁偏角随地区与时间变化，全国并没有统一值，因此默认 0 表示「未设置」，
/// 由用户在房屋档案里确认；房屋档案里改了就按房屋的来。
const double kDefaultDeclination = 0.0;

/// 房间档案：只记「房间名 + 落在哪一宫」。
///
/// 宫位用固定方位九宫索引（与 [PalaceGrid.fixedOrder] 一致）：
/// ```
/// 0 东南  1 正南  2 西南
/// 3 正东  4 中宫  5 正西
/// 6 东北  7 正北  8 西北
/// ```
/// 渲染时再按房屋向方旋转到实际位置；同一宫位放多个房间会自动均分该格。
class RoomProfile {
  RoomProfile({
    required this.id,
    required this.name,
    required this.cell,
  });

  final String id;
  final String name;

  /// 所在宫位索引 0..8
  final int cell;

  RoomProfile copyWith({String? id, String? name, int? cell}) => RoomProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        cell: cell ?? this.cell,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cell': cell,
      };

  factory RoomProfile.fromJson(Map<String, dynamic> j) => RoomProfile(
        id: j['id'] ?? newRoomId(),
        name: j['name'] ?? '房间',
        cell: (j['cell'] as num?)?.toInt().clamp(0, 8) ?? 4,
      );
}

/// 新房间 id
String newRoomId() => 'room_${DateTime.now().microsecondsSinceEpoch}';

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
    /// 磁北读数；为 null 表示尚未用罗盘测量
    this.degree,
    this.declination = kDefaultDeclination,
    int? year,
    List<RoomProfile>? rooms,
  })  : year = year ?? DateTime.now().year,
        rooms = rooms ?? const [];

  /// 唯一标识（新建时用时间戳生成）
  final String id;

  /// 小区 / 楼盘名，如「朗诗国际」
  final String name;

  /// 户型，如「3室2厅」
  final String layout;

  /// 建筑面积（㎡）
  final double area;

  /// 手机读取的磁方位角（磁北 0~359）；null = 未测量，等罗盘回写
  final double? degree;

  /// 当地磁偏角
  final double declination;

  /// 流年（默认当前公历年）
  final int year;

  /// 房间列表；未录入时为空，由用户在「我的房屋」里添加
  final List<RoomProfile> rooms;

  /// 是否已测量坐向（坐向由罗盘测量回写，不是手填的）
  bool get measured => degree != null;

  /// 真北坐向度数 = 磁北 + 磁偏角；未测量时为 null
  double? get trueNorth =>
      degree == null ? null : Angle.normalize(degree! + declination);

  /// 是否已录入磁偏角（0 视为未设置，需要用户确认）
  bool get hasDeclination => declination != 0;

  /// 卡片 / 标题展示名：朗诗国际 3室2厅
  String get displayName => layout.isEmpty ? name : '$name $layout';

  /// 面积文案：96㎡ / 89.5㎡
  String get areaText =>
      '${area.toStringAsFixed(area.truncateToDouble() == area ? 0 : 1)}㎡';

  /// 本地换算的坐向（与后端 engine/compass.py 规则一致）；未测量时为 null
  OrientationResult? get orientation {
    final t = trueNorth;
    return t == null ? null : OrientationCalc.of(t);
  }

  HouseProfile copyWith({
    String? id,
    String? name,
    String? layout,
    double? area,
    double? degree,
    double? declination,
    int? year,
    List<RoomProfile>? rooms,
  }) {
    return HouseProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      layout: layout ?? this.layout,
      area: area ?? this.area,
      degree: degree ?? this.degree,
      declination: declination ?? this.declination,
      year: year ?? this.year,
      rooms: rooms ?? this.rooms,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'layout': layout,
        'area': area,
        // null = 未测量，反序列化后仍是 null，不会退化成 0 度
        'degree': degree,
        'declination': declination,
        'year': year,
        'rooms': rooms.map((r) => r.toJson()).toList(),
      };

  factory HouseProfile.fromJson(Map<String, dynamic> j) => HouseProfile(
        id: j['id'] ?? newHouseId(),
        name: j['name'] ?? '我的房屋',
        layout: j['layout'] ?? '',
        area: (j['area'] as num?)?.toDouble() ?? 0.0,
        degree: (j['degree'] as num?)?.toDouble(),
        declination: (j['declination'] as num?)?.toDouble() ?? kDefaultDeclination,
        year: (j['year'] as num?)?.toInt() ?? DateTime.now().year,
        rooms: (j['rooms'] as List? ?? [])
            .map((e) => RoomProfile.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 新房屋 id：时间戳，保证本地唯一
String newHouseId() => 'house_${DateTime.now().microsecondsSinceEpoch}';
